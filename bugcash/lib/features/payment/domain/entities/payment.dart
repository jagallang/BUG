import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

enum PaymentMethod {
  creditCard,
  bankTransfer,
  kakaoPayMoney, 
  naverPay,
  tossPay,
  paypal,
  googlePay,
  applePay,
}

class Payment extends Equatable {
  final String id;
  final String userId;
  final String? missionId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  const Payment({
    required this.id,
    required this.userId,
    this.missionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.failureReason,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        missionId,
        amount,
        currency,
        status,
        method,
        createdAt,
        completedAt,
        transactionId,
        failureReason,
        metadata,
      ];

  Payment copyWith({
    String? id,
    String? userId,
    String? missionId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? createdAt,
    DateTime? completedAt,
    String? transactionId,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      missionId: missionId ?? this.missionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }
}