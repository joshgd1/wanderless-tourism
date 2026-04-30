import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/guide.dart';

class MatchCard extends StatelessWidget {
  final MatchedGuide guide;
  final VoidCallback onTap;

  const MatchCard({super.key, required this.guide, required this.onTap});

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF25D366), const Color(0xFF1A2E1A),
      const Color(0xFF128C7E), const Color(0xFF2D6A4F),
      const Color(0xFF40916C), const Color(0xFF52B788),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isMl ? const Color(0xFF6B4EFF) : const Color(0xFF25D366),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isMl ? const Color(0xFF6B4EFF) : const Color(0xFF25D366))
                              .withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                guide.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (guide.licenseVerified) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'License verified',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 13, color: Color(0xFF25D366)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF25D366),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(guide.ratingHistory.floor(), (i) {
                              return Icon(Icons.star, size: 16, color: Colors.amber[700]);
                            }),
                            if (guide.ratingHistory % 1 >= 0.5)
                              Icon(Icons.star_half, size: 16, color: Colors.amber[700]),
                            ...List.generate(5 - guide.ratingHistory.ceil(), (i) {
                              return Icon(Icons.star_border, size: 16, color: Colors.grey[400]);
                            }),
                            const SizedBox(width: 4),
                            Text(
                              '${guide.ratingHistory.toStringAsFixed(1)} (${guide.ratingCount})',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.translate, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                guide.languagePairs.take(2).map((l) {
                                  final parts = l.split('→');
                                  return parts.length >= 2
                                      ? '${parts[0].trim()} → ${parts[1].trim()}'
                                      : l;
                                }).join(', '),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                guide.locationCoverage.isNotEmpty
                                    ? guide.locationCoverage.first
                                    : 'Chiang Mai',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                guide.bio,
                style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (guide.expertiseTags.isNotEmpty
                        ? guide.expertiseTags
                        : ['Cultural', 'History', 'Nature'])
                    .take(3)
                    .map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF25D366),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ScoreBadge(
                    score: guide.score,
                    isMl: _isMl,
                    scoreContent: guide.scoreContent,
                    scoreCollab: guide.scoreCollab,
                    scoreDest: guide.scoreDest,
                  ),
                  const SizedBox(width: 12),
                  _BudgetBadge(tier: guide.budgetTier),
                  const Spacer(),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final bool isMl;
  final double? scoreContent;
  final double? scoreCollab;
  final double? scoreDest;

  const _ScoreBadge({
    required this.score,
    this.isMl = false,
    this.scoreContent,
    this.scoreCollab,
    this.scoreDest,
  });

  @override
  Widget build(BuildContext context) {
    if (isMl) {
      return GestureDetector(
        onTap: () => _showMlBreakdown(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4EFF), Color(0xFF25D366)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'ML ${(score * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 14, color: Color(0xFF25D366)),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFF25D366),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showMlBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF6B4EFF), size: 20),
                SizedBox(width: 8),
                Text(
                  'ML Score Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ScoreRow('Overall Score', '${(score * 100).toInt()}%', isBold: true),
            if (scoreContent != null)
              _ScoreRow('Content Match', '${(scoreContent! * 100).toInt()}%',
                  subtitle: 'Preference similarity'),
            if (scoreCollab != null)
              _ScoreRow('Collaborative', '${(scoreCollab! * 100).toInt()}%',
                  subtitle: 'Rating pattern learning'),
            if (scoreDest != null && scoreDest! > 0)
              _ScoreRow('Destination Fit', '${(scoreDest! * 100).toInt()}%',
                  subtitle: 'Location bonus'),
            if (guide.mlExplanation != null) ...[
              const Divider(height: 24),
              Text(
                guide.mlExplanation!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
              ),
            ],
            const SizedBox(height: 8),
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

  const _ScoreRow(this.label, this.value, {this.subtitle, this.isBold = false});

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
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? const Color(0xFF6B4EFF) : Colors.black87,
            ),
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
