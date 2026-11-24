import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '123456789');
  final TextEditingController _urlController = TextEditingController(text: 'https://google.com');

  Future<void> _launchDialer() async {
    final uri = Uri.parse('tel:${_phoneController.text.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open phone dialer')));
      }
    }
  }

  Future<void> _launchBrowser() async {
    final uri = Uri.parse(_urlController.text.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch browser')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Utilities & System Integrations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  label: const Text('Open Native Phone Dialer', style: TextStyle(color: Colors.white)),
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
                  label: const Text('Open in System Browser', style: TextStyle(color: Colors.white)),
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
