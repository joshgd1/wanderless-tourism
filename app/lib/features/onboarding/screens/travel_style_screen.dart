import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/onboarding_provider.dart';

class TravelStyleScreen extends ConsumerWidget {
  const TravelStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Almost there!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'A few more details to personalize your experience.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              Text('Travel Style', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['solo', 'couple', 'group', 'family'].map((style) {
                  final selected = state.travelStyle == style;
                  return ChoiceChip(
                    label: Text(style[0].toUpperCase() + style.substring(1)),
                    selected: selected,
                    onSelected: (_) => notifier.setTravelStyle(style),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Age Group', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['18-25', '26-35', '36-50', '51-65', '65+'].map((age) {
                  final selected = state.ageGroup == age;
                  return ChoiceChip(
                    label: Text(age),
                    selected: selected,
                    onSelected: (_) => notifier.setAgeGroup(age),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Budget Level', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Budget'),
                  Expanded(
                    child: Slider(
                      value: state.budgetLevel,
                      onChanged: notifier.setBudgetLevel,
                      divisions: 10,
                    ),
                  ),
                  const Text('Premium'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/onboarding/language'),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final touristId = await notifier.createTourist();
                      if (context.mounted) {
                        context.go('/discover');
                      }
                    },
                    child: const Text('Find My Guide'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
