import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/entities/user_entity.dart';

abstract class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== 새로운 최적화된 컬렉션 구조 =====

  /// 통합 사용자 관리 (tester + provider + admin)
  static CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  /// 통합 프로젝트 관리 (apps + missions 통합)
  static CollectionReference<Map<String, dynamic>> get projects =>
      _firestore.collection('projects');

  /// 통합 신청 관리 (mission_applications + tester_applications + mission_workflows 통합)
  static CollectionReference<Map<String, dynamic>> get applications =>
      _firestore.collection('applications');

  /// 활성 미션 관리 (승인된 신청의 진행 상황)
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

  // ===== 레거시 컬렉션 지원 (마이그레이션 기간 동안) =====

  @Deprecated('Use applications instead')
  static CollectionReference<Map<String, dynamic>> get missionApplications =>
      _firestore.collection('mission_applications');

  @Deprecated('Use applications instead')
  static CollectionReference<Map<String, dynamic>> get testerApplications =>
      _firestore.collection('tester_applications');

  @Deprecated('Use projects instead')
  static CollectionReference<Map<String, dynamic>> get apps =>
      _firestore.collection('apps');

  @Deprecated('Use reports instead')
  static CollectionReference<Map<String, dynamic>> get bugReports =>
      _firestore.collection('bug_reports');

  @Deprecated('Use pointsTransactions instead')
  static CollectionReference<Map<String, dynamic>> get payments =>
      _firestore.collection('payments');

  // Generic CRUD Operations
  static Future<String> create(
    CollectionReference<Map<String, dynamic>> collection,
    Map<String, dynamic> data,
  ) async {
    final doc = await collection.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  static Future<Map<String, dynamic>?> read(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
  ) async {
    final doc = await collection.doc(docId).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data()!};
    }
    return null;
  }

  static Future<void> update(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await collection.doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> delete(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
  ) async {
    await collection.doc(docId).delete();
  }

  static Stream<List<Map<String, dynamic>>> streamCollection(
    CollectionReference<Map<String, dynamic>> collection, {
    Query<Map<String, dynamic>>? Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = collection;
    
    if (queryBuilder != null) {
      final result = queryBuilder(query);
      if (result != null) {
        query = result;
      }
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  static Future<List<Map<String, dynamic>>> getCollection(
    CollectionReference<Map<String, dynamic>> collection, {
    Query<Map<String, dynamic>>? Function(Query<Map<String, dynamic>>)? queryBuilder,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = collection;
    
    if (queryBuilder != null) {
      final result = queryBuilder(query);
      if (result != null) {
        query = result;
      }
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  // User-specific operations
  static Future<UserEntity?> getUser(String userId) async {
    final data = await read(users, userId);
    if (data != null) {
      return UserEntity.fromFirestore(userId, data);
    }
    return null;
  }

  static Future<void> createUser(UserEntity user) async {
    await users.doc(user.uid).set(user.toFirestore());
  }

  static Future<void> updateUser(UserEntity user) async {
    await update(users, user.uid, user.toFirestore());
  }

  static Stream<UserEntity?> streamUser(String userId) {
    return users.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserEntity.fromFirestore(userId, doc.data()!);
      }
      return null;
    });
  }

  // Mission-specific operations
  static Stream<List<Map<String, dynamic>>> streamMissions({
    String? providerId,
    String? status,
    List<String>? types,
    String? difficulty,
    int? limit,
  }) {
    return streamCollection(
      missions,
      queryBuilder: (query) {
        Query<Map<String, dynamic>> filteredQuery = query;
        
        if (providerId != null) {
          filteredQuery = filteredQuery.where('providerId', isEqualTo: providerId);
        }
        
        if (status != null) {
          filteredQuery = filteredQuery.where('status', isEqualTo: status);
        }
        
        if (types != null && types.isNotEmpty) {
          filteredQuery = filteredQuery.where('type', whereIn: types);
        }
        
        if (difficulty != null) {
          filteredQuery = filteredQuery.where('difficulty', isEqualTo: difficulty);
        }
        
        filteredQuery = filteredQuery.orderBy('createdAt', descending: true);
        
        if (limit != null) {
          filteredQuery = filteredQuery.limit(limit);
        }
        
        return filteredQuery;
      },
    );
  }

  // Bug Reports operations
  static Stream<List<Map<String, dynamic>>> streamBugReports({
    String? missionId,
    String? testerId,
    String? providerId,
    String? status,
    String? severity,
    int? limit,
  }) {
    return streamCollection(
      reports,
      queryBuilder: (query) {
        Query<Map<String, dynamic>> filteredQuery = query;
        
        if (missionId != null) {
          filteredQuery = filteredQuery.where('missionId', isEqualTo: missionId);
        }
        
        if (testerId != null) {
          filteredQuery = filteredQuery.where('testerId', isEqualTo: testerId);
        }
        
        if (providerId != null) {
          filteredQuery = filteredQuery.where('providerId', isEqualTo: providerId);
        }
        
        if (status != null) {
          filteredQuery = filteredQuery.where('status', isEqualTo: status);
        }
        
        if (severity != null) {
          filteredQuery = filteredQuery.where('severity', isEqualTo: severity);
        }
        
        filteredQuery = filteredQuery.orderBy('submittedAt', descending: true);
        
        if (limit != null) {
          filteredQuery = filteredQuery.limit(limit);
        }
        
        return filteredQuery;
      },
    );
  }

  // Mission Applications operations
  static Stream<List<Map<String, dynamic>>> streamMissionApplications({
    String? missionId,
    String? testerId,
    String? providerId,
    String? status,
    int? limit,
  }) {
    return streamCollection(
      applications,
      queryBuilder: (query) {
        Query<Map<String, dynamic>> filteredQuery = query;
        
        if (missionId != null) {
          filteredQuery = filteredQuery.where('missionId', isEqualTo: missionId);
        }
        
        if (testerId != null) {
          filteredQuery = filteredQuery.where('testerId', isEqualTo: testerId);
        }
        
        if (providerId != null) {
          filteredQuery = filteredQuery.where('providerId', isEqualTo: providerId);
        }
        
        if (status != null) {
          filteredQuery = filteredQuery.where('status', isEqualTo: status);
        }
        
        filteredQuery = filteredQuery.orderBy('createdAt', descending: true);
        
        if (limit != null) {
          filteredQuery = filteredQuery.limit(limit);
        }
        
        return filteredQuery;
      },
    );
  }

  // Analytics and Stats
  static Future<Map<String, dynamic>> getProviderStats(String providerId) async {
    // Get provider missions count
    final missionsQuery = await missions
        .where('providerId', isEqualTo: providerId)
        .get();

    final activeMissions = missionsQuery.docs
        .where((doc) => doc.data()['status'] == 'active')
        .length;

    final completedMissions = missionsQuery.docs
        .where((doc) => doc.data()['status'] == 'completed')
        .length;

    // Get bug reports count
    final bugReportsQuery = await reports
        .where('providerId', isEqualTo: providerId)
        .get();

    final totalBugReports = bugReportsQuery.docs.length;
    final criticalBugs = bugReportsQuery.docs
        .where((doc) => doc.data()['severity'] == 'critical')
        .length;

    return {
      'totalMissions': missionsQuery.docs.length,
      'activeMissions': activeMissions,
      'completedMissions': completedMissions,
      'totalBugReports': totalBugReports,
      'criticalBugs': criticalBugs,
    };
  }

  static Future<Map<String, dynamic>> getTesterStats(String testerId) async {
    // Get tester applications count
    final applicationsQuery = await applications
        .where('testerId', isEqualTo: testerId)
        .get();

    final acceptedApplications = applicationsQuery.docs
        .where((doc) => doc.data()['status'] == 'accepted')
        .length;

    final completedApplications = applicationsQuery.docs
        .where((doc) => doc.data()['status'] == 'completed')
        .length;

    // Get submitted bug reports count
    final bugReportsQuery = await reports
        .where('testerId', isEqualTo: testerId)
        .get();

    return {
      'totalApplications': applicationsQuery.docs.length,
      'acceptedMissions': acceptedApplications,
      'completedMissions': completedApplications,
      'totalBugReports': bugReportsQuery.docs.length,
    };
  }

  // Utility methods
  static Future<bool> checkDocumentExists(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
  ) async {
    final doc = await collection.doc(docId).get();
    return doc.exists;
  }

  static Future<int> getCollectionCount(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.count().get();
    return snapshot.count ?? 0;
  }

  // Batch operations
  static WriteBatch batch() => _firestore.batch();

  static Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }
}