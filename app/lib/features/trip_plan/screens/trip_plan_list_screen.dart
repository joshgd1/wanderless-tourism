import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../shared/models/trip_plan.dart';
import '../../../../shared/models/guide.dart';
import '../../../../shared/models/safety_result.dart';
import '../../../../shared/widgets/safety_score_card.dart';
import '../../../../design_system.dart';
import '../../bookings/screens/bookings_screen.dart';

// Provider to fetch top matched guides for a destination
final _matchedGuidesForPlanProvider = FutureProvider.family<List<MatchedGuide>, String>((ref, destination) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return [];
  final api = ApiClient();
  final data = await api.getMlGuideRecommendations(touristId, topN: 3, destination: destination);
  final guides = data.map((e) => MatchedGuide.fromJson(e as Map<String, dynamic>)).toList();
  // Always show Mei Ling first as the demo guide
  final meiLing = MatchedGuide(
    guideId: 'GTH268',
    name: 'Mei Ling',
    photoUrl: 'https://picsum.photos/seed/mei_ling_guide/400/400',
    bio: 'Passionate Singapore guide specializing in cultural heritage walks through Chinatown, Little India, and Gardens by the Bay.',
    expertiseTags: ['culture', 'food', 'heritage', 'nature'],
    languagePairs: ['en→zh', 'en→ms'],
    locationCoverage: ['SG:Chinatown', 'SG:Little India', 'SG:Gardens by the Bay'],
    ratingHistory: 4.8,
    ratingCount: 127,
    budgetTier: 'mid',
    licenseVerified: true,
    score: 0.99,
    langMatch: true,
  );
  return [meiLing, ...guides];
});

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

