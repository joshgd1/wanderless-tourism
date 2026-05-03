class Tourist {
  final String id;
  final String name;
  final String photoUrl;
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
    required this.name,
    required this.photoUrl,
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
    // Handle both 'id' and 'tourist_id' field names from backend
    final id = json['id'] as String? ?? json['tourist_id'] as String? ?? '';
    return Tourist(
      id: id,
      name: json['name'] as String? ?? 'Tourist',
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String? ?? '',
      foodInterest: _toDouble(json['food_interest']),
      cultureInterest: _toDouble(json['culture_interest']),
      adventureInterest: _toDouble(json['adventure_interest']),
      pacePreference: _toDouble(json['pace_preference']),
      budgetLevel: _toDouble(json['budget_level']),
      language: json['language'] as String? ?? 'en',
      ageGroup: json['age_group'] as String? ?? 'Adult',
      travelStyle: json['travel_style'] as String? ?? 'Independent',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.5;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.5;
    return 0.5;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photo_url': photoUrl,
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
