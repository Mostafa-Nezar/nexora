import 'package:flutter/material.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/native_context_menu_wrapper.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text(
          'Scanner & Vision',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF04201A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'QR Code & Barcode Scanner',
            icon: Icons.qr_code_scanner,
            accentColor: const Color(0xFF10B981),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan any QR code, Barcode, Aztec or DataMatrix format with hardware camera acceleration.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    AppToast.error(
                      context,
                      'Live camera scanning is not implemented yet.',
                    );
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.black),
                  label: const Text(
                    'Open QR / Barcode Scanner',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          NativeContextMenuWrapper(
            title: 'OCR Recognized Text',
            shareContent:
                'Recognized Sample Text: INVOICE #8942\nTotal: 1,450.00 EGP\nDate: 2026-11-24',
            child: _buildCard(
              title: 'OCR & Text Recognition (On-Device)',
              icon: Icons.document_scanner,
              accentColor: Colors.tealAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extract text instantly from documents, receipts, or photos using machine vision.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'Sample OCR Output:\nINVOICE #8942\nTotal: 1,450.00 EGP\nDate: 2026-11-24\n(Long-press to Copy or Share)',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
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
        color: const Color(0xFF041814),
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
