import 'package:equatable/equatable.dart';

/// 결제 방법
enum PaymentMethod {
  card, // 카드 결제
  transfer, // 계좌 이체
  kakaopay, // 카카오페이
  naverpay, // 네이버페이
  tosspay, // 토스페이
}

/// 결제 상태
enum PaymentStatus {
  ready, // 결제 준비
  inProgress, // 결제 진행중
  waiting, // 입금 대기 (가상계좌)
  done, // 결제 완료
  canceled, // 결제 취소
  partialCanceled, // 부분 취소
  aborted, // 결제 승인 실패
  expired, // 결제 유효기간 만료
}

/// 결제 엔티티
class PaymentEntity extends Equatable {
  final String paymentKey; // 토스 결제 고유 키
  final String orderId; // 주문 ID (자체 생성)
  final String orderName; // 주문명 (벅스리워드 포인트 충전 10,000원)
  final int amount; // 결제 금액 (원)
  final PaymentMethod method; // 결제 방법
  final PaymentStatus status; // 결제 상태
  final String userId; // 사용자 ID
  final DateTime requestedAt; // 결제 요청 시각
  final DateTime? approvedAt; // 결제 승인 시각
  final Map<String, dynamic> metadata; // 추가 정보

  const PaymentEntity({
    required this.paymentKey,
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.method,
    required this.status,
    required this.userId,
    required this.requestedAt,
    this.approvedAt,
    this.metadata = const {},
  });

  /// 결제 준비 상태로 생성
  factory PaymentEntity.create({
    required String orderId,
    required int amount,
    required String userId,
  }) {
    return PaymentEntity(
      paymentKey: '', // 토스에서 발급받음
      orderId: orderId,
      orderName: '벅스리워드 포인트 충전 ${_formatAmount(amount)}원',
      amount: amount,
      method: PaymentMethod.card, // 기본값
      status: PaymentStatus.ready,
      userId: userId,
      requestedAt: DateTime.now(),
      metadata: const {},
    );
  }

  /// 금액 포맷팅 (1000 → 1,000)
  static String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 복사본 생성
  PaymentEntity copyWith({
    String? paymentKey,
    String? orderId,
    String? orderName,
    int? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? userId,
    DateTime? requestedAt,
    DateTime? approvedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentEntity(
      paymentKey: paymentKey ?? this.paymentKey,
      orderId: orderId ?? this.orderId,
      orderName: orderName ?? this.orderName,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'paymentKey': paymentKey,
      'orderId': orderId,
      'orderName': orderName,
      'amount': amount,
      'method': method.name,
      'status': status.name,
      'userId': userId,
      'requestedAt': requestedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Firestore에서 불러오기
  factory PaymentEntity.fromMap(Map<String, dynamic> map) {
    return PaymentEntity(
      paymentKey: map['paymentKey'] ?? '',
      orderId: map['orderId'] ?? '',
      orderName: map['orderName'] ?? '',
      amount: map['amount'] ?? 0,
      method: PaymentMethod.values.byName(map['method'] ?? 'card'),
      status: PaymentStatus.values.byName(map['status'] ?? 'ready'),
      userId: map['userId'] ?? '',
      requestedAt: DateTime.parse(map['requestedAt']),
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        paymentKey,
        orderId,
        orderName,
        amount,
        method,
        status,
        userId,
        requestedAt,
        approvedAt,
        metadata,
      ];
}
