import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/wallet_exceptions.dart';
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
    debugPrint('🟦 [WalletRepository] getWallet called - userId: $userId');

    // v2.168.0: 로그아웃 상태 처리 (anonymous_user는 Firestore 접근 불가)
    if (userId == 'anonymous_user') {
      debugPrint('⚠️ [WalletRepository] User is logged out (anonymous_user), returning empty wallet');
      return Stream.value(WalletEntity.empty(userId));
    }

    // v2.149.2: handleError() 제거, StreamTransformer로 에러를 empty wallet으로 변환
    return _firestore.collection('wallets').doc(userId).snapshots()
        .transform(StreamTransformer<DocumentSnapshot<Map<String, dynamic>>, WalletEntity>.fromHandlers(
          handleData: (doc, sink) {
            debugPrint('🟦 [WalletRepository] Snapshot received - exists: ${doc.exists}');

            if (!doc.exists) {
              debugPrint('⚠️ [WalletRepository] Wallet document not found, auto-creating and returning empty wallet');
              _createWalletIfNeeded(userId);
              sink.add(WalletEntity.empty(userId));
              return;
            }

            final data = doc.data();
            if (data == null) {
              debugPrint('⚠️ [WalletRepository] Wallet document exists but data is null');
              sink.add(WalletEntity.empty(userId));
              return;
            }

            debugPrint('✅ [WalletRepository] Wallet loaded - balance: ${data['balance']}');
            sink.add(WalletEntity.fromFirestore(userId, data));
          },
          handleError: (error, stack, sink) {
            debugPrint('❌ [WalletRepository] Stream error: $error');
            debugPrint('❌ [WalletRepository] Stack trace: $stack');
            // v2.149.2: 에러 발생 시에도 empty wallet을 emit하여 UI가 로딩 상태에 멈추지 않도록 함
            sink.add(WalletEntity.empty(userId));
          },
        ));
  }

  /// v2.147.1: 지갑 문서 자동 생성 (권한 문제 대응)
  Future<void> _createWalletIfNeeded(String userId) async {
    try {
      debugPrint('🔧 [WalletRepository] Attempting to auto-create wallet for userId: $userId');
      await createWallet(userId);
      debugPrint('✅ [WalletRepository] Wallet auto-created successfully');
    } catch (e) {
      debugPrint('❌ [WalletRepository] Failed to auto-create wallet: $e');
      // 권한 오류 등으로 생성 실패해도 무시 (읽기 전용 모드로 동작)
    }
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
    if (kDebugMode) {
      print('🔵 updateBalance 시작 - userId: $userId, amount: $amount, type: ${type.name}');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        if (kDebugMode) {
          print('🔵 Firestore Transaction 시작');
        }

        final walletRef = _firestore.collection('wallets').doc(userId);
        final walletDoc = await transaction.get(walletRef);

        if (kDebugMode) {
          print('🔵 Wallet 문서 조회 - exists: ${walletDoc.exists}');
        }

        // 지갑이 없으면 자동 생성 (legacy 사용자 대응)
        if (!walletDoc.exists) {
          if (kDebugMode) {
            print('⚠️ Wallet not found. Auto-creating wallet for userId: $userId');
          }
          transaction.set(walletRef, WalletEntity.empty(userId).toFirestore());
          if (kDebugMode) {
            print('✅ Wallet auto-created');
          }
        }

        final wallet = walletDoc.exists
            ? WalletEntity.fromFirestore(userId, walletDoc.data()!)
            : WalletEntity.empty(userId);

        if (kDebugMode) {
          print('🔵 현재 잔액: ${wallet.balance}');
        }

        final isCredit = type == TransactionType.charge || type == TransactionType.earn;
        final newBalance = isCredit ? wallet.balance + amount : wallet.balance - amount;

        if (kDebugMode) {
          print('🔵 새 잔액: $newBalance');
        }

        if (!isCredit && newBalance < 0) {
          if (kDebugMode) {
            print('❌ Insufficient balance');
          }
          throw InsufficientBalanceException(
            currentBalance: wallet.balance,
            requiredAmount: amount,
          );
        }

        // 지갑 업데이트
        if (kDebugMode) {
          print('🔵 지갑 업데이트 중...');
        }
        transaction.update(walletRef, {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
          if (type == TransactionType.charge) 'totalCharged': FieldValue.increment(amount),
          if (type == TransactionType.spend) 'totalSpent': FieldValue.increment(amount),
          if (type == TransactionType.earn) 'totalEarned': FieldValue.increment(amount),
          if (type == TransactionType.withdraw) 'totalWithdrawn': FieldValue.increment(amount),
        });

        // 거래 내역 생성
        if (kDebugMode) {
          print('🔵 거래 내역 생성 중...');
        }
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(
          transactionRef,
          {
            'userId': userId,
            'type': type.name,
            'amount': amount,
            'status': TransactionStatus.completed.name,
            'description': description,
            'metadata': metadata ?? {},
            'createdAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(),
          },
        );

        if (kDebugMode) {
          print('✅ Transaction.set 완료');
        }
      });

      if (kDebugMode) {
        print('✅ updateBalance 완료');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ updateBalance 실패: $e');
        print('StackTrace: $stackTrace');
      }
      rethrow;
    }
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
      (total, doc) => total + ((doc.data()['amount'] as int?) ?? 0),
    );
  }

  @override
  Stream<List<TransactionEntity>> getWithdrawalsByStatus(TransactionStatus status) {
    return _firestore
        .collection('transactions')
        .where('type', isEqualTo: TransactionType.withdraw.name)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionEntity.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> approveWithdrawal(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': TransactionStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rejectWithdrawal(String transactionId, String reason) async {
    await _firestore.runTransaction((transaction) async {
      final transactionRef = _firestore.collection('transactions').doc(transactionId);
      final transactionDoc = await transaction.get(transactionRef);

      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }

      final transactionData = TransactionEntity.fromFirestore(transactionId, transactionDoc.data()!);

      // 거래 상태를 취소로 변경
      transaction.update(transactionRef, {
        'status': TransactionStatus.cancelled.name,
        'completedAt': FieldValue.serverTimestamp(),
        'metadata': {
          ...transactionData.metadata,
          'rejectReason': reason,
        },
      });

      // 지갑 잔액 복구 (출금 신청 시 차감했던 금액을 다시 추가)
      final walletRef = _firestore.collection('wallets').doc(transactionData.userId);
      transaction.update(walletRef, {
        'balance': FieldValue.increment(transactionData.amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
