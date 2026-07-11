import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  DioClient({Function? onUnauthorized}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.get('BASE_URL'),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          final publicToken = dotenv.get('API_TOKEN', fallback: '');
          if (publicToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $publicToken';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Requirement: If 401 with "Current password is incorrect", do not logout automatically.
          final path = e.requestOptions.path;
          if (path.contains('reset-password')) {
            return handler.next(e);
          }

          // Auto-clear invalid token for other cases (expired session, etc)
          await _storage.delete(key: 'auth_token');
          if (onUnauthorized != null) {
            onUnauthorized();
          }
        }
        return handler.next(e);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Dio get dio => _dio;
}
