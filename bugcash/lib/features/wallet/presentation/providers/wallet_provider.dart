import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/usecases/wallet_service.dart';

// Repository Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl();
});

// Service Provider
final walletServiceProvider = Provider<WalletService>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WalletService(repository);
});

// 지갑 정보 실시간 조회 (Repository 사용)
final walletProvider = StreamProvider.family<WalletEntity, String>((ref, userId) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWallet(userId);
});

// 거래 내역 실시간 조회 (Repository 사용)
final transactionsProvider = StreamProvider.family<List<TransactionEntity>, String>((ref, userId) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getTransactions(userId);
});

// 이번 달 충전 금액 (공급자)
final monthlyChargedProvider = StreamProvider.family<int, String>((ref, userId) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'charge')
      .where('status', isEqualTo: 'completed')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['amount'] as int?) ?? 0),
    );
  });
});

// 이번 달 사용 금액 (공급자)
final monthlySpentProvider = StreamProvider.family<int, String>((ref, userId) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'spend')
      .where('status', isEqualTo: 'completed')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['amount'] as int?) ?? 0),
    );
  });
});

// 이번 달 적립 금액 (테스터)
final monthlyEarnedProvider = StreamProvider.family<int, String>((ref, userId) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'earn')
      .where('status', isEqualTo: 'completed')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['amount'] as int?) ?? 0),
    );
  });
});
