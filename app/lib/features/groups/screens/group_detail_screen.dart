import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../shared/models/travel_group.dart';
import '../../../../design_system.dart';

final groupDetailProvider = FutureProvider.family<TravelGroup, int>((ref, groupId) async {
  final api = ApiClient();
  final data = await api.getGroup(groupId);
  return TravelGroup.fromJson(data as Map<String, dynamic>);
});

class GroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  bool _isJoining = false;
  bool _hasJoined = false;
  bool _isLeaving = false;

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Date TBD';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  String _estimatedPrice(TravelGroup group) {
    const baseGuidePricePerHour = 50.0;
    final hours = group.proposedDuration ?? 4.0;
    final total = baseGuidePricePerHour * hours;
    final perPerson = total / group.memberCount.clamp(1, group.maxSize);
    return '\$${perPerson.toStringAsFixed(0)}';
  }

  Color _coherenceColor(String? coherence) {
    switch (coherence?.toLowerCase()) {
      case 'high_coherence':
        return AppColors.success;
      case 'moderate_coherence':
        return AppColors.warning;
      case 'low_coherence':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  String _coherenceLabel(String? coherence) {
    switch (coherence?.toLowerCase()) {
      case 'high_coherence':
        return 'High Match';
      case 'moderate_coherence':
        return 'Good Match';
      case 'low_coherence':
        return 'Low Match';
      default:
        return 'Unknown';
    }
  }

  Future<void> _joinGroup(TravelGroup group) async {
    final authState = ref.read(authProvider);
    if (authState.touristId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in first'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);
    try {
      final api = ApiClient();
      await api.joinGroup(group.id);
      setState(() => _hasJoined = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request sent! You\'re in the group.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      ref.invalidate(groupDetailProvider(widget.groupId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveGroup(TravelGroup group) async {
    final authState = ref.read(authProvider);
    if (authState.touristId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in first'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLeaving = true);
    try {
      final api = ApiClient();
      await api.leaveGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You have left the group.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving group: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: groupAsync.when(
        data: (group) => CustomScrollView(
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
                              Text(
                                group.destination,
                                style: AppText.h3.copyWith(color: Colors.white),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group overview card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: const Icon(Icons.group, color: AppColors.brand, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Group Trip', style: AppText.h1),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _coherenceColor(group.coherence).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppRadius.full),
                                          ),
                                          child: Text(
                                            _coherenceLabel(group.coherence),
                                            style: AppText.caption.copyWith(
                                              color: _coherenceColor(group.coherence),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceSecondary,
                                            borderRadius: BorderRadius.circular(AppRadius.full),
                                          ),
                                          child: Text(
                                            '${group.memberCount}/${group.maxSize} joined',
                                            style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: AppSpacing.md),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 360) {
                                return Column(
                                  children: [
                                    _DetailItem(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Date',
                                      value: _formatDate(group.proposedDate),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _DetailItem(
                                      icon: Icons.schedule_outlined,
                                      label: 'Duration',
                                      value: '${(group.proposedDuration ?? 4.0).toStringAsFixed(1)} hours',
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _DetailItem(
                                      icon: Icons.person_outline,
                                      label: 'Min. Group',
                                      value: '${group.minSize} people',
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _DetailItem(
                                      icon: Icons.attach_money,
                                      label: 'Est. Per Person',
                                      value: '${_estimatedPrice(group)}',
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      _DetailItem(
                                        icon: Icons.calendar_today_outlined,
                                        label: 'Date',
                                        value: _formatDate(group.proposedDate),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      _DetailItem(
                                        icon: Icons.schedule_outlined,
                                        label: 'Duration',
                                        value: '${(group.proposedDuration ?? 4.0).toStringAsFixed(1)} hours',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      _DetailItem(
                                        icon: Icons.person_outline,
                                        label: 'Min. Group',
                                        value: '${group.minSize} people',
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      _DetailItem(
                                        icon: Icons.attach_money,
                                        label: 'Est. Per Person',
                                        value: '${_estimatedPrice(group)}',
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Members card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_outline, size: 18, color: AppColors.brand),
                              const SizedBox(width: 8),
                              Text('Group Members', style: AppText.labelBold),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (group.members == null || group.members!.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
                                  const SizedBox(width: 8),
                                  Text('Be the first to join this group!', style: AppText.body.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          else
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              children: group.members!.map((member) {
                                final color = _hexToColor(member.colorHex);
                                return Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: color.withOpacity(0.2),
                                      child: Text(
                                        member.initials,
                                        style: AppText.labelBold.copyWith(color: color),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: member.status == 'CONFIRMED'
                                            ? AppColors.success.withOpacity(0.1)
                                            : AppColors.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                      ),
                                      child: Text(
                                        member.status == 'CONFIRMED' ? 'Confirmed' : 'Pending',
                                        style: AppText.caption.copyWith(
                                          color: member.status == 'CONFIRMED' ? AppColors.success : AppColors.warning,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Guide card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18, color: AppColors.brand),
                              const SizedBox(width: 8),
                              Text('Your Guide', style: AppText.labelBold),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (group.guide != null) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.brand.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: AppColors.brand),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(group.guide!['name'] as String? ?? 'Guide', style: AppText.labelBold),
                                      if (group.guide!['expertise_tags'] != null)
                                        Text(
                                          (group.guide!['expertise_tags'] as List).join(', '),
                                          style: AppText.caption,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 20, color: AppColors.textTertiary),
                                  const SizedBox(width: 10),
                                  Text('Guide will be assigned when the group is confirmed', style: AppText.body.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Join button
                    if (!group.status.toUpperCase().contains('CONFIRMED') && !group.status.toUpperCase().contains('CANCELLED'))
                      _isJoining
                          ? const AppLoading()
                          : _hasJoined
                              ? Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        border: Border.all(color: AppColors.success),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle, color: AppColors.success),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Request Sent!',
                                            style: AppText.labelBold.copyWith(color: AppColors.success),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: _isLeaving ? null : () => _leaveGroup(group),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          minimumSize: const Size(0, 44),
                                        ),
                                        child: _isLeaving
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                            : const Text('Leave Group'),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: PrimaryButton(
                                    label: 'Join This Group',
                                    icon: Icons.group_add_outlined,
                                    onPressed: () => _joinGroup(group),
                                  ),
                                )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            group.status.toUpperCase().contains('CANCELLED')
                                ? 'This group is no longer available'
                                : 'This group is confirmed',
                            style: AppText.body.copyWith(color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                e.toString().contains('401') || e.toString().contains('Authorization')
                    ? 'Session expired — please sign in again'
                    : 'Failed to load group',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (e.toString().contains('401') || e.toString().contains('Authorization'))
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Go to Sign In'),
                )
              else
                TextButton(
                  onPressed: () => ref.invalidate(groupDetailProvider(widget.groupId)),
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.caption),
              Text(value, style: AppText.label),
            ],
          ),
        ],
      ),
    );
  }
}
