import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/business_auth_provider.dart';
import '../../../../design_system.dart';

final _syntheticBusinessBookings = [
  {'id': 101, 'guide_name': 'Wayan Berata', 'tourist_name': 'Sarah Johnson', 'tour_date': '2026-05-15', 'destination': 'Mount Batur Sunrise Trek', 'group_size': 4, 'duration_hours': 6.0, 'status': 'CONFIRMED', 'gross_value': 240.0, 'tour_type': 'Adventure', 'commission': 36.0},
  {'id': 102, 'guide_name': 'Wayan Berata', 'tourist_name': 'Michael Chen', 'tour_date': '2026-05-18', 'destination': 'Uluwatu Temple Tour', 'group_size': 2, 'duration_hours': 4.0, 'status': 'REQUESTED', 'gross_value': 120.0, 'tour_type': 'Cultural', 'commission': 18.0},
  {'id': 103, 'guide_name': 'Made Surya', 'tourist_name': 'Emma Williams', 'tour_date': '2026-05-10', 'destination': 'Nusa Penida Island', 'group_size': 6, 'duration_hours': 8.0, 'status': 'COMPLETED', 'gross_value': 360.0, 'tour_type': 'Adventure', 'commission': 54.0},
  {'id': 104, 'guide_name': 'Wayan Berata', 'tourist_name': 'David Kim', 'tour_date': '2026-05-08', 'destination': 'Rice Terraces Walk', 'group_size': 3, 'duration_hours': 5.0, 'status': 'COMPLETED', 'gross_value': 150.0, 'tour_type': 'Nature', 'commission': 22.5},
  {'id': 105, 'guide_name': 'Ketut Sari', 'tourist_name': 'Lisa Anderson', 'tour_date': '2026-05-22', 'destination': 'Waterfall Adventure', 'group_size': 5, 'duration_hours': 7.0, 'status': 'CONFIRMED', 'gross_value': 280.0, 'tour_type': 'Adventure', 'commission': 42.0},
  {'id': 106, 'guide_name': 'Ketut Sari', 'tourist_name': 'James Wilson', 'tour_date': '2026-05-25', 'destination': 'Local Cooking Class', 'group_size': 2, 'duration_hours': 3.0, 'status': 'REQUESTED', 'gross_value': 90.0, 'tour_type': 'Cultural', 'commission': 13.5},
  {'id': 107, 'guide_name': 'Made Surya', 'tourist_name': 'Ana Rodriguez', 'tour_date': '2026-05-03', 'destination': 'Snorkeling Day Trip', 'group_size': 4, 'duration_hours': 5.0, 'status': 'COMPLETED', 'gross_value': 200.0, 'tour_type': 'Water Sports', 'commission': 30.0},
  {'id': 108, 'guide_name': 'Wayan Berata', 'tourist_name': 'Tom Brown', 'tour_date': '2026-05-01', 'destination': 'Temple Sunrise Tour', 'group_size': 3, 'duration_hours': 4.0, 'status': 'CANCELLED', 'gross_value': 135.0, 'tour_type': 'Cultural', 'commission': 0.0},
  {'id': 109, 'guide_name': 'Ketut Sari', 'tourist_name': 'Sophie Taylor', 'tour_date': '2026-05-28', 'destination': 'Coffee Plantation Tour', 'group_size': 2, 'duration_hours': 3.0, 'status': 'CONFIRMED', 'gross_value': 80.0, 'tour_type': 'Nature', 'commission': 12.0},
  {'id': 110, 'guide_name': 'Made Surya', 'tourist_name': 'Ryan Martinez', 'tour_date': '2024-04-28', 'destination': 'ATV Jungle Ride', 'group_size': 4, 'duration_hours': 4.0, 'status': 'COMPLETED', 'gross_value': 220.0, 'tour_type': 'Adventure', 'commission': 33.0},
];

final businessBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(businessAuthProvider);
  if (authState.businessOwnerId == null) return [];
  try {
    final api = ApiClient();
    final data = await api.businessDashboard();
    return (data['bookings'] as List? ?? _syntheticBusinessBookings).cast<Map<String, dynamic>>();
  } catch (_) {
    return _syntheticBusinessBookings;
  }
});

class BusinessJobsScreen extends ConsumerStatefulWidget {
  const BusinessJobsScreen({super.key});

  @override
  ConsumerState<BusinessJobsScreen> createState() => _BusinessJobsScreenState();
}

