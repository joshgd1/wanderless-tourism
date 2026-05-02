import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api_client.dart';
import '../../../../shared/models/guide.dart';
import '../../../../design_system.dart';

final guideDetailProvider = FutureProvider.family<Guide, String>((ref, guideId) async {
  final api = ApiClient();
  final data = await api.getGuide(guideId);
  return Guide.fromJson(data);
});

class GuideDetailScreen extends ConsumerWidget {
  final String guideId;

  const GuideDetailScreen({super.key, required this.guideId});

  static int _uniqueLanguages(List<String> pairs) {
    final langs = <String>{};
    for (final lp in pairs) {
      final parts = lp.split('→');
      if (parts.isNotEmpty) langs.add(parts[0].trim());
    }
    return langs.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(guideDetailProvider(guideId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: guideAsync.when(
        loading: () => const AppLoading(message: 'Loading guide...'),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load guide',
          subtitle: e.toString(),
        ),
        data: (guide) => _buildContent(context, guide),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Guide guide) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.textPrimary,
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: guide.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.textSecondary),
                  errorWidget: (_, __, ___) => Container(color: AppColors.textSecondary),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: _FloatingBackButton(onTap: () => context.pop()),
                ),
                Positioned(
                  left: 16,
                  top: MediaQuery.of(context).padding.top + 60,
                  child: _GuideFloatingCard(guide: guide),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.translate,
                        color: AppColors.success,
                        title: 'Languages',
                        value: guide.languagePairs.isNotEmpty
                            ? '${_uniqueLanguages(guide.languagePairs)}'
                            : '1',
                        subtitle: 'languages',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.group,
                        color: AppColors.info,
                        title: 'Max Group',
                        value: '${guide.groupSizePreferred}',
                        subtitle: 'people',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.account_balance_wallet,
                        color: Colors.orange,
                        title: 'Budget',
                        value: guide.budgetTier[0].toUpperCase(),
                        subtitle: guide.budgetTier.substring(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(label: 'About', icon: Icons.person_outline),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Text(guide.bio, style: AppText.body.copyWith(height: 1.6)),
                ),
                if (guide.expertiseTags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(label: 'Expertise', icon: Icons.star_outline),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: guide.expertiseTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          tag,
                          style: AppText.label.copyWith(color: AppColors.brand),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (guide.locationCoverage.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(label: 'Locations', icon: Icons.place_outlined),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: guide.locationCoverage.map((loc) {
                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(loc, style: AppText.label),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (guide.languagePairs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(label: 'Languages Offered', icon: Icons.translate),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: guide.languagePairs.map((lp) {
                      final langs = lp.split('→');
                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.translate, size: 14, color: AppColors.success),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              langs.length >= 2
                                  ? '${langs[0].trim()} → ${langs[1].trim()}'
                                  : lp,
                              style: AppText.label,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BookNowBar(guideId: guide.id),
        ),
      ],
    );
  }
}

class _BookNowBar extends StatelessWidget {
  final String guideId;
  const _BookNowBar({required this.guideId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Starting from', style: AppText.caption),
                Text(
                  '\$45 / person',
                  style: AppText.h3.copyWith(color: AppColors.brand),
                ),
              ],
            ),
          ),
          PrimaryButton(
            label: 'Book Now',
            icon: Icons.calendar_today,
            onPressed: () => context.push('/book/$guideId'),
          ),
        ],
      ),
    );
  }
}

class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GuideFloatingCard extends StatelessWidget {
  final Guide guide;

  const _GuideFloatingCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: guide.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.textSecondary),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.textSecondary,
                  child: const Icon(Icons.person, color: Colors.white54, size: 36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(guide.name, style: AppText.h3.copyWith(color: Colors.white)),
                  if (guide.licenseVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 11, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ...List.generate(guide.ratingHistory.floor(), (i) {
                    return const Icon(Icons.star, size: 15, color: Colors.amber);
                  }),
                  if (guide.ratingHistory % 1 >= 0.5)
                    const Icon(Icons.star_half, size: 15, color: Colors.amber),
                  ...List.generate(5 - guide.ratingHistory.ceil(), (i) {
                    return const Icon(Icons.star_border, size: 15, color: Colors.white54);
                  }),
                  const SizedBox(width: 6),
                  Text(
                    '${guide.ratingHistory.toStringAsFixed(1)} (${guide.ratingCount})',
                    style: AppText.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: 6),
        Text(label, style: AppText.h3),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppText.h2.copyWith(color: color)),
          Text(subtitle, style: AppText.caption),
        ],
      ),
    );
  }
}
