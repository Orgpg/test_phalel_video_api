import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/mobile_user.dart';
import '../models/user_preference.dart';
import '../models/user_verification.dart';
import '../services/auth_service.dart';
import '../services/preference_service.dart';
import '../services/verification_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final PreferenceService _preferenceService;
  final VerificationService _verificationService;
  final _storage = const FlutterSecureStorage();

  MobileUser? _user;
  AuthState _state = AuthState.initial;
  String? _errorMessage;

  AuthProvider(
    this._authService,
    this._preferenceService,
    this._verificationService,
  );

  MobileUser? get user => _user;
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> initialize() async {
    if (_state == AuthState.loading) return;
    
    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _state = AuthState.unauthenticated;
      } else {
        await refreshUser();
        _state = AuthState.authenticated;
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        await logout();
      } else {
        _state = AuthState.error;
        _errorMessage = e.toString();
      }
    }
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _user = await _authService.getMe();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('401')) {
        await logout();
      } else {
        rethrow;
      }
    }
  }

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email: email, password: password);
      await _storage.write(key: 'auth_token', value: response.token);
      // Requirement: After login success, call GET /api/mobile/users/me
      await refreshUser();
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> signup(String username, String email, String password, {String? name}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signup(
        username: username,
        email: email,
        password: password,
        name: name,
      );
      await _storage.write(key: 'auth_token', value: response.token);
      // Requirement: After signup success, call GET /api/mobile/users/me
      await refreshUser();
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> savePreference(UserPreference preference) async {
    try {
      final updatedPref = await _preferenceService.savePreference(preference);
      // Refresh user to get the latest data structure from server
      await refreshUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitVerification(UserVerification verification) async {
    try {
      await _verificationService.submitVerification(verification);
      await refreshUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.resetPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }
}
