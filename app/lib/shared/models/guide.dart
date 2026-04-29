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
      ratingHistory: (json['rating_history'] as num).toDouble(),
      ratingCount: json['rating_count'] as int,
      specialties: List<String>.from(json['specialties'] ?? []),
      personalityVector: json['personality_vector'] != null
          ? List<double>.from((json['personality_vector'] as List).map((e) => (e as num).toDouble()))
          : null,
    );
  }
}

class MatchedGuide {
  final String guideId;
  final String name;
  final String photoUrl;
  final String bio;
  final List<String> expertiseTags;
  final double ratingHistory;
  final int ratingCount;
  final String budgetTier;
  final double score;
  final bool langMatch;

  MatchedGuide({
    required this.guideId,
    required this.name,
    required this.photoUrl,
    required this.bio,
    required this.expertiseTags,
    required this.ratingHistory,
    required this.ratingCount,
    required this.budgetTier,
    required this.score,
    required this.langMatch,
  });

  factory MatchedGuide.fromJson(Map<String, dynamic> json) {
    return MatchedGuide(
      guideId: json['guide_id'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String,
      bio: json['bio'] as String,
      expertiseTags: List<String>.from(json['expertise_tags'] ?? []),
      ratingHistory: (json['rating_history'] as num).toDouble(),
      ratingCount: json['rating_count'] as int,
      budgetTier: json['budget_tier'] as String,
      score: (json['score'] as num).toDouble(),
      langMatch: json['lang_match'] as bool,
    );
  }
}
