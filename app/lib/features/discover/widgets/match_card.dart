import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/guide.dart';
import '../../../../design_system.dart';

class MatchCard extends StatelessWidget {
  final MatchedGuide guide;
  final VoidCallback onTap;

  const MatchCard({super.key, required this.guide, required this.onTap});

  Color _avatarColor(String name) {
    final colors = [
      AppColors.brand,
      AppColors.success,
      AppColors.info,
      Colors.purple,
      Colors.teal,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get _isMl => guide.mlExplanation != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Larger avatar with colored ring
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isMl ? AppColors.info : AppColors.brand,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isMl ? AppColors.info : AppColors.brand).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: guide.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _InitialsAvatar(
                        name: guide.name,
                        color: _avatarColor(guide.name),
                      ),
                      errorWidget: (_, __, ___) => _InitialsAvatar(
                        name: guide.name,
                        color: _avatarColor(guide.name),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          CountryFlags.fromName(guide.name),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(guide.name, style: AppText.labelBold),
                        ),
                        if (guide.licenseVerified) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text('Verified', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Stars + rating
                    Row(
                      children: [
                        ...List.generate(guide.ratingHistory.floor(), (i) {
                          return Icon(Icons.star, size: 16, color: Colors.amber[700]);
                        }),
                        if (guide.ratingHistory % 1 >= 0.5)
                          Icon(Icons.star_half, size: 16, color: Colors.amber[700]),
                        ...List.generate(5 - guide.ratingHistory.ceil(), (i) {
                          return Icon(Icons.star_border, size: 16, color: AppColors.border);
                        }),
                        const SizedBox(width: 6),
                        Text(
                          '${guide.ratingHistory.toStringAsFixed(1)}',
                          style: AppText.labelBold.copyWith(color: Colors.amber[700]),
                        ),
                        Text(
                          ' (${guide.ratingCount})',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.translate, size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            guide.languagePairs.take(2).map((l) {
                              final parts = l.split('→');
                              return parts.length >= 2
                                  ? '${parts[0].trim()} → ${parts[1].trim()}'
                                  : l;
                            }).join(', '),
                            style: AppText.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on, size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(
                          guide.locationCoverage.isNotEmpty
                              ? guide.locationCoverage.first
                              : 'Singapore',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            guide.bio,
            style: AppText.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (guide.expertiseTags.isNotEmpty
                    ? guide.expertiseTags
                    : ['Cultural', 'History', 'Nature'])
                .take(3)
                .map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  tag,
                  style: AppText.caption.copyWith(color: AppColors.brand),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                _ScoreBadge(
                  score: guide.score,
                  isMl: _isMl,
                  scoreContent: guide.scoreContent,
                  scoreCollab: guide.scoreCollab,
                  scoreDest: guide.scoreDest,
                  mlExplanation: guide.mlExplanation,
                ),
                const SizedBox(width: 8),
                _BudgetBadge(tier: guide.budgetTier),
                const Spacer(),
                PrimaryButton(
                  label: 'View Profile',
                  icon: Icons.arrow_forward,
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text, style: AppText.caption, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final bool isMl;
  final double? scoreContent;
  final double? scoreCollab;
  final double? scoreDest;
  final String? mlExplanation;

  const _ScoreBadge({
    required this.score,
    this.isMl = false,
    this.scoreContent,
    this.scoreCollab,
    this.scoreDest,
    this.mlExplanation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMlBreakdown(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isMl ? AppColors.info.withOpacity(0.1) : AppColors.brand.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMl ? Icons.auto_awesome : Icons.favorite,
              size: 14,
              color: isMl ? AppColors.info : AppColors.brand,
            ),
            const SizedBox(width: 4),
            Text(
              isMl ? 'ML ${(score * 100).toInt()}%' : score.toStringAsFixed(1),
              style: AppText.labelBold.copyWith(
                color: isMl ? AppColors.info : AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMlBreakdown(BuildContext context) {
    if (!isMl) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text('ML Score Breakdown', style: AppText.h3),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ScoreRow('Overall Score', '${(score * 100).toInt()}%', isBold: true, valueColor: AppColors.info),
            if (scoreContent != null)
              _ScoreRow('Content Match', '${(scoreContent! * 100).toInt()}%', subtitle: 'Preference similarity'),
            if (scoreCollab != null)
              _ScoreRow('Collaborative', '${(scoreCollab! * 100).toInt()}%', subtitle: 'Rating pattern learning'),
            if (scoreDest != null && scoreDest! > 0)
              _ScoreRow('Destination Fit', '${(scoreDest! * 100).toInt()}%', subtitle: 'Location bonus'),
            if (mlExplanation != null) ...[
              const Divider(height: AppSpacing.lg),
              Text(mlExplanation!, style: AppText.bodySmall.copyWith(height: 1.5)),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final bool isBold;
  final Color? valueColor;

  const _ScoreRow(this.label, this.value, {this.subtitle, this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: isBold ? AppText.labelBold : AppText.label),
              if (subtitle != null) Text(subtitle!, style: AppText.caption),
            ],
          ),
          Text(
            value,
            style: AppText.labelBold.copyWith(color: valueColor ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _BudgetBadge extends StatelessWidget {
  final String tier;
  const _BudgetBadge({required this.tier});

  String get label {
    switch (tier) {
      case 'budget':
        return 'Budget';
      case 'mid':
        return 'Mid-range';
      case 'premium':
        return 'Premium';
      default:
        return tier;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: AppText.caption),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final Color color;

  const _InitialsAvatar({required this.name, required this.color});

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
