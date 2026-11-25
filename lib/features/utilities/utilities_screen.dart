import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/app_toast.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  final TextEditingController _phoneController = TextEditingController(
    text: '123456789',
  );
  final TextEditingController _urlController = TextEditingController(
    text: 'https://google.com',
  );

  Future<void> _launchDialer() async {
    try {
      final uri = Uri.parse('tel:${_phoneController.text.trim()}');
      if (!await canLaunchUrl(uri)) {
        throw StateError('No phone app can handle this number.');
      }
      if (!await launchUrl(uri)) {
        throw StateError('The phone app did not open the dialer.');
      }
      if (mounted) AppToast.success(context, 'Phone dialer opened.');
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Could not open phone dialer: $error');
      }
    }
  }

  Future<void> _launchBrowser() async {
    try {
      final uri = Uri.parse(_urlController.text.trim());
      if (!await canLaunchUrl(uri)) {
        throw StateError('No browser can handle this address.');
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('The browser did not open the address.');
      }
      if (mounted) AppToast.success(context, 'Address opened in your browser.');
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Could not launch browser: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text(
          'Utilities & System Integrations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Native OS Dialers & Applications',
            icon: Icons.apps,
            accentColor: Colors.blueAccent,
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    prefixIcon: Icon(Icons.phone, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _launchDialer,
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text(
                    'Open Native Phone Dialer',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Web URL / Deep Link',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    prefixIcon: Icon(Icons.link, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _launchBrowser,
                  icon: const Icon(Icons.open_in_browser, color: Colors.white),
                  label: const Text(
                    'Open in System Browser',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildCard(
            title: 'Calculator, Stopwatch & Unit Converter',
            icon: Icons.calculate,
            accentColor: Colors.amberAccent,
            child: const Text(
              'Integrated calculators, timers, digital rulers, and password generators operate fully offline with high precision.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
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
        color: const Color(0xFF0F172A),
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
