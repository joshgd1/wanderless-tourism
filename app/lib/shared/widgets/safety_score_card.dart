import 'package:flutter/material.dart';
import '../../design_system.dart';
import '../models/safety_result.dart';

class SafetyScoreCard extends StatelessWidget {
  final SafetyResult safetyResult;

  const SafetyScoreCard({super.key, required this.safetyResult});

  Color get _scoreColor {
    switch (safetyResult.color) {
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
    switch (safetyResult.color) {
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
    switch (safetyResult.level) {
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
    switch (safetyResult.level) {
      case 'safe':
        return 'Safe';
      case 'caution':
        return 'Caution';
      case 'risky':
        return 'Risky';
      default:
        return safetyResult.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _scoreColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _scoreColor, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'AI Safety Score',
                style: AppText.h3.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _levelLabel,
                  style: AppText.labelBold.copyWith(color: _scoreColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              safetyResult.totalScore.toStringAsFixed(0),
              style: AppText.display.copyWith(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: _scoreColor,
                height: 1,
              ),
            ),
          ),
          Center(
            child: Text(
              'out of 100',
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              safetyResult.recommendation,
              style: AppText.body.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFactorRow('Area', safetyResult.breakdown['Area']),
          _buildFactorRow('Route', safetyResult.breakdown['Route']),
          _buildFactorRow('Time', safetyResult.breakdown['Time']),
          _buildFactorRow('Transport', safetyResult.breakdown['Transport']),
          _buildFactorRow('Weather', safetyResult.breakdown['Weather']),
          _buildFactorRow('Venue', safetyResult.breakdown['Venue']),
          _buildFactorRow('Traveller Fit', safetyResult.breakdown['TravellerFit']),
        ],
      ),
    );
  }

  Widget _buildFactorRow(String label, SafetyScoreBreakdown? breakdown) {
    if (breakdown == null) return const SizedBox.shrink();
    final pct = breakdown.score / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(_scoreColor.withOpacity(0.7)),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 32,
            child: Text(
              breakdown.score.toStringAsFixed(0),
              style: AppText.captionBold.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
