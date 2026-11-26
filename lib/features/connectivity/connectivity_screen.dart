import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bluetooth_screen.dart';
import '../../core/widgets/app_toast.dart';

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});

  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (mounted) {
        setState(() => _connectionStatus = result);
      }
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (result) {
          if (mounted) {
            setState(() => _connectionStatus = result);
          }
        },
        onError: (Object error) {
          if (mounted) {
            AppToast.error(context, 'Connectivity monitoring failed: $error');
          }
        },
      );
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Could not read connectivity status: $error');
      }
    }
  }

  Future<void> _openSystemSettings() async {
    try {
      final uri = Uri.parse('app-settings:');
      if (!await canLaunchUrl(uri)) {
        throw StateError('System connectivity settings are unavailable.');
      }
      if (!await launchUrl(uri)) {
        throw StateError('The system settings screen did not open.');
      }
      if (mounted) AppToast.success(context, 'Connectivity settings opened.');
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Could not open connectivity settings: $error');
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = !_connectionStatus.contains(ConnectivityResult.none);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text(
          'Connectivity & Networks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF041E26),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Internet & Connection Status',
            icon: Icons.wifi,
            accentColor: Colors.cyanAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Status:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Row(
                      children: [
                        Icon(
                          isConnected
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: isConnected
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'ONLINE' : 'DISCONNECTED',
                          style: TextStyle(
                            color: isConnected
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Connection Types: ${_connectionStatus.map((e) => e.name.toUpperCase()).join(", ")}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildCard(
            title: 'Native OS Connectivity Settings',
            icon: Icons.settings_ethernet,
            accentColor: Colors.tealAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modern OS policies (Android 10+ / iOS) restrict background toggling of Wi-Fi & Bluetooth. Tools redirects you straight to native panels.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openSystemSettings,
                  icon: const Icon(Icons.settings, color: Colors.black),
                  label: const Text(
                    'Open System Connectivity Settings',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    minimumSize: const Size.fromHeight(45),
                  ),
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
                  icon: const Icon(Icons.bluetooth, color: Colors.white),
                  label: const Text(
                    'Bluetooth Hardware Manager & Scanner',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
              ],
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
        color: const Color(0xFF04171E),
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
