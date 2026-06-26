import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class UploadRepository {
  final DioClient _dioClient;

  UploadRepository(this._dioClient);

  Future<Map<String, dynamic>> getPresignedUrl({
    required String assetType,
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/mobile/uploads/presigned-url',
      data: {
        'assetType': assetType,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': fileSize,
      },
    );
    return response.data;
  }

  Future<void> uploadBytes({
    required String url,
    required Uint8List bytes,
    required String contentType,
    Function(int, int)? onProgress,
  }) async {
    await Dio().put(
      url,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> submitMetadata({
    required String fileName,
    required int fileSize,
    required String fileType,
    required String r2ObjectKey,
    required String thumbnailFileName,
    required int thumbnailFileSize,
    required String thumbnailFileType,
    required String thumbnailObjectKey,
    required String displayName,
    required String category,
    required String description,
    required List<String> tags,
    required String accessType,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/mobile/uploads',
      data: {
        'fileName': fileName,
        'fileSize': fileSize,
        'fileType': fileType,
        'r2ObjectKey': r2ObjectKey,
        'thumbnailFileName': thumbnailFileName,
        'thumbnailFileSize': thumbnailFileSize,
        'thumbnailFileType': thumbnailFileType,
        'thumbnailObjectKey': thumbnailObjectKey,
        'displayName': displayName,
        'category': category,
        'description': description,
        'tags': tags,
        'accessType': accessType,
      },
    );
    return response.data;
  }
}
