import '../entities/payment_entity.dart';

/// 결제 Repository 인터페이스
abstract class PaymentRepository {
  /// 결제 준비 (토스 결제 위젯 초기화)
  Future<PaymentEntity> preparePayment({
    required String userId,
    required int amount,
  });

  /// 결제 승인 요청 (토스 서버로)
  Future<PaymentEntity> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  });

  /// 결제 취소
  Future<void> cancelPayment({
    required String paymentKey,
    String? cancelReason,
  });

  /// 결제 내역 조회
  Future<List<PaymentEntity>> getPaymentHistory(String userId);

  /// 결제 상세 조회
  Future<PaymentEntity?> getPaymentDetail(String orderId);

  /// 결제 정보 Firestore에 저장
  Future<void> savePayment(PaymentEntity payment);

  /// 결제 상태 업데이트
  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentStatus status,
  });
}
