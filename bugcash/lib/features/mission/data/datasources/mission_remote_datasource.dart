import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mission_workflow_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/notification_service.dart';

/// Mission Remote Datasource
/// Firestore 직접 접근 레이어 (구현 세부사항)
class MissionRemoteDatasource {
  final FirebaseFirestore _firestore;

  MissionRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'mission_workflows';

  // ========================================
  // Query Methods (모두 .get() 사용 - 실시간 리스너 제거)
  // ========================================

  /// 공급자의 모든 미션 조회
  Future<List<MissionWorkflowModel>> fetchProviderMissions(String providerId) async {
    try {
      AppLogger.info('Fetching provider missions: $providerId', 'MissionDatasource');

      final snapshot = await _firestore
          .collection(_collection)
          .where('providerId', isEqualTo: providerId)
          .orderBy('appliedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MissionWorkflowModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch provider missions', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 테스터의 모든 미션 조회
  Future<List<MissionWorkflowModel>> fetchTesterMissions(String testerId) async {
    try {
      AppLogger.info('Fetching tester missions: $testerId', 'MissionDatasource');

      final snapshot = await _firestore
          .collection(_collection)
          .where('testerId', isEqualTo: testerId)
          .orderBy('appliedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MissionWorkflowModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch tester missions', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 특정 앱의 테스터 신청 목록 조회 (승인 대기 중)
  Future<List<MissionWorkflowModel>> fetchAppTesterApplications(String appId) async {
    try {
      AppLogger.info('Fetching app tester applications: $appId', 'MissionDatasource');

      final snapshot = await _firestore
          .collection(_collection)
          .where('appId', isEqualTo: appId)
          .where('currentState', isEqualTo: 'application_submitted')
          .orderBy('appliedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MissionWorkflowModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch app applications', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 특정 앱의 승인된 테스터 목록 조회
  Future<List<MissionWorkflowModel>> fetchAppApprovedTesters(String appId) async {
    try {
      AppLogger.info('Fetching app approved testers: $appId', 'MissionDatasource');

      final snapshot = await _firestore
          .collection(_collection)
          .where('appId', isEqualTo: appId)
          .where('currentState', isEqualTo: 'approved')
          .orderBy('approvedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MissionWorkflowModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch approved testers', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 특정 미션 상세 조회
  Future<MissionWorkflowModel?> fetchMissionById(String missionId) async {
    try {
      AppLogger.info('Fetching mission by id: $missionId', 'MissionDatasource');

      final doc = await _firestore.collection(_collection).doc(missionId).get();

      if (!doc.exists) {
        return null;
      }

      return MissionWorkflowModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to fetch mission by id', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 테스터의 진행 중인 미션 조회 (단일)
  Future<MissionWorkflowModel?> fetchTesterActiveMission(String testerId) async {
    try {
      AppLogger.info('Fetching active mission for tester: $testerId', 'MissionDatasource');

      final snapshot = await _firestore
          .collection(_collection)
          .where('testerId', isEqualTo: testerId)
          .where('currentState', isEqualTo: 'in_progress')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return MissionWorkflowModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      AppLogger.error('Failed to fetch active mission', 'MissionDatasource', e);
      rethrow;
    }
  }

  // ========================================
  // Command Methods (CUD operations)
  // ========================================

  /// 미션 신청 생성
  /// v2.18.0: totalDays 기본값 14일 → 10일 변경
  Future<String> createMissionApplication({
    required String appId,
    required String appName,
    required String testerId,
    required String testerName,
    required String testerEmail,
    required String experience,
    required String motivation,
    String? providerId,
    String? providerName,
    int totalDays = 10,  // v2.18.0: 14 → 10
    int dailyReward = 5000,
  }) async {
    try {
      AppLogger.info('Creating mission application for app: $appId', 'MissionDatasource');

      // providerId 자동 조회 (필요시)
      String safeProviderId = providerId ?? '';
      String safeProviderName = providerName ?? '';

      if (safeProviderId.isEmpty) {
        final normalizedAppId = appId.replaceAll('provider_app_', '');
        final projectDoc = await _firestore.collection('projects').doc(normalizedAppId).get();

        if (!projectDoc.exists) {
          throw Exception('Project not found: $normalizedAppId');
        }

        final projectData = projectDoc.data()!;
        safeProviderId = projectData['providerId'] ?? '';
        safeProviderName = projectData['providerName'] ?? projectData['appName'] ?? 'Unknown Provider';

        AppLogger.info('Auto-lookup provider: $safeProviderId', 'MissionDatasource');
      }

      if (safeProviderId.isEmpty) {
        throw ArgumentError('providerId could not be determined');
      }

      final model = MissionWorkflowModel(
        id: '',
        appId: appId,
        appName: appName,
        testerId: testerId,
        testerName: testerName,
        testerEmail: testerEmail,
        providerId: safeProviderId,
        providerName: safeProviderName,
        currentState: 'application_submitted',
        appliedAt: DateTime.now(),
        experience: experience,
        motivation: motivation,
        totalDays: totalDays,
        dailyReward: dailyReward,
      );

      final docRef = await _firestore.collection(_collection).add(model.toFirestore());

      AppLogger.info('Mission application created: ${docRef.id}', 'MissionDatasource');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create mission application', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 미션 승인
  /// v2.186.19: 테스터 알림 추가
  Future<void> approveMission(String missionId) async {
    try {
      AppLogger.info('Approving mission: $missionId', 'MissionDatasource');

      // Firestore 업데이트
      await _firestore.collection(_collection).doc(missionId).update({
        'currentState': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'stateUpdatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Mission approved: $missionId', 'MissionDatasource');

      // v2.186.19: 테스터에게 알림 전송
      try {
        final doc = await _firestore.collection(_collection).doc(missionId).get();
        if (doc.exists) {
          final data = doc.data()!;
          final testerId = data['testerId'] as String? ?? '';
          final appName = data['appName'] as String? ?? '';

          if (testerId.isEmpty) {
            AppLogger.warning(
              '⚠️ 테스터 알림 전송 실패: testerId가 비어있음\n'
              '   ├─ missionId: $missionId\n'
              '   └─ appName: $appName',
              'MissionDatasource'
            );
          } else {
            AppLogger.info(
              '📧 테스터에게 미션 승인 알림 전송 준비\n'
              '   ├─ testerId: $testerId\n'
              '   ├─ missionId: $missionId\n'
              '   └─ appName: $appName',
              'MissionDatasource'
            );

            await NotificationService.sendNotification(
              recipientId: testerId,
              title: '미션이 시작되었습니다!',
              message: '$appName 테스트가 시작되었습니다. Day 1부터 시작하세요!',
              type: 'mission_started',
              data: {
                'workflowId': missionId,
                'appName': appName,
              },
            );
          }
        }
      } catch (notificationError) {
        // 알림 실패 시에도 미션 승인은 성공으로 처리
        AppLogger.error(
          '❌ 테스터 알림 전송 실패 (미션 승인은 성공)\n'
          '   ├─ missionId: $missionId\n'
          '   └─ error: $notificationError',
          'MissionDatasource',
          notificationError
        );
      }
    } catch (e) {
      AppLogger.error('Failed to approve mission', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 미션 거부
  Future<void> rejectMission(String missionId, String reason) async {
    try {
      AppLogger.info('Rejecting mission: $missionId', 'MissionDatasource');

      await _firestore.collection(_collection).doc(missionId).update({
        'currentState': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Mission rejected: $missionId', 'MissionDatasource');
    } catch (e) {
      AppLogger.error('Failed to reject mission', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 미션 시작
  Future<void> startMission(String missionId) async {
    try {
      AppLogger.info('Starting mission: $missionId', 'MissionDatasource');

      await _firestore.collection(_collection).doc(missionId).update({
        'currentState': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'stateUpdatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Mission started: $missionId', 'MissionDatasource');
    } catch (e) {
      AppLogger.error('Failed to start mission', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 일일 미션 완료 기록
  Future<void> markDailyMissionCompleted({
    required String missionId,
    required int dayNumber,
  }) async {
    try {
      AppLogger.info('Marking daily mission completed: $missionId, day $dayNumber', 'MissionDatasource');

      await _firestore.collection(_collection).doc(missionId).update({
        'currentState': 'testing_completed',
        'completedDays': FieldValue.increment(1),
        'lastCompletedAt': FieldValue.serverTimestamp(),
        'stateUpdatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Daily mission completed: $missionId', 'MissionDatasource');
    } catch (e) {
      AppLogger.error('Failed to mark daily mission completed', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 미션 취소
  Future<void> cancelMission(String missionId, String reason) async {
    try {
      AppLogger.info('Cancelling mission: $missionId', 'MissionDatasource');

      await _firestore.collection(_collection).doc(missionId).update({
        'currentState': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Mission cancelled: $missionId', 'MissionDatasource');
    } catch (e) {
      AppLogger.error('Failed to cancel mission', 'MissionDatasource', e);
      rethrow;
    }
  }

  /// 미션 삭제
  Future<void> deleteMission(String missionId) async {
    try {
      AppLogger.info('Deleting mission: $missionId', 'MissionDatasource');

      await _firestore.collection(_collection).doc(missionId).delete();

      AppLogger.info('Mission deleted: $missionId', 'MissionDatasource');
    } catch (e) {
      AppLogger.error('Failed to delete mission', 'MissionDatasource', e);
      rethrow;
    }
  }

  // ========================================
  // Real-time Stream (선택적 - 진행 중 미션만)
  // ========================================

  /// 테스터의 활성 미션 실시간 감시 (단 1개만)
  Stream<MissionWorkflowModel?> watchActiveMission(String testerId) {
    AppLogger.info('Watching active mission for tester: $testerId', 'MissionDatasource');

    return _firestore
        .collection(_collection)
        .where('testerId', isEqualTo: testerId)
        .where('currentState', isEqualTo: 'in_progress')
        .limit(1) // 단 1개만 실시간 감시
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return MissionWorkflowModel.fromFirestore(snapshot.docs.first);
    });
  }
}
