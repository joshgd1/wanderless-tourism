import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Preferred Language',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Which language would you like your guide to speak?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _languages.map((lang) {
                  final selected = state.language == lang.$1;
                  return ChoiceChip(
                    label: Text(lang.$2),
                    selected: selected,
                    onSelected: (_) => notifier.setLanguage(lang.$1),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/onboarding'),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => context.go('/onboarding/travel-style'),
                    child: const Text('Continue'),
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