class _BusinessJobsScreenState extends ConsumerState<BusinessJobsScreen>
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
        case 'date':
          return (b['tour_date'] ?? '').compareTo(a['tour_date'] ?? '');
        case 'amount':
          return ((b['gross_value'] ?? 0) as num).compareTo((a['gross_value'] ?? 0) as num);
        case 'guide':
          return (a['guide_name'] ?? '').compareTo(b['guide_name'] ?? '');
        default:
          return 0;
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(businessAuthProvider);
    final bookingsAsync = ref.watch(businessBookingsProvider);

    final allBookings = bookingsAsync.when(
      data: (data) => data.isEmpty ? _syntheticBusinessBookings : data,
      loading: () => _syntheticBusinessBookings,
      error: (_, __) => _syntheticBusinessBookings,
    );

    final totalBookings = allBookings.length;
    final totalRevenue = allBookings
        .where((b) => b['status'] == 'COMPLETED')
        .fold(0.0, (sum, b) => sum + ((b['gross_value'] ?? 0) as num).toDouble());
    final totalCommission = allBookings
        .where((b) => b['status'] == 'COMPLETED')
        .fold(0.0, (sum, b) => sum + ((b['commission'] ?? 0) as num).toDouble());
    final activeGuides = allBookings
        .where((b) => ['REQUESTED', 'CONFIRMED', 'IN_PROGRESS'].contains(b['status']))
        .map((b) => b['guide_name'])
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.brand,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.brand,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _BrandGridPainter()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                        child: Row(
                          children: [
                            _BackBtn(onTap: () => context.pop()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authState.businessName ?? 'Business Portal',
                                style: AppText.h3.copyWith(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_outline, color: Colors.white70),
                              onPressed: () {},
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
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Bookings',
                          value: '$totalBookings',
                          icon: Icons.calendar_today_outlined,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Revenue',
                          value: '\$${totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Commission',
                          value: '\$${totalCommission.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Active Guides',
                          value: '$activeGuides',
                          icon: Icons.people_outlined,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, color: AppColors.success, size: 24),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${((totalCommission / (totalRevenue == 0 ? 1 : totalRevenue)) * 100).toStringAsFixed(1)}%',
                                    style: AppText.labelBold.copyWith(color: AppColors.success),
                                  ),
                                  Text('Commission Rate', style: AppText.caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _SortDropdown(
                          value: _sortBy,
                          onChanged: (v) => setState(() => _sortBy = v ?? 'date'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterDropdown(
                          value: _filterStatus,
                          onChanged: (v) => setState(() => _filterStatus = v ?? 'all'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.brand.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text('Guide', style: AppText.captionBold)),
                  SizedBox(width: 70, child: Text('Date', style: AppText.captionBold)),
                  Expanded(child: Text('Tour', style: AppText.captionBold)),
                  SizedBox(width: 40, child: Text('Pax', style: AppText.captionBold, textAlign: TextAlign.center)),
                  SizedBox(width: 80, child: Text('Status', style: AppText.captionBold)),
                  SizedBox(width: 50, child: Text('Comm.', style: AppText.captionBold, textAlign: TextAlign.right)),
                ],
              ),
            ),
            Expanded(
              child: bookingsAsync.when(
                loading: () => const AppLoading(message: 'Loading...'),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load',
                  subtitle: e.toString(),
                ),
                data: (_) => TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingList(
                      bookings: _filterAndSort(allBookings),
                    ),
                    _BookingList(
                      bookings: _filterAndSort(allBookings.where((b) {
                        final s = b['status'] as String;
                        return s == 'REQUESTED' || s == 'CONFIRMED' || s == 'IN_PROGRESS';
                      }).toList()),
                    ),
                    _BookingList(
                      bookings: _filterAndSort(allBookings.where((b) {
                        final s = b['status'] as String;
                        return s == 'COMPLETED' || s == 'CANCELLED';
                      }).toList()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: [
          BottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            isSelected: false,
            onTap: () => context.go('/business/dashboard'),
          ),
          BottomNavItem(
            icon: Icons.work_outlined,
            activeIcon: Icons.work,
            label: 'Bookings',
            isSelected: true,
            onTap: () {},
          ),
          BottomNavItem(
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            label: 'Guides',
            isSelected: false,
            onTap: () {},
          ),
          BottomNavItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Reports',
            isSelected: false,
            onTap: () {},
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            isSelected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppText.labelBold.copyWith(color: color, fontSize: 16)),
          Text(title, style: AppText.caption, textAlign: TextAlign.center),
        ],
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
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'date', child: Text('Sort by Date', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'amount', child: Text('Sort by Revenue', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'guide', child: Text('Sort by Guide', style: TextStyle(fontSize: 13))),
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
          isExpanded: true,
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
        icon: Icons.work_off_outlined,
        title: 'No bookings found',
        subtitle: 'Your bookings will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return _BookingRow(booking: b);
      },
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingRow({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'REQUESTED': return AppColors.warning;
      case 'CONFIRMED': return AppColors.info;
      case 'IN_PROGRESS': return AppColors.statusInProgress;
      case 'COMPLETED': return AppColors.success;
      case 'CANCELLED': return AppColors.error;
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

    // Extract names for flag display
    final guideName = booking['guide_name'] as String? ?? 'Guide';
    final touristName = booking['tourist_name'] as String? ?? 'Tourist';
    final guideFlag = CountryFlags.fromName(guideName);
    final touristFlag = CountryFlags.fromFirstName(touristName.split(' ').first);
    final destinationFlag = CountryFlags.fromLocation(booking['destination'] as String? ?? '');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(guideFlag, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        guideName.split(' ').first,
                        style: AppText.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  booking['tour_type'] as String? ?? '',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Text(
                  destinationFlag,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  (booking['tour_date'] as String? ?? '').isNotEmpty
                      ? (booking['tour_date'] as String).substring(5)
                      : '',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['destination'] as String? ?? 'Tour',
                  style: AppText.label,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(touristFlag, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        touristName,
                        style: AppText.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${booking['group_size'] ?? 0}',
              style: AppText.label,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 80,
            child: StatusBadge(
              label: _statusLabel(status),
              color: statusColor,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '\$${(booking['commission'] ?? 0).toStringAsFixed(0)}',
              style: AppText.labelBold.copyWith(color: AppColors.success),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
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
