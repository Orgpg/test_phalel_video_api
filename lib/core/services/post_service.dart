import 'package:dio/dio.dart';
import '../network/dio_client.dart';

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

  String _handleError(DioException e) {
    return e.response?.data?['error'] ?? e.message ?? 'Unknown error';
  }
}
