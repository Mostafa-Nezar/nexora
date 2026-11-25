import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../scanner/scanner_screen.dart';
import '../device_controls/device_controls_screen.dart';
import '../file_manager/file_manager_screen.dart';
import '../utilities/utilities_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

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
    _NavItemData(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view, label: 'الرئيسية'),
    _NavItemData(icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, label: 'الماسح'),
    _NavItemData(icon: Icons.smartphone_outlined, activeIcon: Icons.smartphone, label: 'الجهاز'),
    _NavItemData(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'الملفات'),
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
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
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
            color: Colors.white.withOpacity(0.06),
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
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
      decoration: BoxDecoration(
        color: const Color(0xFF070D1E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: const Color(0xFF10B981).withOpacity(0.2),
            width: 1.2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = _navItems[index];

            return InkWell(
              onTap: () => _onItemTapped(index),
              borderRadius: BorderRadius.circular(16),
              splashColor: const Color(0xFF10B981).withOpacity(0.15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 16 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                      size: 24,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
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
