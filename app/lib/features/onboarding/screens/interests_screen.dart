import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Logo + step indicator
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '1 / 3',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF25D366),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
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
              const SizedBox(height: 32),
              _InterestSlider(
                label: 'Food & Cuisine',
                icon: Icons.restaurant,
                value: state.foodInterest,
                onChanged: notifier.setFoodInterest,
              ),
              _InterestSlider(
                label: 'Culture & History',
                icon: Icons.museum,
                value: state.cultureInterest,
                onChanged: notifier.setCultureInterest,
              ),
              _InterestSlider(
                label: 'Adventure & Nature',
                icon: Icons.terrain,
                value: state.adventureInterest,
                onChanged: notifier.setAdventureInterest,
              ),
              const Spacer(),
              Text(
                'Tip: Slide to adjust — tell us what matters most to you!',
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding/language'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  const _InterestSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF25D366)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF25D366),
              thumbColor: const Color(0xFF25D366),
              overlayColor: const Color(0xFF25D366).withOpacity(0.2),
              inactiveTrackColor: Colors.grey[200],
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
