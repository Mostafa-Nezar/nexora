import 'package:flutter/material.dart';

class MediaToolsScreen extends StatelessWidget {
  const MediaToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Media & Audio/Video Tools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF03221C),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Image Compression & Cropping',
            icon: Icons.image,
            accentColor: const Color(0xFF14B8A6),
            child: const Text(
              'Convert images to WebP / JPEG, crop with aspect-ratio snapping, and read EXIF metadata (GPS, Camera Model, Exposure).',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          _buildCard(
            title: 'Video & Audio Player / Trimmer',
            icon: Icons.video_library,
            accentColor: Colors.tealAccent,
            child: const Text(
              'High-performance hardware-accelerated video playback, audio waveform visualizer, and trimming capabilities.',
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
        color: const Color(0xFF031915),
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
