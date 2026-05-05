import 'package:flutter/material.dart';
import '../../design_system.dart';
import '../models/safety_result.dart';

class SafetyScoreCard extends StatefulWidget {
  final SafetyResult safetyResult;
  final VoidCallback? onDismiss;

  const SafetyScoreCard({super.key, required this.safetyResult, this.onDismiss});

  @override
  State<SafetyScoreCard> createState() => _SafetyScoreCardState();
}

class _SafetyScoreCardState extends State<SafetyScoreCard> {
  bool _dismissed = false;

  Color get _scoreColor {
    switch (widget.safetyResult.color) {
      case 'green':
        return AppColors.success;
      case 'amber':
        return AppColors.warning;
      case 'red':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _backgroundColor {
    switch (widget.safetyResult.color) {
      case 'green':
        return AppColors.successBg;
      case 'amber':
        return AppColors.warningBg;
      case 'red':
        return AppColors.errorBg;
      default:
        return AppColors.surfaceSecondary;
    }
  }

  IconData get _icon {
    switch (widget.safetyResult.level) {
      case 'safe':
        return Icons.check_circle_outline;
      case 'caution':
        return Icons.warning_amber_outlined;
      case 'risky':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  String get _levelLabel {
    switch (widget.safetyResult.level) {
      case 'safe':
        return 'Safe';
      case 'caution':
        return 'Caution';
      case 'risky':
        return 'Risky';
      default:
        return widget.safetyResult.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _scoreColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _scoreColor, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'AI Safety',
                style: AppText.labelBold.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _levelLabel,
                  style: AppText.captionBold.copyWith(color: _scoreColor, fontSize: 10),
                ),
              ),
              if (widget.onDismiss != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() => _dismissed = true);
                    widget.onDismiss?.call();
                  },
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.safetyResult.totalScore.toStringAsFixed(0),
                style: AppText.h2.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _scoreColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/100',
                  style: AppText.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: _scoreColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.safetyResult.level == 'safe'
                          ? Icons.check_circle
                          : widget.safetyResult.level == 'caution'
                              ? Icons.warning_amber
                              : Icons.error,
                      size: 12,
                      color: _scoreColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.safetyResult.totalScore.round().toString(),
                      style: AppText.labelBold.copyWith(color: _scoreColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              widget.safetyResult.recommendation,
              style: AppText.caption.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildFactorRow('Area', widget.safetyResult.breakdown['Area']),
          _buildFactorRow('Route', widget.safetyResult.breakdown['Route']),
          _buildFactorRow('Time', widget.safetyResult.breakdown['Time']),
          _buildFactorRow('Transport', widget.safetyResult.breakdown['Transport']),
          _buildFactorRow('Weather', widget.safetyResult.breakdown['Weather']),
          _buildFactorRow('Venue', widget.safetyResult.breakdown['Venue']),
          _buildFactorRow('Traveller Fit', widget.safetyResult.breakdown['TravellerFit']),
        ],
      ),
    );
  }

  Widget _buildFactorRow(String label, SafetyScoreBreakdown? breakdown) {
    if (breakdown == null) return const SizedBox.shrink();
    final pct = breakdown.score / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppText.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(_scoreColor.withOpacity(0.7)),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 24,
            child: Text(
              breakdown.score.toStringAsFixed(0),
              style: AppText.captionBold.copyWith(color: AppColors.textSecondary, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
