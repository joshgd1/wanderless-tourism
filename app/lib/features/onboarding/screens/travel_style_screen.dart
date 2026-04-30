import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../core/auth_provider.dart';
import '../widgets/onboarding_shell.dart';

class TravelStyleScreen extends ConsumerWidget {
  const TravelStyleScreen({super.key});

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
                      currentStep: 3,
                      totalSteps: 4,
                      activeColor: const Color(0xFF25D366),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Hero visual
                const OnboardingHeroVisual(screenIndex: 3),

                const SizedBox(height: 32),

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
                const SizedBox(height: 28),

                // Travel Style section
                _SectionTitle(label: 'Travel Style', icon: Icons.group_outlined),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['solo', 'couple', 'group', 'family'].map((style) {
                    final selected = state.travelStyle == style;
                    return _PillChoice(
                      label: style[0].toUpperCase() + style.substring(1),
                      isSelected: selected,
                      onTap: () => notifier.setTravelStyle(style),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Age Group section
                _SectionTitle(label: 'Age Group', icon: Icons.person_outline),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['18-25', '26-35', '36-50', '51-65', '65+'].map((age) {
                    final selected = state.ageGroup == age;
                    return _PillChoice(
                      label: age,
                      isSelected: selected,
                      onTap: () => notifier.setAgeGroup(age),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Budget section
                _SectionTitle(label: 'Budget Level', icon: Icons.account_balance_wallet_outlined),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget',
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _budgetLabel(state.budgetLevel),
                              style: const TextStyle(
                                color: Color(0xFF25D366),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
                          Text('Budget', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                          Text('Premium', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/onboarding/language'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
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
                          'Find My Guide',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _budgetLabel(double value) {
    if (value <= 0.2) return 'Economy';
    if (value <= 0.4) return 'Budget';
    if (value <= 0.6) return 'Mid-range';
    if (value <= 0.8) return 'Upscale';
    return 'Premium';
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
        Icon(icon, size: 18, color: const Color(0xFF25D366)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E1A),
          ),
        ),
      ],
    );
  }
}

class _PillChoice extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillChoice({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF25D366) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF25D366) : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF25D366).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
