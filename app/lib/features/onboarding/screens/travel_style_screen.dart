import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';

class TravelStyleScreen extends ConsumerWidget {
  const TravelStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? _buildWideLayout(context, ref, state, notifier)
            : _buildMobileLayout(context, ref, state, notifier),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, WidgetRef ref, OnboardingState state, OnboardingNotifier notifier) {
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
                        'Almost\nthere!',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'A few more details\nto personalize your\nexperience.',
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
                    Text('Almost there!', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'A few more details to personalize your experience.',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle(label: 'Travel Style', icon: Icons.group_outlined),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['solo', 'couple', 'group', 'family'].map((style) {
                        final selected = state.travelStyle == style;
                        return _ChoicePill(
                          label: style[0].toUpperCase() + style.substring(1),
                          isSelected: selected,
                          onTap: () => notifier.setTravelStyle(style),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(label: 'Age Group', icon: Icons.person_outlined),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['18-25', '26-35', '36-50', '51-65', '65+'].map((age) {
                        final selected = state.ageGroup == age;
                        return _ChoicePill(
                          label: age,
                          isSelected: selected,
                          onTap: () => notifier.setAgeGroup(age),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(label: 'Budget Level', icon: Icons.account_balance_wallet_outlined),
                    const SizedBox(height: AppSpacing.sm),
                    _BudgetSlider(state: state, notifier: notifier),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Back',
                            onPressed: () => context.go('/onboarding/language'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: 'Find My Guide',
                            onPressed: () async {
                              final authState = ref.read(authProvider);
                              final touristId = authState.touristId;
                              final savedTouristId = await notifier.savePreferences(touristId);
                              if (savedTouristId != null && touristId == null) {
                                ref.read(authProvider.notifier).setTouristId(savedTouristId);
                              }
                              if (context.mounted) {
                                context.go('/discover');
                              }
                            },
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

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, OnboardingState state, OnboardingNotifier notifier) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                _buildBackButton(context),
                const Spacer(),
                _OnboardingStepper(currentStep: 3, totalSteps: 4),
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
                Text('Almost there!', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'A few more details to personalize your experience.',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(label: 'Travel Style', icon: Icons.group_outlined),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['solo', 'couple', 'group', 'family'].map((style) {
                    final selected = state.travelStyle == style;
                    return _ChoicePill(
                      label: style[0].toUpperCase() + style.substring(1),
                      isSelected: selected,
                      onTap: () => notifier.setTravelStyle(style),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(label: 'Age Group', icon: Icons.person_outlined),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['18-25', '26-35', '36-50', '51-65', '65+'].map((age) {
                    final selected = state.ageGroup == age;
                    return _ChoicePill(
                      label: age,
                      isSelected: selected,
                      onTap: () => notifier.setAgeGroup(age),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(label: 'Budget Level', icon: Icons.account_balance_wallet_outlined),
                const SizedBox(height: AppSpacing.sm),
                _BudgetSlider(state: state, notifier: notifier),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Back',
                    onPressed: () => context.go('/onboarding/language'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Find My Guide',
                    onPressed: () async {
                      final authState = ref.read(authProvider);
                      final touristId = authState.touristId;
                      final savedTouristId = await notifier.savePreferences(touristId);
                      if (savedTouristId != null && touristId == null) {
                        ref.read(authProvider.notifier).setTouristId(savedTouristId);
                      }
                      if (context.mounted) {
                        context.go('/discover');
                      }
                    },
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
        onPressed: () => context.go('/onboarding/language'),
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
      child: const Icon(Icons.style_outlined, color: Colors.white, size: 26),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionTitle({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brand),
        const SizedBox(width: 6),
        Text(label, style: AppText.labelBold),
      ],
    );
  }
}

class _ChoicePill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChoicePill> createState() => _ChoicePillState();
}

class _ChoicePillState extends State<_ChoicePill> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.brand : _isHovered ? AppColors.surfaceSecondary : AppColors.surface,
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
      ),
    );
  }
}

class _BudgetSlider extends StatelessWidget {
  final OnboardingState state;
  final OnboardingNotifier notifier;

  const _BudgetSlider({required this.state, required this.notifier});

  String _budgetLabel(double value) {
    if (value <= 0.2) return 'Economy';
    if (value <= 0.4) return 'Budget';
    if (value <= 0.6) return 'Mid-range';
    if (value <= 0.8) return 'Upscale';
    return 'Premium';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget', style: AppText.label),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _budgetLabel(state.budgetLevel),
                  style: AppText.labelBold.copyWith(color: AppColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.brand,
              thumbColor: AppColors.brand,
              overlayColor: AppColors.brand.withOpacity(0.2),
              inactiveTrackColor: AppColors.surfaceSecondary,
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: state.budgetLevel,
              onChanged: notifier.setBudgetLevel,
              divisions: 10,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget', style: AppText.caption),
              Text('Premium', style: AppText.caption),
            ],
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

