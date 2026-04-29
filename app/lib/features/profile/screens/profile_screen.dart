import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/onboarding_provider.dart';
import '../../../shared/models/tourist.dart';

final profileProvider = FutureProvider<Tourist?>((ref) async {
  final touristId = await ref.watch(touristIdProvider.future);
  if (touristId == null) return null;
  final api = ApiClient();
  final data = await api.getTourist(touristId);
  return Tourist.fromJson(data);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tourist) {
          if (tourist == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No profile yet'),
                  TextButton(
                    onPressed: () => context.go('/onboarding'),
                    child: const Text('Start Onboarding'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text('Tourist ${tourist.id}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(tourist.travelStyle.toUpperCase(), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Your Interests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InterestRow(label: 'Food', value: tourist.foodInterest, color: Colors.orange),
                      const SizedBox(height: 12),
                      _InterestRow(label: 'Culture', value: tourist.cultureInterest, color: Colors.purple),
                      const SizedBox(height: 12),
                      _InterestRow(label: 'Adventure', value: tourist.adventureInterest, color: Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(leading: const Icon(Icons.language), title: const Text('Language'), trailing: Text(tourist.language.toUpperCase())),
                    ListTile(leading: const Icon(Icons.group), title: const Text('Age Group'), trailing: Text(tourist.ageGroup)),
                    ListTile(leading: const Icon(Icons.attach_money), title: const Text('Budget'), trailing: Text(_budgetLabel(tourist.budgetLevel))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.go('/onboarding'),
                icon: const Icon(Icons.edit),
                label: const Text('Update Preferences'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _budgetLabel(double v) {
    if (v < 0.35) return 'Budget';
    if (v < 0.65) return 'Mid-range';
    return 'Premium';
  }
}

class _InterestRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _InterestRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 40, child: Text('${(value * 100).round()}%', textAlign: TextAlign.right)),
      ],
    );
  }
}
