class Wallet {
  final String userId;
  final int skillCoins;
  final int premiumCoins;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Wallet({
    required this.userId,
    required this.skillCoins,
    required this.premiumCoins,
    this.createdAt,
    this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      userId: json['userId'] ?? '',
      skillCoins: json['skillCoins'] ?? 0,
      premiumCoins: json['premiumCoins'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

enum TransactionType { 
  BOOKING_PAYMENT, 
  BOOKING_REFUND, 
  BOOKING_RELEASE, 
  WALLET_TOPUP, 
  ADMIN_ADJUSTMENT 
}

class CoinTransaction {
  final String id;
  final String userId;
  final String? bookingId;
  final int amount;
  final String coinType;
  final TransactionType type;
  final int balanceAfter;
  final String? note;
  final DateTime createdAt;
  final dynamic booking; // Can be a simplified booking object

  CoinTransaction({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.amount,
    required this.coinType,
    required this.type,
    required this.balanceAfter,
    this.note,
    required this.createdAt,
    this.booking,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bookingId: json['bookingId'],
      amount: json['amount'] ?? 0,
      coinType: json['coinType'] ?? 'SKILL',
      type: _parseType(json['type']),
      balanceAfter: json['balanceAfter'] ?? 0,
      note: json['note'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      booking: json['booking'],
    );
  }

  static TransactionType _parseType(String? type) {
    switch (type) {
      case 'BOOKING_PAYMENT': return TransactionType.BOOKING_PAYMENT;
      case 'BOOKING_REFUND': return TransactionType.BOOKING_REFUND;
      case 'BOOKING_RELEASE': return TransactionType.BOOKING_RELEASE;
      case 'WALLET_TOPUP': return TransactionType.WALLET_TOPUP;
      default: return TransactionType.ADMIN_ADJUSTMENT;
    }
  }
}
