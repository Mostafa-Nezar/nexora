import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/transfer_models.dart';

class DeviceSharingService extends ChangeNotifier {
  static final DeviceSharingService _instance = DeviceSharingService._internal();
  factory DeviceSharingService() => _instance;
  DeviceSharingService._internal();

  static const int broadcastPort = 52141;
  static const int tcpTransferPort = 52140;
  static const String protocolMagic = 'TOOLS_SHARE_V1';

  // Identity
  String deviceId = '';
  String deviceName = 'My Device';
  DevicePlatformType devicePlatform = DevicePlatformType.unknown;
  String currentPin = '1234';
  String currentLocalIp = '127.0.0.1';

  // Network Sockets
  RawDatagramSocket? _discoverySocket;
  ServerSocket? _serverSocket;
  Timer? _beaconTimer;
  Timer? _cleanupTimer;

  // State
  bool isBroadcasting = false;
  bool isServerRunning = false;
  final Map<String, DiscoveredDevice> _discoveredDevices = {};
  List<DiscoveredDevice> get nearbyDevices => _discoveredDevices.values.toList();

  final List<TransferItem> _transfers = [];
  List<TransferItem> get transfers => List.unmodifiable(_transfers);

  // Incoming transfer requests awaiting user approval
  final StreamController<IncomingTransferPrompt> _incomingTransferController =
      StreamController<IncomingTransferPrompt>.broadcast();
  Stream<IncomingTransferPrompt> get incomingTransfers => _incomingTransferController.stream;

  // Active sockets for pause/cancel
  final Map<String, Socket> _activeTransferSockets = {};
  final Set<String> _pausedTransferIds = {};

  Future<void> initialize() async {
    _generateRandomPin();
    await _resolveDeviceInfo();
    await _detectLocalIp();
    await startReceiverServer();
    startDiscovery();
  }

  void _generateRandomPin() {
    final rand = Random();
    currentPin = (1000 + rand.nextInt(9000)).toString();
  }

