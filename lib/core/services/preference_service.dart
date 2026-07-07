import 'package:dio/dio.dart';
import '../models/user_preference.dart';
import '../network/dio_client.dart';

class PreferenceService {
  final DioClient _dioClient;

  PreferenceService(this._dioClient);

  Future<UserPreference?> getPreference() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/users/me/preferences');
      if (response.data == null || response.data['preference'] == null) return null;
      return UserPreference.fromJson(response.data['preference']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  Future<UserPreference> savePreference(UserPreference preference) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/mobile/users/me/preferences',
        data: preference.toJson(),
      );
      return UserPreference.fromJson(response.data['preference']);
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
