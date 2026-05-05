import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../shared/models/travel_group.dart';
import '../../../../design_system.dart';

final _syntheticGroups = [
  TravelGroup(
    id: 1,
    destination: 'Singapore',
    coherence: 'high_coherence',
    memberCount: 4,
    tripDate: '2026-05-20',
    durationDays: 3,
    estimatedPricePerPerson: 185.0,
    interests: ['culture', 'food'],
    memberProfiles: [
      {'name': 'Sarah', 'gender': 'female', 'age': 28},
      {'name': 'Mike', 'gender': 'male', 'age': 32},
      {'name': 'Emma', 'gender': 'female', 'age': 26},
      {'name': 'James', 'gender': 'male', 'age': 30},
    ],
  ),
  TravelGroup(
    id: 2,
    destination: 'Chiang Mai',
    coherence: 'moderate_coherence',
    memberCount: 6,
    tripDate: '2026-06-05',
    durationDays: 4,
    estimatedPricePerPerson: 120.0,
    interests: ['temples', 'nature', 'food'],
    memberProfiles: [
      {'name': 'Anna', 'gender': 'female', 'age': 25},
      {'name': 'Ben', 'gender': 'male', 'age': 29},
      {'name': 'Clara', 'gender': 'female', 'age': 31},
      {'name': 'David', 'gender': 'male', 'age': 35},
      {'name': 'Eva', 'gender': 'female', 'age': 27},
      {'name': 'Frank', 'gender': 'male', 'age': 33},
    ],
  ),
  TravelGroup(
    id: 3,
    destination: 'Bali',
    coherence: 'high_coherence',
    memberCount: 3,
    tripDate: '2026-06-15',
    durationDays: 5,
    estimatedPricePerPerson: 210.0,
    interests: ['beach', 'yoga', 'nature'],
    memberProfiles: [
      {'name': 'Grace', 'gender': 'female', 'age': 30},
      {'name': 'Henry', 'gender': 'male', 'age': 28},
      {'name': 'Iris', 'gender': 'female', 'age': 26},
    ],
  ),
  TravelGroup(
    id: 4,
    destination: 'Bangkok',
    coherence: 'low_coherence',
    memberCount: 5,
    tripDate: '2026-07-01',
    durationDays: 3,
    estimatedPricePerPerson: 95.0,
    interests: ['nightlife', 'shopping', 'food'],
    memberProfiles: [
      {'name': 'Jack', 'gender': 'male', 'age': 24},
      {'name': 'Kate', 'gender': 'female', 'age': 29},
      {'name': 'Leo', 'gender': 'male', 'age': 27},
      {'name': 'Mia', 'gender': 'female', 'age': 31},
      {'name': 'Noah', 'gender': 'male', 'age': 26},
    ],
  ),
];

final groupsProvider = FutureProvider.family<List<TravelGroup>, String?>((ref, destination) async {
  try {
    final api = ApiClient();
    final data = await api.getGroups(destination: destination);
    final groups = data.map((e) => TravelGroup.fromJson(e as Map<String, dynamic>)).toList();
    return groups.isEmpty ? _syntheticGroups : groups;
  } catch (_) {
    return _syntheticGroups;
  }
});

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  String? _selectedDestination;
  bool _isFindingMatches = false;

  static const _destinations = ['Singapore', 'Chiang Mai', 'Bangkok', 'Bali'];

  Future<void> _findMatches() async {
    if (_isFindingMatches) return;
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select a destination first'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isFindingMatches = true);
    try {
      final api = ApiClient();
      await api.formGroups({
        'destination': _selectedDestination,
        'min_group_size': 3,
        'max_group_size': 8,
      });
      ref.invalidate(groupsProvider(_selectedDestination));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Match search complete! New groups may appear below.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match search failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFindingMatches = false);
    }
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
    // Placeholder: assumes base price of $50/h for guide, shared among group
    const baseGuidePricePerHour = 50.0;
    final hours = group.proposedDuration ?? 4.0;
    final total = baseGuidePricePerHour * hours;
    final perPerson = total / group.memberCount.clamp(1, group.maxSize);
    return '\$${perPerson.toStringAsFixed(0)}/person';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final groupsAsync = ref.watch(groupsProvider(_selectedDestination));

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
                            Text(
                              'Group Trips',
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
                  Text('Find your travel group', style: AppText.h2),
                  const SizedBox(height: 4),
                  Text(
                    'Join tourists with similar preferences and share a guide.',
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _selectedDestination == null,
                          onTap: () => setState(() => _selectedDestination = null),
                        ),
                        const SizedBox(width: 8),
                        ..._destinations.map((d) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: d,
                            isSelected: _selectedDestination == d,
                            onTap: () => setState(() => _selectedDestination = d),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _isFindingMatches ? null : _findMatches,
                      icon: _isFindingMatches
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(_isFindingMatches ? 'Finding matches…' : 'Find Matches'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        side: BorderSide(color: AppColors.brand.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          groupsAsync.when(
            data: (groups) {
              if (groups.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: AppSpacing.md),
                        Text('No groups yet', style: AppText.h2.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Create a trip plan and share it as a group\nto start matching with other travelers.',
                          style: AppText.body.copyWith(color: AppColors.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? AppSpacing.lg : AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _GroupCard(
                        group: groups[i],
                        coherenceColor: _coherenceColor(groups[i].coherence),
                        coherenceLabel: _coherenceLabel(groups[i].coherence),
                        formatDate: _formatDate,
                        estimatedPrice: _estimatedPrice,
                        onTap: () => context.push('/group/${groups[i].id}'),
                      ),
                    ),
                    childCount: groups.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: AppLoading()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      e.toString().contains('401') || e.toString().contains('Authorization')
                          ? 'Session expired — please sign in again'
                          : 'Failed to load groups',
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
                        onPressed: () => ref.invalidate(groupsProvider(_selectedDestination)),
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            ),
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
          padding: const EdgeInsets.all(12),
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

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.brand
                : _isHovered
                    ? AppColors.surfaceSecondary
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: widget.isSelected ? AppColors.brand : AppColors.border,
            ),
          ),
          child: Text(
            widget.label,
            style: AppText.label.copyWith(
              color: widget.isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatefulWidget {
  final TravelGroup group;
  final Color coherenceColor;
  final String coherenceLabel;
  final String Function(String?) formatDate;
  final String Function(TravelGroup) estimatedPrice;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.coherenceColor,
    required this.coherenceLabel,
    required this.formatDate,
    required this.estimatedPrice,
    required this.onTap,
  });

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
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
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _isHovered ? AppColors.brand : AppColors.border,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: AppColors.brand.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
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
                        Text(widget.group.destination, style: AppText.h2),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: widget.coherenceColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    widget.coherenceLabel,
                                    style: AppText.caption.copyWith(color: widget.coherenceColor, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    '${widget.group.memberCount}/${widget.group.maxSize} joined',
                                    style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _InfoChip(icon: Icons.calendar_today_outlined, label: widget.formatDate(widget.group.proposedDate)),
                  const SizedBox(width: AppSpacing.sm),
                  _InfoChip(icon: Icons.schedule_outlined, label: '${(widget.group.proposedDuration ?? 4.0).toStringAsFixed(1)}h'),
                  const Spacer(),
                  Text(
                    widget.estimatedPrice(widget.group),
                    style: AppText.h2.copyWith(color: AppColors.brand),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
