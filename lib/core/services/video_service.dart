import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../network/dio_client.dart';

class VideoService {
  final DioClient _dioClient;

  VideoService(this._dioClient);

  Future<List<VideoModel>> fetchVideos({String? folder, String? accessType, bool? singleVideoOnly, int limit = 50, String? cursor}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/feed',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
          if (folder != null) 'folder': folder,
          if (singleVideoOnly != null) 'singleVideoOnly': singleVideoOnly,
        },
      );
      
      if (response.statusCode == 200) {
        final List items = response.data['items'] ?? [];
        // Map Feed items back to VideoModel for compatibility with existing UI
        return items
            .where((e) => e['type'] == 'VIDEO')
            .map((json) => VideoModel.fromJson({
                  'id': json['id'],
                  'displayName': json['title'],
                  'description': json['description'],
                  'videoUrl': json['videoUrl'],
                  'thumbnailUrl': json['thumbnail']?['url'],
                  'author': json['author']?['name'],
                  'folder': json['folder'],
                }))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching videos from feed: $e');
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

  Future<Map<String, dynamic>> saveVideo(String videoId) async {
    try {
      final response = await _dioClient.dio.post('/api/mobile/videos/$videoId/save');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> unsaveVideo(String videoId) async {
    try {
      final response = await _dioClient.dio.delete('/api/mobile/videos/$videoId/save');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> rateVideo(String videoId, int rating) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/videos/$videoId/rate',
        data: {'rating': rating},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    return e.response?.data?['error'] ?? e.message ?? 'Unknown error';
  }
}
