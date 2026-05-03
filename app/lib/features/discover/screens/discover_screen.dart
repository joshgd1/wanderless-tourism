import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';
import '../../../../shared/models/guide.dart';
import '../../profile/widgets/profile_menu_sheet.dart';
import '../widgets/match_card.dart';

final _filterDestinationMap = {
  'Recommended': null,
  'All': null,
  'Cultural': 'Chinatown',
  'Nature': 'Gardens by the Bay',
  'Adventure': 'Sentosa',
  'Wellness': 'Marina Bay',
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
final _smartModeProvider = StateProvider<bool>((_) => false);
final _searchQueryProvider = StateProvider<String>((_) => '');

// Static fallback destinations — Singapore, Malaysia, Thailand, Bali order
final _staticDestinations = [
  _Destination(
    name: 'Marina Bay',
    country: 'Singapore',
    imageUrl: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80',
    guideCount: 52,
    tag: 'Waterfront Skyline',
  ),
  _Destination(
    name: 'Chinatown',
    country: 'Singapore',
    imageUrl: 'https://images.unsplash.com/photo-1559628376-64e7d7b67a5a?w=800&q=80',
    guideCount: 38,
    tag: 'Heritage & Food',
  ),
  _Destination(
    name: 'Sentosa',
    country: 'Singapore',
    imageUrl: 'https://images.unsplash.com/photo-1505852679233-d9fd70c2dz2d?w=800&q=80',
    guideCount: 45,
    tag: 'Beach & Attractions',
  ),
  _Destination(
    name: 'Gardens by the Bay',
    country: 'Singapore',
    imageUrl: 'https://images.unsplash.com/photo-1513836279014-a89f7d76ae86?w=800&q=80',
    guideCount: 29,
    tag: 'Nature & Light Show',
  ),
  _Destination(
    name: 'Petronas Towers',
    country: 'Malaysia',
    imageUrl: 'https://images.unsplash.com/photo-1598935898639-81586f7d2129?w=800&q=80',
    guideCount: 34,
    tag: 'City Landmark',
  ),
  _Destination(
    name: 'Chiang Mai',
    country: 'Thailand',
    imageUrl: 'https://images.unsplash.com/photo-1512553269949-a524842f5ab4?w=800&q=80',
    guideCount: 41,
    tag: 'Temples & Culture',
  ),
  _Destination(
    name: 'Ubud',
    country: 'Bali',
    imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800&q=80',
    guideCount: 28,
    tag: 'Nature & Arts',
  ),
];

final destinationsProvider = FutureProvider<List<_Destination>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return _staticDestinations;
  try {
    final api = ApiClient();
    final data = await api.getMlDestinationRecommendations(touristId);
    if (data.isEmpty) return _staticDestinations;
    return data.map((d) {
      final map = d as Map<String, dynamic>;
      return _Destination(
        name: map['destination'] as String? ?? 'Singapore',
        country: map['region'] as String? ?? 'Singapore',
        imageUrl: map['image_url'] as String? ??
            'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80',
        guideCount: map['guide_count'] as int? ?? 20,
        tag: map['tag'] as String? ?? 'Popular',
      );
    }).toList();
  } catch (_) {
    return _staticDestinations;
  }
});

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSmart = ref.watch(_smartModeProvider);
    final matchesAsync = isSmart ? ref.watch(mlMatchesProvider) : ref.watch(matchesProvider);
    final selectedFilter = ref.watch(_selectedFilterProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
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
                        child: CustomPaint(painter: GridPainter()),
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
                                        'WanderAI',
                                        style: AppText.h3.copyWith(color: Colors.white, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                IconBtn(
                                  icon: Icons.notifications_outlined,
                                  onPressed: () => context.push('/notifications'),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => ProfileMenuSheet.show(context),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.brand.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                                  ),
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

          // ── Featured Destinations Carousel ──────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Featured Destinations', style: AppText.h3),
                    ],
                  ),
                ),
                SizedBox(
                  height: 190,
                  child: ref.watch(destinationsProvider).when(
                    loading: () => const Center(child: AppLoading()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (dests) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dests.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final dest = dests[index];
                        return _DestinationCard(
                          destination: dest,
                          onTap: () {
                            ref.read(_selectedFilterProvider.notifier).state = 'All';
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Quick Actions Strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      Expanded(child: _QuickAction(icon: Icons.explore, label: 'Explore', color: AppColors.info, onTap: () {})),
                      const SizedBox(width: 10),
                      Expanded(child: _QuickAction(icon: Icons.card_travel, label: 'My Trips', color: AppColors.success, onTap: () => context.go('/bookings'))),
                      const SizedBox(width: 10),
                      Expanded(child: _QuickAction(icon: Icons.lightbulb, label: 'Plan Trip', color: AppColors.warning, onTap: () => context.push('/trip-plan/create'))),
                      const SizedBox(width: 10),
                      Expanded(child: _QuickAction(icon: Icons.person, label: 'Profile', color: Colors.purple, onTap: () => context.go('/profile'))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Smart Match Toggle ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, AppSpacing.md, 16, 0),
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
                      label: 'Curated',
                      sublabel: 'Expert picks',
                      icon: Icons.star,
                      isSelected: !isSmart,
                      onTap: () {
                        ref.read(_smartModeProvider.notifier).state = false;
                        ref.invalidate(matchesProvider);
                      },
                    ),
                  ),
                  Expanded(
                    child: _ModeToggle(
                      label: 'Smart Match',
                      sublabel: 'AI powered',
                      icon: Icons.auto_awesome,
                      isSelected: isSmart,
                      onTap: () {
                        ref.read(_smartModeProvider.notifier).state = true;
                        ref.invalidate(mlMatchesProvider);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  _InfoTooltip(),
                ],
              ),
            ),
          ),

          // ── Filter Chips ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, AppSpacing.md, 16, 0),
              child: SingleChildScrollView(
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
                          if (isSmart) {
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
            ),
          ),

          // ── Section Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, AppSpacing.lg, 20, 4),
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
                    isSmart ? 'AI-Guided Matches' : 'Top Guides',
                    style: AppText.h3,
                  ),
                  const Spacer(),
                  Text(
                    'Sorted by ${isSmart ? 'match score' : 'rating'}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
          ),

          // ── Smart Match explanation banner ────────────────────────────
          if (isSmart)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, AppSpacing.sm, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info.withOpacity(0.12),
                        AppColors.info.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.info.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.info, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Matched to your preferences',
                              style: AppText.labelBold.copyWith(color: AppColors.info),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'These guides are ranked by how well their expertise, language, and travel style match your interests — set during onboarding.',
                              style: AppText.caption.copyWith(height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Guide List ─────────────────────────────────────────────────
          matchesAsync.when(
            loading: () => SliverFillRemaining(
              child: Center(
                child: AppLoading(message: isSmart ? 'Finding AI matches...' : 'Loading guides...'),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: EmptyState(
                icon: Icons.cloud_off,
                title: 'Connection issue',
                subtitle: 'Could not load guides. Check your connection.',
                action: PrimaryButton(
                  label: 'Try Again',
                  onPressed: () => isSmart
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

class _Destination {
  final String name;
  final String country;
  final String imageUrl;
  final int guideCount;
  final String tag;

  const _Destination({
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.guideCount,
    required this.tag,
  });
}

class _DestinationCard extends StatelessWidget {
  final _Destination destination;
  final VoidCallback onTap;

  const _DestinationCard({required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image with gradient
              Image.network(
                destination.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        destination.tag,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 11),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            destination.country,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${destination.guideCount} guides',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          hintText: 'Search guides, destinations...',
          hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 18),
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
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggle({
    required this.label,
    required this.sublabel,
    required this.icon,
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
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
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

class _InfoTooltip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: 'Curated\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: 'Guides selected by our travel experts based on reviews and quality.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
          TextSpan(
            text: '\n\nSmart Match\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: 'AI-powered recommendations personalized to your travel preferences and style.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
      preferBelow: false,
      child: IconBtn(
        icon: Icons.info_outline,
        onPressed: () {},
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
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
