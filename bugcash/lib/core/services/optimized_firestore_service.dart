import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// 최적화된 Firestore 서비스 클래스
/// PRD 요구사항에 따른 새로운 컬렉션 구조 지원
class OptimizedFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==============================================
  // 컬렉션 참조들
  // ==============================================

  /// 통합 사용자 관리
  static CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  /// 통합 프로젝트 관리 (apps + missions 통합)
  static CollectionReference<Map<String, dynamic>> get projects =>
      _firestore.collection('projects');

  /// 통합 신청 관리
  static CollectionReference<Map<String, dynamic>> get applications =>
      _firestore.collection('applications');

  /// 활성 미션 관리
  static CollectionReference<Map<String, dynamic>> get enrollments =>
      _firestore.collection('enrollments');

  /// 일일 미션 관리
  static CollectionReference<Map<String, dynamic>> get missions =>
      _firestore.collection('missions');

  /// 포인트 거래 내역
  static CollectionReference<Map<String, dynamic>> get pointsTransactions =>
      _firestore.collection('points_transactions');

  /// 신고 관리
  static CollectionReference<Map<String, dynamic>> get reports =>
      _firestore.collection('reports');

  /// 알림 관리
  static CollectionReference<Map<String, dynamic>> get notifications =>
      _firestore.collection('notifications');

  /// 관리자 대시보드 통계
  static CollectionReference<Map<String, dynamic>> get adminDashboard =>
      _firestore.collection('admin_dashboard');

  // ==============================================
  // 범용 CRUD 작업
  // ==============================================

  /// 문서 생성
  static Future<String> create(
    CollectionReference<Map<String, dynamic>> collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final doc = await collection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Document created: ${doc.id}', 'OptimizedFirestore');
      return doc.id;
    } catch (e) {
      AppLogger.error('Failed to create document', e.toString());
      rethrow;
    }
  }

  /// 특정 ID로 문서 생성
  static Future<void> createWithId(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await collection.doc(docId).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Document created with ID: $docId', 'OptimizedFirestore');
    } catch (e) {
      AppLogger.error('Failed to create document with ID: $docId', e.toString());
      rethrow;
    }
  }

  /// 문서 읽기
  static Future<Map<String, dynamic>?> read(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
  ) async {
    try {
      final doc = await collection.doc(docId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to read document: $docId', e.toString());
      return null;
    }
  }

  /// 문서 업데이트
  static Future<void> update(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await collection.doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Document updated: $docId', 'OptimizedFirestore');
    } catch (e) {
      AppLogger.error('Failed to update document: $docId', e.toString());
      rethrow;
    }
  }

  /// 문서 삭제
  static Future<void> delete(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
  ) async {
    try {
      await collection.doc(docId).delete();
      AppLogger.info('Document deleted: $docId', 'OptimizedFirestore');
    } catch (e) {
      AppLogger.error('Failed to delete document: $docId', e.toString());
      rethrow;
    }
  }

  // ==============================================
  // 쿼리 빌더들
  // ==============================================

  /// 프로젝트 스트림 (상태별 필터링)
  static Stream<List<Map<String, dynamic>>> getProjectsStream({
    String? status,
    String? providerId,
    String? category,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = projects;

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (providerId != null) {
      query = query.where('providerId', isEqualTo: providerId);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  /// 신청 스트림 (프로젝트별 또는 테스터별)
  static Stream<List<Map<String, dynamic>>> getApplicationsStream({
    String? projectId,
    String? testerId,
    String? status,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = applications;

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (testerId != null) {
      query = query.where('testerId', isEqualTo: testerId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('appliedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  /// 활성 미션 스트림
  static Stream<List<Map<String, dynamic>>> getEnrollmentsStream({
    String? projectId,
    String? testerId,
    String? status,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = enrollments;

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (testerId != null) {
      query = query.where('testerId', isEqualTo: testerId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('startedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  /// 일일 미션 스트림
  static Stream<List<Map<String, dynamic>>> getMissionsStream({
    String? enrollmentId,
    String? projectId,
    String? testerId,
    String? status,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = missions;

    if (enrollmentId != null) {
      query = query.where('enrollmentId', isEqualTo: enrollmentId);
    }
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (testerId != null) {
      query = query.where('testerId', isEqualTo: testerId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('dayNumber', descending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  /// 포인트 거래 내역 스트림
  static Stream<List<Map<String, dynamic>>> getPointsTransactionsStream({
    required String userId,
    String? type,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = pointsTransactions;

    query = query.where('userId', isEqualTo: userId);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    query = query.orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  /// 알림 스트림
  static Stream<List<Map<String, dynamic>>> getNotificationsStream({
    required String userId,
    bool? read,
    String? type,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = notifications;

    query = query.where('userId', isEqualTo: userId);

    if (read != null) {
      query = query.where('read', isEqualTo: read);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    query = query.orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  // ==============================================
  // 복잡한 쿼리들
  // ==============================================

  /// 사용자 포인트 잔액 조회
  static Future<int> getUserPoints(String userId) async {
    try {
      final userDoc = await read(users, userId);
      return userDoc?['points'] ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get user points: $userId', e.toString());
      return 0;
    }
  }

  /// 사용자 포인트 업데이트 (트랜잭션)
  static Future<void> updateUserPoints({
    required String userId,
    required int amount,
    required String type,
    required String description,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 사용자 문서 읽기
        final userRef = users.doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found: $userId');
        }

        final currentPoints = userDoc.data()!['points'] as int? ?? 0;
        final newBalance = currentPoints + amount;

        if (newBalance < 0) {
          throw Exception('Insufficient points');
        }

        // 포인트 업데이트
        transaction.update(userRef, {'points': newBalance});

        // 거래 내역 생성
        final transactionRef = pointsTransactions.doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'type': type,
          'amount': amount,
          'balance': newBalance,
          'description': description,
          'relatedId': relatedId,
          'metadata': metadata ?? {},
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      AppLogger.info('Points updated for user: $userId, amount: $amount', 'OptimizedFirestore');
    } catch (e) {
      AppLogger.error('Failed to update user points: $userId', e.toString());
      rethrow;
    }
  }

  /// 프로젝트 통계 조회
  static Future<Map<String, int>> getProjectStats({String? providerId}) async {
    try {
      Query<Map<String, dynamic>> query = projects;

      if (providerId != null) {
        query = query.where('providerId', isEqualTo: providerId);
      }

      final snapshot = await query.get();
      final projectDocs = snapshot.docs;

      final stats = <String, int>{
        'total': projectDocs.length,
        'draft': 0,
        'pending': 0,
        'open': 0,
        'closed': 0,
        'rejected': 0,
      };

      for (final doc in projectDocs) {
        final status = doc.data()['status'] as String? ?? 'draft';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      AppLogger.error('Failed to get project stats', e.toString());
      return {};
    }
  }

  /// 배치 작업 지원
  static WriteBatch batch() => _firestore.batch();

  /// 트랜잭션 지원
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) {
    return _firestore.runTransaction(updateFunction);
  }

  // ==============================================
  // 유틸리티 메서드들
  // ==============================================

  /// 컬렉션 존재 확인
  static Future<bool> collectionExists(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 문서 존재 확인
  static Future<bool> documentExists(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
  ) async {
    try {
      final doc = await collection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 페이지네이션 지원
  static Future<QuerySnapshot<Map<String, dynamic>>> getPage(
    Query<Map<String, dynamic>> query,
    DocumentSnapshot? lastDocument,
    int pageSize,
  ) async {
    Query<Map<String, dynamic>> pageQuery = query.limit(pageSize);

    if (lastDocument != null) {
      pageQuery = pageQuery.startAfterDocument(lastDocument);
    }

    return await pageQuery.get();
  }
}