import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../data/repositories/wallet_repository_impl.dart';

/// Wallet Repository Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl();
});

/// 상태별 출금 신청 목록 Provider
final withdrawalsByStatusProvider = StreamProvider.family<List<TransactionEntity>, TransactionStatus>(
  (ref, status) {
    final repository = ref.watch(walletRepositoryProvider);
    return repository.getWithdrawalsByStatus(status);
  },
);

/// 출금 승인 Provider
final approveWithdrawalProvider = FutureProvider.family<void, String>(
  (ref, transactionId) async {
    final repository = ref.read(walletRepositoryProvider);
    await repository.approveWithdrawal(transactionId);
    // 목록 갱신
    ref.invalidate(withdrawalsByStatusProvider);
  },
);

/// 출금 거부 Parameters
class RejectWithdrawalParams {
  final String transactionId;
  final String reason;

  RejectWithdrawalParams({
    required this.transactionId,
    required this.reason,
  });
}

/// 출금 거부 Provider
final rejectWithdrawalProvider = FutureProvider.family<void, RejectWithdrawalParams>(
  (ref, params) async {
    final repository = ref.read(walletRepositoryProvider);
    await repository.rejectWithdrawal(params.transactionId, params.reason);
    // 목록 갱신
    ref.invalidate(withdrawalsByStatusProvider);
  },
);
