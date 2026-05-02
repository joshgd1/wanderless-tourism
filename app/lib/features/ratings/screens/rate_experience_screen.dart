import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';

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
      final authState = ref.read(authProvider);
      final touristId = authState.touristId;
      if (touristId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please sign in to rate'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
        }
        return;
      }
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
          SnackBar(
            content: const Text('Thank you for your rating!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(ratingProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

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
                              'Rate Experience',
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
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
                child: Padding(
                  padding: EdgeInsets.all(isWide ? AppSpacing.xl : AppSpacing.lg),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Text('How was your tour?', style: AppText.h1),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final starValue = i + 1;
                          return IconButton(
                            iconSize: 48,
                            icon: Icon(
                              rating >= starValue ? Icons.star : Icons.star_border,
                              color: AppColors.brand,
                            ),
                            onPressed: () =>
                                ref.read(ratingProvider.notifier).state = starValue.toDouble(),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _ratingLabel(rating),
                        style: AppText.label,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppCard(
                        child: Column(
                          children: [
                            _RatingDimension(label: 'Communication', initial: 4.0),
                            const SizedBox(height: AppSpacing.sm),
                            _RatingDimension(label: 'Knowledge', initial: 4.0),
                            const SizedBox(height: AppSpacing.sm),
                            _RatingDimension(label: 'Punctuality', initial: 4.0),
                            const SizedBox(height: AppSpacing.sm),
                            _RatingDimension(label: 'Friendliness', initial: 4.0),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_loading)
                        const AppLoading()
                      else
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: 'Submit Rating',
                            icon: Icons.check,
                            onPressed: _submitRating,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(6),
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

class _RatingDimension extends StatefulWidget {
  final String label;
  final double initial;

  const _RatingDimension({required this.label, required this.initial});

  @override
  State<_RatingDimension> createState() => _RatingDimensionState();
}

class _RatingDimensionState extends State<_RatingDimension> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.label, style: AppText.label)),
        ...List.generate(5, (i) {
          return IconButton(
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              i < _rating ? Icons.star : Icons.star_border,
              color: AppColors.brand,
            ),
            onPressed: () => setState(() => _rating = (i + 1).toDouble()),
          );
        }),
      ],
    );
  }
}

}
