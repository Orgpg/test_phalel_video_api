import 'package:dio/dio.dart';
import '../models/feed_item.dart';
import '../network/dio_client.dart';
import 'package:flutter/foundation.dart';

class FeedService {
  final DioClient _dioClient;

  FeedService(this._dioClient);

  Future<FeedResponse> getFeed({int limit = 10, String? cursor}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/feed',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      final List items = response.data['items'] ?? [];
      final feedItems = items.map((e) => FeedItem.fromJson(e)).toList();

      // Debug logging for video URLs
      for (final item in feedItems) {
        if (item.videoUrl != null) {
          debugPrint('VIDEO_URL: ${item.videoUrl}');
          if (item.videoUrl!.contains('/api/uploads/') || item.videoUrl!.contains('/stream')) {
            debugPrint('Wrong videoUrl from API. Expected CDN URL.');
          }
        }
      }

      return FeedResponse(
        items: feedItems,
        nextCursor: response.data['nextCursor'],
        hasMore: response.data['hasMore'] ?? false,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<FeedItem>> getRelatedVideos(String videoId, {int limit = 12}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/videos/$videoId/related',
        queryParameters: {'limit': limit},
      );
      final List items = response.data['items'] ?? [];
      return items.map((e) => FeedItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> recordView(String videoId, {required int watchSeconds, required bool completed, String source = 'feed'}) async {
    try {
      await _dioClient.dio.post(
        '/api/mobile/videos/$videoId/view',
        data: {
          'watchSeconds': watchSeconds,
          'completed': completed,
          'source': source,
        },
      );
    } catch (e) {
      // Views are low priority, don't throw
    }
  }

  String _handleError(DioException e) {
    return e.response?.data?['error'] ?? e.message ?? 'Unknown error';
  }
}

class FeedResponse {
  final List<FeedItem> items;
  final String? nextCursor;
  final bool hasMore;

  FeedResponse({required this.items, this.nextCursor, required this.hasMore});
}
