import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthState {
  final String? token;
  final String? touristId;
  final String? name;
  final String? email;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.touristId,
    this.name,
    this.email,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null && touristId != null;

  AuthState copyWith({
    String? token,
    String? touristId,
    String? name,
    String? email,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      touristId: touristId ?? this.touristId,
      name: name ?? this.name,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadFromStorage();
  }

  static const _tokenKey = 'auth_token';
  static const _touristIdKey = 'tourist_id';
  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final touristId = prefs.getString(_touristIdKey);
    final name = prefs.getString(_nameKey);
    final email = prefs.getString(_emailKey);
    if (token != null && touristId != null) {
      state = AuthState(
        token: token,
        touristId: touristId,
        name: name,
        email: email,
      );
      ApiClient().setAuthToken(token);
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.token != null) {
      await prefs.setString(_tokenKey, state.token!);
      await prefs.setString(_touristIdKey, state.touristId!);
      if (state.name != null) await prefs.setString(_nameKey, state.name!);
      if (state.email != null) await prefs.setString(_emailKey, state.email!);
    } else {
      await prefs.remove(_tokenKey);
      await prefs.remove(_touristIdKey);
      await prefs.remove(_nameKey);
      await prefs.remove(_emailKey);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ApiClient();
      final result = await api.register(email: email, password: password, name: name);
      final token = result['access_token'] as String;
      final touristId = result['tourist_id'] as String;
      final savedName = result['name'] as String;

      state = AuthState(
        token: token,
        touristId: touristId,
        name: savedName,
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

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ApiClient();
      final result = await api.login(email: email, password: password);
      final token = result['access_token'] as String;
      final touristId = result['tourist_id'] as String;
      final savedName = result['name'] as String? ?? 'Tourist';

      state = AuthState(
        token: token,
        touristId: touristId,
        name: savedName,
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
    state = const AuthState();
    ApiClient().clearAuthToken();
    await _saveToStorage();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
