import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/business_auth_provider.dart';
import '../../../../design_system.dart';

final businessDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(businessAuthProvider);
  if (authState.businessOwnerId == null) return {};
  final api = ApiClient();
  return await api.businessDashboard();
});

class BusinessDashboardScreen extends ConsumerWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(businessAuthProvider);
    final dashboardAsync = ref.watch(businessDashboardProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: AppColors.textPrimary,
              leadingWidth: 0,
              leading: const SizedBox.shrink(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.textPrimary,
                  child: SafeArea(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _DarkGridPainter()),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                          child: Row(
                            children: [
                              _BusinessFloatingCard(
                                businessName: authState.businessName ?? 'Business',
                              ),
                              const Spacer(),
                              _LogoutBtn(
                                onPressed: () async {
                                  await ref.read(businessAuthProvider.notifier).logout();
                                  if (context.mounted) context.go('/business/login');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: dashboardAsync.when(
          loading: () => const AppLoading(message: 'Loading dashboard...'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load dashboard',
            subtitle: e.toString(),
            action: PrimaryButton(
              label: 'Retry',
              onPressed: () => ref.refresh(businessDashboardProvider),
            ),
          ),
          data: (data) {
            if (data.isEmpty) {
              return EmptyState(
                icon: Icons.business_outlined,
                title: 'No dashboard data available',
                subtitle: 'Data will appear once guides start accepting bookings',
              );
            }
            final totalBookings = data['total_bookings'] ?? 0;
            final totalRevenue = (data['total_revenue'] ?? 0.0).toDouble();
            final totalCommission = (data['total_commission'] ?? 0.0).toDouble();
            final guides = data['guides'] as List? ?? [];
            final recentBookings = data['recent_bookings'] as List? ?? [];

            return ListView(
              padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Bookings',
                        value: '$totalBookings',
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        title: 'Revenue',
                        value: '\$${totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.attach_money_outlined,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatCard(
                  title: 'Platform Commission Earned',
                  value: '\$${totalCommission.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.brand,
                  subtitle: '15% of gross booking value',
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Guides', style: AppText.h3),
                    GhostButton(
                      label: 'Add Guide',
                      icon: Icons.person_add_outlined,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (guides.isEmpty)
                  AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(Icons.group_outlined, size: 40, color: AppColors.textTertiary),
                            const SizedBox(height: 8),
                            Text('No guides yet', style: AppText.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...guides.map((guide) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GuideCard(guide: guide),
                  )),
                const SizedBox(height: AppSpacing.xl),
                Text('Recent Bookings', style: AppText.h3),
                const SizedBox(height: AppSpacing.sm),
                if (recentBookings.isEmpty)
                  AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 40, color: AppColors.textTertiary),
                            const SizedBox(height: 8),
                            Text('No bookings yet', style: AppText.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...recentBookings.take(5).map((booking) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _BookingCard(booking: booking),
                  )),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoutBtn extends StatefulWidget {
  final VoidCallback onPressed;
  const _LogoutBtn({required this.onPressed});

  @override
  State<_LogoutBtn> createState() => _LogoutBtnState();
}

class _LogoutBtnState extends State<_LogoutBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.logout, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppText.h2.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(title, style: AppText.label),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final Map<String, dynamic> guide;

  const _GuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final name = guide['name'] ?? 'Guide';
    final guideId = guide['id'] ?? '';
    final ratingCount = guide['rating_count'] ?? 0;
    final ratingHistory = (guide['rating_history'] ?? 0.0).toDouble();
    final licenseVerified = guide['license_verified'] ?? false;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.person, color: AppColors.textTertiary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppText.labelBold),
                    if (licenseVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: AppColors.success, size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFBBF24), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${ratingHistory.toStringAsFixed(1)} ($ratingCount)',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            guideId,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED': return AppColors.statusConfirmed;
      case 'COMPLETED': return AppColors.statusCompleted;
      case 'CANCELLED': return AppColors.statusCancelled;
      default: return AppColors.statusRequested;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'PENDING';
    final grossValue = (booking['gross_value'] ?? 0.0).toDouble();
    final destination = booking['destination'] ?? 'Unknown';
    final guideName = booking['guide_name'] ?? 'Guide';

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(
                  label: status.toUpperCase(),
                  color: _statusColor(status),
                ),
                const SizedBox(height: 8),
                Text(destination, style: AppText.labelBold),
                Text('Guide: $guideName', style: AppText.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${grossValue.toStringAsFixed(2)}',
                style: AppText.labelBold,
              ),
              Text('gross', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessFloatingCard extends StatelessWidget {
  final String businessName;

  const _BusinessFloatingCard({required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: Text(
              businessName.isNotEmpty ? businessName[0].toUpperCase() : 'B',
              style: AppText.h3.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businessName,
              style: AppText.labelBold.copyWith(color: Colors.white, fontSize: 15),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 10, color: AppColors.success),
                  const SizedBox(width: 3),
                  Text(
                    'Business',
                    style: AppText.caption.copyWith(color: AppColors.success, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DarkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
