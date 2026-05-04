class SafetyScoreBreakdown {
  final double score;
  final double weight;
  final double contribution;

  SafetyScoreBreakdown({
    required this.score,
    required this.weight,
    required this.contribution,
  });

  factory SafetyScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return SafetyScoreBreakdown(
      score: (json['score'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      contribution: (json['contribution'] as num).toDouble(),
    );
  }
}

class SafetyResult {
  final double totalScore;
  final String label;
  final String level;
  final String color;
  final Map<String, SafetyScoreBreakdown> breakdown;
  final String recommendation;

  SafetyResult({
    required this.totalScore,
    required this.label,
    required this.level,
    required this.color,
    required this.breakdown,
    required this.recommendation,
  });

  factory SafetyResult.fromJson(Map<String, dynamic> json) {
    final breakdownMap = <String, SafetyScoreBreakdown>{};
    final rawBreakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    for (final entry in rawBreakdown.entries) {
      breakdownMap[entry.key] = SafetyScoreBreakdown.fromJson(entry.value as Map<String, dynamic>);
    }
    return SafetyResult(
      totalScore: (json['total_score'] as num).toDouble(),
      label: json['label'] as String,
      level: json['level'] as String,
      color: json['color'] as String,
      breakdown: breakdownMap,
      recommendation: json['recommendation'] as String,
    );
  }
}
