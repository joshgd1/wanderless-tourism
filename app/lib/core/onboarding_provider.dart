import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'api_client.dart';
import 'auth_provider.dart';
import '../shared/models/tourist.dart';

class OnboardingState {
  final double foodInterest;
  final double cultureInterest;
  final double adventureInterest;
  final double pacePreference;
  final double budgetLevel;
  final List<String> languages;
  final String ageGroup;
  final String travelStyle;
  /// Experience type: 'authentic_local' or 'tourist_friendly'
  final String experienceType;

  OnboardingState({
    this.foodInterest = 0.5,
    this.cultureInterest = 0.5,
    this.adventureInterest = 0.5,
    this.pacePreference = 0.5,
    this.budgetLevel = 0.5,
    this.languages = const ['en'],
    this.ageGroup = '26-35',
    this.travelStyle = 'solo',
    this.experienceType = 'authentic_local',
  });

  OnboardingState copyWith({
    double? foodInterest,
    double? cultureInterest,
    double? adventureInterest,
    double? pacePreference,
    double? budgetLevel,
    List<String>? languages,
    String? ageGroup,
    String? travelStyle,
    String? experienceType,
  }) {
    return OnboardingState(
      foodInterest: foodInterest ?? this.foodInterest,
      cultureInterest: cultureInterest ?? this.cultureInterest,
      adventureInterest: adventureInterest ?? this.adventureInterest,
      pacePreference: pacePreference ?? this.pacePreference,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      languages: languages ?? this.languages,
      ageGroup: ageGroup ?? this.ageGroup,
      travelStyle: travelStyle ?? this.travelStyle,
      experienceType: experienceType ?? this.experienceType,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'food_interest': foodInterest,
      'culture_interest': cultureInterest,
      'adventure_interest': adventureInterest,
      'pace_preference': pacePreference,
      'budget_level': budgetLevel,
      'languages': languages,
      'age_group': ageGroup,
      'travel_style': travelStyle,
      'experience_type': experienceType,
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
  void setLanguages(List<String> v) => state = state.copyWith(languages: v);
  void setAgeGroup(String v) => state = state.copyWith(ageGroup: v);
  void setTravelStyle(String v) => state = state.copyWith(travelStyle: v);
  void setExperienceType(String v) => state = state.copyWith(experienceType: v);

  /// Save preferences — uses updatePreferences if touristId exists (post-registration),
  /// otherwise creates a new anonymous tourist profile.
  Future<String?> savePreferences(String? touristId) async {
    final api = ApiClient();

    if (touristId != null) {
      // Authenticated user — update preferences
      await api.updatePreferences(touristId, state.toApiJson());
      return touristId;
    } else {
      // Anonymous onboarding — create tourist
      final result = await api.createTourist(state.toApiJson());
      return result['id'] as String?;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
