import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class BusinessAuthState {
  final String? token;
  final String? businessOwnerId;
  final String? businessName;
  final String? email;
  final bool isLoading;
  final String? error;

  const BusinessAuthState({
    this.token,
    this.businessOwnerId,
    this.businessName,
    this.email,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null && businessOwnerId != null;

  BusinessAuthState copyWith({
    String? token,
    String? businessOwnerId,
    String? businessName,
    String? email,
    bool? isLoading,
    String? error,
  }) {
    return BusinessAuthState(
      token: token ?? this.token,
      businessOwnerId: businessOwnerId ?? this.businessOwnerId,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BusinessAuthNotifier extends StateNotifier<BusinessAuthState> {
  BusinessAuthNotifier() : super(const BusinessAuthState()) {
    _loadFromStorage();
  }

  static const _tokenKey = 'business_token';
  static const _idKey = 'business_owner_id';
  static const _nameKey = 'business_name';
  static const _emailKey = 'business_email';

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final id = prefs.getString(_idKey);
    final name = prefs.getString(_nameKey);
    final email = prefs.getString(_emailKey);
    if (token != null && id != null) {
      state = BusinessAuthState(
        token: token,
        businessOwnerId: id,
        businessName: name,
        email: email,
      );
      ApiClient().setAuthToken(token);
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.token != null) {
      await prefs.setString(_tokenKey, state.token!);
      await prefs.setString(_idKey, state.businessOwnerId!);
      if (state.businessName != null) await prefs.setString(_nameKey, state.businessName!);
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
      final result = await api.businessLogin(email: email, password: password);
      final token = result['access_token'] as String;
      final id = result['business_owner_id'] as String;
      final name = result['business_name'] as String;

      state = BusinessAuthState(
        token: token,
        businessOwnerId: id,
        businessName: name,
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

  Future<bool> register({
    required String email,
    required String password,
    required String businessName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ApiClient();
      final result = await api.businessRegister(
        email: email,
        password: password,
        businessName: businessName,
        phone: phone,
      );
      final token = result['access_token'] as String;
      final id = result['business_owner_id'] as String;

      state = BusinessAuthState(
        token: token,
        businessOwnerId: id,
        businessName: businessName,
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
    state = const BusinessAuthState();
    ApiClient().clearAuthToken();
    await _saveToStorage();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final businessAuthProvider = StateNotifierProvider<BusinessAuthNotifier, BusinessAuthState>((ref) {
  return BusinessAuthNotifier();
});
