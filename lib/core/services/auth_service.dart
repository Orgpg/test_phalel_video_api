import 'package:dio/dio.dart';
import '../models/auth_response.dart';
import '../models/mobile_user.dart';
import '../network/dio_client.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  Future<AuthResponse> signup({
    required String username,
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/auth/signup',
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MobileUser> getMe() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/users/me');
      return MobileUser.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dioClient.dio.post(
        '/api/mobile/auth/reset-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 409) {
      return 'Username or email already exists';
    }
    if (e.response?.data != null && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }
    return e.message ?? 'An unknown server error occurred';
  }
}