final _safetyScoreProvider = FutureProvider.family<SafetyResult?, int>((ref, planId) async {
  try {
    final api = ApiClient();
    final data = await api.getSafetyScore(planId: planId);
    if (data['total_score'] != null) {
      return SafetyResult.fromJson(data);
    }
  } catch (_) {}
  return null;
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
      await api.acceptTripPlan(widget.plan.id);
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
      await api.updateTripPlan(widget.plan.id, {'status': 'CANCELLED'});
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
      if (sheetCtx.mounted) {
        // Show fake payment success dialog first
        await showDialog(
          context: sheetCtx,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Payment Successful!', style: AppText.h3.copyWith(color: AppColors.success)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your booking has been confirmed.',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Booking ID: ${result['id']}',
                    style: AppText.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Done',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
        // Close the bottom sheet after dialog completes
        Navigator.pop(sheetCtx);
        // Show confirmation snackbar on the main scaffold
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking confirmed! Your guide will contact you soon.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
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

class _TripPlanCard extends ConsumerStatefulWidget {
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
  ConsumerState<_TripPlanCard> createState() => _TripPlanCardState();
}

class _TripPlanCardState extends ConsumerState<_TripPlanCard> {
  SafetyResult? _safetyResult;
  bool _safetyLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSafetyScore();
  }

  Future<void> _fetchSafetyScore() async {
    if (widget.widget.plan.id == null) return;
    setState(() => _safetyLoading = true);
    try {
      final api = ApiClient();
      final data = await api.getSafetyScore(planId: widget.widget.plan.id!);
      if (mounted && data['total_score'] != null) {
        setState(() {
          _safetyResult = SafetyResult.fromJson(data);
          _safetyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _safetyLoading = false);
    }
  }

  Color _scoreColor() {
    switch (_safetyResult?.color) {
      case 'green': return AppColors.success;
      case 'amber': return AppColors.warning;
      case 'red': return AppColors.error;
      default: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: widget.plan.status,
                color: widget.statusColor,
              ),
              const Spacer(),
              if (_safetyResult != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _scoreColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: _scoreColor().withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _safetyResult!.level == 'safe'
                            ? Icons.check_circle
                            : _safetyResult!.level == 'caution'
                                ? Icons.warning_amber
                                : Icons.error,
                        size: 12,
                        color: _scoreColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_safetyResult!.totalScore.round()}',
                        style: AppText.labelBold.copyWith(color: _scoreColor(), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.plan.tourDate != null)
                Text(widget.plan.tourDate!, style: AppText.caption),
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
                    Text(widget.plan.destination, style: AppText.labelBold),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.plan.durationHours?.toStringAsFixed(1) ?? '?'}h  •  Group ${widget.plan.groupSize ?? '?'}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
            ],
          ),
          if (widget.plan.interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.plan.interests.take(4).map((i) {
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
          if (widget.plan.proposedStops.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${widget.plan.proposedStops.length} proposed stop${widget.plan.proposedStops.length > 1 ? 's' : ''}',
              style: AppText.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanDetailSheet extends ConsumerStatefulWidget {
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
  ConsumerState<_PlanDetailSheet> createState() => _PlanDetailSheetState();
}

class _PlanDetailSheetState extends ConsumerState<_PlanDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final guidesAsync = widget.isGuideView || widget.plan.status != 'OPEN'
        ? null
        : ref.watch(_matchedGuidesForPlanProvider(widget.plan.destination));

    final safetyAsync = widget.plan.id != null
        ? ref.watch(_safetyScoreProvider(widget.plan.id!))
        : null;

    return Column(
      children: [
        // Sticky header + scrollable content
        Expanded(
          child: ListView(
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
                    child: Text(widget.plan.destination, style: AppText.h1),
                  ),
                  StatusBadge(
                    label: widget.plan.status,
                    color: widget.statusColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (safetyAsync != null) ...[
                safetyAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (safety) {
                    if (safety == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SafetyScoreCard(safetyResult: safety),
                    );
                  },
                ),
              ],
              if (!widget.isGuideView && widget.plan.status == 'OPEN')
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
          if (!widget.isGuideView && widget.plan.status == 'ACCEPTED' && widget.plan.guideId != null) ...[
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
                      Text('ID: ${widget.plan.guideId}', style: AppText.caption),
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
        // Top 3 matched guides for OPEN plans (tourist view)
        if (!widget.isGuideView && widget.plan.status == 'OPEN' && guidesAsync != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('AI-Powered Guide Matches', style: AppText.labelBold),
          const SizedBox(height: 2),
          Text(
            'Based on your trip preferences and destination',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          guidesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppLoading(message: 'Finding best guides...'),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Text('Could not load matches', style: AppText.caption),
                ],
              ),
            ),
            data: (guides) {
              if (guides.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text('No matches found for your destination', style: AppText.caption),
                );
              }
              return Column(
                children: guides.take(3).map((guide) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MatchedGuideCard(
                    guide: guide,
                    onTap: () => context.push('/confirm-request?planId=${widget.plan.id}&guideId=${guide.guideId}'),
                  ),
                )).toList(),
              );
            },
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(Icons.calendar_today_outlined, 'Date', widget.plan.tourDate ?? 'Not specified'),
        _DetailRow(Icons.schedule_outlined, 'Duration', widget.plan.durationHours != null ? '${widget.plan.durationHours!.toStringAsFixed(1)} hours' : 'Not specified'),
        _DetailRow(Icons.group_outlined, 'Group size', widget.plan.groupSize != null ? '${widget.plan.groupSize} people' : 'Not specified'),
        if (widget.plan.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Interests', style: AppText.labelBold),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.plan.interests.map((i) {
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
        if (widget.plan.proposedStops.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Proposed Itinerary', style: AppText.labelBold),
          const SizedBox(height: AppSpacing.md),
          ...widget.plan.proposedStops.asMap().entries.map((entry) {
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
      ],
        ),
        // ── Sticky Bottom CTAs ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isGuideView && widget.plan.status == 'OPEN' && widget.onAccept != null)
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Accept This Trip',
                      icon: Icons.check,
                      onPressed: widget.onAccept,
                    ),
                  ),
                if (!widget.isGuideView && widget.plan.status == 'OPEN' && widget.onCancel != null)
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      label: 'Cancel Plan',
                      icon: Icons.close,
                      color: AppColors.error,
                      onPressed: widget.onCancel,
                    ),
                  ),
                if (!widget.isGuideView && widget.plan.status == 'ACCEPTED' && widget.onConfirmPay != null)
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Confirm & Pay Now',
                      icon: Icons.payment,
                      onPressed: widget.onConfirmPay,
                    ),
                  ),
              ],
            ),
          ),
        ),
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

class _MatchedGuideCard extends StatelessWidget {
  final MatchedGuide guide;
  final VoidCallback onTap;

  const _MatchedGuideCard({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = (guide.score * 100).round();
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: guide.photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                      imageUrl: guide.photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textTertiary, size: 22),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.textTertiary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(guide.name, style: AppText.labelBold),
                    if (guide.licenseVerified) ...[
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
                      '${guide.ratingHistory.toStringAsFixed(1)} (${guide.ratingCount})',
                      style: AppText.caption,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      guide.budgetTier.toUpperCase(),
                      style: AppText.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$score% match',
              style: AppText.captionBold.copyWith(color: AppColors.brand),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

