import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/mobile_user.dart';
import '../models/user_preference.dart';
import '../models/user_verification.dart';
import '../services/auth_service.dart';
import '../services/preference_service.dart';
import '../services/verification_service.dart';

enum AuthState { 
  initial, 
  loading, 
  authenticated, 
  unauthenticated, 
  signupVerificationRequired,
  forgotPasswordCodeRequired,
  error 
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final PreferenceService _preferenceService;
  final VerificationService _verificationService;
  final _storage = const FlutterSecureStorage();

  MobileUser? _user;
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  
  // For verification flow
  String? _verificationEmail;
  DateTime? _verificationExpiresAt;

  AuthProvider(
    this._authService,
    this._preferenceService,
    this._verificationService,
  );

  MobileUser? get user => _user;
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get verificationEmail => _verificationEmail;
  DateTime? get verificationExpiresAt => _verificationExpiresAt;

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
      await refreshUser();
      _state = AuthState.authenticated;
    } catch (e) {
      final error = e.toString();
      if (error.contains('Email verification is required')) {
        _verificationEmail = email;
        _state = AuthState.signupVerificationRequired;
      } else {
        _state = AuthState.unauthenticated;
        _errorMessage = error;
      }
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
      );
      
      _verificationEmail = response['email'] ?? email;
      if (response['expiresAt'] != null) {
        _verificationExpiresAt = DateTime.parse(response['expiresAt']);
      }
      
      _state = AuthState.signupVerificationRequired;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> verifyEmail(String code) async {
    if (_verificationEmail == null) return;
    
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.verifyEmail(
        email: _verificationEmail!,
        code: code,
      );
      await _storage.write(key: 'auth_token', value: response.token);
      await refreshUser();
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.signupVerificationRequired;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> resendVerificationCode() async {
    if (_verificationEmail == null) return;
    
    try {
      final response = await _authService.resendVerificationCode(_verificationEmail!);
      if (response['expiresAt'] != null) {
        _verificationExpiresAt = DateTime.parse(response['expiresAt']);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> requestForgotPasswordCode(String email) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.requestForgotPasswordCode(email);
      _verificationEmail = email;
      _state = AuthState.forgotPasswordCodeRequired;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> confirmForgotPassword(String code, String newPassword) async {
    if (_verificationEmail == null) return;
    
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.confirmForgotPassword(
        email: _verificationEmail!,
        code: code,
        newPassword: newPassword,
      );
      await _storage.write(key: 'auth_token', value: response.token);
      await refreshUser();
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.forgotPasswordCodeRequired;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _user = null;
    _state = AuthState.unauthenticated;
    _verificationEmail = null;
    _verificationExpiresAt = null;
    notifyListeners();
  }

  Future<void> savePreference(UserPreference preference) async {
    try {
      await _preferenceService.savePreference(preference);
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
