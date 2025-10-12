import '../entities/wallet_entity.dart';
import '../entities/transaction_entity.dart';

abstract class WalletRepository {
  /// 지갑 조회
  Stream<WalletEntity> getWallet(String userId);

  /// 거래 내역 조회
  Stream<List<TransactionEntity>> getTransactions(String userId, {int limit = 50});

  /// 거래 생성
  Future<void> createTransaction(TransactionEntity transaction);

  /// 지갑 생성 (회원가입 시)
  Future<void> createWallet(String userId);

  /// 포인트 업데이트 (트랜잭션 포함)
  Future<void> updateBalance(
    String userId,
    int amount,
    TransactionType type,
    String description, {
    Map<String, dynamic>? metadata,
  });

  /// 월별 통계
  Future<int> getMonthlyAmount(String userId, TransactionType type);

  /// 상태별 출금 신청 목록 조회 (관리자용)
  Stream<List<TransactionEntity>> getWithdrawalsByStatus(TransactionStatus status);

  /// 출금 승인 (관리자)
  Future<void> approveWithdrawal(String transactionId);

  /// 출금 거부 (관리자)
  Future<void> rejectWithdrawal(String transactionId, String reason);
}
