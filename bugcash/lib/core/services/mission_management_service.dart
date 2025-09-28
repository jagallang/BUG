import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/shared/models/mission_management_model.dart';
import '../../features/shared/models/mission_workflow_model.dart';
import '../utils/logger.dart';

/// 미션 관리 서비스 (기존 시스템과 완전 분리)
class MissionManagementService {
  static final MissionManagementService _instance = MissionManagementService._internal();
  factory MissionManagementService() => _instance;
  MissionManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 이름들 (기존 시스템과 분리)
  static const String _missionManagementCollection = 'missionManagement';
  static const String _testerApplicationsCollection = 'testerApplications';
  static const String _dailyMissionsCollection = 'mission_workflows';
  static const String _settlementsCollection = 'settlements';

  /// 미션 관리 시스템 초기화
  Future<String> initializeMissionManagement({
    required String appId,
    required String providerId,
    int testPeriodDays = 14,
  }) async {
    try {
      final docRef = _firestore.collection(_missionManagementCollection).doc();

      final missionManagement = MissionManagementModel(
        id: docRef.id,
        appId: appId,
        providerId: providerId,
        currentPhase: MissionPhase.testerRecruitment,
        isActive: true,
        startDate: DateTime.now(),
        testPeriodDays: testPeriodDays,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(missionManagement.toFirestore());

      AppLogger.info('Mission management initialized for app: $appId', 'MissionManagementService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to initialize mission management', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 미션 관리 상태 조회
  Stream<MissionManagementModel?> watchMissionManagement(String appId) {
    return _firestore
        .collection(_missionManagementCollection)
        .where('appId', isEqualTo: appId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return MissionManagementModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// 미션 관리 상태 업데이트
  Future<void> updateMissionPhase({
    required String appId,
    required MissionPhase newPhase,
  }) async {
    try {
      final query = await _firestore
          .collection(_missionManagementCollection)
          .where('appId', isEqualTo: appId)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'currentPhase': newPhase.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        AppLogger.info('Mission phase updated for app: $appId to $newPhase', 'MissionManagementService');
      }
    } catch (e) {
      AppLogger.error('Failed to update mission phase', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 테스터 신청 추가
  Future<String> addTesterApplication({
    required String appId,
    required String testerId,
    required String testerName,
    required String testerEmail,
    Map<String, dynamic> testerProfile = const {},
  }) async {
    try {
      final docRef = _firestore.collection(_testerApplicationsCollection).doc();

      final application = TesterApplicationModel(
        id: docRef.id,
        appId: appId,
        testerId: testerId,
        testerName: testerName,
        testerEmail: testerEmail,
        status: TesterApplicationStatus.pending,
        appliedAt: DateTime.now(),
        testerProfile: testerProfile,
      );

      await docRef.set(application.toFirestore());

      AppLogger.info('Tester application added: $testerId for app: $appId', 'MissionManagementService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to add tester application', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 테스터 신청 목록 조회 (mission_workflows 컬렉션에서 application_submitted, approved 상태 조회)
  Stream<List<TesterApplicationModel>> watchTesterApplications(String appId) {
    return _firestore
        .collection(_dailyMissionsCollection) // mission_workflows 컬렉션 사용
        .where('appId', isEqualTo: appId)
        .where('currentState', whereIn: ['application_submitted', 'approved']) // 신청 및 승인 상태 모두 조회
        .snapshots()
        .map((snapshot) {
          final results = snapshot.docs
              .map((doc) => _convertMissionWorkflowToTesterApplication(doc.data(), doc.id))
              .toList();

          // 클라이언트 사이드 정렬 (appliedAt 기준 내림차순)
          results.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

          return results;
        });
  }

  /// MissionWorkflow 데이터를 TesterApplicationModel로 변환
  TesterApplicationModel _convertMissionWorkflowToTesterApplication(Map<String, dynamic> data, String docId) {
    return TesterApplicationModel(
      id: docId,
      appId: data['appId'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? data['testerDisplayName'] ?? 'Unknown Tester',
      testerEmail: data['testerEmail'] ?? '',
      status: TesterApplicationStatus.pending, // application_submitted → pending 매핑
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      testerProfile: {
        'photoURL': data['testerPhotoURL'],
        'experience': data['testerExperience'] ?? 'Unknown',
      },
    );
  }

  /// 테스터 신청 승인/거부 (mission_workflows 컬렉션의 currentState 업데이트)
  Future<void> reviewTesterApplication({
    required String applicationId,
    required TesterApplicationStatus status,
    String? reviewNote,
  }) async {
    try {
      // TesterApplicationStatus를 MissionWorkflow state로 변환
      String newState;
      switch (status) {
        case TesterApplicationStatus.approved:
          newState = 'approved';
          break;
        case TesterApplicationStatus.rejected:
          newState = 'rejected';
          break;
        default:
          newState = 'application_submitted';
          break;
      }

      await _firestore.collection(_dailyMissionsCollection).doc(applicationId).update({
        'currentState': newState,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': 'provider', // 실제 providerId로 교체 가능
        'reviewNote': reviewNote,
      });

      AppLogger.info('Tester application reviewed: $applicationId -> $newState', 'MissionManagementService');
    } catch (e) {
      AppLogger.error('Failed to review tester application', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 일일 미션 생성
  Future<String> createDailyMission({
    required String appId,
    required String testerId,
    required DateTime missionDate,
    required String missionTitle,
    required String missionDescription,
    required int baseReward,
  }) async {
    try {
      final docRef = _firestore.collection(_dailyMissionsCollection).doc();

      final mission = DailyMissionModel(
        id: docRef.id,
        appId: appId,
        testerId: testerId,
        missionDate: missionDate,
        status: DailyMissionStatus.pending,
        missionTitle: missionTitle,
        missionDescription: missionDescription,
        baseReward: baseReward,
      );

      await docRef.set(mission.toFirestore());

      AppLogger.info('Daily mission created: $testerId for ${missionDate.toString()}', 'MissionManagementService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create daily mission', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 오늘 미션 조회 (앱 기반)
  Stream<List<DailyMissionModel>> watchTodayMissions(String appId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_dailyMissionsCollection)
        .where('appId', isEqualTo: appId)
        .where('missionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('missionDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('missionDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyMissionModel.fromFirestore(doc))
            .toList());
  }

  /// 테스터 오늘 미션 조회 (테스터 기반) - mission_workflows 컬렉션 사용
  Stream<List<DailyMissionModel>> watchTesterTodayMissions(String testerId) {
    return _firestore
        .collection(_dailyMissionsCollection)
        .where('testerId', isEqualTo: testerId)
        .where('currentState', whereIn: ['mission_in_progress', 'daily_mission_started', 'daily_mission_completed'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              // MissionWorkflowModel을 DailyMissionModel로 변환
              final workflowData = MissionWorkflowModel.fromFirestore(doc);
              return DailyMissionModel(
                id: workflowData.id,
                appId: workflowData.appId,
                testerId: workflowData.testerId,
                missionDate: workflowData.appliedAt, // appliedAt을 missionDate로 사용
                status: _convertWorkflowStateToDailyMissionStatus(workflowData.currentState),
                missionTitle: '일일 테스트 미션',
                missionDescription: '앱의 주요 기능들을 테스트하고 발견된 이슈를 리포트해주세요.',
                baseReward: 5000,
              );
            })
            .toList());
  }

  /// MissionWorkflowState를 DailyMissionStatus로 변환하는 헬퍼 메서드
  DailyMissionStatus _convertWorkflowStateToDailyMissionStatus(MissionWorkflowState state) {
    switch (state) {
      case MissionWorkflowState.missionInProgress:
      case MissionWorkflowState.dailyMissionStarted:
        return DailyMissionStatus.inProgress;
      case MissionWorkflowState.dailyMissionCompleted:
        return DailyMissionStatus.completed;
      default:
        return DailyMissionStatus.pending;
    }
  }

  /// 완료된 미션 조회
  Stream<List<DailyMissionModel>> watchCompletedMissions(String appId) {
    return _firestore
        .collection(_dailyMissionsCollection)
        .where('appId', isEqualTo: appId)
        .where('status', isEqualTo: DailyMissionStatus.approved.name)
        .orderBy('approvedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyMissionModel.fromFirestore(doc))
            .toList());
  }

  /// 미션 상태 업데이트
  Future<void> updateMissionStatus({
    required String missionId,
    required DailyMissionStatus status,
    String? note,
    List<String>? attachments,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      switch (status) {
        case DailyMissionStatus.inProgress:
          updateData['startedAt'] = FieldValue.serverTimestamp();
          break;
        case DailyMissionStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          if (note != null) updateData['completionNote'] = note;
          if (attachments != null) updateData['attachments'] = attachments;
          break;
        case DailyMissionStatus.approved:
          updateData['approvedAt'] = FieldValue.serverTimestamp();
          if (note != null) updateData['reviewNote'] = note;
          break;
        case DailyMissionStatus.rejected:
          if (note != null) updateData['reviewNote'] = note;
          break;
        default:
          break;
      }

      await _firestore.collection(_dailyMissionsCollection).doc(missionId).update(updateData);

      AppLogger.info('Mission status updated: $missionId -> $status', 'MissionManagementService');
    } catch (e) {
      AppLogger.error('Failed to update mission status', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 14일 완료 시 정산 생성
  Future<String> createSettlement({
    required String appId,
    required String testerId,
    required String testerName,
  }) async {
    try {
      // 완료된 미션들 조회
      final completedMissions = await _firestore
          .collection(_dailyMissionsCollection)
          .where('appId', isEqualTo: appId)
          .where('testerId', isEqualTo: testerId)
          .where('status', isEqualTo: DailyMissionStatus.approved.name)
          .get();

      final totalBaseReward = completedMissions.docs.fold<int>(
        0,
        (total, doc) => total + (doc.data()['baseReward'] as int? ?? 0),
      );

      // 보너스 계산 (완료율 기반)
      const totalDays = 14;
      final completedCount = completedMissions.docs.length;
      final completionRate = completedCount / totalDays;

      int bonusReward = 0;
      if (completionRate >= 1.0) {
        bonusReward = (totalBaseReward * 0.2).round(); // 100% 완료 시 20% 보너스
      } else if (completionRate >= 0.8) {
        bonusReward = (totalBaseReward * 0.1).round(); // 80% 이상 완료 시 10% 보너스
      }

      final docRef = _firestore.collection(_settlementsCollection).doc();

      final settlement = MissionSettlementModel(
        id: docRef.id,
        appId: appId,
        testerId: testerId,
        testerName: testerName,
        totalDays: totalDays,
        completedMissions: completedCount,
        totalBaseReward: totalBaseReward,
        bonusReward: bonusReward,
        finalAmount: totalBaseReward + bonusReward,
        isPaid: false,
        calculatedAt: DateTime.now(),
      );

      await docRef.set(settlement.toFirestore());

      AppLogger.info('Settlement created for tester: $testerId, amount: ${settlement.finalAmount}', 'MissionManagementService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create settlement', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 정산 목록 조회 (앱 기반)
  Stream<List<MissionSettlementModel>> watchSettlements(String appId) {
    return _firestore
        .collection(_settlementsCollection)
        .where('appId', isEqualTo: appId)
        .orderBy('calculatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissionSettlementModel.fromFirestore(doc))
            .toList());
  }

  /// 테스터 정산 목록 조회 (테스터 기반)
  Stream<List<MissionSettlementModel>> watchTesterSettlements(String testerId) {
    return _firestore
        .collection(_settlementsCollection)
        .where('testerId', isEqualTo: testerId)
        .orderBy('calculatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissionSettlementModel.fromFirestore(doc))
            .toList());
  }

  /// 정산 지급 완료 처리
  Future<void> markSettlementAsPaid({
    required String settlementId,
    String? paymentMethod,
    String? paymentNote,
  }) async {
    try {
      await _firestore.collection(_settlementsCollection).doc(settlementId).update({
        'isPaid': true,
        'paidAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        'paymentNote': paymentNote,
      });

      AppLogger.info('Settlement marked as paid: $settlementId', 'MissionManagementService');
    } catch (e) {
      AppLogger.error('Failed to mark settlement as paid', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 자동 일일 미션 생성 (매일 실행)
  Future<void> generateDailyMissions(String appId) async {
    try {
      // 승인된 테스터들 조회
      final approvedTesters = await _firestore
          .collection(_testerApplicationsCollection)
          .where('appId', isEqualTo: appId)
          .where('status', isEqualTo: TesterApplicationStatus.approved.name)
          .get();

      final today = DateTime.now();
      final todayFormatted = DateTime(today.year, today.month, today.day);

      // 각 테스터에 대해 오늘 미션 생성
      for (final testerDoc in approvedTesters.docs) {
        final testerId = testerDoc.data()['testerId'] as String;

        // 이미 오늘 미션이 있는지 확인
        final existingMission = await _firestore
            .collection(_dailyMissionsCollection)
            .where('appId', isEqualTo: appId)
            .where('testerId', isEqualTo: testerId)
            .where('missionDate', isEqualTo: Timestamp.fromDate(todayFormatted))
            .get();

        if (existingMission.docs.isEmpty) {
          await createDailyMission(
            appId: appId,
            testerId: testerId,
            missionDate: todayFormatted,
            missionTitle: '일일 테스트 미션',
            missionDescription: '앱의 주요 기능들을 테스트하고 발견된 이슈를 리포트해주세요.',
            baseReward: 5000, // 기본 보상
          );
        }
      }

      AppLogger.info('Daily missions generated for app: $appId', 'MissionManagementService');
    } catch (e) {
      AppLogger.error('Failed to generate daily missions', 'MissionManagementService', e);
      rethrow;
    }
  }
}