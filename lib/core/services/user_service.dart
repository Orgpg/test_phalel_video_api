import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/mobile_user.dart';
import '../models/feed_item.dart';
import 'feed_service.dart';

class UserService {
  final DioClient _dioClient;

  UserService(this._dioClient);

  Future<MobileUser> getMe() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/users/me');
      return MobileUser.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MobileUser> updateMe({
    String? username,
    String? name,
    String? bio,
    String? phone,
    String? avatarObjectKey,
    String? avatarFileName,
    int? avatarFileSize,
    String? avatarFileType,
  }) async {
    try {
      final response = await _dioClient.dio.patch(
        '/api/mobile/users/me',
        data: {
          if (username != null) 'username': username,
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (phone != null) 'phone': phone,
          if (avatarObjectKey != null) 'avatarObjectKey': avatarObjectKey,
          if (avatarFileName != null) 'avatarFileName': avatarFileName,
          if (avatarFileSize != null) 'avatarFileSize': avatarFileSize,
          if (avatarFileType != null) 'avatarFileType': avatarFileType,
        },
      );
      return MobileUser.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAvatarPresignedUrl({
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/users/me/avatar/presigned-url',
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

  Future<MobileUser> getUser(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/users/$id');
      return MobileUser.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MobileUser>> searchUsers(String query, {int limit = 20}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/users/search',
        queryParameters: {'q': query, 'limit': limit},
      );
      final List items = response.data['users'] ?? [];
      return items.map((e) => MobileUser.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FeedResponse> getMyUploads({String? cursor, int limit = 20}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/users/me/uploads',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
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

  Future<FeedResponse> getMySaved({String? cursor, int limit = 20}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/users/me/saved',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
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

  Future<void> deleteAccount() async {
    try {
      await _dioClient.dio.delete('/api/mobile/auth/account');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    return e.response?.data?['error'] ?? e.message ?? 'Unknown error';
  }
}
