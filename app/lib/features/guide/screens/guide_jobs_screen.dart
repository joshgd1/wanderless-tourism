import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/guide_auth_provider.dart';
import '../../../../core/api_client.dart';
import '../../../../design_system.dart';

final _syntheticGuideBookings = [
  {'id': 1, 'tourist_name': 'Sarah Johnson', 'tour_date': '2026-05-15', 'destination': 'Mount Batur Sunrise Trek', 'group_size': 4, 'duration_hours': 6.0, 'status': 'CONFIRMED', 'gross_value': 240.0, 'tour_type': 'Adventure'},
  {'id': 2, 'tourist_name': 'Michael Chen', 'tour_date': '2026-05-18', 'destination': 'Uluwatu Temple Tour', 'group_size': 2, 'duration_hours': 4.0, 'status': 'REQUESTED', 'gross_value': 120.0, 'tour_type': 'Cultural'},
  {'id': 3, 'tourist_name': 'Emma Williams', 'tour_date': '2026-05-10', 'destination': 'Nusa Penida Island', 'group_size': 6, 'duration_hours': 8.0, 'status': 'COMPLETED', 'gross_value': 360.0, 'tour_type': 'Adventure'},
  {'id': 4, 'tourist_name': 'David Kim', 'tour_date': '2026-05-08', 'destination': 'Rice Terraces Walk', 'group_size': 3, 'duration_hours': 5.0, 'status': 'COMPLETED', 'gross_value': 150.0, 'tour_type': 'Nature'},
  {'id': 5, 'tourist_name': 'Lisa Anderson', 'tour_date': '2026-05-22', 'destination': 'Waterfall Adventure', 'group_size': 5, 'duration_hours': 7.0, 'status': 'CONFIRMED', 'gross_value': 280.0, 'tour_type': 'Adventure'},
  {'id': 6, 'tourist_name': 'James Wilson', 'tour_date': '2026-05-25', 'destination': 'Local Cooking Class', 'group_size': 2, 'duration_hours': 3.0, 'status': 'REQUESTED', 'gross_value': 90.0, 'tour_type': 'Cultural'},
  {'id': 7, 'tourist_name': 'Ana Rodriguez', 'tour_date': '2026-05-03', 'destination': 'Snorkeling Day Trip', 'group_size': 4, 'duration_hours': 5.0, 'status': 'COMPLETED', 'gross_value': 200.0, 'tour_type': 'Water Sports'},
  {'id': 8, 'tourist_name': 'Tom Brown', 'tour_date': '2026-05-01', 'destination': 'Temple Sunrise Tour', 'group_size': 3, 'duration_hours': 4.0, 'status': 'CANCELLED', 'gross_value': 135.0, 'tour_type': 'Cultural'},
  {'id': 9, 'tourist_name': 'Sophie Taylor', 'tour_date': '2026-05-28', 'destination': 'Coffee Plantation Tour', 'group_size': 2, 'duration_hours': 3.0, 'status': 'CONFIRMED', 'gross_value': 80.0, 'tour_type': 'Nature'},
  {'id': 10, 'tourist_name': 'Ryan Martinez', 'tour_date': '2026-04-28', 'destination': 'ATV Jungle Ride', 'group_size': 4, 'duration_hours': 4.0, 'status': 'COMPLETED', 'gross_value': 220.0, 'tour_type': 'Adventure'},
];

final guideBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(guideAuthProvider);
  if (authState.guideId == null) return [];
  try {
    final api = ApiClient();
    final data = await api.getGuideBookings();
    return data.cast<Map<String, dynamic>>();
  } catch (_) {
    return _syntheticGuideBookings;
  }
});

class GuideJobsScreen extends ConsumerStatefulWidget {
  const GuideJobsScreen({super.key});

  @override
  ConsumerState<GuideJobsScreen> createState() => _GuideJobsScreenState();
}

