import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/toss_payment_datasource.dart';

/// Payment Repository 구현
class PaymentRepositoryImpl implements PaymentRepository {
  final TossPaymentDataSource _tossDataSource;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  static const String _paymentsCollection = 'payments';

  PaymentRepositoryImpl({
    required TossPaymentDataSource tossDataSource,
    FirebaseFirestore? firestore,
  })  : _tossDataSource = tossDataSource,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<PaymentEntity> preparePayment({
    required String userId,
    required int amount,
  }) async {
    // 고유 주문 ID 생성 (UUID v4)
    final orderId = _uuid.v4();

    // 결제 엔티티 생성
    final payment = PaymentEntity.create(
      orderId: orderId,
      amount: amount,
      userId: userId,
    );

    // Firestore에 저장 (상태: ready)
    await savePayment(payment);

    return payment;
  }

  @override
  Future<PaymentEntity> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      // 토스 API로 결제 승인 요청
      final response = await _tossDataSource.confirmPayment(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );

      // 응답에서 결제 정보 파싱
      final payment = PaymentEntity(
        paymentKey: response['paymentKey'],
        orderId: response['orderId'],
        orderName: response['orderName'],
        amount: response['totalAmount'],
        method: _parsePaymentMethod(response['method']),
        status: PaymentStatus.done,
        userId: '', // Firestore에서 가져와야 함
        requestedAt: DateTime.parse(response['requestedAt']),
        approvedAt: DateTime.parse(response['approvedAt']),
        metadata: response,
      );

      // Firestore 업데이트
      await _firestore.collection(_paymentsCollection).doc(orderId).update({
        'paymentKey': paymentKey,
        'status': PaymentStatus.done.name,
        'approvedAt': payment.approvedAt?.toIso8601String(),
        'metadata': payment.metadata,
      });

      return payment;
    } catch (e) {
      // 실패 시 상태 업데이트
      await updatePaymentStatus(
        orderId: orderId,
        status: PaymentStatus.aborted,
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelPayment({
    required String paymentKey,
    String? cancelReason,
  }) async {
    await _tossDataSource.cancelPayment(
      paymentKey: paymentKey,
      cancelReason: cancelReason,
    );

    // Firestore에서 해당 결제 찾아서 상태 업데이트
    final querySnapshot = await _firestore
        .collection(_paymentsCollection)
        .where('paymentKey', isEqualTo: paymentKey)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'status': PaymentStatus.canceled.name,
      });
    }
  }

  @override
  Future<List<PaymentEntity>> getPaymentHistory(String userId) async {
    final querySnapshot = await _firestore
        .collection(_paymentsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PaymentEntity.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<PaymentEntity?> getPaymentDetail(String orderId) async {
    final doc = await _firestore.collection(_paymentsCollection).doc(orderId).get();

    if (!doc.exists) return null;

    return PaymentEntity.fromMap(doc.data()!);
  }

  @override
  Future<void> savePayment(PaymentEntity payment) async {
    await _firestore
        .collection(_paymentsCollection)
        .doc(payment.orderId)
        .set(payment.toMap());
  }

  @override
  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentStatus status,
  }) async {
    await _firestore.collection(_paymentsCollection).doc(orderId).update({
      'status': status.name,
    });
  }

  /// 결제 방법 문자열 → enum 변환
  PaymentMethod _parsePaymentMethod(String? method) {
    switch (method) {
      case '카드':
      case 'CARD':
        return PaymentMethod.card;
      case '계좌이체':
      case 'TRANSFER':
        return PaymentMethod.transfer;
      case '카카오페이':
        return PaymentMethod.kakaopay;
      case '네이버페이':
        return PaymentMethod.naverpay;
      case '토스페이':
        return PaymentMethod.tosspay;
      default:
        return PaymentMethod.card;
    }
  }
}
