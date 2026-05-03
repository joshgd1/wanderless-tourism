import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design_system.dart';
import '../../../core/auth_provider.dart';

/// Grab/Klook-style profile bottom sheet.
/// Shown when tapping the Profile bottom nav item.
class ProfileMenuSheet extends ConsumerWidget {
  const ProfileMenuSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProfileMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header — avatar, name, email
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? AppSpacing.xl : AppSpacing.lg),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceSecondary,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipOval(
                    child: const Icon(Icons.person, size: 32, color: AppColors.textTertiary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.name ?? 'Tourist',
                        style: AppText.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (auth.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          auth.email!,
                          style: AppText.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),

          // Quick links
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? AppSpacing.xl : AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                _MenuRow(
                  icon: Icons.person_outline,
                  label: 'View Full Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/profile');
                  },
                ),
                _MenuRow(
                  icon: Icons.card_travel_outlined,
                  label: 'My Bookings',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/bookings');
                  },
                ),
                _MenuRow(
                  icon: Icons.lightbulb_outline,
                  label: 'My Trip Plans',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/trip-plans');
                  },
                ),
                _MenuRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/notifications');
                  },
                ),
                const Divider(height: AppSpacing.lg),
                _MenuRow(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // Could link to help center
                  },
                ),
                _MenuRow(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),

          // Sign out
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? AppSpacing.xl : AppSpacing.lg),
            child: _MenuRow(
              icon: Icons.logout,
              label: 'Sign Out',
              color: AppColors.error,
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/login');
                }
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(color: textColor),
              ),
            ),
            if (color == null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
