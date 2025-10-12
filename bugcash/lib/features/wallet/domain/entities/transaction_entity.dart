import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType {
  charge, // 충전 (공급자)
  spend, // 사용 (공급자 - 앱 등록)
  earn, // 적립 (테스터 - 미션 완료)
  withdraw, // 출금 (테스터)
}

enum TransactionStatus {
  pending, // 대기 중
  completed, // 완료
  failed, // 실패
  cancelled, // 취소
}

class TransactionEntity extends Equatable {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount; // 포인트 금액
  final TransactionStatus status;
  final String description;
  final Map<String, dynamic> metadata; // 추가 정보
  final DateTime createdAt;
  final DateTime? completedAt;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    this.metadata = const {},
    required this.createdAt,
    this.completedAt,
  });

  TransactionEntity copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    int? amount,
    TransactionStatus? status,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'status': status.name,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory TransactionEntity.fromFirestore(String id, Map<String, dynamic> data) {
    return TransactionEntity(
      id: id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.byName(data['type'] ?? 'earn'),
      amount: data['amount'] ?? 0,
      status: TransactionStatus.values.byName(data['status'] ?? 'pending'),
      description: data['description'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  // 타입별 아이콘 헬퍼
  String get iconEmoji {
    switch (type) {
      case TransactionType.charge:
        return '💳'; // 충전
      case TransactionType.spend:
        return '📤'; // 사용
      case TransactionType.earn:
        return '💰'; // 적립
      case TransactionType.withdraw:
        return '🏦'; // 출금
    }
  }

  // 금액 표시 (+ 또는 -)
  String get amountWithSign {
    final sign = (type == TransactionType.charge || type == TransactionType.earn) ? '+' : '-';
    return '$sign${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // 상태 색상 헬퍼
  String get statusColor {
    switch (status) {
      case TransactionStatus.completed:
        return 'green';
      case TransactionStatus.pending:
        return 'orange';
      case TransactionStatus.failed:
        return 'red';
      case TransactionStatus.cancelled:
        return 'grey';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        amount,
        status,
        description,
        metadata,
        createdAt,
        completedAt,
      ];
}
