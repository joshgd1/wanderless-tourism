import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';
import '../../../../shared/models/tourist.dart';

final profileProvider = FutureProvider<Tourist?>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return null;
  try {
    final api = ApiClient();
    final data = await api.getTourist(touristId);
    return Tourist.fromJson(data);
  } catch (e) {
    // Tourist record may not exist yet — return null to show empty state
    return null;
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.textPrimary,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: GridPainter()),
                      ),
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
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
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
              loading: () => const AppLoading(message: 'Loading profile...'),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load profile',
                subtitle: e.toString(),
              ),
              data: (tourist) {
                if (tourist == null) {
                  return EmptyState(
                    icon: Icons.person_outline,
                    title: 'No profile yet',
                    subtitle: 'Complete onboarding to get started',
                    action: PrimaryButton(
                      label: 'Start Onboarding',
                      onPressed: () => context.go('/onboarding'),
                    ),
                  );
                }
                return ListView(
                  padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipOval(
                              child: tourist.photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: tourist.photoUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Icon(Icons.person, size: 32, color: AppColors.textTertiary),
                                      errorWidget: (_, __, ___) => const Icon(Icons.person, size: 32, color: AppColors.textTertiary),
                                    )
                                  : const Icon(Icons.person, size: 32, color: AppColors.textTertiary),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(tourist.name, style: AppText.h2),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              tourist.travelStyle.toUpperCase(),
                              style: AppText.captionBold.copyWith(color: AppColors.brand),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Your Interests', style: AppText.h3),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children: [
                          _InterestRow(label: 'Food', value: tourist.foodInterest, color: Colors.orange),
                          const Divider(height: AppSpacing.md),
                          _InterestRow(label: 'Culture', value: tourist.cultureInterest, color: Colors.purple),
                          const Divider(height: AppSpacing.md),
                          _InterestRow(label: 'Adventure', value: tourist.adventureInterest, color: AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Details', style: AppText.h3),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.language_outlined,
                            label: 'Language',
                            value: tourist.language.toUpperCase(),
                          ),
                          const Divider(height: 1),
                          _DetailRow(
                            icon: Icons.group_outlined,
                            label: 'Age Group',
                            value: tourist.ageGroup,
                          ),
                          const Divider(height: 1),
                          _DetailRow(
                            icon: Icons.attach_money_outlined,
                            label: 'Budget',
                            value: _budgetLabel(tourist.budgetLevel),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SecondaryButton(
                      label: 'Update Preferences',
                      icon: Icons.edit,
                      onPressed: () => context.go('/onboarding'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: GhostButton(
                        label: 'Sign Out',
                        icon: Icons.logout,
                        color: AppColors.error,
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
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
          child: Text(label, style: AppText.label),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: AppText.labelBold,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: AppText.body),
          const Spacer(),
          Text(value, style: AppText.bodySmall),
        ],
      ),
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
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brand, width: 2),
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildPlaceholder(),
                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: AppText.labelBold.copyWith(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceSecondary,
      child: const Icon(Icons.person, color: Colors.white54, size: 24),
    );
  }
}

