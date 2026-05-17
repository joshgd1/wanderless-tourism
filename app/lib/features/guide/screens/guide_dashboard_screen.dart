import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_flags/country_flags.dart';
import '../../../../core/api_client.dart';
import '../../../../core/guide_auth_provider.dart';
import '../../../../design_system.dart';
import '../../trip_plan/providers/trip_plan_providers.dart'
    as trip_plan_providers show guideOpenRequestsProvider;

const _openRequestsPollInterval = Duration(seconds: 30);

/// Provider for guide's open requests (PENDING_ACCEPTANCE plans assigned to this guide).
/// Returns live API data only — no synthetic masking.
final guideOpenRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final liveAsync = ref.watch(trip_plan_providers.guideOpenRequestsProvider);
  return liveAsync.value ?? [];
});

final guideBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(guideAuthProvider);
  if (authState.guideId == null || authState.token == null) return [];
  try {
    final api = ApiClient();
    final data = await api.getGuideBookings(guideToken: authState.token!);
    final bookings = data.cast<Map<String, dynamic>>();
    // Demo: if no bookings, add a sample pending REQUESTED booking for Singapore demo
    if (bookings.isEmpty) {
      return [
        {
          'id': 999001,
          'status': 'REQUESTED',
          'tourist_name': 'Alexandra Tan',
          'tour_date': '2026-05-10',
          'duration_hours': 4.0,
          'destination': 'Marina Bay, Singapore',
          'group_size': 2,
          'gross_value': 280.00,
          'notes': 'Interested in a private city tour covering Gardens by the Bay and Marina Bay Sands.',
        },
      ];
    }
    return bookings;
  } catch (e) {
    // Demo fallback: return sample pending booking on API error
    return [
      {
        'id': 999001,
        'status': 'REQUESTED',
        'tourist_name': 'Alexandra Tan',
        'tour_date': '2026-05-10',
        'duration_hours': 4.0,
        'destination': 'Marina Bay, Singapore',
        'group_size': 2,
        'gross_value': 280.00,
        'notes': 'Interested in a private city tour covering Gardens by the Bay and Marina Bay Sands.',
      },
    ];
  }
});

final guideMeProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(guideAuthProvider);
  if (authState.guideId == null || authState.token == null) return null;
  final api = ApiClient();
  final data = await api.getGuideMe(guideToken: authState.token);
  return data;
});

final guideOpenGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(guideAuthProvider);
  if (authState.guideId == null) return _syntheticOpenGroups;
  try {
    final api = ApiClient();
    final data = await api.getGroups(status: 'OPEN');
    final groups = data.where((g) => g['guide_id'] == null).toList().cast<Map<String, dynamic>>();
    return groups.isEmpty ? _syntheticOpenGroups : groups;
  } catch (_) {
    return _syntheticOpenGroups;
  }
});

final _syntheticOpenGroups = [
  {
    'id': 201,
    'status': 'OPEN',
    'destination': 'Gardens by the Bay Explorer',
    'proposed_date': '2026-05-18',
    'member_count': 3,
    'max_size': 8,
    'interests': ['nature', 'photography'],
    'budget_range': '\$\$',
    'preferred_guide_gender': 'No preference',
  },
  {
    'id': 202,
    'status': 'OPEN',
    'destination': 'Haw Par Villa & Chinatown',
    'proposed_date': '2026-05-22',
    'member_count': 5,
    'max_size': 10,
    'interests': ['culture', 'history'],
    'budget_range': '\$',
    'preferred_guide_gender': 'No preference',
  },
  {
    'id': 203,
    'status': 'OPEN',
    'destination': 'Sentosa Island Adventure',
    'proposed_date': '2026-05-25',
    'member_count': 2,
    'max_size': 6,
    'interests': ['adventure', 'beach'],
    'budget_range': '\$\$\$',
    'preferred_guide_gender': 'No preference',
  },
  {
    'id': 204,
    'status': 'OPEN',
    'destination': 'Little India & Kampong Glam',
    'proposed_date': '2026-05-28',
    'member_count': 4,
    'max_size': 8,
    'interests': ['food', 'culture'],
    'budget_range': '\$\$',
    'preferred_guide_gender': 'No preference',
  },
];

