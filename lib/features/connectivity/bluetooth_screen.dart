import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/widgets/app_toast.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _isSupported = true;
  String? _unsupportedReason;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> _scanResults = [];
  List<BluetoothDevice> _systemDevices = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _discoveredServices = [];
  bool _isConnecting = false;

  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _checkSupportAndInit();
  }

  Future<void> _checkSupportAndInit() async {
    // FlutterBluePlus supports Android, iOS, macOS, Linux, Web.
    // It does not support native Windows desktop out of the box.
    if (!kIsWeb && Platform.isWindows) {
      if (mounted) {
        setState(() {
          _isSupported = false;
          _unsupportedReason =
              'Bluetooth hardware scanning via flutter_blue_plus is designed for Mobile (Android & iOS), macOS, Linux, and Web.\n\nOn Windows Desktop, native BLE requires WinRT plugins or running the app on an Android device / emulator.';
        });
      }
      return;
    }

    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        if (mounted) {
          setState(() {
            _isSupported = false;
            _unsupportedReason = 'Bluetooth is not supported on this device/hardware.';
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSupported = false;
          _unsupportedReason = 'Bluetooth plugin error: $e\n\nIf you recently added the plugin, please do a full Restart (Stop & Run) instead of Hot Reload so native code is compiled.';
        });
      }
      return;
    }

    _initBluetooth();
  }

  void _initBluetooth() {
    try {
      // Monitor adapter state
      _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
        if (mounted) {
          setState(() => _adapterState = state);
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _isSupported = false;
            _unsupportedReason = 'Bluetooth initialization error: $e';
          });
        }
      });

      // Monitor scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() => _scanResults = results);
        }
      }, onError: (Object e) {
        if (mounted) {
          AppToast.error(context, 'Scan error: $e');
        }
      });

      // Monitor scanning state
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
        if (mounted) {
          setState(() => _isScanning = scanning);
        }
      });

      _loadSystemDevices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSupported = false;
          _unsupportedReason = 'Failed to initialize Bluetooth: $e';
        });
      }
    }
  }

  Future<void> _loadSystemDevices() async {
    try {
      final bonded = await FlutterBluePlus.bondedDevices;
      if (mounted) {
        setState(() => _systemDevices = bonded);
      }
    } catch (_) {}
  }

  Future<void> _startScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      AppToast.error(context, 'Please turn on Bluetooth first');
      return;
    }

    try {
      _loadSystemDevices();
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to start scan: $e');
      }
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to stop scan: $e');
      }
    }
  }

  Future<void> _turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
      if (mounted) {
        AppToast.success(context, 'Bluetooth requested to turn on');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not turn on Bluetooth: $e');
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      if (_isScanning) {
        await _stopScan();
      }

      await device.connect(timeout: const Duration(seconds: 15));
      final services = await device.discoverServices();

      if (mounted) {
        setState(() {
          _connectedDevice = device;
          _discoveredServices = services;
          _isConnecting = false;
        });
        AppToast.success(context, 'Connected to ${device.platformName.isNotEmpty ? device.platformName : "Device"}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        AppToast.error(context, 'Connection failed: $e');
      }
    }
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      if (mounted) {
        setState(() {
          _connectedDevice = null;
          _discoveredServices = [];
        });
        AppToast.success(context, 'Disconnected');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Disconnect failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _adapterSubscription?.cancel();
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBtOn = _adapterState == BluetoothAdapterState.on;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text(
          'Bluetooth & Hardware Specs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        actions: [
          if (isBtOn)
            IconButton(
              icon: Icon(_isScanning ? Icons.stop_circle : Icons.refresh),
              tooltip: _isScanning ? 'Stop Scan' : 'Scan Devices',
              color: _isScanning ? Colors.redAccent : Colors.cyanAccent,
              onPressed: _isScanning ? _stopScan : _startScan,
            ),
        ],
      ),
      body: !_isSupported
          ? _buildUnsupportedView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
          // Bluetooth Status & Adapter Overview
          _buildAdapterStatusCard(isBtOn),
          const SizedBox(height: 16),

          // Connected Device Inspector (If connected)
          if (_connectedDevice != null) ...[
            _buildConnectedDeviceCard(_connectedDevice!),
            const SizedBox(height: 16),
          ],

          // Paired / Bonded Devices
          if (_systemDevices.isNotEmpty) ...[
            _buildSectionHeader('Paired / Bonded Devices (${_systemDevices.length})', Icons.link),
            const SizedBox(height: 8),
            ..._systemDevices.map((device) => _buildPairedDeviceTile(device)),
            const SizedBox(height: 16),
          ],

          // Scanned BLE Devices
          _buildSectionHeader(
            _isScanning
                ? 'Scanning for Nearby Devices...'
                : 'Discovered Nearby Devices (${_scanResults.length})',
            Icons.bluetooth_searching,
          ),
          const SizedBox(height: 8),

          if (!isBtOn)
            _buildWarningBox('Please enable Bluetooth above to scan for and connect to nearby devices.')
          else if (_scanResults.isEmpty)
            _buildEmptyState()
          else
            ..._scanResults.map((result) => _buildScanResultCard(result)),
        ],
      ),
    );
  }

  Widget _buildAdapterStatusCard(bool isBtOn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBtOn ? Colors.blueAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isBtOn ? Colors.blue.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBtOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                  color: isBtOn ? Colors.blueAccent : Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bluetooth Controller State',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: ${_adapterState.name.toUpperCase()}',
                      style: TextStyle(
                        color: isBtOn ? Colors.greenAccent : Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isBtOn)
                ElevatedButton(
                  onPressed: _turnOnBluetooth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Turn ON', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('Scanner', _isScanning ? 'ACTIVE' : 'IDLE', _isScanning ? Colors.cyanAccent : Colors.white60),
              _buildMetricItem('Paired Count', '${_systemDevices.length}', Colors.purpleAccent),
              _buildMetricItem('Nearby Found', '${_scanResults.length}', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 12),
          if (isBtOn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? _stopScan : _startScan,
                icon: Icon(_isScanning ? Icons.stop : Icons.search),
                label: Text(_isScanning ? 'Stop Scanning' : 'Scan for Nearby BLE Devices'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.redAccent.withValues(alpha: 0.8) : const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildPairedDeviceTile(BluetoothDevice device) {
    final name = device.platformName.isNotEmpty ? device.platformName : 'Unknown / Hidden Device';
    final isConnected = _connectedDevice?.remoteId == device.remoteId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.devices, color: Colors.purpleAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'ID: ${device.remoteId}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isConnecting
                ? null
                : () => isConnected ? _disconnectDevice(device) : _connectToDevice(device),
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.redAccent.withValues(alpha: 0.8) : Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              isConnected ? 'Disconnect' : 'Connect',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultCard(ScanResult r) {
    final name = r.device.platformName.isNotEmpty ? r.device.platformName : (r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : 'Unknown BLE Device');
    final rssi = r.rssi;
    final isConnected = _connectedDevice?.remoteId == r.device.remoteId;

    Color signalColor = Colors.greenAccent;
    if (rssi < -80) {
      signalColor = Colors.redAccent;
    } else if (rssi < -65) {
      signalColor = Colors.amberAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth, color: signalColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$rssi dBm',
                  style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Address: ${r.device.remoteId}',
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
          ),
          if (r.advertisementData.serviceUuids.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Services: ${r.advertisementData.serviceUuids.map((u) => u.toString().substring(0, 8)).join(", ")}',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.advertisementData.connectable ? 'Connectable: YES' : 'Connectable: NO',
                style: TextStyle(
                  color: r.advertisementData.connectable ? Colors.greenAccent : Colors.white38,
                  fontSize: 12,
                ),
              ),
              if (r.advertisementData.connectable)
                ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : () => isConnected ? _disconnectDevice(r.device) : _connectToDevice(r.device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.redAccent : const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  child: Text(
                    isConnected ? 'Disconnect' : 'Connect',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard(BluetoothDevice device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF042F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth_connected, color: Colors.tealAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected Hardware Device',
                      style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () => _disconnectDevice(device),
                tooltip: 'Disconnect',
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Text(
            'Discovered GATT Services (${_discoveredServices.length}):',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          if (_discoveredServices.isEmpty)
            const Text('No services discovered or still reading...', style: TextStyle(color: Colors.white38, fontSize: 12))
          else
            ..._discoveredServices.take(5).map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• UUID: ${s.uuid.toString()} (${s.characteristics.length} chars)',
                      style: const TextStyle(color: Colors.tealAccent, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.amberAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Hardware Platform Notice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _unsupportedReason ?? 'Bluetooth plugin is not available on this platform.',
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Tip: If running on Android, please do a full app rebuild / restart (stop flutter and run again) so the new native plugin compiles.',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            _isScanning ? Icons.radar : Icons.bluetooth_searching,
            color: Colors.white24,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _isScanning ? 'Scanning for nearby Bluetooth devices...' : 'No devices found yet. Tap "Scan" to discover.',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
