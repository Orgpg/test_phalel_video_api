import 'package:dio/dio.dart';
import '../models/comment.dart';
import '../network/dio_client.dart';

class SocialService {
  final DioClient _dioClient;

  SocialService(this._dioClient);

  // Likes
  Future<Map<String, dynamic>> likeVideo(String videoId) async {
    try {
      final response = await _dioClient.dio.post('/api/mobile/videos/$videoId/like');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> unlikeVideo(String videoId) async {
    try {
      final response = await _dioClient.dio.delete('/api/mobile/videos/$videoId/like');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Comments
  Future<CommentResponse> getComments(String videoId, {int limit = 20, String? cursor}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/videos/$videoId/comments',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
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

  Future<Comment> createComment(String videoId, String body) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/videos/$videoId/comments',
        data: {'body': body},
      );
      return Comment.fromJson(response.data['comment']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteComment(String videoId, String commentId) async {
    try {
      await _dioClient.dio.delete('/api/mobile/videos/$videoId/comments/$commentId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Follow
  Future<void> followUser(String userId) async {
    try {
      await _dioClient.dio.post('/api/mobile/users/$userId/follow');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await _dioClient.dio.delete('/api/mobile/users/$userId/follow');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Friends
  Future<void> sendFriendRequest(String receiverUserId) async {
    try {
      await _dioClient.dio.post(
        '/api/mobile/friends/requests',
        data: {'receiverUserId': receiverUserId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getFriendRequests() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/friends/requests');
      return response.data['requests'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _dioClient.dio.patch('/api/mobile/friends/requests/$requestId/accept');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _dioClient.dio.patch('/api/mobile/friends/requests/$requestId/reject');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getFriends() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/friends');
      return response.data['friends'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    return e.response?.data?['error'] ?? e.message ?? 'Unknown error';
  }
}

class CommentResponse {
  final List<Comment> comments;
  final String? nextCursor;

  CommentResponse({required this.comments, this.nextCursor});
}
