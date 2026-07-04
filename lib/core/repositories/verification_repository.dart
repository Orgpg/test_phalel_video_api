import 'package:dio/dio.dart';
import '../models/user_verification.dart';
import '../network/dio_client.dart';

class VerificationRepository {
  final DioClient _dioClient;

  VerificationRepository(this._dioClient);

  Future<UserVerification?> getVerification() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/users/me/verification');
      if (response.data == null || response.data['verification'] == null) return null;
      return UserVerification.fromJson(response.data['verification']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitVerification(UserVerification verification) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/users/me/verification',
        data: verification.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }
    return e.message ?? 'An unknown error occurred';
  }
}
