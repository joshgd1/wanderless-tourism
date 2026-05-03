import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design_system.dart';
import '../../features/profile/widgets/profile_menu_sheet.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: 'Discover',
                  isSelected: _isSelected(context, '/discover'),
                  onTap: () => context.go('/discover'),
                ),
                _NavItem(
                  icon: Icons.card_travel_outlined,
                  activeIcon: Icons.card_travel,
                  label: 'My Trips',
                  isSelected: _isSelected(context, '/bookings'),
                  onTap: () => context.go('/bookings'),
                ),
                _NavItem(
                  icon: Icons.lightbulb_outline,
                  activeIcon: Icons.lightbulb,
                  label: 'Plan Trip',
                  isSelected: _isSelected(context, '/trip-plans'),
                  onTap: () => context.go('/trip-plans'),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isSelected: _isSelected(context, '/profile'),
                  onTap: () => ProfileMenuSheet.show(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelected(BuildContext context, String path) {
    final location = GoRouterState.of(context).uri.toString();
    return location.startsWith(path);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.brand : Colors.grey[400],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.brand : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
