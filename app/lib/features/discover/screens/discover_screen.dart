import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/onboarding_provider.dart';
import '../../../shared/models/guide.dart';
import '../widgets/match_card.dart';

final matchesProvider = FutureProvider<List<MatchedGuide>>((ref) async {
  final prefs = await ref.watch(touristIdProvider.future);
  if (prefs == null) return [];
  final api = ApiClient();
  final data = await api.getMatches(prefs, topN: 5);
  return data.map((e) => MatchedGuide.fromJson(e as Map<String, dynamic>)).toList();
});

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => context.push('/bookings'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(matchesProvider);
          await ref.read(matchesProvider.future);
        },
        child: matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Failed to load matches', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(matchesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (matches) {
            if (matches.isEmpty) {
              return const Center(
                child: Text('Complete onboarding to see your matches'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final guide = matches[index];
                return MatchCard(
                  guide: guide,
                  onTap: () => context.push('/guide/${guide.guideId}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
