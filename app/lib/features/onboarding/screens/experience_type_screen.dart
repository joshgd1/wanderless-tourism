import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../design_system.dart';

class ExperienceTypeScreen extends ConsumerWidget {
  const ExperienceTypeScreen({super.key});

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
                  child: CustomPaint(painter: _DarkGridPainter()),
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
                        'What kind\nof guide?',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "We'll match you with the\nright guide for the experience\nyou want.",
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
                    Text('What kind of guide?', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      "We'll match you with the right guide for the experience you want.",
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ExperienceOption(
                      title: 'Authentic local experience',
                      description: 'I want a guide who truly lives here — someone who knows hidden neighborhoods, local families, and off-the-beaten-path spots.',
                      icon: Icons.home_outlined,
                      color: AppColors.success,
                      isSelected: state.experienceType == 'authentic_local',
                      onTap: () => notifier.setExperienceType('authentic_local'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ExperienceOption(
                      title: 'Professional tourist-friendly',
                      description: 'I want a well-organized guide who speaks my language well and knows the top tourist attractions inside and out.',
                      icon: Icons.verified_outlined,
                      color: AppColors.info,
                      isSelected: state.experienceType == 'tourist_friendly',
                      onTap: () => notifier.setExperienceType('tourist_friendly'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Continue',
                        onPressed: () => context.go('/onboarding/language'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: GhostButton(
                        label: 'Skip',
                        onPressed: () => context.go('/onboarding/language'),
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
                _OnboardingStepper(currentStep: 1, totalSteps: 4),
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
                Text('What kind of guide?', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  "We'll match you with the right guide.",
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
                _ExperienceOption(
                  title: 'Authentic local experience',
                  description: 'I want a guide who truly lives here — someone who knows hidden neighborhoods, local families, and off-the-beaten-path spots.',
                  icon: Icons.home_outlined,
                  color: AppColors.success,
                  isSelected: state.experienceType == 'authentic_local',
                  onTap: () => notifier.setExperienceType('authentic_local'),
                ),
                const SizedBox(height: AppSpacing.md),
                _ExperienceOption(
                  title: 'Professional tourist-friendly',
                  description: 'I want a well-organized guide who speaks my language well and knows the top tourist attractions inside and out.',
                  icon: Icons.verified_outlined,
                  color: AppColors.info,
                  isSelected: state.experienceType == 'tourist_friendly',
                  onTap: () => notifier.setExperienceType('tourist_friendly'),
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
                    onPressed: () => context.go('/onboarding/language'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: GhostButton(
                    label: 'Skip',
                    onPressed: () => context.go('/onboarding/language'),
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
        onPressed: () => context.go('/onboarding'),
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
      child: const Icon(Icons.explore, color: Colors.white, size: 26),
    );
  }
}

class _ExperienceOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExperienceOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 24, color: isSelected ? color : AppColors.textTertiary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.labelBold),
                const SizedBox(height: 4),
                Text(description, style: AppText.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          ],
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
