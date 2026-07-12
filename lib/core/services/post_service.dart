import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/feed_item.dart';
import '../models/comment.dart';
import 'social_service.dart';

class PostService {
  final DioClient _dioClient;

  PostService(this._dioClient);

  Future<Map<String, dynamic>> getPostPresignedUrl({
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/posts/presigned-url',
        data: {
          'fileName': fileName,
          'fileType': fileType,
          'fileSize': fileSize,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createPost({
    required String body,
    String? imageObjectKey,
    String? imageFileName,
    int? imageFileSize,
    String? imageFileType,
    String visibility = 'PUBLIC',
  }) async {
    try {
      await _dioClient.dio.post(
        '/api/mobile/posts',
        data: {
          'body': body,
          'visibility': visibility,
          if (imageObjectKey != null) 'imageObjectKey': imageObjectKey,
          if (imageFileName != null) 'imageFileName': imageFileName,
          if (imageFileSize != null) 'imageFileSize': imageFileSize,
          if (imageFileType != null) 'imageFileType': imageFileType,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyPosts({String? status}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/posts/me',
        queryParameters: {if (status != null) 'status': status},
      );
      return response.data['posts'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FeedResponse> listPosts({String? cursor, String? authorId, int limit = 20}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/posts',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (authorId != null) 'authorId': authorId,
          'limit': limit,
        },
      );
      final List items = response.data['items'] ?? [];
      return FeedResponse(
        items: items.map((e) => FeedItem.fromJson(e)).toList(),
        nextCursor: response.data['nextCursor'],
        hasMore: response.data['hasMore'] ?? false,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CommentResponse> getPostComments(String postId, {String? cursor, int limit = 20}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/posts/$postId/comments',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final List items = response.data['comments'] ?? [];
      return CommentResponse(
        comments: items.map((e) => Comment.fromJson(e)).toList(),
        nextCursor: response.data['nextCursor'],
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Comment> createPostComment(String postId, String body) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/posts/$postId/comments',
        data: {'body': body},
      );
      return Comment.fromJson(response.data['comment']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      final response = await _dioClient.dio.post('/api/mobile/posts/$postId/like');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> unlikePost(String postId) async {
    try {
      final response = await _dioClient.dio.delete('/api/mobile/posts/$postId/like');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> savePost(String postId) async {
    try {
      final response = await _dioClient.dio.post('/api/mobile/posts/$postId/save');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> unsavePost(String postId) async {
    try {
      final response = await _dioClient.dio.delete('/api/mobile/posts/$postId/save');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePostComment(String postId, String commentId) async {
    try {
      await _dioClient.dio.delete('/api/mobile/posts/$postId/comments/$commentId');
    } on DioException catch (e) {
      throw _handleError(e);
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
