import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  String _authStatus = 'Not Authenticated';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsSupport();
  }

  Future<void> _checkBiometricsSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      List<BiometricType> biometrics = [];
      if (canCheck || isDeviceSupported) {
        biometrics = await _auth.getAvailableBiometrics();
      }
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck || isDeviceSupported;
          _availableBiometrics = biometrics;
        });
      }
    } catch (e) {
      setState(() => _authStatus = 'Error checking biometrics: $e');
    }
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access secure vault and OS credentials',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (mounted) {
        setState(() {
          _isAuthenticated = authenticated;
          _authStatus = authenticated ? 'Authentication Successful!' : 'Authentication Failed / Cancelled';
        });
        if (authenticated) {
          HapticFeedback.heavyImpact();
        }
      }
    } on PlatformException catch (e) {
      setState(() => _authStatus = 'Platform Exception: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Security & Biometrics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF200717),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Biometric Authentication (Fingerprint / Face)',
            icon: Icons.fingerprint,
            accentColor: Colors.pinkAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hardware Biometric Support:', style: TextStyle(color: Colors.white70)),
                    Text(
                      _canCheckBiometrics ? 'SUPPORTED' : 'NOT DETECTED',
                      style: TextStyle(
                        color: _canCheckBiometrics ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Available Types: ${_availableBiometrics.isEmpty ? "PIN / Pattern fallback" : _availableBiometrics.map((e) => e.name).join(", ")}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        _isAuthenticated ? Icons.lock_open : Icons.lock_outline,
                        size: 56,
                        color: _isAuthenticated ? Colors.greenAccent : Colors.pinkAccent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _authStatus,
                        style: TextStyle(
                          color: _isAuthenticated ? Colors.greenAccent : Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.security, color: Colors.white),
                  label: const Text('Authenticate with OS Biometrics', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildCard(
            title: 'Secure Storage & Runtime Permissions',
            icon: Icons.shield,
            accentColor: Colors.purpleAccent,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hardware-backed Keystore & Keychain integration secures app tokens, cryptographic keys, and user credentials.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  'Runtime permissions are requested on-demand following modern OS Sandboxing policies.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
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
        color: const Color(0xFF14040F),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
