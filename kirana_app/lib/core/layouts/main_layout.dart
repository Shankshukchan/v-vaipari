import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/app/inventory')) {
      return 1;
    }
    if (location.startsWith('/app/billing')) {
      return 2;
    }
    if (location.startsWith('/app/khata')) {
      return 3;
    }
    if (location.startsWith('/app/settings')) {
      return 4;
    }
    return 0; // dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/app/dashboard');
        break;
      case 1:
        context.go('/app/inventory');
        break;
      case 2:
        context.go('/app/billing');
        break;
      case 3:
        context.go('/app/khata');
        break;
      case 4:
        context.go('/app/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: widget.child
          .animate(key: ValueKey(GoRouterState.of(context).uri.path))
          .fadeIn(duration: 220.ms)
          .moveY(begin: 10, end: 0, curve: Curves.easeOut),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: AppTheme.border.withOpacity(0.8),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, 'Home', selectedIndex),
                _buildNavItem(
                  1,
                  LucideIcons.package,
                  'Inventory',
                  selectedIndex,
                ),
                _buildNavItem(2, LucideIcons.receipt, 'Bill', selectedIndex),
                _buildNavItem(3, LucideIcons.users, 'Khata', selectedIndex),
                _buildNavItem(
                  4,
                  LucideIcons.settings,
                  'Settings',
                  selectedIndex,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    int selectedIndex,
  ) {
    final isActive = index == selectedIndex;
    final activeColor = const Color(0xFF21385D);
    final inactiveColor = const Color(0xFF8A8080);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  Container(
                    width: 48,
                    height: 32,
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ).animate().scale(
                    duration: 200.ms,
                    curve: Curves.easeOutBack,
                  ),
                Icon(
                      icon,
                      size: 22,
                      color: isActive ? activeColor : inactiveColor,
                    )
                    .animate(target: isActive ? 1 : 0)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                    )
                    .moveY(begin: 0, end: -1),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack)
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}


