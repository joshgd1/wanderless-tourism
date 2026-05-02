import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';
import '../../../../shared/models/guide.dart';
import '../widgets/match_card.dart';

final _filterDestinationMap = {
  'Recommended': null,
  'All': null,
  'Cultural': 'Old City',
  'Nature': 'Doi Suthep',
  'Adventure': 'Mae Sa Valley',
  'Wellness': 'Nimman',
};

final matchesProvider = FutureProvider<List<MatchedGuide>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return [];
  final selectedFilter = ref.watch(_selectedFilterProvider);
  final destination = _filterDestinationMap[selectedFilter];
  final api = ApiClient();
  final data = await api.getMatches(touristId, topN: 10, destination: destination);
  return data.map((e) => MatchedGuide.fromJson(e as Map<String, dynamic>)).toList();
});

final mlMatchesProvider = FutureProvider<List<MatchedGuide>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return [];
  final selectedFilter = ref.watch(_selectedFilterProvider);
  final destination = _filterDestinationMap[selectedFilter];
  final api = ApiClient();
  final data = await api.getMlGuideRecommendations(touristId, topN: 10, destination: destination);
  return data.map((e) => MatchedGuide.fromJson(e as Map<String, dynamic>)).toList();
});

final _selectedFilterProvider = StateProvider<String>((_) => 'Recommended');
final _mlModeProvider = StateProvider<bool>((_) => false);
final _searchQueryProvider = StateProvider<String>((_) => '');

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMl = ref.watch(_mlModeProvider);
    final matchesAsync = isMl ? ref.watch(mlMatchesProvider) : ref.watch(matchesProvider);
    final selectedFilter = ref.watch(_selectedFilterProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.textPrimary,
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
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.go('/discover'),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.brand,
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: const Icon(Icons.explore, color: Colors.white, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'WanderLess',
                                        style: AppText.h3.copyWith(color: Colors.white, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                _IconBtn(
                                  icon: Icons.notifications_outlined,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SearchBar(
                              onChanged: (value) {
                                ref.read(_searchQueryProvider.notifier).state = value;
                              },
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
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeToggle(
                            label: 'Rules',
                            sublabel: 'Curated',
                            isSelected: !isMl,
                            onTap: () {
                              ref.read(_mlModeProvider.notifier).state = false;
                              ref.invalidate(matchesProvider);
                            },
                          ),
                        ),
                        Expanded(
                          child: _ModeToggle(
                            label: 'ML-Powered',
                            sublabel: 'AI Match',
                            isSelected: isMl,
                            onTap: () {
                              ref.read(_mlModeProvider.notifier).state = true;
                              ref.invalidate(mlMatchesProvider);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Recommended', 'All', 'Cultural', 'Nature', 'Adventure', 'Wellness'].map((filter) {
                        final isSelected = selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: filter,
                            isSelected: isSelected,
                            onTap: () {
                              ref.read(_selectedFilterProvider.notifier).state = filter;
                              if (isMl) {
                                ref.invalidate(mlMatchesProvider);
                              } else {
                                ref.invalidate(matchesProvider);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Top Guides for You',
                    style: AppText.h3,
                  ),
                ],
              ),
            ),
          ),
          matchesAsync.when(
            loading: () => SliverFillRemaining(
              child: Center(
                child: AppLoading(message: 'Finding your perfect guides...'),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: EmptyState(
                icon: Icons.cloud_off,
                title: 'Connection issue',
                subtitle: 'Could not load guides. Check your connection.',
                action: PrimaryButton(
                  label: 'Try Again',
                  onPressed: () => isMl
                      ? ref.refresh(mlMatchesProvider)
                      : ref.refresh(matchesProvider),
                ),
              ),
            ),
            data: (matches) {
              final searchQuery = ref.watch(_searchQueryProvider).toLowerCase();
              final filtered = searchQuery.isEmpty
                  ? matches
                  : matches.where((g) {
                      final name = g.name.toLowerCase();
                      final guideId = g.guideId.toLowerCase();
                      final locations = g.locationCoverage.join(' ').toLowerCase();
                      final expertise = g.expertiseTags.join(' ').toLowerCase();
                      return name.contains(searchQuery) ||
                          guideId.contains(searchQuery) ||
                          locations.contains(searchQuery) ||
                          expertise.contains(searchQuery);
                    }).toList();
              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No guides found',
                    subtitle: 'Try a different search term',
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final guide = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MatchCard(
                          guide: guide,
                          onTap: () => context.push('/guide/${guide.guideId}'),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final void Function(String) onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppText.body,
        decoration: InputDecoration(
          hintText: 'Search destinations, experiences...',
          hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 18),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.tune, color: AppColors.brand, size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggle({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                label.contains('ML') ? Icons.auto_awesome : Icons.star,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.labelBold.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                Text(
                  sublabel,
                  style: AppText.caption.copyWith(
                    color: isSelected ? Colors.white70 : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (label) {
      case 'Recommended': return Icons.recommend;
      case 'All': return Icons.apps;
      case 'Cultural': return Icons.museum;
      case 'Nature': return Icons.terrain;
      case 'Adventure': return Icons.bolt;
      case 'Wellness': return Icons.spa;
      default: return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppText.labelBold.copyWith(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
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
