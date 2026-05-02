import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../shared/models/trip_plan.dart';
import '../../../../design_system.dart';
import '../../bookings/screens/bookings_screen.dart';

final myTripPlansProvider = FutureProvider<List<TripPlan>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
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
        return AppColors.success;
      case 'ACCEPTED':
        return AppColors.warning;
      case 'COMPLETED':
        return AppColors.info;
      case 'CANCELLED':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = isGuideView
        ? ref.watch(openTripPlansProvider)
        : ref.watch(myTripPlansProvider);

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
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: GridPainter()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                        child: Row(
                          children: [
                            _BackBtn(onTap: () => context.pop()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isGuideView ? 'Open Trip Requests' : 'My Trip Plans',
                                style: AppText.h3.copyWith(color: Colors.white),
                              ),
                            ),
                            if (!isGuideView)
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                                onPressed: () => context.push('/trip-plan/create'),
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
          asyncPlans.when(
            loading: () => const SliverFillRemaining(
              child: AppLoading(message: 'Loading...'),
            ),
            error: (e, _) => SliverFillRemaining(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                subtitle: e.toString(),
              ),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.explore_off_outlined,
                    title: isGuideView ? 'No open trip requests' : 'No trip plans yet',
                    subtitle: isGuideView
                        ? 'Check back later for new requests'
                        : 'Propose your own trip and let guides compete for it!',
                    action: !isGuideView
                        ? PrimaryButton(
                            label: 'Create Trip Plan',
                            icon: Icons.add,
                            onPressed: () => context.push('/trip-plan/create'),
                          )
                        : null,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plan = plans[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _TripPlanCard(
                          plan: plan,
                          isGuideView: isGuideView,
                          statusColor: _statusColor(plan.status),
                          onTap: () => _showPlanDetail(context, ref, plan),
                        ),
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

  void _showPlanDetail(BuildContext context, WidgetRef ref, TripPlan plan) {
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
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: _PlanDetailSheet(
            plan: plan,
            isGuideView: isGuideView,
            statusColor: _statusColor(plan.status),
            scrollController: scrollController,
            onAccept: isGuideView ? () => _acceptPlan(context, ref, ctx, plan) : null,
            onCancel: !isGuideView && plan.status == 'OPEN'
                ? () => _cancelPlan(context, ref, ctx, plan)
                : null,
            onConfirmPay: !isGuideView && plan.status == 'ACCEPTED'
                ? () => _confirmAndPay(context, ref, ctx, plan)
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptPlan(BuildContext context, WidgetRef ref, BuildContext sheetCtx, TripPlan plan) async {
    final authState = ref.read(authProvider);
    if (authState.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in as a guide to accept plans'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }

    try {
      final api = ApiClient();
      await api.acceptTripPlan(plan.id);
      ref.invalidate(openTripPlansProvider);
      if (context.mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip plan accepted! The tourist will be notified.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    }
  }

  Future<void> _cancelPlan(BuildContext context, WidgetRef ref, BuildContext sheetCtx, TripPlan plan) async {
    try {
      final api = ApiClient();
      await api.updateTripPlan(plan.id, {'status': 'CANCELLED'});
      ref.invalidate(myTripPlansProvider);
      if (context.mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip plan cancelled. Any payment has been refunded.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndPay(BuildContext context, WidgetRef ref, BuildContext sheetCtx, TripPlan plan) async {
    if (plan.guideId == null) return;
    try {
      final authState = ref.read(authProvider);
      final touristId = authState.touristId;
      if (touristId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please sign in to confirm booking'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
        }
        return;
      }
      final api = ApiClient();
      final result = await api.createBooking({
        'tourist_id': touristId,
        'guide_id': plan.guideId,
        'tour_date': plan.tourDate ?? DateTime.now().toString().split(' ')[0],
        'duration_hours': plan.durationHours ?? 4.0,
        'group_size': plan.groupSize ?? 1,
        'destination': plan.destination,
      });
      ref.invalidate(myTripPlansProvider);
      ref.invalidate(bookingsListProvider);
      if (context.mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed! ID: ${result['id']}. Your guide will contact you soon.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    }
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
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _TripPlanCard extends StatelessWidget {
  final TripPlan plan;
  final bool isGuideView;
  final Color statusColor;
  final VoidCallback onTap;

  const _TripPlanCard({
    required this.plan,
    required this.isGuideView,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: plan.status,
                color: statusColor,
              ),
              const Spacer(),
              if (plan.tourDate != null)
                Text(plan.tourDate!, style: AppText.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tour, color: AppColors.brand, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.destination, style: AppText.labelBold),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.durationHours?.toStringAsFixed(1) ?? '?'}h  •  Group ${plan.groupSize ?? '?'}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
            ],
          ),
          if (plan.interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: plan.interests.take(4).map((i) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    i[0].toUpperCase() + i.substring(1),
                    style: AppText.caption.copyWith(color: AppColors.brand),
                  ),
                );
              }).toList(),
            ),
          ],
          if (plan.proposedStops.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${plan.proposedStops.length} proposed stop${plan.proposedStops.length > 1 ? 's' : ''}',
              style: AppText.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanDetailSheet extends StatelessWidget {
  final TripPlan plan;
  final bool isGuideView;
  final Color statusColor;
  final ScrollController scrollController;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirmPay;

  const _PlanDetailSheet({
    required this.plan,
    required this.isGuideView,
    required this.statusColor,
    required this.scrollController,
    this.onAccept,
    this.onCancel,
    this.onConfirmPay,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        Row(
          children: [
            Expanded(
              child: Text(plan.destination, style: AppText.h1),
            ),
            StatusBadge(
              label: plan.status,
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!isGuideView && plan.status == 'OPEN')
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waiting for a guide to accept',
                        style: AppText.labelBold.copyWith(color: AppColors.success),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You\'ll be notified when a guide picks up your request. No payment required yet.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!isGuideView && plan.status == 'ACCEPTED' && plan.guideId != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guide Assigned!', style: AppText.labelBold),
                      Text('ID: ${plan.guideId}', style: AppText.caption),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.success, size: 22),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Confirm and pay to finalize your booking.',
                    style: AppText.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(Icons.calendar_today_outlined, 'Date', plan.tourDate ?? 'Not specified'),
        _DetailRow(Icons.schedule_outlined, 'Duration', plan.durationHours != null ? '${plan.durationHours!.toStringAsFixed(1)} hours' : 'Not specified'),
        _DetailRow(Icons.group_outlined, 'Group size', plan.groupSize != null ? '${plan.groupSize} people' : 'Not specified'),
        if (plan.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Interests', style: AppText.labelBold),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.interests.map((i) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  i[0].toUpperCase() + i.substring(1),
                  style: AppText.caption.copyWith(color: AppColors.brand),
                ),
              );
            }).toList(),
          ),
        ],
        if (plan.proposedStops.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Proposed Itinerary', style: AppText.labelBold),
          const SizedBox(height: AppSpacing.md),
          ...plan.proposedStops.asMap().entries.map((entry) {
            final stop = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
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
                        Text(stop.name, style: AppText.labelBold),
                        if (stop.notes != null)
                          Text(stop.notes!, style: AppText.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('${stop.durationHours.toStringAsFixed(1)}h', style: AppText.caption),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (isGuideView && plan.status == 'OPEN' && onAccept != null)
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Accept This Trip',
              icon: Icons.check,
              onPressed: onAccept,
            ),
          ),
        if (!isGuideView && plan.status == 'OPEN' && onCancel != null) ...[
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Cancel Plan',
              icon: Icons.close,
              color: AppColors.error,
              onPressed: onCancel,
            ),
          ),
        ],
        if (!isGuideView && plan.status == 'ACCEPTED' && onConfirmPay != null) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Confirm & Pay Now',
              icon: Icons.payment,
              onPressed: onConfirmPay,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text('$label:', style: AppText.caption),
          const SizedBox(width: 6),
          Text(value, style: AppText.label),
        ],
      ),
    );
  }
}

