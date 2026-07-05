import 'package:dio/dio.dart';
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

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }
    return e.message ?? 'Wallet service error';
  }
}
