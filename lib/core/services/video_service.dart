import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../network/dio_client.dart';

class VideoService {
  final DioClient _dioClient;

  VideoService(this._dioClient);

  Future<List<VideoModel>> fetchVideos({String? folder, String? accessType, bool? singleVideoOnly}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/feed',
        queryParameters: {
          'limit': 50,
          // We can't easily filter by folder/accessType on /feed unless the backend supports it
          // But as per instructions, we replace old calls with /feed
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
                  // Mapping other fields if possible
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
}
