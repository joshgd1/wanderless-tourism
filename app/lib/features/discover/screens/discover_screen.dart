import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
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

/// Rules-based match provider
final matchesProvider = FutureProvider<List<MatchedGuide>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return [];
  final selectedFilter = ref.watch(_selectedFilterProvider);
  final destination = _filterDestinationMap[selectedFilter];
  final api = ApiClient();
  final data = await api.getMatches(touristId, topN: 5, destination: destination);
  return data.map((e) => MatchedGuide.fromJson(e as Map<String, dynamic>)).toList();
});

/// ML-powered recommendation provider
final mlMatchesProvider = FutureProvider<List<MatchedGuide>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return [];
  final selectedFilter = ref.watch(_selectedFilterProvider);
  final destination = _filterDestinationMap[selectedFilter];
  final api = ApiClient();
  final data = await api.getMlGuideRecommendations(touristId, topN: 5, destination: destination);
  return data.map((e) => MatchedGuide.fromJson(e as Map<String, dynamic>)).toList();
});

final _selectedFilterProvider = StateProvider<String>((_) => 'Recommended');
final _mlModeProvider = StateProvider<bool>((_) => false);

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMl = ref.watch(_mlModeProvider);
    final matchesAsync = isMl ? ref.watch(mlMatchesProvider) : ref.watch(matchesProvider);
    final selectedFilter = ref.watch(_selectedFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Dark App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF1A2E1A),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'WanderLess',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Search destinations, experience',
                              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                              suffixIcon: Icon(Icons.tune, color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ML Toggle Row
                  Row(
                    children: [
                      const Text(
                        'Recommendation Mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2E1A),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isMl
                              ? const LinearGradient(
                                  colors: [Color(0xFF6B4EFF), Color(0xFF25D366)],
                                )
                              : null,
                          color: isMl ? null : const Color(0xFFF0F0F0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeTab(
                              label: 'Rules',
                              isSelected: !isMl,
                              onTap: () {
                                ref.read(_mlModeProvider.notifier).state = false;
                                ref.invalidate(matchesProvider);
                              },
                            ),
                            _ModeTab(
                              label: 'ML-Powered',
                              isSelected: isMl,
                              onTap: () {
                                ref.read(_mlModeProvider.notifier).state = true;
                                ref.invalidate(mlMatchesProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Recommended', 'All', 'Cultural', 'Nature', 'Adventure', 'Wellness'].map((filter) {
                    final isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(_selectedFilterProvider.notifier).state = filter;
                          if (isMl) {
                            ref.invalidate(mlMatchesProvider);
                          } else {
                            ref.invalidate(matchesProvider);
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF25D366).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF25D366),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF25D366) : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF25D366) : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Top Guide for You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),

          // Guide Cards
          matchesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Failed to load matches', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => isMl
                          ? ref.refresh(mlMatchesProvider)
                          : ref.refresh(matchesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (matches) {
              if (matches.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Complete onboarding to see your matches',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final guide = matches[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MatchCard(
                          guide: guide,
                          onTap: () => context.push('/guide/${guide.guideId}'),
                        ),
                      );
                    },
                    childCount: matches.length,
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
