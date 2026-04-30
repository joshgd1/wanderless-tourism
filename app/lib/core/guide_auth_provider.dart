import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class GuideAuthState {
  final String? token;
  final String? guideId;
  final String? guideName;
  final String? email;
  final bool isLoading;
  final String? error;

  const GuideAuthState({
    this.token,
    this.guideId,
    this.guideName,
    this.email,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null && guideId != null;

  GuideAuthState copyWith({
    String? token,
    String? guideId,
    String? guideName,
    String? email,
    bool? isLoading,
    String? error,
  }) {
    return GuideAuthState(
      token: token ?? this.token,
      guideId: guideId ?? this.guideId,
      guideName: guideName ?? this.guideName,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GuideAuthNotifier extends StateNotifier<GuideAuthState> {
  GuideAuthNotifier() : super(const GuideAuthState()) {
    _loadFromStorage();
  }

  static const _tokenKey = 'guide_token';
  static const _idKey = 'guide_id';
  static const _nameKey = 'guide_name';
  static const _emailKey = 'guide_email';

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final id = prefs.getString(_idKey);
    final name = prefs.getString(_nameKey);
    final email = prefs.getString(_emailKey);
    if (token != null && id != null) {
      state = GuideAuthState(
        token: token,
        guideId: id,
        guideName: name,
        email: email,
      );
      ApiClient().setAuthToken(token);
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.token != null) {
      await prefs.setString(_tokenKey, state.token!);
      await prefs.setString(_idKey, state.guideId!);
      if (state.guideName != null) await prefs.setString(_nameKey, state.guideName!);
      if (state.email != null) await prefs.setString(_emailKey, state.email!);
    } else {
      await prefs.remove(_tokenKey);
      await prefs.remove(_idKey);
      await prefs.remove(_nameKey);
      await prefs.remove(_emailKey);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ApiClient();
      final result = await api.guideLogin(email: email, password: password);
      final token = result['access_token'] as String;
      final id = result['guide_id'] as String;
      final name = result['name'] as String;

      state = GuideAuthState(
        token: token,
        guideId: id,
        guideName: name,
        email: email,
      );
      api.setAuthToken(token);
      await _saveToStorage();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = const GuideAuthState();
    ApiClient().clearAuthToken();
    await _saveToStorage();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final guideAuthProvider = StateNotifierProvider<GuideAuthNotifier, GuideAuthState>((ref) {
  return GuideAuthNotifier();
});
