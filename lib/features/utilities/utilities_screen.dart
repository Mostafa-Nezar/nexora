import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/app_toast.dart';
import 'widgets/calculator_tool.dart';
import 'widgets/timer_stopwatch_tool.dart';
import 'widgets/unit_converter_tool.dart';

enum _UtilityTab {
  calculator('Calculator', Icons.calculate_outlined),
  timer('Timer', Icons.timer_outlined),
  converter('Converter', Icons.swap_horiz_rounded);

  final String label;
  final IconData icon;
  const _UtilityTab(this.label, this.icon);
}

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
  _UtilityTab _selectedTab = _UtilityTab.calculator;

  @override
  void dispose() {
    _phoneController.dispose();
    _urlController.dispose();
    super.dispose();
  }

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
            title: 'Calculator, Timer & Unit Converter',
            icon: Icons.calculate,
            accentColor: Colors.amberAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030712),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      for (final tab in _UtilityTab.values)
                        Expanded(
                          child: _buildTabButton(tab),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                switch (_selectedTab) {
                  _UtilityTab.calculator => const CalculatorTool(),
                  _UtilityTab.timer => const TimerStopwatchTool(),
                  _UtilityTab.converter => const UnitConverterTool(),
                },
              ],
            ),
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildTabButton(_UtilityTab tab) {
    final selected = _selectedTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.amberAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 16,
              color: selected ? const Color(0xFF030712) : Colors.white70,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                tab.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? const Color(0xFF030712) : Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
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
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
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
