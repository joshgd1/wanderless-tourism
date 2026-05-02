import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api_client.dart';
import '../../../../core/guide_auth_provider.dart';
import '../../../../design_system.dart';

final guideBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(guideAuthProvider);
  if (authState.guideId == null) return [];
  final api = ApiClient();
  final data = await api.getGuideBookings();
  return data.cast<Map<String, dynamic>>();
});

final guideMeProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(guideAuthProvider);
  if (authState.guideId == null) return null;
  final api = ApiClient();
  final data = await api.getGuideMe();
  return data;
});

class GuideDashboardScreen extends ConsumerStatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  ConsumerState<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends ConsumerState<GuideDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(guideAuthProvider);
    final bookingsAsync = ref.watch(guideBookingsProvider);
    final guideMeAsync = ref.watch(guideMeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
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
                        // Subtle grid
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DarkGridPainter(),
                            size: Size.infinite,
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Guide profile card
                                  guideMeAsync.when(
                                    data: (guide) {
                                      if (guide == null) return const SizedBox.shrink();
                                      return _GuideProfileCard(
                                        name: guide['name'] ?? authState.guideName ?? 'Guide',
                                        guideId: guide['id'] ?? '',
                                        photoUrl: guide['photo_url'] ?? '',
                                        rating: (guide['rating_history'] ?? 0.0).toDouble(),
                                        ratingCount: guide['rating_count'] ?? 0,
                                        licenseVerified: guide['license_verified'] ?? false,
                                      );
                                    },
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                  // Logout
                                  _LogoutButton(
                                    onPressed: () async {
                                      await ref.read(guideAuthProvider.notifier).logout();
                                      if (context.mounted) {
                                        context.go('/guide/login');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.brand,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Current Jobs'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _CurrentJobsTab(bookingsAsync: bookingsAsync),
            _HistoryTab(bookingsAsync: bookingsAsync),
          ],
        ),
      ),
    );
  }
}

class _GuideProfileCard extends StatelessWidget {
  final String name;
  final String guideId;
  final String photoUrl;
  final double rating;
  final int ratingCount;
  final bool licenseVerified;

  const _GuideProfileCard({
    required this.name,
    required this.guideId,
    required this.photoUrl,
    required this.rating,
    required this.ratingCount,
    required this.licenseVerified,
  });

