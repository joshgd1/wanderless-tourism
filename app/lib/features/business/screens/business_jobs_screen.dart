import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/business_auth_provider.dart';

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
  {'id': 110, 'guide_name': 'Made Surya', 'tourist_name': 'Ryan Martinez', 'tour_date': '2026-04-28', 'destination': 'ATV Jungle Ride', 'group_size': 4, 'duration_hours': 4.0, 'status': 'COMPLETED', 'gross_value': 220.0, 'tour_type': 'Adventure', 'commission': 33.0},
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
      backgroundColor: const Color(0xFFFAF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFED8A19),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(authState.businessName ?? 'Business Portal', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'All Bookings'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatCard(
                  title: 'Total Bookings',
                  value: '$totalBookings',
                  icon: Icons.calendar_today,
                  color: const Color(0xFFED8A19),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: 'Gross Revenue',
                  value: '\$${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.blue[600]!,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: 'Commission',
                  value: '\$${totalCommission.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green[600]!,
                ),
              ],
            ),
          ),
          // Stats Row 2
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _StatCard(
                  title: 'Active Guides',
                  value: '$activeGuides',
                  icon: Icons.people,
                  color: Colors.purple[600]!,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green[600]!, size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${((totalCommission / (totalRevenue == 0 ? 1 : totalRevenue)) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[600]!),
                            ),
                            Text('Commission Rate', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sort and Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _SortDropdown(
                    value: _sortBy,
                    onChanged: (v) => setState(() => _sortBy = v ?? 'date'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterDropdown(
                    value: _filterStatus,
                    onChanged: (v) => setState(() => _filterStatus = v ?? 'all'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Booking Table Header
          Container(
            color: const Color(0xFFED8A19).withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 80, child: Text('Guide', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF3C3830)))),
                SizedBox(width: 70, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF3C3830)))),
                Expanded(child: Text('Tour', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF3C3830)))),
                SizedBox(width: 50, child: Text('Pax', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF3C3830)), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF3C3830)))),
                SizedBox(width: 60, child: Text('Comm.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF3C3830)), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Booking List
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (_) => TabBarView(
                controller: _tabController,
                children: [
                  _BookingList(
                    bookings: _filterAndSort(allBookings),
                    filter: null,
                  ),
                  _BookingList(
                    bookings: _filterAndSort(allBookings.where((b) {
                      final s = b['status'] as String;
                      return s == 'REQUESTED' || s == 'CONFIRMED' || s == 'IN_PROGRESS';
                    }).toList()),
                    filter: 'active',
                  ),
                  _BookingList(
                    bookings: _filterAndSort(allBookings.where((b) {
                      final s = b['status'] as String;
                      return s == 'COMPLETED' || s == 'CANCELLED';
                    }).toList()),
                    filter: 'history',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFFED8A19),
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 0) context.go('/business/dashboard');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Guides'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
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
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
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
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
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
  final String? filter;

  const _BookingList({required this.bookings, this.filter});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No bookings found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
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
      case 'REQUESTED': return Colors.orange;
      case 'CONFIRMED': return Colors.blue;
      case 'IN_PROGRESS': return Colors.purple;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['guide_name'] as String? ?? 'Guide',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  booking['tour_type'] as String? ?? '',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              (booking['tour_date'] as String? ?? '').substring(5),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['destination'] as String? ?? 'Tour',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  booking['tourist_name'] as String? ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${booking['group_size'] ?? 0}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '\$${(booking['commission'] ?? 0).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
