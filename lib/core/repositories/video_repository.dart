import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../network/dio_client.dart';

class VideoRepository {
  final DioClient _dioClient;

  VideoRepository(this._dioClient);

  Future<List<VideoModel>> fetchVideos({String? folder, String? accessType}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (folder != null) queryParams['folder'] = folder;
      if (accessType != null) queryParams['accessType'] = accessType;

      final response = await _dioClient.dio.get(
        '/api/uploads',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        if (response.data is Map && response.data['videos'] is List) {
          return (response.data['videos'] as List)
              .map((json) => VideoModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching videos from uploads: $e');
      return [];
    }
  }

  Future<List<String>> fetchFolders() async {
    try {
      final response = await _dioClient.dio.get('/api/folders');
      if (response.statusCode == 200) {
        if (response.data is Map && response.data['folders'] is List) {
          return List<String>.from(response.data['folders']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching folders: $e');
      return [];
    }
  }

  Future<List<String>> fetchCategories() async {
    try {
      final response = await _dioClient.dio.get('/api/categories');
      if (response.statusCode == 200) {
        if (response.data is Map && response.data['categories'] is List) {
          return List<String>.from(response.data['categories']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }
}
