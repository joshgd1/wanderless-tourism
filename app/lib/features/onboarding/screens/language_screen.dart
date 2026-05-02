import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../design_system.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const _languages = [
    ('en', 'English'),
    ('zh', 'Chinese'),
    ('ko', 'Korean'),
    ('ja', 'Japanese'),
    ('de', 'German'),
    ('fr', 'French'),
    ('ru', 'Russian'),
    ('th', 'Thai'),
  ];

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
                        'Preferred\nLanguage',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Which language would\nyou like your guide\nto speak?',
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
                    Text('Preferred Language', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Which language would you like your guide to speak?',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildLanguageGrid(state, notifier),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Back',
                            onPressed: () => context.go('/onboarding/experience-type'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: 'Continue',
                            onPressed: () => context.go('/onboarding/travel-style'),
                          ),
                        ),
                      ],
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
                _OnboardingStepper(currentStep: 2, totalSteps: 4),
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
                Text('Preferred Language', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'Which language would you like your guide to speak?',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildLanguageGrid(state, notifier),
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
                    onPressed: () => context.go('/onboarding/travel-style'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: GhostButton(
                    label: 'Back',
                    onPressed: () => context.go('/onboarding/experience-type'),
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

  Widget _buildLanguageGrid(OnboardingState state, OnboardingNotifier notifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _languages.map((lang) {
        final selected = state.languages.contains(lang.$1);
        return _LanguagePill(
          label: lang.$2,
          isSelected: selected,
          onTap: () {
            final current = List<String>.from(state.languages);
            if (selected) {
              current.remove(lang.$1);
            } else {
              current.add(lang.$1);
            }
            if (current.isEmpty) current.add(lang.$1);
            notifier.setLanguages(current);
          },
        );
      }).toList(),
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
      child: const Icon(Icons.translate, color: Colors.white, size: 26),
    );
  }
}

class _LanguagePill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguagePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LanguagePill> createState() => _LanguagePillState();
}

class _LanguagePillState extends State<_LanguagePill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.brand
              : _isPressed
                  ? AppColors.surfaceSecondary
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: widget.isSelected ? AppColors.brand : AppColors.border,
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          widget.label,
          style: AppText.label.copyWith(
            color: widget.isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
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

