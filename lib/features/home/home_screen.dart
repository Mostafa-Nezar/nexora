import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../device_controls/device_controls_screen.dart';
import '../scanner/scanner_screen.dart';
import '../share_actions/share_actions_screen.dart';
import '../file_manager/file_manager_screen.dart';
import '../connectivity/connectivity_screen.dart';
import '../security/security_screen.dart';
import '../media_tools/media_tools_screen.dart';
import '../utilities/utilities_screen.dart';
import '../device_sharing/device_sharing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar (Matching App Structure and TOOLS in design image)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF063321),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: const Text(
                      'App Structure',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    'TOOLS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // 8 Grid Cards matching user layout exactly (2 columns x 4 rows)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.25,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                children: [
                  // Row 1: Left = Scanner, Right = Device Controls
                  _buildToolCard(
                    context: context,
                    title: 'Scanner',
                    subtitle: 'QR, Barcode, OCR',
                    icon: Icons.qr_code_scanner,
                    bgColor: AppColors.scannerBg,
                    accentColor: AppColors.scannerAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
                  ),
                  _buildToolCard(
                    context: context,
                    title: 'Device Controls',
                    subtitle: 'Flash, Bluetooth, Sensors',
                    icon: Icons.smartphone,
                    bgColor: AppColors.deviceBg,
                    accentColor: AppColors.deviceAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceControlsScreen())),
                  ),

                  // Row 2: Left = File Manager, Right = Share & Actions
                  _buildToolCard(
                    context: context,
                    title: 'File Manager',
                    subtitle: 'Files, Download, PDF',
                    icon: Icons.folder,
                    bgColor: AppColors.fileBg,
                    accentColor: AppColors.fileAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FileManagerScreen())),
                  ),
                  _buildToolCard(
                    context: context,
                    title: 'Share & Actions',
                    subtitle: 'Share, Copy, Save, Open With',
                    icon: Icons.share,
                    bgColor: AppColors.shareBg,
                    accentColor: AppColors.shareAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareActionsScreen())),
                  ),

                  // Row 3: Left = Security, Right = Connectivity
                  _buildToolCard(
                    context: context,
                    title: 'Security',
                    subtitle: 'Biometrics, Permissions',
                    icon: Icons.verified_user,
                    bgColor: AppColors.securityBg,
                    accentColor: AppColors.securityAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                  ),
                  _buildToolCard(
                    context: context,
                    title: 'Connectivity',
                    subtitle: 'Wi-Fi, NFC, Network',
                    icon: Icons.wifi,
                    bgColor: AppColors.connectBg,
                    accentColor: AppColors.connectAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectivityScreen())),
                  ),

                  // Row 4: Left = Utilities, Right = Media Tools
                  _buildToolCard(
                    context: context,
                    title: 'Utilities',
                    subtitle: 'Calculator, Timer, Converter',
                    icon: Icons.calculate,
                    bgColor: AppColors.utilBg,
                    accentColor: AppColors.utilAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilitiesScreen())),
                  ),
                  _buildToolCard(
                    context: context,
                    title: 'Media Tools',
                    subtitle: 'Image, Video, Audio',
                    icon: Icons.photo_library,
                    bgColor: AppColors.mediaBg,
                    accentColor: AppColors.mediaAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MediaToolsScreen())),
                  ),

                  // Row 5: Tab 9 = Device Sharing (Advanced File Transfer)
                  _buildToolCard(
                    context: context,
                    title: 'Device Sharing',
                    subtitle: 'AirDrop, QuickShare, Wi-Fi Direct',
                    icon: Icons.wifi_tethering,
                    bgColor: AppColors.sharingBg,
                    accentColor: AppColors.sharingAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceSharingScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withValues(alpha: 0.15),
          highlightColor: accentColor.withValues(alpha: 0.08),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  Color.lerp(bgColor, Colors.black, 0.35) ?? bgColor,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: accentColor.withValues(alpha: 0.4),
                      size: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
