import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

enum WalletState { initial, loading, loaded, error }

class WalletProvider with ChangeNotifier {
  final WalletService _service;

  WalletProvider(this._service);

  Wallet? _wallet;
  List<CoinTransaction> _transactions = [];
  List<TopupRequest> _topupRequests = [];
  WalletState _state = WalletState.initial;
  String _errorMessage = '';

  Wallet? get wallet => _wallet;
  List<CoinTransaction> get transactions => _transactions;
  List<TopupRequest> get topupRequests => _topupRequests;
  WalletState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchWallet() async {
    _state = WalletState.loading;
    notifyListeners();

    try {
      _wallet = await _service.getMyWallet();
      _state = WalletState.loaded;
    } catch (e) {
      _state = WalletState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    try {
      _transactions = await _service.getMyTransactions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  Future<void> fetchTopupRequests() async {
    try {
      _topupRequests = await _service.listTopupRequests();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching topup requests: $e');
    }
  }

  Future<void> submitTopupRequest({
    required XFile screenshot,
    required String requestedCoins,
    required String mmkAmount,
  }) async {
    try {
      await _service.createTopupRequest(
        screenshot: screenshot,
        requestedCoins: requestedCoins,
        mmkAmount: mmkAmount,
      );
      await fetchTopupRequests();
    } catch (e) {
      rethrow;
    }
  }

  void updateWallet(Wallet newWallet) {
    _wallet = newWallet;
    notifyListeners();
  }
}
