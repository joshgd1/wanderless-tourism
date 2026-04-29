import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/onboarding_provider.dart';

final ratingProvider = StateProvider<double>((_) => 4.0);

class RateExperienceScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final String guideId;

  const RateExperienceScreen({
    super.key,
    required this.bookingId,
    required this.guideId,
  });

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
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: Color(0xFF25D366),
          ),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2E1A),
        foregroundColor: Colors.white,
        title: const Text('Rate Your Experience'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'How was your tour?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2E1A),
                  ),
            ),
            const SizedBox(height: 32),
            // Main star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starValue = i + 1;
                return IconButton(
                  iconSize: 48,
                  icon: Icon(
                    rating >= starValue ? Icons.star : Icons.star_border,
                    color: const Color(0xFF25D366),
                  ),
                  onPressed: () =>
                      ref.read(ratingProvider.notifier).state = starValue.toDouble(),
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
            // Dimension ratings card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 5) return 'Excellent!';
    if (r >= 4) return 'Great';
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
              color: const Color(0xFF25D366),
            ),
            onPressed: () {},
          );
        }),
      ],
    );
  }
}