class GuideDashboardScreen extends ConsumerStatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  ConsumerState<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends ConsumerState<GuideDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pollingTimer = Timer.periodic(_openRequestsPollInterval, (_) {
      ref.invalidate(guideOpenRequestsProvider);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(guideAuthProvider);
    final bookingsAsync = ref.watch(guideBookingsProvider);
    final guideMeAsync = ref.watch(guideMeProvider);
    final openRequestsAsync = ref.watch(guideOpenRequestsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _GuideDrawer(
        onLogout: () async {
          await ref.read(guideAuthProvider.notifier).logout();
          if (context.mounted) {
            Navigator.pop(context);
            context.go('/guide/login');
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Clean sticky header — Airbnb/Grab-style
            _GuideStickyHeader(
              guideMeAsync: guideMeAsync,
              guideName: authState.guideName ?? 'Guide',
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            // Sticky tab bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.brand,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                labelStyle: AppText.labelBold,
                unselectedLabelStyle: AppText.label,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Jobs'),
                  Tab(text: 'History'),
                  Tab(text: 'Groups'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PendingTab(bookingsAsync: bookingsAsync, openRequestsAsync: openRequestsAsync),
                  _CurrentJobsTab(bookingsAsync: bookingsAsync),
                  _HistoryTab(bookingsAsync: bookingsAsync),
                  _OpenGroupsTab(),
                ],
              ),
            ),
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

class _GuideStickyHeader extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> guideMeAsync;
  final String guideName;
  final VoidCallback onMenuTap;

  const _GuideStickyHeader({
    required this.guideMeAsync,
    required this.guideName,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Guide avatar + name
          guideMeAsync.when(
            data: (guide) {
              if (guide == null) return _buildCompactProfile(guideName, '');
              return _buildCompactProfile(
                guide['name'] ?? guideName,
                guide['photo_url'] ?? '',
              );
            },
            loading: () => _buildCompactProfile(guideName, ''),
            error: (_, __) => _buildCompactProfile(guideName, ''),
          ),
          const Spacer(),
          // Notification bell (placeholder for future)
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
          // Hamburger menu
          _HeaderIconButton(
            icon: Icons.menu,
            onTap: onMenuTap,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProfile(String name, String photoUrl) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brand.withOpacity(0.3)),
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.person, color: AppColors.brand, size: 18),
                    errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.brand, size: 18),
                  )
                : const Icon(Icons.person, color: AppColors.brand, size: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi, ${name.split(' ').first} 🇸🇬',
              style: AppText.labelBold.copyWith(fontSize: 14),
            ),
            Text(
              'Guide Dashboard',
              style: AppText.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _GuideDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const _GuideDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.brand,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Guide Menu',
                    style: AppText.h2.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Wanderless Guide App',
                    style: AppText.caption.copyWith(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.home_outlined,
                    label: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: () {},
                  ),
                  _DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {},
                  ),
                  _DrawerMenuItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.border),
                  _DrawerMenuItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    isDestructive: true,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
            // App version
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Wanderless v1.0.0',
                style: AppText.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: AppText.label.copyWith(color: color),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      dense: true,
    );
  }
}

