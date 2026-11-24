import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets/native_context_menu_wrapper.dart';

class ShareActionsScreen extends StatefulWidget {
  const ShareActionsScreen({super.key});

  @override
  State<ShareActionsScreen> createState() => _ShareActionsScreenState();
}

class _ShareActionsScreenState extends State<ShareActionsScreen> {
  final TextEditingController _textController = TextEditingController(
    text: 'https://flutter.dev - Native OS Utilities and System Integrations for Flutter!',
  );
  String _clipboardData = '';

  @override
  void initState() {
    super.initState();
    _fetchClipboard();
  }

  Future<void> _fetchClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (mounted && data?.text != null) {
      setState(() => _clipboardData = data!.text!);
    }
  }

  void _shareText() {
    if (_textController.text.isNotEmpty) {
      Share.share(_textController.text, subject: 'Shared via Tools App');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Share & Native OS Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A0A2A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Native System Share Sheet Card
          _buildCard(
            title: 'Native System Share Sheet',
            icon: Icons.share,
            accentColor: Colors.purpleAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Text / URL to share',
                    labelStyle: const TextStyle(color: Colors.purpleAccent),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.purpleAccent), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _shareText,
                  icon: const Icon(Icons.ios_share, color: Colors.white),
                  label: const Text('Invoke System Share Sheet', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7), minimumSize: const Size.fromHeight(45)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Long Press Context Menu Demonstration
          NativeContextMenuWrapper(
            title: 'Demonstration Item Options',
            shareContent: 'Confidential file or link: https://tools.app/demo-item-3829',
            onShare: () => Share.share('https://tools.app/demo-item-3829'),
            onSave: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved item to local storage!')),
              );
            },
            onOpenWith: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoking OS "Open With" intent...')),
              );
            },
            child: _buildCard(
              title: 'Long-Press Context Menu (Interactive)',
              icon: Icons.touch_app,
              accentColor: Colors.pinkAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👉 Press and HOLD (Long Press) this card!',
                    style: TextStyle(color: Colors.pinkAccent, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This triggers the OS contextual bottom sheet offering: Copy, Share, Save As, and Open With options.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Clipboard Integration
          _buildCard(
            title: 'Clipboard Integration (Copy / Paste)',
            icon: Icons.content_copy,
            accentColor: Colors.cyanAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clipboardData.isEmpty ? 'Clipboard is empty or inaccessible.' : 'Current Clipboard: $_clipboardData',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _textController.text));
                          HapticFeedback.lightImpact();
                          _fetchClipboard();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied input to Clipboard!')));
                        },
                        icon: const Icon(Icons.copy, color: Colors.cyanAccent, size: 18),
                        label: const Text('Copy Input', style: TextStyle(color: Colors.cyanAccent)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.cyanAccent)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            setState(() {
                              _textController.text = data!.text!;
                              _clipboardData = data.text!;
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                        icon: const Icon(Icons.paste, color: Colors.greenAccent, size: 18),
                        label: const Text('Paste Here', style: TextStyle(color: Colors.greenAccent)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent)),
                      ),
                    ),
                  ],
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
        color: const Color(0xFF10091E),
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
