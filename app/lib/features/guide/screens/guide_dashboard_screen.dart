import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api_client.dart';
import '../../../../core/guide_auth_provider.dart';

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

class _GuideDashboardScreenState extends ConsumerState<GuideDashboardScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: const Color(0xFFED8A19),
              leadingWidth: 0,
              leading: const SizedBox.shrink(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFED8A19), Color(0xFFEF9B2A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        // Floating avatar card
                        Positioned(
                          left: 16,
                          top: 12,
                          child: guideMeAsync.when(
                            data: (guide) {
                              if (guide == null) return const SizedBox.shrink();
                              return _GuideFloatingCard(
                                photoUrl: guide['photo_url'] ?? '',
                                name: guide['name'] ?? authState.guideName ?? 'Guide',
                                guideId: guide['id'] ?? '',
                                ratingHistory: (guide['rating_history'] ?? 0.0).toDouble(),
                                ratingCount: guide['rating_count'] ?? 0,
                                licenseVerified: guide['license_verified'] ?? false,
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                        // Top-right logout button
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () async {
                              await ref.read(guideAuthProvider.notifier).logout();
                              if (context.mounted) {
                                context.go('/guide/login');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
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

class _CurrentJobsTab extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> bookingsAsync;

  const _CurrentJobsTab({required this.bookingsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Failed to load bookings', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.refresh(guideBookingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (bookings) {
        // Filter to active bookings (not completed or cancelled)
        final activeStatuses = ['REQUESTED', 'CONFIRMED', 'PAID', 'IN_PROGRESS'];
        final activeBookings = bookings.where((b) => activeStatuses.contains(b['status'])).toList();

        if (activeBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off_outlined, size: 72, color: Colors.grey[300]),
                const SizedBox(height: 20),
                Text(
                  'No current jobs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'New booking requests will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(guideBookingsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeBookings.length,
            itemBuilder: (context, index) {
              final booking = activeBookings[index];
              return _GuideBookingCard(
                booking: booking,
                onAccept: booking['status'] == 'REQUESTED'
                    ? () => _updateStatus(context, ref, booking['id'], 'CONFIRMED')
                    : null,
                onDecline: booking['status'] == 'REQUESTED'
                    ? () => _updateStatus(context, ref, booking['id'], 'CANCELLED')
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, int bookingId, String status) async {
    try {
      final api = ApiClient();
      await api.updateBookingStatus(bookingId, status);
      ref.refresh(guideBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'CONFIRMED' ? 'Booking accepted!' : 'Booking declined'),
            backgroundColor: status == 'CONFIRMED' ? const Color(0xFFED8A19) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: $e'),
            backgroundColor: Colors.red,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Failed to load history', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.refresh(guideBookingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (bookings) {
        // Filter to completed/cancelled bookings
        final historyStatuses = ['COMPLETED', 'CANCELLED'];
        final historyBookings = bookings.where((b) => historyStatuses.contains(b['status'])).toList();

        if (historyBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 72, color: Colors.grey[300]),
                const SizedBox(height: 20),
                Text(
                  'No booking history',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed trips will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(guideBookingsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyBookings.length,
            itemBuilder: (context, index) {
              final booking = historyBookings[index];
              return _GuideBookingCard(
                booking: booking,
                isHistory: true,
              );
            },
          ),
        );
      },
    );
  }
}

class _GuideFloatingCard extends StatelessWidget {
  final String photoUrl;
  final String name;
  final String guideId;
  final double ratingHistory;
  final int ratingCount;
  final bool licenseVerified;

  const _GuideFloatingCard({
    required this.photoUrl,
    required this.name,
    required this.guideId,
    required this.ratingHistory,
    required this.ratingCount,
    required this.licenseVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: Colors.grey[700],
                          child: const Icon(Icons.person, color: Colors.white54, size: 28)),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[700],
                          child: const Icon(Icons.person, color: Colors.white54, size: 28)),
                    )
                  : Container(
                      color: Colors.grey[700],
                      child: const Icon(Icons.person, color: Colors.white54, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    guideId,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (licenseVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(ratingHistory.floor(), (i) {
                    return const Icon(Icons.star, size: 14, color: Colors.amber);
                  }),
                  if (ratingHistory % 1 >= 0.5)
                    const Icon(Icons.star_half, size: 14, color: Colors.amber),
                  ...List.generate(5 - ratingHistory.ceil(), (i) {
                    return Icon(Icons.star_border, size: 14, color: Colors.white.withOpacity(0.5));
                  }),
                  const SizedBox(width: 4),
                  Text(
                    '${ratingHistory.toStringAsFixed(1)} ($ratingCount)',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool isHistory;

  const _GuideBookingCard({
    required this.booking,
    this.onAccept,
    this.onDecline,
    this.isHistory = false,
  });

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return Colors.orange;
      case 'CONFIRMED':
        return const Color(0xFFED8A19);
      case 'PAID':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return 'New Request';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PAID':
        return 'Paid';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String;
    final isRequested = status == 'REQUESTED';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRequested) ...[
                        Icon(Icons.fiber_manual_record, color: _statusColor(status), size: 12),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Booking #${booking['id']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tourist info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFED8A19).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFFED8A19)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tourist',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        booking['tourist_name'] as String? ?? 'Unknown Tourist',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking['tour_date'] as String? ?? 'TBD',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${(booking['duration_hours'] as num?)?.toStringAsFixed(1) ?? '0'}h',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Destination and group
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking['destination'] as String? ?? 'TBD',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                Icon(Icons.group_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${booking['group_size'] ?? 1} people',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),

            // Track Tour button for IN_PROGRESS status
            if (status == 'IN_PROGRESS' && !isHistory) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/track/${booking['id']}');
                  },
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('Track Tour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],

            // Action buttons for REQUESTED status
            if (isRequested && !isHistory) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED8A19),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],

            // Completed/Cancelled shows earnings
            if (isHistory && (status == 'COMPLETED')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Earned: \$${(booking['gross_value'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
