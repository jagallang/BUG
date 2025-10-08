import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/toss_payment_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';

/// 토스 페이먼츠 설정
/// ⚠️ 실제 프로젝트에서는 .env 파일이나 Firebase Remote Config에서 로드
class TossPaymentsConfig {
  final String clientKey;
  final String secretKey;
  final bool isTestMode;

  const TossPaymentsConfig({
    required this.clientKey,
    required this.secretKey,
    required this.isTestMode,
  });

  // 테스트 설정
  static const TossPaymentsConfig test = TossPaymentsConfig(
    clientKey: 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq',
    secretKey: 'test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R',
    isTestMode: true,
  );
}

/// Test Payment Config Provider
final testPaymentConfigProvider = Provider<TossPaymentsConfig>((ref) {
  return TossPaymentsConfig.test;
});

/// Toss Payment DataSource Provider
final tossPaymentDataSourceProvider = Provider<TossPaymentDataSource>((ref) {
  final config = ref.watch(testPaymentConfigProvider);
  return TossPaymentDataSource(
    clientKey: config.clientKey,
    secretKey: config.secretKey,
    isTestMode: config.isTestMode,
  );
});

/// Payment Repository Provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final tossDataSource = ref.watch(tossPaymentDataSourceProvider);
  return PaymentRepositoryImpl(tossDataSource: tossDataSource);
});

/// 결제 준비 Provider
final preparePaymentProvider = FutureProvider.family<PaymentEntity, PreparePaymentParams>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.preparePayment(
    userId: params.userId,
    amount: params.amount,
  );
});

/// 결제 승인 Provider
final confirmPaymentProvider = FutureProvider.family<PaymentEntity, ConfirmPaymentParams>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.confirmPayment(
    paymentKey: params.paymentKey,
    orderId: params.orderId,
    amount: params.amount,
  );
});

/// 결제 내역 조회 Provider
final paymentHistoryProvider = FutureProvider.family<List<PaymentEntity>, String>((ref, userId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentHistory(userId);
});

/// 결제 상세 조회 Provider
final paymentDetailProvider = FutureProvider.family<PaymentEntity?, String>((ref, orderId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentDetail(orderId);
});

/// 결제 준비 파라미터
class PreparePaymentParams {
  final String userId;
  final int amount;

  PreparePaymentParams({
    required this.userId,
    required this.amount,
  });
}

/// 결제 승인 파라미터
class ConfirmPaymentParams {
  final String paymentKey;
  final String orderId;
  final int amount;

  ConfirmPaymentParams({
    required this.paymentKey,
    required this.orderId,
    required this.amount,
  });
}
