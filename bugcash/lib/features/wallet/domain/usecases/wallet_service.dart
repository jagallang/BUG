import '../repositories/wallet_repository.dart';
import '../entities/transaction_entity.dart';

/// Wallet Service - 지갑 관련 비즈니스 로직
/// Repository를 통해 포인트 충전/사용/적립/출금 처리
class WalletService {
  final WalletRepository _repository;

  WalletService(this._repository);

  /// 포인트 충전 (공급자)
  /// TODO: 결제 모듈과 연동하여 실제 결제 완료 후 호출
  Future<void> chargePoints(
    String userId,
    int amount,
    String description, {
    Map<String, dynamic>? metadata,
  }) async {
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
