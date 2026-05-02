import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../design_system.dart';

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? _buildWideLayout(context, state, notifier)
            : _buildMobileLayout(context, state, notifier),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, OnboardingState state, OnboardingNotifier notifier) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.textPrimary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: GridPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrandMark(),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Tell us what\nyou love.',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Your interests help us find\nthe perfect local guide\nfor your adventure.',
                        style: AppText.body.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Text('What do you love?', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Slide to adjust — tell us what matters most.',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _InterestSlider(
                      label: 'Food & Cuisine',
                      description: 'Local restaurants, street food, cooking classes',
                      icon: Icons.restaurant_outlined,
                      value: state.foodInterest,
                      onChanged: notifier.setFoodInterest,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InterestSlider(
                      label: 'Culture & History',
                      description: 'Museums, temples, ancient traditions',
                      icon: Icons.museum_outlined,
                      value: state.cultureInterest,
                      onChanged: notifier.setCultureInterest,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InterestSlider(
                      label: 'Adventure & Nature',
                      description: 'Hiking, wildlife, outdoor exploration',
                      icon: Icons.terrain_outlined,
                      value: state.adventureInterest,
                      onChanged: notifier.setAdventureInterest,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Continue',
                        onPressed: () => context.go('/onboarding/experience-type'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: GhostButton(
                        label: 'Skip',
                        onPressed: () => context.go('/onboarding/experience-type'),
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, OnboardingState state, OnboardingNotifier notifier) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                _buildBackButton(context),
                const Spacer(),
                _OnboardingStepper(currentStep: 0, totalSteps: 4),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandMark(),
                const SizedBox(height: AppSpacing.lg),
                Text('What do you love?', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'Slide to adjust — tell us what matters most.',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _InterestSlider(
                  label: 'Food & Cuisine',
                  description: 'Local restaurants, street food, cooking classes',
                  icon: Icons.restaurant_outlined,
                  value: state.foodInterest,
                  onChanged: notifier.setFoodInterest,
                  color: Colors.orange,
                ),
                const SizedBox(height: AppSpacing.md),
                _InterestSlider(
                  label: 'Culture & History',
                  description: 'Museums, temples, ancient traditions',
                  icon: Icons.museum_outlined,
                  value: state.cultureInterest,
                  onChanged: notifier.setCultureInterest,
                  color: Colors.purple,
                ),
                const SizedBox(height: AppSpacing.md),
                _InterestSlider(
                  label: 'Adventure & Nature',
                  description: 'Hiking, wildlife, outdoor exploration',
                  icon: Icons.terrain_outlined,
                  value: state.adventureInterest,
                  onChanged: notifier.setAdventureInterest,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Continue',
                    onPressed: () => context.go('/onboarding/experience-type'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: GhostButton(
                    label: 'Skip',
                    onPressed: () => context.go('/onboarding/experience-type'),
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.arrow_back, size: 18),
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildBrandMark() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.favorite_outline, color: Colors.white, size: 26),
    );
  }
}

class _InterestSlider extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;

  const _InterestSlider({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final isActive = value > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.labelBold),
                    Text(description, style: AppText.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.1) : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$pct%',
                  style: AppText.labelBold.copyWith(color: isActive ? color : AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              inactiveTrackColor: AppColors.surfaceSecondary,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              divisions: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _OnboardingStepper({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Row(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: isCurrent ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                color: isCompleted || isCurrent ? AppColors.brand : AppColors.border,
              ),
            ),
            if (index < totalSteps - 1) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }
}
