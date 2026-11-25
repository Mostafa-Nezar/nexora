import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/native_context_menu_wrapper.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<PlatformFile> _pickedFiles = [];
  String _statusMessage = 'No files picked yet.';

  Future<void> _pickSingleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _pickedFiles = result.files;
          _statusMessage =
              'Selected: ${result.files.first.name} (${(result.files.first.size / 1024).toStringAsFixed(1)} KB)';
        });
        AppToast.success(context, 'Selected ${result.files.first.name}.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Error picking file: $e');
        AppToast.error(context, 'Could not pick file: $e');
      }
    }
  }

  Future<void> _pickMultipleFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _pickedFiles = result.files;
          _statusMessage =
              'Selected ${result.files.length} files successfully.';
        });
        AppToast.success(context, 'Selected ${result.files.length} files.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Error: $e');
        AppToast.error(context, 'Could not pick files: $e');
      }
    }
  }

  Future<void> _createLocalSampleFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/Tools_Sample_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(
        'Tools Application: File Management & OS Integration test file.\nCreated at: ${DateTime.now()}',
      );
      HapticFeedback.lightImpact();
      if (mounted) {
        AppToast.success(
          context,
          'Created sample file: ${file.path.split('/').last}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to create file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text(
          'File Manager & Storage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF261904),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'System File Picker (Native SAF)',
            icon: Icons.folder_open,
            accentColor: Colors.amberAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickSingleFile,
                        icon: const Icon(
                          Icons.file_upload,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'Pick Single File',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickMultipleFiles,
                        icon: const Icon(
                          Icons.file_copy,
                          color: Colors.amberAccent,
                        ),
                        label: const Text(
                          'Pick Multiple',
                          style: TextStyle(color: Colors.amberAccent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.amberAccent),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _createLocalSampleFile,
                  icon: const Icon(Icons.note_add, color: Colors.white),
                  label: const Text(
                    'Generate Sample Document',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B2A0F),
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_pickedFiles.isNotEmpty) ...[
            const Text(
              'Selected Files (Long Press for Context Menu):',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ..._pickedFiles.map(
              (file) => NativeContextMenuWrapper(
                title: file.name,
                shareContent: file.path ?? file.name,
                onShare: () async {
                  final path = file.path;
                  if (path == null) {
                    throw StateError('The selected file has no local path.');
                  }
                  await Share.shareXFiles([
                    XFile(path),
                  ], text: 'Sharing ${file.name}');
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1304),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Colors.amberAccent,
                    ),
                    title: Text(
                      file.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.more_vert,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        color: const Color(0xFF170F03),
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
