import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../network/dio_client.dart';

class WalletService {
  final DioClient _dioClient;

  WalletService(this._dioClient);

  Future<Wallet> getMyWallet() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/users/me/wallet');
      return Wallet.fromJson(response.data['wallet']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<CoinTransaction>> getMyTransactions() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/users/me/transactions');
      if (response.data['transactions'] != null) {
        return (response.data['transactions'] as List)
            .map((e) => CoinTransaction.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createTopupRequest({
    required XFile screenshot,
    required String requestedCoins,
    required String mmkAmount,
  }) async {
    try {
      MultipartFile file;
      if (kIsWeb) {
        final bytes = await screenshot.readAsBytes();
        file = MultipartFile.fromBytes(bytes, filename: screenshot.name);
      } else {
        file = await MultipartFile.fromFile(screenshot.path, filename: screenshot.name);
      }

      final formData = FormData.fromMap({
        'screenshot': file,
        'requestedCoins': requestedCoins,
        'mmkAmount': mmkAmount,
      });

      await _dioClient.dio.post(
        '/api/mobile/wallet/topup-requests',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TopupRequest>> listTopupRequests() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/wallet/topup-requests');
      final List items = response.data['requests'] ?? [];
      return items.map((e) => TopupRequest.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }
    return e.message ?? 'Wallet service error';
  }
}
