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
                    Material(
                      color: Colors.white.withOpacity(0.15),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                        ),
                      ),
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

