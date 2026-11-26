import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../connectivity/bluetooth_screen.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/native_context_menu_wrapper.dart';

class DeviceControlsScreen extends StatefulWidget {
  const DeviceControlsScreen({super.key});

  @override
  State<DeviceControlsScreen> createState() => _DeviceControlsScreenState();
}

class _DeviceControlsScreenState extends State<DeviceControlsScreen> {
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batterySubscription;

  // Sensors
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Device Info
  Map<String, dynamic> _deviceData = {};

  @override
  void initState() {
    super.initState();
    _initBattery();
    _initSensors();
    _initDeviceInfo();
  }

  Future<void> _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
          _batteryState = state;
        });
      }
      _batterySubscription = _battery.onBatteryStateChanged.listen(
        (state) async {
          try {
            final lvl = await _battery.batteryLevel;
            if (mounted) {
              setState(() {
                _batteryState = state;
                _batteryLevel = lvl;
              });
            }
          } catch (error) {
            if (mounted) {
              AppToast.error(context, 'Could not read battery status: $error');
            }
          }
        },
        onError: (Object error) {
          if (mounted) {
            AppToast.error(context, 'Battery monitoring failed: $error');
          }
        },
      );
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Could not read battery status: $error');
      }
    }
  }

  void _initSensors() {
    try {
      _accelSubscription = accelerometerEventStream().listen(
        (event) {
          if (mounted) {
            setState(() => _accelerometerEvent = event);
          }
        },
        onError: (Object error) {
          if (mounted) AppToast.error(context, 'Accelerometer failed: $error');
        },
      );
      _gyroSubscription = gyroscopeEventStream().listen(
        (event) {
          if (mounted) {
            setState(() => _gyroscopeEvent = event);
          }
        },
        onError: (Object error) {
          if (mounted) AppToast.error(context, 'Gyroscope failed: $error');
        },
      );
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Could not start device sensors: $error');
      }
    }
  }

  Future<void> _initDeviceInfo() async {
    try {
      final info = await _deviceInfoPlugin.deviceInfo;
      if (mounted) {
        setState(() {
          _deviceData = info.data;
        });
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Could not read device information: $error');
      }
    }
  }

  Future<void> _triggerHaptic(HapticFeedbackType type) async {
    try {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.vibrate:
          await HapticFeedback.vibrate();
          break;
      }
      if (mounted) AppToast.success(context, 'Haptic feedback triggered.');
    } catch (error) {
      if (mounted) AppToast.error(context, 'Haptic feedback failed: $error');
    }
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text(
          'Device Controls & Hardware',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF08152B),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Flashlight / Torch
          _buildCard(
            title: 'Flashlight (Torch)',
            icon: Icons.highlight,
            accentColor: Colors.blueAccent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Torch control is unavailable',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Switch(
                  value: false,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (_) {
                    AppToast.error(
                      context,
                      'Flashlight control is not available yet.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bluetooth Manager & Hardware Scanner
          _buildCard(
            title: 'Bluetooth & Hardware Radio',
            icon: Icons.bluetooth,
            accentColor: Colors.cyanAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan nearby BLE/Bluetooth devices, inspect signal strength (RSSI), GATT services, and connect directly.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BluetoothScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
                  label: const Text(
                    'Open Bluetooth Manager & Scanner',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Battery & Charging Status
          _buildCard(
            title: 'Battery & Charging Status',
            icon: Icons.battery_charging_full,
            accentColor: Colors.greenAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level: $_batteryLevel%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'State: ${_batteryState.name.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _batteryLevel / 100.0,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _batteryLevel < 20 ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Haptics & Vibration
          _buildCard(
            title: 'Vibration & Haptic Feedback',
            icon: Icons.vibration,
            accentColor: Colors.purpleAccent,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _triggerHaptic(HapticFeedbackType.light),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                  child: const Text(
                    'Light',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _triggerHaptic(HapticFeedbackType.medium),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                  child: const Text(
                    'Medium',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _triggerHaptic(HapticFeedbackType.heavy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                  child: const Text(
                    'Heavy',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _triggerHaptic(HapticFeedbackType.vibrate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text(
                    'Vibrate',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sensors (Live Accelerometer & Gyroscope)
          _buildCard(
            title: 'Live Hardware Sensors',
            icon: Icons.sensors,
            accentColor: Colors.cyanAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accelerometer (m/s²):',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _accelerometerEvent != null
                      ? 'X: ${_accelerometerEvent!.x.toStringAsFixed(2)} | Y: ${_accelerometerEvent!.y.toStringAsFixed(2)} | Z: ${_accelerometerEvent!.z.toStringAsFixed(2)}'
                      : 'Waiting for sensor input...',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gyroscope (rad/s):',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _gyroscopeEvent != null
                      ? 'X: ${_gyroscopeEvent!.x.toStringAsFixed(2)} | Y: ${_gyroscopeEvent!.y.toStringAsFixed(2)} | Z: ${_gyroscopeEvent!.z.toStringAsFixed(2)}'
                      : 'Waiting for gyro input...',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Device Information (with Native Context Menu on Long-Press)
          NativeContextMenuWrapper(
            title: 'Device Hardware Metadata',
            shareContent: _deviceData.entries
                .take(15)
                .map((e) => '${e.key}: ${e.value}')
                .join('\n'),
            child: _buildCard(
              title: 'Device & OS Information (Long-press for options)',
              icon: Icons.info_outline,
              accentColor: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hold (Long Press) this card to copy or share device details!',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ..._deviceData.entries
                      .take(6)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          child,
        ],
      ),
    );
  }
}

enum HapticFeedbackType { light, medium, heavy, vibrate }
