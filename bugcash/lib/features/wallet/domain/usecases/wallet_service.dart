import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/exceptions/wallet_exceptions.dart';
import '../repositories/wallet_repository.dart';
import '../entities/transaction_entity.dart';

/// Wallet Service - 지갑 관련 비즈니스 로직
/// Repository를 통해 포인트 충전/사용/적립/출금 처리
class WalletService {
  final WalletRepository _repository;
  final FirebaseFirestore _firestore;

  WalletService(this._repository, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 포인트 충전 (공급자)
  /// 중복 결제 방지 로직 포함
  Future<void> chargePoints(
    String userId,
    int amount,
    String description, {
    Map<String, dynamic>? metadata,
  }) async {
    // 금액 유효성 검증
    if (amount < 1000) {
      throw InvalidAmountException(
        amount: amount,
        minAmount: 1000,
        message: '최소 1,000원 이상 충전해주세요',
      );
    }

    // 중복 결제 체크 (orderId가 있는 경우)
    final orderId = metadata?['orderId'] as String?;
    if (orderId != null && !orderId.startsWith('mock_')) {
      // Mock 결제는 중복 체크 제외
      final existingTx = await _firestore
          .collection('transactions')
          .where('metadata.orderId', isEqualTo: orderId)
          .where('status', isEqualTo: TransactionStatus.completed.name)
          .limit(1)
          .get();

      if (existingTx.docs.isNotEmpty) {
        throw DuplicatePaymentException(
          orderId: orderId,
          message: '이미 처리된 결제입니다',
        );
      }
    }

    await _repository.updateBalance(
      userId,
      amount,
      TransactionType.charge,
      description,
      metadata: metadata,
    );
  }

  /// 포인트 차감 (공급자 - 앱 등록 시)
  /// TODO: 앱 등록 시 필요한 총 포인트 계산 로직 추가
  /// TODO: 포인트 부족 시 에러 메시지 UI 표시
  Future<void> spendPoints(
    String userId,
    int amount,
    String description, {
    Map<String, dynamic>? metadata,
  }) async {
    await _repository.updateBalance(
      userId,
      amount,
      TransactionType.spend,
      description,
      metadata: metadata,
    );
  }

  /// 포인트 적립 (테스터 - 미션 완료 시)
  /// TODO: 미션 승인 로직과 연동
  Future<void> earnPoints(
    String userId,
    int amount,
    String description, {
    Map<String, dynamic>? metadata,
  }) async {
    await _repository.updateBalance(
      userId,
      amount,
      TransactionType.earn,
      description,
      metadata: metadata,
    );
  }

  /// 포인트 출금 (테스터)
  /// TODO: 출금 신청 프로세스 구현
  /// TODO: 최소 출금 금액, 수수료 계산
  /// TODO: 출금 상태 관리 (pending → completed)
  Future<void> withdrawPoints(
    String userId,
    int amount,
    String description, {
    Map<String, dynamic>? metadata,
  }) async {
    await _repository.updateBalance(
      userId,
      amount,
      TransactionType.withdraw,
      description,
      metadata: metadata,
    );
  }

  /// 지갑 생성 (회원가입 시 자동 호출)
  Future<void> createWalletForNewUser(String userId) async {
    await _repository.createWallet(userId);
  }
}
