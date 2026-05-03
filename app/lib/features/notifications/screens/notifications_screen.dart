import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.textPrimary,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.textPrimary,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Notifications',
                          style: AppText.h2.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: _NotificationList(),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Static demo notifications — wire to real API by adding a notifications endpoint
    final notifications = [
      _NotifItem(
        icon: Icons.check_circle,
        color: AppColors.success,
        title: 'Booking Confirmed!',
        subtitle: 'Your Singapore City Tour with Mei Ling has been confirmed.',
        time: '2 hours ago',
        unread: true,
      ),
      _NotifItem(
        icon: Icons.location_on,
        color: AppColors.info,
        title: 'Guide is on the way',
        subtitle: 'Somchai started the tour and is heading to your location.',
        time: '4 hours ago',
        unread: true,
      ),
      _NotifItem(
        icon: Icons.star,
        color: AppColors.warning,
        title: 'Rate your experience',
        subtitle: 'How was your Ancient Temple Tour? Share your feedback!',
        time: 'Yesterday',
        unread: false,
      ),
      _NotifItem(
        icon: Icons.lightbulb,
        color: AppColors.brand,
        title: 'New guide matches your style',
        subtitle: '5 new guides in Singapore match your travel preferences.',
        time: '2 days ago',
        unread: false,
      ),
      _NotifItem(
        icon: Icons.card_travel,
        color: AppColors.textSecondary,
        title: 'Trip plan updated',
        subtitle: 'Guide responded to your Doi Suthep Day Trip proposal.',
        time: '3 days ago',
        unread: false,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final n = notifications[index];
        return Container(
          decoration: BoxDecoration(
            color: n.unread ? AppColors.brand.withOpacity(0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: n.unread ? AppColors.brand.withOpacity(0.2) : AppColors.border,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: n.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(n.icon, color: n.color, size: 22),
            ),
            title: Text(
              n.title,
              style: AppText.labelBold.copyWith(
                color: n.unread ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(n.subtitle, style: AppText.bodySmall),
                const SizedBox(height: 4),
                Text(n.time, style: AppText.caption),
              ],
            ),
            trailing: n.unread
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;

  _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
  });
}
