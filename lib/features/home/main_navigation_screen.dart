import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../scanner/scanner_screen.dart';
import '../device_controls/device_controls_screen.dart';
import '../file_manager/file_manager_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  // The 4 main featured pages from the 9 tool categories
  final List<Widget> _pages = const [
    HomeScreen(),
    ScannerScreen(),
    DeviceControlsScreen(),
    FileManagerScreen(),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner_rounded,
      label: 'Scanner',
    ),
    _NavItemData(
      icon: Icons.devices_other_outlined,
      activeIcon: Icons.devices_other_rounded,
      label: 'Device',
    ),
    _NavItemData(
      icon: Icons.folder_open_outlined,
      activeIcon: Icons.folder_open_rounded,
      label: 'Files',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = _selectedIndex != 0 || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button and nexora.png logo
            _buildCustomHeader(canGoBack),

            // Active Page Body
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomHeader(bool canGoBack) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          InkWell(
            onTap: () {
              if (_selectedIndex != 0) {
                setState(() => _selectedIndex = 0);
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          // Center / Right App Logo (nexora.png)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/nexora.png',
                  height: 34,
                  width: 34,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.apps_rounded,
                    color: Color(0xFF10B981),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'NEXORA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          // Trailing Placeholder to maintain balance
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1324),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_navItems.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = _navItems[index];

            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: item.label,
                child: InkWell(
                  onTap: () => _onItemTapped(index),
                  borderRadius: BorderRadius.circular(18),
                  splashColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF10B981).withValues(alpha: 0.07)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: 42,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : const Color(0xFF8993A7),
                            size: 21,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF8993A7),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 10.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
