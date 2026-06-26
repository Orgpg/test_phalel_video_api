import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../network/dio_client.dart';

class VideoRepository {
  final DioClient _dioClient;

  VideoRepository(this._dioClient);

  Future<List<VideoModel>> fetchVideos() async {
    try {
      final response = await _dioClient.dio.get('/api/uploads');
      
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        debugPrint('API Response Data: $responseData');

        List<dynamic>? list;

        if (responseData is List) {
          list = responseData;
        } else if (responseData is Map) {
          // Look for common keys that might hold the list
          if (responseData['videos'] is List) {
            list = responseData['videos'];
          } else if (responseData['data'] is List) {
            list = responseData['data'];
          } else if (responseData['uploads'] is List) {
            list = responseData['uploads'];
          } else if (responseData['items'] is List) {
            list = responseData['items'];
          } else {
            // Fallback: Find the first list in the map
            for (var value in responseData.values) {
              if (value is List) {
                list = value;
                break;
              }
            }
          }
        }

        if (list != null) {
          return list.map((json) => VideoModel.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Could not find a video list in the API response');
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to load videos: status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Dio Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('General Error in fetchVideos: $e');
      throw Exception('Error: $e');
    }
  }
}
