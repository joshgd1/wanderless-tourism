import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // JWT token stored in encrypted secure storage; rest in SharedPreferences
    final token = await _secure.read(key: _tokenKey);
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
      // Set on the singleton so cold-start guide API calls use the restored token.
      ApiClient().setAuthToken(token);
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.token != null) {
      // JWT token stored in encrypted secure storage
      await _secure.write(key: _tokenKey, value: state.token!);
      await prefs.setString(_idKey, state.guideId!);
      if (state.guideName != null) await prefs.setString(_nameKey, state.guideName!);
      if (state.email != null) await prefs.setString(_emailKey, state.email!);
    } else {
      await _secure.delete(key: _tokenKey);
      await prefs.remove(_idKey);
      await prefs.remove(_nameKey);
      await prefs.remove(_emailKey);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Use the ApiClient singleton so _authToken static is set — not a local var.
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
      // Set on the singleton so all subsequent guide API calls use this token.
      ApiClient().setAuthToken(token);
      await _saveToStorage();
      return true;
    } catch (e) {
      String msg = e.toString();
      if (msg.toLowerCase().contains('connection') || msg.toLowerCase().contains('network')) {
        msg = 'Cannot connect to server. Check your internet connection.';
      } else if (msg.contains('DioException')) {
        if (msg.contains('401') || msg.toLowerCase().contains('unauthorized')) {
          msg = 'Invalid email or password.';
        } else if (msg.contains('404')) {
          msg = 'Server not found. Please try again later.';
        } else if (msg.contains('SocketException') || msg.contains('connection')) {
          msg = 'Cannot connect to server. Check your internet connection.';
        } else if (msg.contains('connection timeout') || msg.contains('receive timeout')) {
          msg = 'Connection timed out. Please try again.';
        } else {
          msg = 'Login failed. Please try again.';
        }
      }
      state = state.copyWith(isLoading: false, error: msg);
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
