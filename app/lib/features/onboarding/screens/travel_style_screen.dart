import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../core/auth_provider.dart';

class TravelStyleScreen extends ConsumerWidget {
  const TravelStyleScreen({super.key});

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
                      '4 / 4',
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
                'Almost there!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A2E1A),
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
              Text(
                'Travel Style',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
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
                    selectedColor: const Color(0xFF25D366).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF25D366),
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF25D366) : Colors.grey[700],
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected ? const Color(0xFF25D366) : Colors.grey[300]!,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Age Group',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
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
                    selectedColor: const Color(0xFF25D366).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF25D366),
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF25D366) : Colors.grey[700],
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected ? const Color(0xFF25D366) : Colors.grey[300]!,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Budget Level',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Budget'),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF25D366),
                        thumbColor: const Color(0xFF25D366),
                        overlayColor: const Color(0xFF25D366).withOpacity(0.2),
                        inactiveTrackColor: Colors.grey[200],
                      ),
                      child: Slider(
                        value: state.budgetLevel,
                        onChanged: notifier.setBudgetLevel,
                        divisions: 10,
                      ),
                    ),
                  ),
                  const Text('Premium'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/onboarding/experience-type'),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final authState = ref.read(authProvider);
                      final touristId = authState.touristId;
                      await notifier.savePreferences(touristId);
                      if (context.mounted) {
                        context.go('/discover');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
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
