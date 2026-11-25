import 'dart:convert';

enum DevicePlatformType {
  android,
  ios,
  windows,
  macos,
  linux,
  unknown;

  static DevicePlatformType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'android':
        return DevicePlatformType.android;
      case 'ios':
        return DevicePlatformType.ios;
      case 'windows':
        return DevicePlatformType.windows;
      case 'macos':
        return DevicePlatformType.macos;
      case 'linux':
        return DevicePlatformType.linux;
      default:
        return DevicePlatformType.unknown;
    }
  }
}

class DiscoveredDevice {
  final String id;
  final String name;
  final DevicePlatformType platform;
  final String ip;
  final int port;
  final DateTime lastSeen;
  final String pin;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.ip,
    required this.port,
    required this.lastSeen,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform.name,
        'ip': ip,
        'port': port,
        'pin': pin,
      };

  factory DiscoveredDevice.fromJson(Map<String, dynamic> json, String senderIp) {
    return DiscoveredDevice(
      id: json['id'] as String? ?? 'dev_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Nearby Device',
      platform: DevicePlatformType.fromString(json['platform'] as String? ?? ''),
      ip: (json['ip'] as String?)?.isNotEmpty == true ? json['ip'] as String : senderIp,
      port: (json['port'] as num?)?.toInt() ?? 52140,
      lastSeen: DateTime.now(),
      pin: json['pin'] as String? ?? '0000',
    );
  }
}

enum TransferStatus {
  pending,
  connecting,
  transferring,
  paused,
  completed,
  failed,
  cancelled,
  rejected,
}

enum TransferDirection {
  send,
  receive,
}

class TransferItem {
  final String id;
  final String fileName;
  final int fileSize;
  final String? filePath;
  final String? mimeType;
  final String checksumSha256;
  int transferredBytes;
  TransferStatus status;
  double speedBytesPerSec;
  String? errorMessage;
  final TransferDirection direction;
  final String remoteDeviceName;
  final DateTime timestamp;

  TransferItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.filePath,
    this.mimeType,
    this.checksumSha256 = '',
    this.transferredBytes = 0,
    this.status = TransferStatus.pending,
    this.speedBytesPerSec = 0,
    this.errorMessage,
    required this.direction,
    required this.remoteDeviceName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get progress => fileSize == 0 ? 0.0 : (transferredBytes / fileSize).clamp(0.0, 1.0);

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedSpeed {
    if (speedBytesPerSec < 1024) return '${speedBytesPerSec.toStringAsFixed(0)} B/s';
    if (speedBytesPerSec < 1024 * 1024) return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String get formattedTimeRemaining {
    if (speedBytesPerSec <= 0 || status != TransferStatus.transferring) return '--:--';
    final remainingBytes = fileSize - transferredBytes;
    if (remainingBytes <= 0) return '00:00';
    final seconds = remainingBytes / speedBytesPerSec;
    if (seconds > 3600) {
      final hours = (seconds / 3600).floor();
      final mins = ((seconds % 3600) / 60).floor();
      return '${hours}h ${mins}m';
    }
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
