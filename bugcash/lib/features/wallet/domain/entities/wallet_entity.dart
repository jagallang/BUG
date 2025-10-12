import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String userId;
  final int balance; // 보유 포인트
  final int totalCharged; // 총 충전 금액 (공급자)
  final int totalSpent; // 총 사용 금액 (공급자)
  final int totalEarned; // 총 적립 금액 (테스터)
  final int totalWithdrawn; // 총 출금 금액 (테스터)
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletEntity({
    required this.userId,
    required this.balance,
    this.totalCharged = 0,
    this.totalSpent = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  WalletEntity copyWith({
    String? userId,
    int? balance,
    int? totalCharged,
    int? totalSpent,
    int? totalEarned,
    int? totalWithdrawn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalCharged: totalCharged ?? this.totalCharged,
      totalSpent: totalSpent ?? this.totalSpent,
      totalEarned: totalEarned ?? this.totalEarned,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'balance': balance,
      'totalCharged': totalCharged,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WalletEntity.fromFirestore(String userId, Map<String, dynamic> data) {
    return WalletEntity(
      userId: userId,
      balance: data['balance'] ?? 0,
      totalCharged: data['totalCharged'] ?? 0,
      totalSpent: data['totalSpent'] ?? 0,
      totalEarned: data['totalEarned'] ?? 0,
      totalWithdrawn: data['totalWithdrawn'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory WalletEntity.empty(String userId) {
    final now = DateTime.now();
    return WalletEntity(
      userId: userId,
      balance: 0,
      totalCharged: 0,
      totalSpent: 0,
      totalEarned: 0,
      totalWithdrawn: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        balance,
        totalCharged,
        totalSpent,
        totalEarned,
        totalWithdrawn,
        createdAt,
        updatedAt,
      ];
}
