import 'package:flutter/material.dart';
import '../../design_system.dart';
import '../models/safety_result.dart';

/// Shows the safety scorecard as a centered modal dialog with animation.
Future<void> showSafetyScoreDialog(
  BuildContext context,
  SafetyResult safetyResult,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss safety score',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => _SafetyScoreModal(safetyResult: safetyResult),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return ScaleTransition(scale: animation.drive(CurveTween(curve: Curves.easeOutBack)), child: child);
    },
  );
}

class _SafetyScoreModal extends StatelessWidget {
  final SafetyResult safetyResult;

  const _SafetyScoreModal({required this.safetyResult});

  Color get _scoreColor {
    switch (safetyResult.color) {
      case 'green': return AppColors.success;
      case 'amber': return AppColors.warning;
      case 'red': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Color get _bgColor {
    switch (safetyResult.color) {
      case 'green': return AppColors.successBg;
      case 'amber': return AppColors.warningBg;
      case 'red': return AppColors.errorBg;
      default: return AppColors.surfaceSecondary;
    }
  }

  String get _message {
    final score = safetyResult.totalScore;
    if (score >= 75) {
      return 'Great news! This destination is very safe for your trip. Enjoy your journey! ✈️';
    } else if (score >= 45) {
      return 'This destination is moderately safe. Take some precautions and stay aware. 🧭';
    } else {
      return 'This destination has some safety concerns. Please plan carefully and stay safe. ⚠️';
    }
  }

  String get _levelLabel {
    switch (safetyResult.level) {
      case 'safe': return '🟢 Safe';
      case 'caution': return '🟠 Caution';
      case 'risky': return '🔴 Risky';
      default: return safetyResult.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Text(_levelLabel, style: AppText.labelBold),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Score ring — compact
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: safetyResult.totalScore / 100,
                              strokeWidth: 8,
                              backgroundColor: _scoreColor.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(_scoreColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                safetyResult.totalScore.round().toString(),
                                style: AppText.h1.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _scoreColor,
                                  height: 1,
                                ),
                              ),
                              Text('/100', style: AppText.caption),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Personalized message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _message,
                        style: AppText.bodySmall.copyWith(height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Compact factor bars
                    ..._buildFactorBars(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recommendation footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Text(
                  safetyResult.recommendation,
                  style: AppText.caption.copyWith(color: _scoreColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFactorBars() {
    final entries = safetyResult.breakdown.entries.toList();
    return entries.map((entry) {
      final pct = entry.value.score / 100;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                entry.key,
                style: AppText.caption.copyWith(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: _scoreColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(_scoreColor.withOpacity(0.7)),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 26,
              child: Text(
                entry.value.score.round().toString(),
                style: AppText.captionBold.copyWith(fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Legacy inline SafetyScoreCard — redirects to modal when tapped.
class SafetyScoreCard extends StatelessWidget {
  final SafetyResult safetyResult;
  final VoidCallback? onDismiss;

  const SafetyScoreCard({super.key, required this.safetyResult, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showSafetyScoreDialog(context, safetyResult),
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor(safetyResult),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _color(safetyResult).withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon(safetyResult), color: _color(safetyResult), size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text('AI Safety', style: AppText.labelBold),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _color(safetyResult).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(_levelLabel(safetyResult),
                    style: AppText.captionBold.copyWith(color: _color(safetyResult), fontSize: 10),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  safetyResult.totalScore.round().toString(),
                  style: AppText.h2.copyWith(fontSize: 32, fontWeight: FontWeight.bold,
                      color: _color(safetyResult), height: 1),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('/100', style: AppText.caption),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              safetyResult.recommendation,
              style: AppText.caption, maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _color(SafetyResult r) {
    switch (r.color) {
      case 'green': return AppColors.success;
      case 'amber': return AppColors.warning;
      case 'red': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Color _bgColor(SafetyResult r) {
    switch (r.color) {
      case 'green': return AppColors.successBg;
      case 'amber': return AppColors.warningBg;
      case 'red': return AppColors.errorBg;
      default: return AppColors.surfaceSecondary;
    }
  }

  IconData _icon(SafetyResult r) {
    switch (r.level) {
      case 'safe': return Icons.check_circle_outline;
      case 'caution': return Icons.warning_amber_outlined;
      case 'risky': return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }

  String _levelLabel(SafetyResult r) {
    switch (r.level) {
      case 'safe': return 'Safe';
      case 'caution': return 'Caution';
      case 'risky': return 'Risky';
      default: return r.label;
    }
  }
}