class _GuideJobsScreenState extends ConsumerState<GuideJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'date';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAndSort(List<Map<String, dynamic>> bookings) {
    var filtered = bookings.where((b) {
      if (_filterStatus == 'all') return true;
      return b['status'] == _filterStatus;
    }).toList();
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date': return (b['tour_date'] ?? '').compareTo(a['tour_date'] ?? '');
        case 'amount': return ((b['gross_value'] ?? 0) as num).compareTo((a['gross_value'] ?? 0) as num);
        case 'tourist': return (a['tourist_name'] ?? '').compareTo(b['tourist_name'] ?? '');
        default: return 0;
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(guideAuthProvider);
    final bookingsAsync = ref.watch(guideBookingsProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    final allBookings = bookingsAsync.when(
      data: (data) => data.isEmpty ? _syntheticGuideBookings : data,
      loading: () => _syntheticGuideBookings,
      error: (_, __) => _syntheticGuideBookings,
    );

    final totalJobs = allBookings.length;
    final totalEarnings = allBookings
        .where((b) => b['status'] == 'COMPLETED')
        .fold(0.0, (sum, b) => sum + ((b['gross_value'] ?? 0) as num).toDouble());

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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authState.guideName ?? 'Guide Portal',
                                    style: AppText.h3.copyWith(color: Colors.white, fontSize: 18),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalJobs jobs · \$${totalEarnings.toStringAsFixed(0)} earned',
                                    style: AppText.caption.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _IconBtn(icon: Icons.notifications_outlined, onPressed: () {}),
                              _IconBtn(icon: Icons.person_outline, onPressed: () {}),
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
                unselectedLabelColor: Colors.white60,
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'All Jobs'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(child: _SortDropdown(value: _sortBy, onChanged: (v) => setState(() => _sortBy = v ?? 'date'))),
                  const SizedBox(width: 8),
                  Expanded(child: _FilterDropdown(value: _filterStatus, onChanged: (v) => setState(() => _filterStatus = v ?? 'all'))),
                ],
              ),
            ),
            Expanded(
              child: bookingsAsync.when(
                loading: () => const AppLoading(message: 'Loading jobs...'),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load jobs',
                  subtitle: e.toString(),
                ),
                data: (_) => TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingList(bookings: _filterAndSort(allBookings)),
                    _BookingList(bookings: _filterAndSort(allBookings.where((b) {
                      final s = b['status'] as String;
                      return s == 'REQUESTED' || s == 'CONFIRMED' || s == 'IN_PROGRESS';
                    }).toList())),
                    _BookingList(bookings: _filterAndSort(allBookings.where((b) {
                      final s = b['status'] as String;
                      return s == 'COMPLETED' || s == 'CANCELLED';
                    }).toList())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _IconBtn({required this.icon, required this.onPressed});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
          child: Icon(widget.icon, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: AppText.bodySmall,
          items: const [
            DropdownMenuItem(value: 'date', child: Text('Sort by Date', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'amount', child: Text('Sort by Amount', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'tourist', child: Text('Sort by Tourist', style: TextStyle(fontSize: 13))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: AppText.bodySmall,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'REQUESTED', child: Text('Requested', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmed', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'COMPLETED', child: Text('Completed', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled', style: TextStyle(fontSize: 13))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.work_outline,
        title: 'No jobs found',
        subtitle: 'Bookings will appear here',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _BookingRow(booking: b),
        );
      },
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingRow({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'REQUESTED': return AppColors.statusRequested;
      case 'CONFIRMED': return AppColors.statusConfirmed;
      case 'IN_PROGRESS': return AppColors.statusInProgress;
      case 'COMPLETED': return AppColors.statusCompleted;
      case 'CANCELLED': return AppColors.statusCancelled;
      default: return AppColors.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'REQUESTED': return 'New';
      case 'CONFIRMED': return 'Confirmed';
      case 'IN_PROGRESS': return 'Active';
      case 'COMPLETED': return 'Done';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String;
    final statusColor = _statusColor(status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(label: _statusLabel(status), color: statusColor),
              const Spacer(),
              Text('Booking #${booking['id']}', style: AppText.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    (booking['tourist_name'] as String? ?? 'T')[0],
                    style: AppText.labelBold.copyWith(color: AppColors.brand),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['tourist_name'] ?? 'Tourist', style: AppText.labelBold),
                    Text(booking['tour_type'] as String? ?? '', style: AppText.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(booking['tour_date'] as String? ?? '', style: AppText.labelBold),
                  Text('${booking['group_size'] ?? 0} pax · \$${(booking['gross_value'] ?? 0).toStringAsFixed(0)}', style: AppText.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(child: Text(booking['destination'] as String? ?? '', style: AppText.bodySmall)),
            ],
          ),
        ],
      ),
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
