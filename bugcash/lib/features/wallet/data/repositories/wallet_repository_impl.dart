import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Wallet Repository 구현체
/// Firestore와 직접 통신하여 지갑 및 거래 내역 관리
class WalletRepositoryImpl implements WalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<WalletEntity> getWallet(String userId) {
    return _firestore.collection('wallets').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return WalletEntity.empty(userId);
      }
      return WalletEntity.fromFirestore(userId, doc.data()!);
    });
  }

  @override
  Stream<List<TransactionEntity>> getTransactions(String userId, {int limit = 50}) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionEntity.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> createWallet(String userId) async {
    final walletRef = _firestore.collection('wallets').doc(userId);
    final exists = (await walletRef.get()).exists;

    if (!exists) {
      await walletRef.set(WalletEntity.empty(userId).toFirestore());
    }
  }

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    await _firestore.collection('transactions').add(transaction.toFirestore());
  }

  @override
  Future<void> updateBalance(
    String userId,
    int amount,
    TransactionType type,
    String description, {
    Map<String, dynamic>? metadata,
  }) async {
    // TODO: Firestore Transaction으로 원자성 보장
    // TODO: 포인트 부족 시 예외 처리
    // TODO: 지갑 잔액 업데이트 + 거래 내역 생성을 하나의 트랜잭션으로 처리

    await _firestore.runTransaction((transaction) async {
      final walletRef = _firestore.collection('wallets').doc(userId);
      final walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw Exception('Wallet not found');
      }

      final wallet = WalletEntity.fromFirestore(userId, walletDoc.data()!);
      final isCredit = type == TransactionType.charge || type == TransactionType.earn;
      final newBalance = isCredit ? wallet.balance + amount : wallet.balance - amount;

      if (!isCredit && newBalance < 0) {
        throw Exception('Insufficient balance');
      }

      // 지갑 업데이트
      transaction.update(walletRef, {
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
        if (type == TransactionType.charge) 'totalCharged': FieldValue.increment(amount),
        if (type == TransactionType.spend) 'totalSpent': FieldValue.increment(amount),
        if (type == TransactionType.earn) 'totalEarned': FieldValue.increment(amount),
        if (type == TransactionType.withdraw) 'totalWithdrawn': FieldValue.increment(amount),
      });

      // 거래 내역 생성
      final transactionRef = _firestore.collection('transactions').doc();
      transaction.set(
        transactionRef,
        TransactionEntity(
          id: transactionRef.id,
          userId: userId,
          type: type,
          amount: amount,
          status: TransactionStatus.completed,
          description: description,
          metadata: metadata ?? {},
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        ).toFirestore(),
      );
    });
  }

  @override
  Future<int> getMonthlyAmount(String userId, TransactionType type) async {
    // TODO: 월별 통계 쿼리 구현
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    return snapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['amount'] as int?) ?? 0),
    );
  }
}
