import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';

class UploadRepository {
  final DioClient _dioClient;

  UploadRepository(this._dioClient);

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
    required String folder,
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/uploads/presigned-url',
        data: {
          'assetType': assetType,
          'folder': folder,
          'fileName': fileName,
          'fileType': fileType,
          'fileSize': fileSize,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      debugPrint('Presigned URL Error: $errorData');
      throw Exception(errorData?['error'] ?? errorData?['message'] ?? 'Failed to get upload URL');
    }
  }

  Future<void> uploadBytes({
    required String url,
    required Uint8List bytes,
    required String contentType,
    Function(int, int)? onProgress,
  }) async {
    // Use a fresh Dio instance for PUT to avoid global interceptors if they interfere
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
    required String folder,
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
  }) async {
    final Map<String, dynamic> data = {
      'fileName': fileName,
      'folder': folder,
      'fileSize': fileSize,
      'fileType': fileType,
      'objectKey': objectKey,
      'displayName': displayName,
      'author': author,
      'category': category,
      'description': description,
      'tags': tags,
      'accessType': accessType.toUpperCase(),
    };

    // Add thumbnail fields only if they exist
    if (thumbnailObjectKey != null && thumbnailObjectKey.isNotEmpty) {
      data['thumbnailFileName'] = thumbnailFileName;
      data['thumbnailFileSize'] = thumbnailFileSize;
      data['thumbnailFileType'] = thumbnailFileType;
      data['thumbnailObjectKey'] = thumbnailObjectKey;
    }

    debugPrint('Submitting Metadata with data: $data');

    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/uploads',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      debugPrint('Submit Metadata Error: $errorData');
      debugPrint('Request Data was: $data');
      throw Exception(errorData?['error'] ?? errorData?['message'] ?? 'Failed to submit metadata');
    }
  }
}
