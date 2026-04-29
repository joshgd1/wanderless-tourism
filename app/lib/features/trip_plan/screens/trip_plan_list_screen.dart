import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../shared/models/trip_plan.dart';

final myTripPlansProvider = FutureProvider<List<TripPlan>>((ref) async {
  final touristId = await ref.watch(touristIdProvider.future);
  if (touristId == null) return [];
  final api = ApiClient();
  final data = await api.getTripPlans(touristId: touristId);
  return data.map((e) => TripPlan.fromJson(e as Map<String, dynamic>)).toList();
});

final openTripPlansProvider = FutureProvider<List<TripPlan>>((ref) async {
  final api = ApiClient();
  final data = await api.getTripPlans(status: 'OPEN');
  return data.map((e) => TripPlan.fromJson(e as Map<String, dynamic>)).toList();
});

class TripPlanListScreen extends ConsumerWidget {
  final bool isGuideView;

  const TripPlanListScreen({super.key, this.isGuideView = false});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFF25D366);
      case 'ACCEPTED':
        return Colors.amber[700]!;
      case 'COMPLETED':
        return Colors.blue[600]!;
      case 'CANCELLED':
        return Colors.grey[600]!;
      default:
        return Colors.grey[500]!;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = isGuideView
        ? ref.watch(openTripPlansProvider)
        : ref.watch(myTripPlansProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: const Color(0xFF1A2E1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2E1A), Color(0xFF2D4A2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Text(
                          isGuideView ? 'Open Trip Requests' : 'My Trip Plans',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (!isGuideView)
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            onPressed: () => context.push('/trip-plan/create'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          asyncPlans.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_off_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          isGuideView ? 'No open trip requests' : 'No trip plans yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isGuideView
                              ? 'Check back later for new requests'
                              : 'Propose your own trip and let guides compete for it!',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        if (!isGuideView) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/trip-plan/create'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Trip Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plan = plans[index];
                      return _TripPlanCard(
                        plan: plan,
                        isGuideView: isGuideView,
                        statusColor: _statusColor(plan.status),
                      );
                    },
                    childCount: plans.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TripPlanCard extends ConsumerWidget {
  final TripPlan plan;
  final bool isGuideView;
  final Color statusColor;

  const _TripPlanCard({
    required this.plan,
    required this.isGuideView,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPlanDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                  const Spacer(),
                  if (plan.tourDate != null)
                    Text(plan.tourDate!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tour, color: Color(0xFF25D366)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.destination,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.durationHours?.toStringAsFixed(1) ?? '?'}h  •  Group ${plan.groupSize ?? '?'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                ],
              ),
              if (plan.interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: plan.interests.take(4).map((i) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        i[0].toUpperCase() + i.substring(1),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF25D366), fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (plan.proposedStops.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${plan.proposedStops.length} proposed stop${plan.proposedStops.length > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.destination,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(plan.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.calendar_today, 'Date', plan.tourDate ?? 'Not specified'),
              _detailRow(Icons.schedule, 'Duration', plan.durationHours != null ? '${plan.durationHours!.toStringAsFixed(1)} hours' : 'Not specified'),
              _detailRow(Icons.group, 'Group size', plan.groupSize != null ? '${plan.groupSize} people' : 'Not specified'),
              if (plan.interests.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Interests', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: plan.interests.map((i) {
                    return Chip(
                      label: Text(i[0].toUpperCase() + i.substring(1)),
                      backgroundColor: const Color(0xFF25D366).withOpacity(0.1),
                      labelStyle: const TextStyle(color: Color(0xFF25D366), fontSize: 12),
                    );
                  }).toList(),
                ),
              ],
              if (plan.proposedStops.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Proposed Itinerary', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...plan.proposedStops.asMap().entries.map((entry) {
                  final stop = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (stop.notes != null)
                                Text(stop.notes!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        Text('${stop.durationHours.toStringAsFixed(1)}h', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              if (isGuideView && plan.status == 'OPEN')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _acceptPlan(context, ref, ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Accept This Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              if (!isGuideView && plan.status == 'OPEN')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelPlan(context, ref, ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel Plan'),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _acceptPlan(BuildContext context, WidgetRef ref, BuildContext sheetCtx) async {
    // Demo: show guide picker to simulate guide selection
    // In production, guide_id comes from authenticated guide session
    final selectedGuideId = await _showGuidePickerDialog(context);
    if (selectedGuideId == null) return; // Cancelled

    try {
      final api = ApiClient();
      await api.acceptTripPlan(plan.id, selectedGuideId);
      ref.invalidate(openTripPlansProvider);
      if (context.mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip accepted by guide $selectedGuideId! The tourist will be notified.'),
            backgroundColor: const Color(0xFF25D366),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<String?> _showGuidePickerDialog(BuildContext context) async {
    // Fetch available guides for demo
    List<Map<String, dynamic>> guides = [];
    try {
      final api = ApiClient();
      guides = await api.getGuides();
    } catch (_) {
      guides = [];
    }

    if (!context.mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Guide (Demo)'),
        content: guides.isEmpty
            ? const Text('No guides available. Using default guide ID.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: guides.length,
                  itemBuilder: (_, i) {
                    final g = guides[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF25D366).withOpacity(0.2),
                        child: const Icon(Icons.person, color: Color(0xFF25D366), size: 20),
                      ),
                      title: Text(g['name'] ?? 'Guide ${g['id']}'),
                      subtitle: Text('ID: ${g['id']}'),
                      onTap: () => Navigator.pop(ctx, g['id'].toString()),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (guides.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'G001'),
              child: const Text('Use G001 (Default)'),
            ),
        ],
      ),
    );
  }

  Future<void> _cancelPlan(BuildContext context, WidgetRef ref, BuildContext sheetCtx) async {
    try {
      final api = ApiClient();
      await api.updateTripPlan(plan.id, {'status': 'CANCELLED'});
      ref.invalidate(myTripPlansProvider);
      if (context.mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip plan cancelled.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
