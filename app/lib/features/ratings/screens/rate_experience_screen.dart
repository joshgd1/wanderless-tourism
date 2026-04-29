import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/onboarding_provider.dart';

final ratingProvider = StateProvider<double>((_) => 4.0);

class RateExperienceScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final String guideId;

  const RateExperienceScreen({super.key, required this.bookingId, required this.guideId});

  @override
  ConsumerState<RateExperienceScreen> createState() => _RateExperienceScreenState();
}

class _RateExperienceScreenState extends ConsumerState<RateExperienceScreen> {
  bool _loading = false;

  Future<void> _submitRating() async {
    setState(() => _loading = true);
    try {
      final touristId = (await ref.read(touristIdProvider.future))!;
      final rating = ref.read(ratingProvider);
      final api = ApiClient();
      await api.createRating({
        'tourist_id': touristId,
        'guide_id': widget.guideId,
        'booking_id': widget.bookingId,
        'rating': rating,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(ratingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Experience')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'How was your tour?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starValue = i + 1;
                return IconButton(
                  iconSize: 48,
                  icon: Icon(
                    rating >= starValue ? Icons.star : Icons.star_border,
                    color: Colors.amber[700],
                  ),
                  onPressed: () => ref.read(ratingProvider.notifier).state = starValue.toDouble(),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabel(rating),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 40),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _RatingDimension(label: 'Communication', initial: 4.0),
                    const SizedBox(height: 12),
                    _RatingDimension(label: 'Knowledge', initial: 4.0),
                    const SizedBox(height: 12),
                    _RatingDimension(label: 'Punctuality', initial: 4.0),
                    const SizedBox(height: 12),
                    _RatingDimension(label: 'Friendliness', initial: 4.0),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitRating,
                child: _loading ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 5) return 'Excellent! 🌟';
    if (r >= 4) return 'Great 👍';
    if (r >= 3) return 'Good';
    if (r >= 2) return 'Fair';
    return 'Poor';
  }
}

class _RatingDimension extends StatelessWidget {
  final String label;
  final double initial;

  const _RatingDimension({required this.label, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        ...List.generate(5, (i) {
          return IconButton(
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              i < initial ? Icons.star : Icons.star_border,
              color: Colors.amber[700],
            ),
            onPressed: () {},
          );
        }),
      ],
    );
  }
}
