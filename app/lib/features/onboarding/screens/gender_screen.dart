import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../design_system.dart';

class GenderScreen extends ConsumerWidget {
  const GenderScreen({super.key});

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
                        'Who are\nyou?',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "Help us match you with\ncompatible travel companions\nand guides.",
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
                    Text('Your gender', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'This helps us find compatible guides and travel companions for shared trips.',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _GenderOption(
                      label: 'Male',
                      icon: Icons.male,
                      isSelected: state.gender == 'male',
                      onTap: () => notifier.setGender('male'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _GenderOption(
                      label: 'Female',
                      icon: Icons.female,
                      isSelected: state.gender == 'female',
                      onTap: () => notifier.setGender('female'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _GenderOption(
                      label: 'Non-binary',
                      icon: Icons.people_outline,
                      isSelected: state.gender == 'non_binary',
                      onTap: () => notifier.setGender('non_binary'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _GenderOption(
                      label: 'Prefer not to say',
                      icon: Icons.person_outline,
                      isSelected: state.gender == 'prefer_not_to_say',
                      onTap: () => notifier.setGender('prefer_not_to_say'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Continue',
                        onPressed: () => context.go('/onboarding/language'),
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
                _OnboardingStepper(currentStep: 2, totalSteps: 5),
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
                Text('Your gender', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'This helps us find compatible guides and companions.',
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
                _GenderOption(
                  label: 'Male',
                  icon: Icons.male,
                  isSelected: state.gender == 'male',
                  onTap: () => notifier.setGender('male'),
                ),
                const SizedBox(height: AppSpacing.md),
                _GenderOption(
                  label: 'Female',
                  icon: Icons.female,
                  isSelected: state.gender == 'female',
                  onTap: () => notifier.setGender('female'),
                ),
                const SizedBox(height: AppSpacing.md),
                _GenderOption(
                  label: 'Non-binary',
                  icon: Icons.people_outline,
                  isSelected: state.gender == 'non_binary',
                  onTap: () => notifier.setGender('non_binary'),
                ),
                const SizedBox(height: AppSpacing.md),
                _GenderOption(
                  label: 'Prefer not to say',
                  icon: Icons.person_outline,
                  isSelected: state.gender == 'prefer_not_to_say',
                  onTap: () => notifier.setGender('prefer_not_to_say'),
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
        onPressed: () => context.go('/onboarding/experience-type'),
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
      child: const Icon(Icons.person_outline, color: Colors.white, size: 26),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brand.withOpacity(0.1) : AppColors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isSelected ? AppColors.brand : AppColors.textTertiary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppText.labelBold),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
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
