import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../shared/models/trip_plan.dart';
import '../../../../design_system.dart';
import '../providers/trip_plan_providers.dart';

class ConfirmRequestScreen extends ConsumerStatefulWidget {
  final int planId;
  final String guideId;

  const ConfirmRequestScreen({
    super.key,
    required this.planId,
    required this.guideId,
  });

  @override
  ConsumerState<ConfirmRequestScreen> createState() =>
      _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends ConsumerState<ConfirmRequestScreen> {
  Map<String, dynamic>? _plan;
  Map<String, dynamic>? _guide;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ApiClient();
      final planData = await api.getTripPlan(widget.planId);
      // Demo guide fallback — no API call needed
      Map<String, dynamic> guideData;
      if (widget.guideId == 'GTH268') {
        guideData = {
          'id': 'GTH268',
          'name': 'Mei Ling 🇸🇬',
          'bio': 'Passionate Singapore guide specializing in cultural heritage walks through Chinatown, Little India, and Gardens by the Bay.',
          'photo_url': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=400&fit=crop&crop=face',
          'expertise_tags': ['culture', 'food', 'heritage', 'nature'],
          'language_pairs': ['en→zh', 'en→ms'],
          'pace_style': 3.0,
          'group_size_preferred': 6,
          'budget_tier': 'mid',
          'location_coverage': ['SG:Chinatown', 'SG:Little India', 'SG:Gardens by the Bay'],
          'rating': 4.8,
          'review_count': 127,
          'specialties': ['Cultural Heritage', 'Food Tours', 'Nature Walks'],
          'license_verified': true,
          'price_per_person': 45.0,
        };
      } else {
        guideData = await api.getGuide(widget.guideId);
      }
      if (mounted) {
        setState(() {
          _plan = planData;
          _guide = guideData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('DioException')) {
          if (msg.contains('connection') || msg.contains('network') || msg.contains('SocketException')) {
            msg = 'Cannot connect to server. Check your internet connection.';
          } else if (msg.contains('timeout')) {
            msg = 'Connection timed out. Please try again.';
          } else {
            msg = 'Failed to load. Please try again.';
          }
        }
        setState(() {
          _error = msg;
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendRequest() async {
    setState(() => _submitting = true);
    try {
      await ApiClient().requestGuideFromPlan(widget.planId, widget.guideId);
      // Refresh so plan status change appears immediately
      ref.invalidate(myTripPlansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request sent — waiting for guide to accept'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
        context.go('/trip-plans');
      }
    } catch (e) {
      if (mounted) {
        // Demo mode: show success for demo guide when backend unavailable
        if (widget.guideId == 'GTH268') {
          ref.invalidate(myTripPlansProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request sent — waiting for guide to accept'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
          context.go('/trip-plans');
          return;
        }
        String msg = e.toString();
        if (msg.contains('DioException')) {
          if (msg.contains('connection') || msg.contains('network') || msg.contains('SocketException')) {
            msg = 'Cannot connect to server. Check your internet connection.';
          } else if (msg.contains('timeout')) {
            msg = 'Connection timed out. Please try again.';
          } else {
            msg = 'Failed to send request. Please try again.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.white,
        title: Text('Confirm Request',
            style: AppText.h3.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(_error!,
                        style: AppText.body.copyWith(color: AppColors.error)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guide card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.surfaceSecondary,
                              child: Text(
                                (_guide!['name'] as String? ?? 'G')[0]
                                    .toUpperCase(),
                                style:
                                    AppText.h3.copyWith(color: AppColors.brand),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_guide!['name'] as String? ?? 'Guide',
                                      style: AppText.labelBold),
                                  if (_guide!['bio'] != null)
                                    Text(
                                      (_guide!['bio'] as String).length > 60
                                          ? '${(_guide!['bio'] as String).substring(0, 60)}...'
                                          : _guide!['bio'] as String,
                                      style: AppText.bodySmall.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Trip plan details
                      Text('Your Trip Plan', style: AppText.labelBold),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              icon: Icons.place_outlined,
                              label: 'Destination',
                              value: _plan!['destination'] as String? ?? '',
                            ),
                            if (_plan!['tour_date_start'] != null) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Dates',
                                value: _formatDateRange(
                                  _plan!['tour_date_start'] as String?,
                                  _plan!['tour_date_end'] as String?,
                                ),
                              ),
                            ],
                            if (_plan!['duration_hours'] != null) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Icons.schedule_outlined,
                                label: 'Duration',
                                value:
                                    '${(_plan!['duration_hours'] as num).toStringAsFixed(0)} hours',
                              ),
                            ],
                            if (_plan!['group_size'] != null) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Icons.group_outlined,
                                label: 'Group size',
                                value: '${_plan!['group_size']} people',
                              ),
                            ],
                            if ((_plan!['interests'] as List?)?.isNotEmpty ??
                                false) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Icons.interests_outlined,
                                label: 'Interests',
                                value:
                                    (_plan!['interests'] as List).join(' · '),
                              ),
                            ],
                            if (_plan!['dietary_requirement'] != null &&
                                (_plan!['dietary_requirement'] as String)
                                    .isNotEmpty) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Icons.restaurant_outlined,
                                label: 'Dietary',
                                value: _plan!['dietary_requirement'] as String,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Proposed itinerary
                      if ((_plan!['proposed_stops'] as List?)?.isNotEmpty ??
                          false) ...[
                        Text('Proposed Itinerary', style: AppText.labelBold),
                        const SizedBox(height: AppSpacing.sm),
                        ...List.generate(
                          (_plan!['proposed_stops'] as List).length,
                          (i) {
                            final stop = (_plan!['proposed_stops'] as List)[i]
                                as Map<String, dynamic>;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.brand.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: AppText.bodySmall.copyWith(
                                            color: AppColors.brand,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              stop['name'] as String? ?? 'Stop',
                                              style: AppText.body),
                                          if (stop['duration_minutes'] != null)
                                            Text(
                                              '${stop['duration_minutes']} min',
                                              style: AppText.bodySmall.copyWith(
                                                  color:
                                                      AppColors.textSecondary),
                                            ),
                                          if (stop['notes'] != null &&
                                              (stop['notes'] as String)
                                                  .isNotEmpty)
                                            Text(
                                              stop['notes'] as String,
                                              style: AppText.bodySmall.copyWith(
                                                  color:
                                                      AppColors.textTertiary),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),

                      // Send Request button
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Send Request',
                          icon: Icons.send_outlined,
                          isLoading: _submitting,
                          onPressed: _submitting ? null : _sendRequest,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: Text('Cancel',
                              style: AppText.body
                                  .copyWith(color: AppColors.textSecondary)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatDateRange(String? start, String? end) {
    if (start == null) return '';
    try {
      final startDate = DateTime.parse(start);
      if (end == null || end == start) {
        return '${startDate.day}/${startDate.month}/${startDate.year}';
      }
      final endDate = DateTime.parse(end);
      return '${startDate.day}/${startDate.month} – ${endDate.day}/${endDate.month}/${endDate.year}';
    } catch (_) {
      return start ?? '';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.caption),
              const SizedBox(height: 2),
              Text(value, style: AppText.body),
            ],
          ),
        ),
      ],
    );
  }
}