  @override
  Widget build(BuildContext context) {
    final flag = CountryFlags.fromName(name);
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brand, width: 2),
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildAvatarPlaceholder(),
                    errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: AppText.labelBold.copyWith(color: Colors.white, fontSize: 15),
                ),
                if (licenseVerified) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 10, color: Color(0xFF25D366)),
                        const SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: AppText.caption.copyWith(
                            color: const Color(0xFF25D366),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  guideId,
                  style: AppText.caption.copyWith(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                ..._buildStars(),
                const SizedBox(width: 4),
                Text(
                  '${rating.toStringAsFixed(1)} ($ratingCount)',
                  style: AppText.caption.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildStars() {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    final empty = 5 - full - (half ? 1 : 0);
    return [
      ...List.generate(full, (_) => const Icon(Icons.star, size: 12, color: Color(0xFFFBBF24))),
      if (half) const Icon(Icons.star_half, size: 12, color: Color(0xFFFBBF24)),
      ...List.generate(empty, (_) => Icon(Icons.star_border, size: 12, color: Colors.white.withOpacity(0.3))),
    ];
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.surfaceSecondary,
      child: const Icon(Icons.person, color: Colors.white54, size: 24),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(Icons.logout, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _CurrentJobsTab extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> bookingsAsync;

  const _CurrentJobsTab({required this.bookingsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bookingsAsync.when(
      loading: () => const AppLoading(message: 'Loading jobs...'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load jobs',
        subtitle: e.toString(),
        action: PrimaryButton(
          label: 'Retry',
          onPressed: () => ref.refresh(guideBookingsProvider),
        ),
      ),
      data: (bookings) {
        final activeStatuses = ['REQUESTED', 'CONFIRMED', 'PAID', 'IN_PROGRESS'];
        final activeBookings =
            bookings.where((b) => activeStatuses.contains(b['status'])).toList();

        if (activeBookings.isEmpty) {
          return EmptyState(
            icon: Icons.work_outline,
            title: 'No current jobs',
            subtitle: 'New booking requests will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(guideBookingsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: activeBookings.length,
            itemBuilder: (context, index) {
              final booking = activeBookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _JobCard(
                  booking: booking,
                  onAccept: booking['status'] == 'REQUESTED'
                      ? () => _confirmAndUpdate(context, ref, booking['id'], 'CONFIRMED',
                            'Accept this booking?', 'Once accepted, the tourist will be notified.')
                      : null,
                  onDecline: booking['status'] == 'REQUESTED'
                      ? () => _confirmAndUpdate(context, ref, booking['id'], 'CANCELLED',
                            'Decline this booking?', 'The tourist will be notified and can find another guide.')
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmAndUpdate(
    BuildContext context,
    WidgetRef ref,
    int bookingId,
    String status,
    String title,
    String body,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppText.h3),
        content: Text(body, style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppText.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(status == 'CONFIRMED' ? 'Accept' : 'Decline',
                style: AppText.label.copyWith(
                    color: status == 'CONFIRMED' ? AppColors.success : AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _updateStatus(context, ref, bookingId, status);
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    int bookingId,
    String status,
  ) async {
    try {
      final api = ApiClient();
      await api.updateBookingStatus(bookingId, status);
      ref.refresh(guideBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'CONFIRMED' ? 'Booking accepted!' : 'Booking declined'),
            backgroundColor: status == 'CONFIRMED' ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    }
  }
}

class _HistoryTab extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> bookingsAsync;

  const _HistoryTab({required this.bookingsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bookingsAsync.when(
      loading: () => const AppLoading(message: 'Loading history...'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load history',
        subtitle: e.toString(),
      ),
      data: (bookings) {
        final historyBookings = bookings
            .where((b) => ['COMPLETED', 'CANCELLED'].contains(b['status']))
            .toList();

        if (historyBookings.isEmpty) {
          return EmptyState(
            icon: Icons.history,
            title: 'No booking history',
            subtitle: 'Your completed trips will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(guideBookingsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: historyBookings.length,
            itemBuilder: (context, index) {
              final booking = historyBookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _JobCard(booking: booking, isHistory: true),
              );
            },
          ),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool isHistory;

  const _JobCard({
    required this.booking,
    this.onAccept,
    this.onDecline,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String;
    final isRequested = status == 'REQUESTED';
    final statusColor = BookingStatus.color(status);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              StatusBadge(
                label: BookingStatus.label(status),
                color: statusColor,
                icon: isRequested ? Icons.fiber_manual_record : null,
              ),
              const Spacer(),
              Text(
                'Booking #${booking['id']}',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Tourist info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                    Text(
                      booking['tourist_name'] as String? ?? 'Unknown Tourist',
                      style: AppText.labelBold,
                    ),
                    Text(
                      'Tourist',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    booking['tour_date'] as String? ?? 'TBD',
                    style: AppText.labelBold,
                  ),
                  Text(
                    '${(booking['duration_hours'] as num?)?.toStringAsFixed(1) ?? '0'}h',
                    style: AppText.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Destination + group
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking['destination'] as String? ?? 'TBD',
                  style: AppText.bodySmall,
                ),
              ),
              const Icon(Icons.group_outlined, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${booking['group_size'] ?? 1} people',
                style: AppText.bodySmall,
              ),
            ],
          ),
          // Track Tour button
          if (status == 'IN_PROGRESS' && !isHistory) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Track Tour',
                icon: Icons.location_on,
                onPressed: () => context.push('/track/${booking['id']}'),
              ),
            ),
          ],
          // Accept / Decline
          if (isRequested && !isHistory) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Decline',
                    icon: Icons.close,
                    color: AppColors.error,
                    onPressed: onDecline,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Accept',
                    icon: Icons.check,
                    onPressed: onAccept,
                  ),
                ),
              ],
            ),
          ],
          // Completed earnings
          if (isHistory && status == 'COMPLETED') ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Earned: \$${(booking['gross_value'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    style: AppText.labelBold.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

}