class _PendingTab extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> bookingsAsync;
  final AsyncValue<List<Map<String, dynamic>>> openRequestsAsync;

  const _PendingTab({required this.bookingsAsync, required this.openRequestsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bookingsAsync.when(
      loading: () => const AppLoading(message: 'Loading requests...'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load requests',
        subtitle: e.toString(),
        action: PrimaryButton(
          label: 'Retry',
          onPressed: () => ref.refresh(guideBookingsProvider),
        ),
      ),
      data: (bookings) {
        final requestedBookings =
            bookings.where((b) => b['status'] == 'REQUESTED').toList();

        final openRequests = openRequestsAsync.whenOrNull(data: (r) => r) ?? [];
        final allPending = [...requestedBookings, ...openRequests];

        if (allPending.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No pending requests',
            subtitle: 'When a tourist sends you a plan request, it will appear here',
          );
        }

        return Column(
          children: [
            // Attention banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.warningBg,
              child: Row(
                children: [
                  const Icon(Icons.pending_actions,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${allPending.length} request${allPending.length > 1 ? 's' : ''} waiting for your response',
                      style: AppText.labelBold
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(guideBookingsProvider);
                  ref.refresh(guideOpenRequestsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: allPending.length,
                  itemBuilder: (context, index) {
                    final item = allPending[index];
                    final isRequest = item.containsKey('tourist_name') && !item.containsKey('gross_value');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: isRequest
                          ? _OpenRequestCard(
                              request: item,
                              onAccept: () => _confirmAndUpdateRequest(
                                context,
                                ref,
                                item['id'],
                                'PENDING_ACCEPTANCE',
                                'Accept this request?',
                                'You will be matched with ${item['tourist_name'] ?? 'this tourist'} for their trip.',
                                item['tourist_name'] ?? 'Unknown',
                                destination: item['destination'] as String?,
                                tourDate: item['tour_date_start'] as String?,
                                durationHours: (item['duration_hours'] as num?)?.toDouble(),
                                groupSize: item['group_size'] as int?,
                              ),
                              onDecline: () => _confirmAndUpdateRequest(
                                context,
                                ref,
                                item['id'],
                                'DECLINED',
                                'Are you sure you want to decline?',
                                '${item['tourist_name'] ?? 'This tourist'} will be notified and can find another guide.',
                                item['tourist_name'] ?? 'Unknown',
                              ),
                            )
                          : _JobCard(
                              booking: item,
                              onAccept: () => _confirmAndUpdate(
                                context,
                                ref,
                                item['id'],
                                'CONFIRMED',
                                'Accept this booking?',
                                'Once accepted, the tourist will be notified and can proceed with payment.',
                              ),
                              onDecline: () => _confirmAndUpdate(
                                context,
                                ref,
                                item['id'],
                                'CANCELLED',
                                'Decline this booking?',
                                'The tourist will be notified and can find another guide.',
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status == 'CONFIRMED'
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                status == 'CONFIRMED' ? Icons.check_circle : Icons.cancel,
                color: status == 'CONFIRMED' ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppText.h3)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, style: AppText.body.copyWith(color: AppColors.textSecondary)),
            if (status == 'CONFIRMED') ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AppColors.brand),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Singapore City Tour',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(CountryFlags.fromName('Singapore'), style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          const Text('Singapore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppText.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              status == 'CONFIRMED' ? 'Accept Booking' : 'Decline',
              style: AppText.label.copyWith(
                color: status == 'CONFIRMED' ? AppColors.success : AppColors.error,
              ),
            ),
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
      final guideAuth = ref.read(guideAuthProvider);
      await api.updateBookingStatus(bookingId, status, guideToken: guideAuth.token);
      ref.refresh(guideBookingsProvider);
      ref.refresh(guideOpenRequestsProvider);
      if (status == 'CONFIRMED' && context.mounted) {
        // Show beautiful success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _AcceptSuccessDialog(
            onDone: () => Navigator.pop(ctx),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'CONFIRMED' ? 'Booking accepted!' : 'Successfully declined'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
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
            duration: const Duration(seconds: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndUpdateRequest(
    BuildContext context,
    WidgetRef ref,
    int requestId,
    String status,
    String title,
    String body,
    String touristName, {
    String? destination,
    String? tourDate,
    double? durationHours,
    int? groupSize,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status == 'PENDING_ACCEPTANCE'
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                status == 'PENDING_ACCEPTANCE' ? Icons.check_circle : Icons.cancel,
                color: status == 'PENDING_ACCEPTANCE' ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppText.h3)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, style: AppText.body.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppText.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              status == 'PENDING_ACCEPTANCE' ? 'Accept' : 'Decline',
              style: AppText.label.copyWith(
                color: status == 'PENDING_ACCEPTANCE' ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _updateRequestStatus(
      context,
      ref,
      requestId,
      status,
      touristName,
      destination: destination,
      tourDate: tourDate,
      durationHours: durationHours,
      groupSize: groupSize,
    );
  }

  Future<void> _updateRequestStatus(
    BuildContext context,
    WidgetRef ref,
    int requestId,
    String status,
    String touristName, {
    String? destination,
    String? tourDate,
    double? durationHours,
    int? groupSize,
  }) async {
    try {
      final guideAuth = ref.read(guideAuthProvider);
      final api = ApiClient();
      if (status == 'PENDING_ACCEPTANCE') {
        await api.acceptGuideRequest(requestId, guideToken: guideAuth.token!);
      } else {
        await api.declineTripRequest(requestId, guideToken: guideAuth.token!);
      }
      ref.refresh(guideOpenRequestsProvider);
      if (context.mounted) {
        if (status == 'PENDING_ACCEPTANCE') {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _AcceptSuccessDialog(
              onDone: () => Navigator.pop(ctx),
              destination: destination ?? 'Tour Request',
              tourDate: tourDate ?? 'TBD',
              durationHours: durationHours ?? 4.0,
              groupSize: groupSize ?? 2,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request declined successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        String msg = e.toString();
        // Clean up DioException message
        if (msg.contains('DioException')) {
          if (msg.contains('connection')) {
            msg = 'Cannot connect to server';
          } else if (msg.contains('401')) {
            msg = 'Unauthorized - please login again';
          } else if (msg.contains('403')) {
            msg = 'Access denied';
          } else if (msg.contains('404')) {
            msg = 'Request not found';
          } else if (msg.contains('500')) {
            msg = 'Server error';
          } else {
            msg = 'Request failed. Please try again.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    }
  }
}

class _AcceptSuccessDialog extends StatefulWidget {
  final VoidCallback onDone;
  final String? destination;
  final String? tourDate;
  final double? durationHours;
  final int? groupSize;

  const _AcceptSuccessDialog({
    required this.onDone,
    this.destination,
    this.tourDate,
    this.durationHours,
    this.groupSize,
  });

  @override
  State<_AcceptSuccessDialog> createState() => _AcceptSuccessDialogState();
}

class _AcceptSuccessDialogState extends State<_AcceptSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 56,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Request Accepted!',
                style: AppText.h3.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You have accepted the tour request${widget.destination != null ? ' for ${widget.destination}' : ''}.',
                style: AppText.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppColors.brand),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(widget.destination ?? 'Tour Request',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(widget.tourDate ?? 'TBD',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.schedule,
                            size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text('${(widget.durationHours ?? 4.0).toStringAsFixed(1)} hours',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.group,
                            size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text('${widget.groupSize ?? 2} tourist${(widget.groupSize ?? 2) == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'View Current Jobs',
                  onPressed: () {
                    widget.onDone();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: GhostButton(
                  label: 'Stay Here',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
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
        final activeStatuses = ['CONFIRMED', 'PAID', 'IN_PROGRESS'];
        final activeBookings =
            bookings.where((b) => activeStatuses.contains(b['status'])).toList();

        if (activeBookings.isEmpty) {
          return const EmptyState(
            icon: Icons.work_outline,
            title: 'No active jobs',
            subtitle: 'Your accepted and in-progress tours will appear here',
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
      final guideAuth = ref.read(guideAuthProvider);
      await api.updateBookingStatus(bookingId, status, guideToken: guideAuth.token);
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
                '#${booking['id']}',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Tourist info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.person, color: AppColors.textTertiary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['tourist_name'] as String? ?? 'Unknown Tourist',
                      style: AppText.labelBold,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tourist',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    booking['tour_date'] as String? ?? 'TBD',
                    style: AppText.labelBold,
                  ),
                  const SizedBox(height: 2),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.group_outlined, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${booking['group_size'] ?? 1}',
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

class _OpenRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _OpenRequestCard({
    required this.request,
    this.onAccept,
    this.onDecline,
  });

  void _showDetailSheet(BuildContext context) {
    final status = request['status'] as String? ?? 'OPEN';
    final destination = request['destination'] as String? ?? 'TBD';
    final touristName = request['tourist_name'] as String? ?? 'Unknown Tourist';
    final groupSize = request['group_size'] as int? ?? 2;
    final durationHours = (request['duration_hours'] as num?)?.toDouble() ?? 4.0;
    final interests = (request['interests'] as List?)?.cast<String>() ?? [];
    final tourDate = request['tour_date_start'] as String? ?? 'TBD';
    final dietary = request['dietary_requirement'] as String? ?? 'None';
    final avoidLateNight = request['avoid_late_night'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Header
            Row(
              children: [
                StatusBadge(
                  label: status == 'PENDING_ACCEPTANCE' ? 'Pending' : 'Open',
                  color: status == 'PENDING_ACCEPTANCE' ? AppColors.warning : AppColors.info,
                ),
                const Spacer(),
                Text('#${request['id']}', style: AppText.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Tourist section
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TouristAvatar(
                        photoUrl: request['tourist_photo_url'] as String?,
                        name: touristName,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(touristName, style: AppText.labelBold),
                            const SizedBox(height: 2),
                            Text('Tourist', style: AppText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Trip details
            Text('Trip Details', style: AppText.labelBold),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.location_on_outlined, label: 'Destination', value: destination),
                  const Divider(height: 16),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: tourDate),
                  const Divider(height: 16),
                  _DetailRow(icon: Icons.schedule_outlined, label: 'Duration', value: '${durationHours.toStringAsFixed(1)} hours'),
                  const Divider(height: 16),
                  _DetailRow(icon: Icons.group_outlined, label: 'Group Size', value: '$groupSize travelers'),
                  const Divider(height: 16),
                  _DetailRow(icon: Icons.restaurant_outlined, label: 'Dietary', value: dietary),
                  const Divider(height: 16),
                  _DetailRow(
                    icon: Icons.nightlight_outlined,
                    label: 'Avoid Late Night',
                    value: avoidLateNight ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
            if (interests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Interests', style: AppText.labelBold),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: interests.map((i) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    i[0].toUpperCase() + i.substring(1),
                    style: AppText.caption.copyWith(color: AppColors.brand),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            // Action buttons — modern rounded style
            Row(
              children: [
                Expanded(
                  child: _ModernActionButton(
                    label: 'Decline',
                    icon: Icons.close,
                    color: AppColors.error,
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      onDecline?.call();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ModernActionButton(
                    label: 'Accept',
                    icon: Icons.check,
                    color: AppColors.success,
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      onAccept?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'OPEN';
    final destination = request['destination'] as String? ?? 'TBD';
    final touristName = request['tourist_name'] as String? ?? 'Unknown Tourist';
    final groupSize = request['group_size'] as int? ?? 2;
    final durationHours = (request['duration_hours'] as num?)?.toDouble() ?? 4.0;
    final interests = (request['interests'] as List?)?.cast<String>() ?? [];

    return AppCard(
      onTap: () => _showDetailSheet(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              StatusBadge(
                label: status == 'PENDING_ACCEPTANCE' ? 'Pending' : 'Open',
                color: status == 'PENDING_ACCEPTANCE' ? AppColors.warning : AppColors.info,
              ),
              const Spacer(),
              Text(
                '#${request['id']}',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Tourist info
          Row(
            children: [
              _TouristAvatar(
                photoUrl: request['tourist_photo_url'] as String?,
                name: touristName,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      touristName,
                      style: AppText.labelBold,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tourist',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    request['tour_date_start'] as String? ?? 'TBD',
                    style: AppText.labelBold,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${durationHours.toStringAsFixed(1)}h',
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
                  destination,
                  style: AppText.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.group_outlined, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '$groupSize',
                style: AppText.bodySmall,
              ),
            ],
          ),
          // Interests
          if (interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: interests.take(3).map((i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(i, style: AppText.caption.copyWith(color: AppColors.brand, fontSize: 10)),
              )).toList(),
            ),
          ],
          // Accept / Decline buttons — modern rounded style
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ModernActionButton(
                  label: 'Decline',
                  icon: Icons.close,
                  color: AppColors.error,
                  onPressed: onDecline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ModernActionButton(
                  label: 'Accept',
                  icon: Icons.check,
                  color: AppColors.success,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppText.caption),
        ),
        Text(value, style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TouristAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const _TouristAvatar({this.photoUrl, required this.name, required this.size});

  Color get _color {
    final colors = [
      AppColors.brand,
      AppColors.success,
      AppColors.info,
      Colors.purple,
      Colors.teal,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallbackAvatar,
          errorWidget: (_, __, ___) => _fallbackAvatar,
        ),
      );
    }
    return _fallbackAvatar;
  }

  Widget get _fallbackAvatar {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: _color,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Modern rounded action button with icon — used in _OpenRequestCard.
class _ModernActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ModernActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.labelBold.copyWith(color: color, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenGroupsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(guideOpenGroupsProvider);

    return groupsAsync.when(
      loading: () => const AppLoading(message: 'Loading open groups...'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load groups',
        subtitle: e.toString(),
        action: PrimaryButton(
          label: 'Retry',
          onPressed: () => ref.refresh(guideOpenGroupsProvider),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return const EmptyState(
            icon: Icons.group_outlined,
            title: 'No open groups',
            subtitle: 'Groups seeking a guide will appear here.\nBrowse destinations and claim a group to get started.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(guideOpenGroupsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _OpenGroupCard(group: group),
              );
            },
          ),
        );
      },
    );
  }
}

class _OpenGroupCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> group;

  const _OpenGroupCard({required this.group});

  @override
  ConsumerState<_OpenGroupCard> createState() => _OpenGroupCardState();
}

class _OpenGroupCardState extends ConsumerState<_OpenGroupCard> {
  bool _isClaiming = false;

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Date TBD';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return date ?? 'Date TBD';
    }
  }

  Future<void> _claimGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.group_add, color: AppColors.brand, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Claim This Group?', style: AppText.h3)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You will be assigned as the guide for this group trip.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.location_on_outlined, label: 'Destination', value: widget.group['destination'] ?? 'TBD'),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.calendar_today_outlined, label: 'Date', value: _formatDate(widget.group['proposed_date'])),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.group_outlined,
                    label: 'Members',
                    value: '${widget.group['member_count'] ?? 0}/${widget.group['max_size'] ?? 8} joined',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppText.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Claim Group', style: AppText.label.copyWith(color: AppColors.brand)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClaiming = true);
    try {
      final api = ApiClient();
      await api.claimGroup(widget.group['id'] as int);
      ref.refresh(guideOpenGroupsProvider);
      ref.refresh(guideBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Group claimed! It is now confirmed.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.group, color: AppColors.brand, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group['destination'] ?? 'TBD',
                      style: AppText.h2,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Open — seeking guide',
                        style: AppText.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _DetailChip(icon: Icons.calendar_today_outlined, label: _formatDate(widget.group['proposed_date'])),
              const SizedBox(width: AppSpacing.sm),
              _DetailChip(
                icon: Icons.schedule_outlined,
                label: '${(widget.group['proposed_duration'] as num?)?.toStringAsFixed(1) ?? '4.0'}h',
              ),
              const Spacer(),
              _DetailChip(
                icon: Icons.group_outlined,
                label: '${widget.group['member_count'] ?? 0}/${widget.group['max_size'] ?? 8}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: _isClaiming
                ? const SizedBox(
                    width: double.infinity,
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                : PrimaryButton(
                    label: 'Claim This Group',
                    icon: Icons.group_add_outlined,
                    onPressed: _claimGroup,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(minHeight: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppText.caption),
        Expanded(child: Text(value, style: AppText.label)),
      ],
    );
  }
}
