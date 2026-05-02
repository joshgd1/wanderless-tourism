import 'package:flutter/material.dart';
import '../../../../design_system.dart';

/// Animated dot step indicator for onboarding screens.
/// Shows filled dots for completed steps, outlined for current, grey for future.
class OnboardingStepper extends StatelessWidget {
  final int currentStep; // 0-indexed
  final int totalSteps;

  const OnboardingStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == totalSteps - 1;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isCurrent ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isCompleted || isCurrent
                    ? AppColors.brand
                    : AppColors.border,
                border: isCurrent
                    ? Border.all(color: AppColors.brand.withOpacity(0.3), width: 2)
                    : null,
              ),
            ),
            if (!isLast) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }
}

/// A placeholder hero visual for onboarding screens.
/// Shows a gradient background with an abstract travel motif.
class OnboardingHeroVisual extends StatelessWidget {
  final int screenIndex;
  final double height;

  const OnboardingHeroVisual({
    super.key,
    required this.screenIndex,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _gradients[screenIndex % _gradients.length],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _gradients[screenIndex % _gradients.length][0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Center icon
          Center(
            child: Icon(
              _icons[screenIndex % _icons.length],
              size: 56,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          // Bottom label
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              _labels[screenIndex % _labels.length],
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static const _gradients = [
    [Color(0xFF25D366), Color(0xFF128C7E)],          // green
    [Color(0xFF6B4EFF), Color(0xFF128C7E)],          // purple-green
    [Color(0xFFFFB347), Color(0xFFFF6B6B)],           // amber-coral
    [Color(0xFF25D366), Color(0xFF2D6A4F)],          // dark green
  ];

  static const _icons = [
    Icons.favorite_outline,
    Icons.explore_outlined,
    Icons.translate,
    Icons.style_outlined,
  ];

  static const _labels = [
    'YOUR INTERESTS',
    'GUIDE EXPERIENCE',
    'LANGUAGE',
    'TRAVEL STYLE',
  ];
}
