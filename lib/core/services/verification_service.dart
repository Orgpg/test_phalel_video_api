import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_verification.dart';
import '../network/dio_client.dart';

class VerificationService {
  final DioClient _dioClient;

  VerificationService(this._dioClient);

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

  Future<Map<String, dynamic>> getVerificationPresignedUrl({
    required String fileName,
    required String fileType,
    required int fileSize,
    required String documentType,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/users/me/verification/presigned-url',
        data: {
          'fileName': fileName,
          'fileType': fileType,
          'fileSize': fileSize,
          'documentType': documentType,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> uploadImageToPresignedUrl({
    required String url,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final dio = Dio();
      await dio.put(
        url,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      debugPrint('MinIO Upload Error: ${e.response?.data ?? e.message}');
      throw 'Failed to upload image to storage. Please try again.';
    } catch (e) {
      debugPrint('MinIO Upload Error: $e');
      throw 'Failed to upload image to storage.';
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
    if (e.response?.statusCode == 403) {
      return 'Action not allowed for your role. Only Teachers can verify identity.';
    }
    if (e.response?.data != null && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }
    return e.message ?? 'An unknown error occurred';
  }
}
