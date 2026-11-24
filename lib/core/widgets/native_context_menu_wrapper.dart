import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeContextMenuWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final String shareContent;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onOpenWith;

  const NativeContextMenuWrapper({
    super.key,
    required this.child,
    required this.title,
    required this.shareContent,
    this.onCopy,
    this.onShare,
    this.onSave,
    this.onOpenWith,
  });

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.cyanAccent),
                  title: const Text('Copy to Clipboard', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: shareContent));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to Clipboard!')),
                    );
                    onCopy?.call();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.purpleAccent),
                  title: const Text('Share Sheet (Native OS)', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onShare?.call();
                  },
                ),
                if (onSave != null)
                  ListTile(
                    leading: const Icon(Icons.save_alt, color: Colors.amberAccent),
                    title: const Text('Save / Export', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onSave?.call();
                    },
                  ),
                if (onOpenWith != null)
                  ListTile(
                    leading: const Icon(Icons.open_in_new, color: Colors.blueAccent),
                    title: const Text('Open With Other App', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onOpenWith?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: child,
    );
  }
}
