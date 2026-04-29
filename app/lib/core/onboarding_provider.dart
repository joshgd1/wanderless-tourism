import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../shared/models/tourist.dart';

class OnboardingState {
  final double foodInterest;
  final double cultureInterest;
  final double adventureInterest;
  final double pacePreference;
  final double budgetLevel;
  final String language;
  final String ageGroup;
  final String travelStyle;

  OnboardingState({
    this.foodInterest = 0.5,
    this.cultureInterest = 0.5,
    this.adventureInterest = 0.5,
    this.pacePreference = 0.5,
    this.budgetLevel = 0.5,
    this.language = 'en',
    this.ageGroup = '26-35',
    this.travelStyle = 'solo',
  });

  OnboardingState copyWith({
    double? foodInterest,
    double? cultureInterest,
    double? adventureInterest,
    double? pacePreference,
    double? budgetLevel,
    String? language,
    String? ageGroup,
    String? travelStyle,
  }) {
    return OnboardingState(
      foodInterest: foodInterest ?? this.foodInterest,
      cultureInterest: cultureInterest ?? this.cultureInterest,
      adventureInterest: adventureInterest ?? this.adventureInterest,
      pacePreference: pacePreference ?? this.pacePreference,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      language: language ?? this.language,
      ageGroup: ageGroup ?? this.ageGroup,
      travelStyle: travelStyle ?? this.travelStyle,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
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
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void setFoodInterest(double v) => state = state.copyWith(foodInterest: v);
  void setCultureInterest(double v) => state = state.copyWith(cultureInterest: v);
  void setAdventureInterest(double v) => state = state.copyWith(adventureInterest: v);
  void setPacePreference(double v) => state = state.copyWith(pacePreference: v);
  void setBudgetLevel(double v) => state = state.copyWith(budgetLevel: v);
  void setLanguage(String v) => state = state.copyWith(language: v);
  void setAgeGroup(String v) => state = state.copyWith(ageGroup: v);
  void setTravelStyle(String v) => state = state.copyWith(travelStyle: v);

  Future<String> createTourist() async {
    final api = ApiClient();
    final result = await api.createTourist(state.toApiJson());
    final touristId = result['id'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tourist_id', touristId);
    return touristId;
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

final touristIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('tourist_id');
});
