import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../network/dio_client.dart';

class UploadService {
  final DioClient _dioClient;

  UploadService(this._dioClient);

  /// Helper to get a Dio instance configured with the static API_TOKEN
  /// Some upload endpoints require the mobile-api-key instead of user JWT
  Dio _getPublicDio() {
    final publicToken = dotenv.get('API_TOKEN', fallback: '');
    final dio = Dio(BaseOptions(
      baseUrl: _dioClient.dio.options.baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (publicToken.isNotEmpty) 'Authorization': 'Bearer $publicToken',
      },
    ));
    return dio;
  }

  Future<List<String>> fetchFolders() async {
    final response = await _dioClient.dio.get('/api/folders');
    if (response.data is Map && response.data['folders'] is List) {
      return List<String>.from(response.data['folders']);
    }
    return ['General'];
  }

  Future<List<String>> fetchCategories() async {
    try {
      final response = await _dioClient.dio.get('/api/categories');
      if (response.data is Map && response.data['categories'] is List) {
        return List<String>.from(response.data['categories']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPresignedUrl({
    required String assetType,
    String? folder,
    bool? singleVideoOnly,
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    try {
      // Use public Dio instance with API_TOKEN as per "Single Video Upload Flow" requirements
      final response = await _getPublicDio().post(
        '/api/mobile/uploads/presigned-url',
        data: {
          'assetType': assetType,
          if (folder != null) 'folder': folder,
          if (singleVideoOnly != null) 'singleVideoOnly': singleVideoOnly,
          'fileName': fileName,
          'fileType': fileType,
          'fileSize': fileSize,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      throw Exception(errorData?['error'] ?? errorData?['message'] ?? 'Failed to get upload URL');
    }
  }

  Future<void> uploadBytes({
    required String url,
    required Uint8List bytes,
    required String contentType,
    Function(int, int)? onProgress,
  }) async {
    await Dio().put(
      url,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
        },
      ),
      onSendProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> submitMetadata({
    required String fileName,
    String? folder,
    bool? singleVideoOnly,
    required int fileSize,
    required String fileType,
    required String objectKey,
    String? thumbnailFileName,
    int? thumbnailFileSize,
    String? thumbnailFileType,
    String? thumbnailObjectKey,
    required String displayName,
    required String author,
    required String category,
    required String description,
    required List<String> tags,
    required String accessType,
    String visibility = 'PUBLIC',
  }) async {
    final Map<String, dynamic> data = {
      'fileName': fileName,
      if (folder != null) 'folder': folder,
      if (singleVideoOnly != null) 'singleVideoOnly': singleVideoOnly,
      'fileSize': fileSize,
      'fileType': fileType,
      'objectKey': objectKey,
      'displayName': displayName,
      'author': author,
      'category': category,
      'description': description,
      'tags': tags,
      'accessType': accessType.toUpperCase(),
      'visibility': visibility,
    };

    if (thumbnailObjectKey != null && thumbnailObjectKey.isNotEmpty) {
      data['thumbnailFileName'] = thumbnailFileName;
      data['thumbnailFileSize'] = thumbnailFileSize;
      data['thumbnailFileType'] = thumbnailFileType;
      data['thumbnailObjectKey'] = thumbnailObjectKey;
    }

    try {
      // Use public Dio instance with API_TOKEN as per "Single Video Upload Flow" requirements
      final response = await _getPublicDio().post(
        '/api/mobile/uploads',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      throw Exception(errorData?['error'] ?? errorData?['message'] ?? 'Failed to submit metadata');
    }
  }
}
