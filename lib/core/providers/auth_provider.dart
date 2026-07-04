import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/mobile_user.dart';
import '../models/user_preference.dart';
import '../models/user_verification.dart';
import '../repositories/auth_repository.dart';
import '../repositories/preference_repository.dart';
import '../repositories/verification_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final PreferenceRepository _preferenceRepository;
  final VerificationRepository _verificationRepository;
  final _storage = const FlutterSecureStorage();

  MobileUser? _user;
  AuthState _state = AuthState.initial;
  String? _errorMessage;

  AuthProvider(
    this._authRepository,
    this._preferenceRepository,
    this._verificationRepository,
  );

  MobileUser? get user => _user;
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> initialize() async {
    if (_state == AuthState.loading) return; // Prevent multiple simultaneous calls
    
    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _state = AuthState.unauthenticated;
      } else {
        _user = await _authRepository.getMe();
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

  /// Refreshes the user data without triggering the global loading state
  Future<void> refreshUser() async {
    try {
      _user = await _authRepository.getMe();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('401')) {
        await logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(email: email, password: password);
      await _storage.write(key: 'auth_token', value: response.token);
      _user = response.user;
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> signup(String username, String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.signup(
        username: username,
        email: email,
        password: password,
      );
      await _storage.write(key: 'auth_token', value: response.token);
      _user = response.user;
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
      final updatedPref = await _preferenceRepository.savePreference(preference);
      if (_user != null) {
        _user = _user!.copyWith(preference: updatedPref);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitVerification(UserVerification verification) async {
    try {
      await _verificationRepository.submitVerification(verification);
      // After submission, fetch user again to get the PENDING status
      await refreshUser();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
