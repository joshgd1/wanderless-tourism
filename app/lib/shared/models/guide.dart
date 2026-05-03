class Guide {
  final String id;
  final String name;
  final String bio;
  final String photoUrl;
  final List<String> expertiseTags;
  final List<String> languagePairs;
  final double paceStyle;
  final int groupSizePreferred;
  final String budgetTier;
  final List<String> locationCoverage;
  final double ratingHistory;
  final int ratingCount;
  final List<String> specialties;
  final List<double>? personalityVector;
  final bool licenseVerified;

  Guide({
    required this.id,
    required this.name,
    required this.bio,
    required this.photoUrl,
    required this.expertiseTags,
    required this.languagePairs,
    required this.paceStyle,
    required this.groupSizePreferred,
    required this.budgetTier,
    required this.locationCoverage,
    required this.ratingHistory,
    required this.ratingCount,
    required this.specialties,
    this.personalityVector,
    this.licenseVerified = false,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String,
      photoUrl: json['photo_url'] as String,
      expertiseTags: List<String>.from(json['expertise_tags'] ?? []),
      languagePairs: List<String>.from(json['language_pairs'] ?? []),
      paceStyle: (json['pace_style'] as num).toDouble(),
      groupSizePreferred: json['group_size_preferred'] as int,
      budgetTier: json['budget_tier'] as String,
      locationCoverage: List<String>.from(json['location_coverage'] ?? []),
      ratingHistory: (json['rating'] as num).toDouble(),
      ratingCount: json['review_count'] as int,
      specialties: List<String>.from(json['specialties'] ?? []),
      personalityVector: json['personality_vector'] != null
          ? List<double>.from((json['personality_vector'] as List).map((e) => (e as num).toDouble()))
          : null,
      licenseVerified: json['license_verified'] as bool? ?? false,
    );
  }
}

class MatchedGuide {
  final String guideId;
  final String name;
  final String photoUrl;
  final String bio;
  final List<String> expertiseTags;
  final List<String> languagePairs;
  final List<String> locationCoverage;
  final double ratingHistory;
  final int ratingCount;
  final String budgetTier;
  final bool licenseVerified;
  final double score;
  final bool langMatch;

  // ML-specific fields (present when using /api/recommendations/{tid}/guides)
  final double? scoreContent;
  final double? scoreCollab;
  final double? scoreDest;
  final String? mlExplanation;

  MatchedGuide({
    required this.guideId,
    required this.name,
    required this.photoUrl,
    required this.bio,
    required this.expertiseTags,
    required this.languagePairs,
    required this.locationCoverage,
    required this.ratingHistory,
    required this.ratingCount,
    required this.budgetTier,
    required this.licenseVerified,
    required this.score,
    required this.langMatch,
    this.scoreContent,
    this.scoreCollab,
    this.scoreDest,
    this.mlExplanation,
  });

  factory MatchedGuide.fromJson(Map<String, dynamic> json) {
    return MatchedGuide(
      guideId: json['guide_id'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String,
      bio: json['bio'] as String,
      expertiseTags: List<String>.from(json['expertise_tags'] ?? []),
      languagePairs: List<String>.from(json['language_pairs'] ?? []),
      locationCoverage: List<String>.from(json['location_coverage'] ?? []),
      ratingHistory: (json['rating'] as num).toDouble(),
      ratingCount: json['review_count'] as int,
      budgetTier: json['budget_tier'] as String,
      licenseVerified: json['license_verified'] as bool? ?? false,
      score: (json['score'] as num).toDouble(),
      langMatch: json['lang_match'] as bool? ?? false,
      scoreContent: json['score_content'] != null
          ? (json['score_content'] as num).toDouble()
          : null,
      scoreCollab: json['score_collab'] != null
          ? (json['score_collab'] as num).toDouble()
          : null,
      scoreDest: json['score_dest'] != null
          ? (json['score_dest'] as num).toDouble()
          : null,
      mlExplanation: json['ml_explanation'] as String?,
    );
  }
}
