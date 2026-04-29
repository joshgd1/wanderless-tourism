import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api_client.dart';
import '../../../../shared/models/guide.dart';

final guideDetailProvider = FutureProvider.family<Guide, String>((ref, guideId) async {
  final api = ApiClient();
  final data = await api.getGuide(guideId);
  return Guide.fromJson(data);
});

class GuideDetailScreen extends ConsumerWidget {
  final String guideId;

  const GuideDetailScreen({super.key, required this.guideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(guideDetailProvider(guideId));

    return Scaffold(
      body: guideAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (guide) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: guide.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guide.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 4),
                        Text('${guide.ratingHistory.toStringAsFixed(1)} (${guide.ratingCount} reviews)'),
                        const SizedBox(width: 16),
                        Icon(Icons.group, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('Max ${guide.groupSizePreferred} people'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(guide.bio, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    Text('Expertise', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: guide.expertiseTags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Locations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: guide.locationCoverage.map((loc) {
                        return Chip(
                          avatar: const Icon(Icons.location_on, size: 16),
                          label: Text(loc),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Languages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: guide.languagePairs.map((lp) {
                        final langs = lp.split('→');
                        return Chip(
                          avatar: const Icon(Icons.translate, size: 16),
                          label: Text('${langs[0]} → ${langs[1]}'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => context.push('/book/$guideId'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Book This Guide'),
          ),
        ),
      ),
    );
  }
}
