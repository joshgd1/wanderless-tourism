class Tourist {
  final String id;
  final double foodInterest;
  final double cultureInterest;
  final double adventureInterest;
  final double pacePreference;
  final double budgetLevel;
  final String language;
  final String ageGroup;
  final String travelStyle;

  Tourist({
    required this.id,
    required this.foodInterest,
    required this.cultureInterest,
    required this.adventureInterest,
    required this.pacePreference,
    required this.budgetLevel,
    required this.language,
    required this.ageGroup,
    required this.travelStyle,
  });

  factory Tourist.fromJson(Map<String, dynamic> json) {
    return Tourist(
      id: json['id'] as String,
      foodInterest: (json['food_interest'] as num).toDouble(),
      cultureInterest: (json['culture_interest'] as num).toDouble(),
      adventureInterest: (json['adventure_interest'] as num).toDouble(),
      pacePreference: (json['pace_preference'] as num).toDouble(),
      budgetLevel: (json['budget_level'] as num).toDouble(),
      language: json['language'] as String,
      ageGroup: json['age_group'] as String,
      travelStyle: json['travel_style'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'food_interest': foodInterest,
    'culture_interest': cultureInterest,
    'adventure_interest': adventureInterest,
    'pace_preference': pacePreference,
    'budget_level': budgetLevel,
    'language': language,
    'age_group': ageGroup,
    'travel_style': travelStyle,
  };
}