  Future<void> _resolveDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        devicePlatform = DevicePlatformType.android;
        final info = await deviceInfo.androidInfo;
        deviceName = '${info.brand.toUpperCase()} ${info.model}';
        deviceId = info.id.isNotEmpty ? info.id : 'android_${info.fingerprint.hashCode}';
      } else if (Platform.isIOS) {
        devicePlatform = DevicePlatformType.ios;
        final info = await deviceInfo.iosInfo;
        deviceName = info.name.isNotEmpty ? info.name : 'iPhone';
        deviceId = info.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isWindows) {
        devicePlatform = DevicePlatformType.windows;
        final info = await deviceInfo.windowsInfo;
        deviceName = info.computerName.isNotEmpty ? info.computerName : 'Windows PC';
        deviceId = info.deviceId;
      } else if (Platform.isMacOS) {
        devicePlatform = DevicePlatformType.macos;
        final info = await deviceInfo.macOsInfo;
        deviceName = info.computerName;
        deviceId = info.systemGUID ?? 'mac_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        devicePlatform = DevicePlatformType.unknown;
        deviceName = 'Tools Device';
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      deviceName = 'Tools Device';
      deviceId = 'tools_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('169.254')) {
            currentLocalIp = addr.address;
            notifyListeners();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error detecting IP: $e');
    }
  }

  // ----------------------------------------------------
  // Discovery: High-Speed UDP Broadcast & Multicast
  // ----------------------------------------------------
  Future<void> startDiscovery() async {
    if (isBroadcasting) return;
    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
        reuseAddress: true,
        reusePort: false,
      );
      _discoverySocket?.broadcastEnabled = true;
      _discoverySocket?.multicastLoopback = false;

      _discoverySocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket?.receive();
          if (datagram != null) {
            _handleDiscoveryPacket(datagram);
          }
        }
      });

      isBroadcasting = true;

      // Broadcast beacon periodically (every 1.5 seconds)
      _beaconTimer?.cancel();
      _beaconTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        broadcastBeacon();
      });

      // Periodic cleanup of stale devices (> 6 seconds without beacon)
      _cleanupTimer?.cancel();
      _cleanupTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        final now = DateTime.now();
        final initialLen = _discoveredDevices.length;
        _discoveredDevices.removeWhere((id, dev) => now.difference(dev.lastSeen).inSeconds > 6);
        if (_discoveredDevices.length != initialLen) {
          notifyListeners();
        }
      });

      broadcastBeacon();
      notifyListeners();
    } catch (e) {
      debugPrint('UDP Discovery error: $e');
    }
  }

  void broadcastBeacon() {
    if (_discoverySocket == null) return;
    try {
      final payload = jsonEncode({
        'magic': protocolMagic,
        'type': 'BEACON',
        'id': deviceId,
        'name': deviceName,
        'platform': devicePlatform.name,
        'ip': currentLocalIp,
        'port': tcpTransferPort,
        'pin': currentPin,
      });
      final bytes = utf8.encode(payload);
      _discoverySocket?.send(bytes, InternetAddress('255.255.255.255'), broadcastPort);
    } catch (e) {
      debugPrint('Broadcast beacon error: $e');
    }
  }

  void _handleDiscoveryPacket(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (json['magic'] != protocolMagic) return;

      final senderId = json['id'] as String?;
      if (senderId == null || senderId == deviceId) return; // Ignore own beacon

      final remoteDevice = DiscoveredDevice.fromJson(json, datagram.address.address);
      _discoveredDevices[remoteDevice.id] = remoteDevice;
      notifyListeners();
    } catch (_) {}
  }

  void stopDiscovery() {
    _beaconTimer?.cancel();
    _cleanupTimer?.cancel();
    _discoverySocket?.close();
    _discoverySocket = null;
    isBroadcasting = false;
    _discoveredDevices.clear();
    notifyListeners();
  }

  // ----------------------------------------------------
  // High-Speed Local TCP Server for File Reception
  // ----------------------------------------------------
  Future<void> startReceiverServer() async {
    if (isServerRunning) return;
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, tcpTransferPort);
      isServerRunning = true;
      _serverSocket?.listen(_handleIncomingConnection, onError: (e) {
        debugPrint('Server socket error: $e');
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Receiver server bind error: $e');
    }
  }

  void _handleIncomingConnection(Socket socket) {
    List<int> buffer = [];
    bool headerReceived = false;
    Map<String, dynamic>? metadata;
    IOSink? fileSink;
    File? tempFile;
    int expectedFileSize = 0;
    int receivedBytes = 0;
    TransferItem? transferItem;
    DateTime lastSpeedCheck = DateTime.now();
    int lastCheckBytes = 0;
    Digest? calculatedDigest;
    final shaSink = sha256.startChunkedConversion(
      ChunkedConversionSink<Digest>.withCallback((accumulated) {
        if (accumulated.isNotEmpty) {
          calculatedDigest = accumulated.single;
        }
      }),
    );

    socket.listen(
      (chunk) async {
        if (!headerReceived) {
          buffer.addAll(chunk);
          final nullTerminator = buffer.indexOf(0); // 0 byte terminates JSON header
          if (nullTerminator != -1) {
            headerReceived = true;
            final headerBytes = buffer.sublist(0, nullTerminator);
            final remainingPayload = buffer.sublist(nullTerminator + 1);
            buffer.clear();

            try {
              final headerJson = utf8.decode(headerBytes);
              metadata = jsonDecode(headerJson) as Map<String, dynamic>;

              final transferId = metadata!['transferId'] as String;
              final fileName = metadata!['fileName'] as String;
              expectedFileSize = (metadata!['fileSize'] as num).toInt();
              final remoteDevName = metadata!['senderName'] as String? ?? 'Remote Device';
              final providedPin = metadata!['pin'] as String? ?? '';
              final expectedSha = metadata!['checksum'] as String? ?? '';

              // Create Transfer Item
              transferItem = TransferItem(
                id: transferId,
                fileName: fileName,
                fileSize: expectedFileSize,
                direction: TransferDirection.receive,
                remoteDeviceName: remoteDevName,
                status: TransferStatus.connecting,
                checksumSha256: expectedSha,
              );
              _transfers.insert(0, transferItem!);
              _activeTransferSockets[transferId] = socket;
              notifyListeners();

              // Prompt User for approval or check PIN
              final prompt = IncomingTransferPrompt(
                transferId: transferId,
                senderName: remoteDevName,
                fileName: fileName,
                fileSize: expectedFileSize,
                pin: providedPin,
              );

              // If pin matches current device pin or user accepts
              final accepted = await _askForApproval(prompt);
              if (!accepted) {
                socket.write(jsonEncode({'status': 'REJECTED'}) + '\n');
                transferItem!.status = TransferStatus.rejected;
                transferItem!.errorMessage = 'Rejected by recipient';
                notifyListeners();
                await socket.close();
                return;
              }

              // Ready to receive - Prepare file
              final saveDir = await _getDownloadDirectory();
              final safeFileName = _getUniqueFileName(saveDir.path, fileName);
              tempFile = File(p.join(saveDir.path, safeFileName));
              fileSink = tempFile!.openWrite();

              // Send ACCEPTED response to sender
              socket.write(jsonEncode({'status': 'ACCEPTED'}) + '\n');
              transferItem!.status = TransferStatus.transferring;
              notifyListeners();

              // Feed leftover bytes if any
              if (remainingPayload.isNotEmpty) {
                receivedBytes += remainingPayload.length;
                shaSink.add(remainingPayload);
                fileSink!.add(remainingPayload);
                transferItem!.transferredBytes = receivedBytes;
              }
            } catch (err) {
              socket.write(jsonEncode({'status': 'ERROR', 'msg': err.toString()}) + '\n');
              await socket.close();
            }
          }
        } else {
          // Streaming high speed payload chunks
          if (_pausedTransferIds.contains(transferItem?.id)) {
            // transfer paused
            return;
          }

          receivedBytes += chunk.length;
          shaSink.add(chunk);
          fileSink?.add(chunk);

          if (transferItem != null) {
            transferItem!.transferredBytes = receivedBytes;

            // Speed calculation every 400ms
            final now = DateTime.now();
            final elapsedMs = now.difference(lastSpeedCheck).inMilliseconds;
            if (elapsedMs >= 400) {
              final bytesInInterval = receivedBytes - lastCheckBytes;
              transferItem!.speedBytesPerSec = (bytesInInterval / elapsedMs) * 1000;
              lastSpeedCheck = now;
              lastCheckBytes = receivedBytes;
              notifyListeners();
            }

            if (receivedBytes >= expectedFileSize) {
              await fileSink?.flush();
              await fileSink?.close();
              shaSink.close();

              final calculatedSha = calculatedDigest?.toString() ?? '';
              final expectedSha = metadata?['checksum'] as String? ?? '';

              bool integrityVerified = true;
              if (expectedSha.isNotEmpty && calculatedSha != expectedSha) {
                integrityVerified = false;
              }

              transferItem!.status = integrityVerified ? TransferStatus.completed : TransferStatus.failed;
              if (!integrityVerified) {
                transferItem!.errorMessage = 'Checksum integrity verification failed!';
              }
              transferItem!.speedBytesPerSec = 0;
              notifyListeners();

              socket.write(jsonEncode({
                'status': integrityVerified ? 'SUCCESS' : 'FAILED',
                'checksum': calculatedSha,
              }) + '\n');
              await socket.close();
            }
          }
        }
      },
      onDone: () async {
        await fileSink?.close();
        if (transferItem != null && transferItem!.status == TransferStatus.transferring) {
          transferItem!.status = TransferStatus.cancelled;
          notifyListeners();
        }
      },
      onError: (err) async {
        await fileSink?.close();
        if (transferItem != null) {
          transferItem!.status = TransferStatus.failed;
          transferItem!.errorMessage = err.toString();
          notifyListeners();
        }
      },
      cancelOnError: true,
    );
  }

  Future<bool> _askForApproval(IncomingTransferPrompt prompt) {
    final completer = Completer<bool>();
    prompt.completer = completer;
    _incomingTransferController.add(prompt);
    // Timeout auto reject after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) completer.complete(false);
    });
    return completer.future;
  }

  // ----------------------------------------------------
  // Sender Client: High-Speed Streaming Sender
  // ----------------------------------------------------
  Future<void> sendFiles({
    required DiscoveredDevice targetDevice,
    required List<File> files,
    String? pin,
  }) async {
    for (final file in files) {
      await _sendFile(targetDevice: targetDevice, file: file, pin: pin);
    }
  }

  Future<void> _sendFile({
    required DiscoveredDevice targetDevice,
    required File file,
    String? pin,
  }) async {
    if (!await file.exists()) return;

    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final transferId = 'tx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    // Compute checksum (SHA-256) streaming for integrity
    final fileBytesForSha = file.openRead();
    final sha = await sha256.bind(fileBytesForSha).first;
    final checksum = sha.toString();

    final item = TransferItem(
      id: transferId,
      fileName: fileName,
      fileSize: fileSize,
      filePath: file.path,
      direction: TransferDirection.send,
      remoteDeviceName: targetDevice.name,
      status: TransferStatus.connecting,
      checksumSha256: checksum,
    );

    _transfers.insert(0, item);
    notifyListeners();

    Socket? socket;
    try {
      socket = await Socket.connect(
        targetDevice.ip,
        targetDevice.port,
        timeout: const Duration(seconds: 8),
      );
      _activeTransferSockets[transferId] = socket;

      // Send JSON Header followed by 0-byte delimiter
      final header = {
        'magic': protocolMagic,
        'transferId': transferId,
        'fileName': fileName,
        'fileSize': fileSize,
        'senderName': deviceName,
        'checksum': checksum,
        'pin': pin ?? currentPin,
      };

      final headerBytes = utf8.encode(jsonEncode(header));
      socket.add(headerBytes);
      socket.add([0]); // Delimiter

      // Wait for Receiver acceptance
      final responseCompleter = Completer<bool>();
      StringBuffer lineBuffer = StringBuffer();

      late StreamSubscription sub;
      sub = socket.listen((data) {
        final text = utf8.decode(data);
        lineBuffer.write(text);
        if (lineBuffer.toString().contains('\n')) {
          final line = lineBuffer.toString().split('\n').first;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            if (json['status'] == 'ACCEPTED') {
              if (!responseCompleter.isCompleted) responseCompleter.complete(true);
            } else {
              item.errorMessage = json['msg'] ?? 'Recipient rejected transfer';
              if (!responseCompleter.isCompleted) responseCompleter.complete(false);
            }
          } catch (_) {
            if (!responseCompleter.isCompleted) responseCompleter.complete(false);
          }
        }
      });

      final accepted = await responseCompleter.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () => false,
      );

      await sub.cancel();

      if (!accepted) {
        item.status = item.errorMessage != null ? TransferStatus.rejected : TransferStatus.cancelled;
        notifyListeners();
        await socket.close();
        return;
      }

      // Receiver accepted: Start high-speed streaming
      item.status = TransferStatus.transferring;
      notifyListeners();

      final stream = file.openRead();
      int bytesSent = 0;
      DateTime lastSpeedCheck = DateTime.now();
      int lastCheckBytes = 0;

      await for (final chunk in stream) {
        // Handle Pause
        while (_pausedTransferIds.contains(transferId)) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (item.status == TransferStatus.cancelled) break;
        }

        if (item.status == TransferStatus.cancelled) {
          await socket.close();
          return;
        }

        socket.add(chunk);
        bytesSent += chunk.length;
        item.transferredBytes = bytesSent;

        final now = DateTime.now();
        final elapsed = now.difference(lastSpeedCheck).inMilliseconds;
        if (elapsed >= 350) {
          item.speedBytesPerSec = ((bytesSent - lastCheckBytes) / elapsed) * 1000;
          lastSpeedCheck = now;
          lastCheckBytes = bytesSent;
          notifyListeners();
        }
      }

      await socket.flush();
      item.transferredBytes = fileSize;
      item.status = TransferStatus.completed;
      item.speedBytesPerSec = 0;
      notifyListeners();
      await socket.close();
    } catch (e) {
      item.status = TransferStatus.failed;
      item.errorMessage = e.toString();
      item.speedBytesPerSec = 0;
      notifyListeners();
      socket?.destroy();
    }
  }

  void pauseTransfer(String id) {
    _pausedTransferIds.add(id);
    final item = _transfers.firstWhere((e) => e.id == id, orElse: () => _transfers.first);
    item.status = TransferStatus.paused;
    item.speedBytesPerSec = 0;
    notifyListeners();
  }

  void resumeTransfer(String id) {
    _pausedTransferIds.remove(id);
    final item = _transfers.firstWhere((e) => e.id == id, orElse: () => _transfers.first);
    item.status = TransferStatus.transferring;
    notifyListeners();
  }

  void cancelTransfer(String id) {
    _pausedTransferIds.remove(id);
    final item = _transfers.firstWhere((e) => e.id == id, orElse: () => _transfers.first);
    item.status = TransferStatus.cancelled;
    _activeTransferSockets[id]?.destroy();
    _activeTransferSockets.remove(id);
    notifyListeners();
  }

  void clearHistory() {
    _transfers.removeWhere((t) =>
        t.status == TransferStatus.completed ||
        t.status == TransferStatus.failed ||
        t.status == TransferStatus.cancelled ||
        t.status == TransferStatus.rejected);
    notifyListeners();
  }

  Future<Directory> _getDownloadDirectory() async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/Tools');
      if (!await dir.exists()) {
        try {
          await dir.create(recursive: true);
        } catch (_) {
          dir = await getExternalStorageDirectory();
        }
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
      final toolsDir = Directory(p.join(dir.path, 'ReceivedFiles'));
      if (!await toolsDir.exists()) {
        await toolsDir.create(recursive: true);
      }
      dir = toolsDir;
    }
    return dir!;
  }

  String _getUniqueFileName(String folderPath, String fileName) {
    String baseName = p.basenameWithoutExtension(fileName);
    String ext = p.extension(fileName);
    String finalPath = p.join(folderPath, fileName);
    int counter = 1;

    while (File(finalPath).existsSync()) {
      finalPath = p.join(folderPath, '$baseName($counter)$ext');
      counter++;
    }
    return p.basename(finalPath);
  }

  @override
  void dispose() {
    stopDiscovery();
    _serverSocket?.close();
    _incomingTransferController.close();
    super.dispose();
  }
}

class IncomingTransferPrompt {
  final String transferId;
  final String senderName;
  final String fileName;
  final int fileSize;
  final String pin;
  Completer<bool>? completer;

  IncomingTransferPrompt({
    required this.transferId,
    required this.senderName,
    required this.fileName,
    required this.fileSize,
    required this.pin,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
