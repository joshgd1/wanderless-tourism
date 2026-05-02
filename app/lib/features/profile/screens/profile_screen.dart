import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../shared/models/tourist.dart';

final profileProvider = FutureProvider<Tourist?>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Dark header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF1A2E1A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2E1A), Color(0xFF2D4A2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Floating avatar card
                      Positioned(
                        left: 16,
                        top: 12,
                        child: profileAsync.when(
                          data: (tourist) {
                            if (tourist == null) return const SizedBox.shrink();
                            return _TouristFloatingCard(
                              photoUrl: tourist.photoUrl,
                              name: tourist.name,
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      // Top-right edit button
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.white),
                          onPressed: () => context.go('/onboarding'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverFillRemaining(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (tourist) {
                if (tourist == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No profile yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/onboarding'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Onboarding'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: tourist.photoUrl.isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: tourist.photoUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Color(0xFF25D366),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Color(0xFF25D366),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Color(0xFF25D366),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tourist.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tourist.travelStyle.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF25D366),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Interests
                    Text(
                      'Your Interests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _InterestRow(
                              label: 'Food',
                              value: tourist.foodInterest,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 14),
                            _InterestRow(
                              label: 'Culture',
                              value: tourist.cultureInterest,
                              color: Colors.purple,
                            ),
                            const SizedBox(height: 14),
                            _InterestRow(
                              label: 'Adventure',
                              value: tourist.adventureInterest,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Details
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language, color: Color(0xFF25D366)),
                            title: const Text('Language'),
                            trailing: Text(
                              tourist.language.toUpperCase(),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[100]),
                          ListTile(
                            leading: const Icon(Icons.group, color: Color(0xFF25D366)),
                            title: const Text('Age Group'),
                            trailing: Text(
                              tourist.ageGroup,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[100]),
                          ListTile(
                            leading: const Icon(Icons.attach_money, color: Color(0xFF25D366)),
                            title: const Text('Budget'),
                            trailing: Text(
                              _budgetLabel(tourist.budgetLevel),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/onboarding'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Update Preferences'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        icon: Icon(Icons.logout, color: Colors.red[400]),
                        label: Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red[400]),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
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

  const _InterestRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}

class _TouristFloatingCard extends StatelessWidget {
  final String photoUrl;
  final String name;

  const _TouristFloatingCard({
    required this.photoUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: Colors.grey[700],
                          child: const Icon(Icons.person, color: Colors.white54, size: 28)),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[700],
                          child: const Icon(Icons.person, color: Colors.white54, size: 28)),
                    )
                  : Container(
                      color: Colors.grey[700],
                      child: const Icon(Icons.person, color: Colors.white54, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
