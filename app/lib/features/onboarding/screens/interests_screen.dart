import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../widgets/onboarding_shell.dart';

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Logo + animated stepper
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.explore,
                        color: Color(0xFF25D366),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'WanderLess',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E1A),
                      ),
                    ),
                    const Spacer(),
                    OnboardingStepper(
                      currentStep: 0,
                      totalSteps: 4,
                      activeColor: const Color(0xFF25D366),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Hero visual
                const OnboardingHeroVisual(screenIndex: 0),

                const SizedBox(height: 32),

                Text(
                  'What do you love?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A2E1A),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us your travel preferences so we can find the perfect guide for you.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 28),

                // Interest sliders with premium card styling
                _InterestCard(
                  label: 'Food & Cuisine',
                  description: 'Local restaurants, street food, cooking classes',
                  icon: Icons.restaurant,
                  value: state.foodInterest,
                  onChanged: notifier.setFoodInterest,
                  gradientColors: [const Color(0xFFFFB347), const Color(0xFFFF6B6B)],
                ),
                const SizedBox(height: 12),
                _InterestCard(
                  label: 'Culture & History',
                  description: 'Museums, temples, ancient traditions',
                  icon: Icons.museum,
                  value: state.cultureInterest,
                  onChanged: notifier.setCultureInterest,
                  gradientColors: [const Color(0xFF6B4EFF), const Color(0xFF128C7E)],
                ),
                const SizedBox(height: 12),
                _InterestCard(
                  label: 'Adventure & Nature',
                  description: 'Hiking, wildlife, outdoor exploration',
                  icon: Icons.terrain,
                  value: state.adventureInterest,
                  onChanged: notifier.setAdventureInterest,
                  gradientColors: [const Color(0xFF25D366), const Color(0xFF128C7E)],
                ),

                const SizedBox(height: 32),

                // Tip card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF25D366).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: const Color(0xFF25D366),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Slide to adjust — tell us what matters most to you!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/onboarding/experience-type'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final List<Color> gradientColors;

  const _InterestCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final isActive = value > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? gradientColors[0].withOpacity(0.4) : Colors.grey[200]!,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E1A),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(gradientColors[0]),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: gradientColors[0],
              thumbColor: gradientColors[0],
              overlayColor: gradientColors[0].withOpacity(0.2),
              inactiveTrackColor: Colors.grey[200],
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
