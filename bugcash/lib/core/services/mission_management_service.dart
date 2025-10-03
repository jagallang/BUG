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

  /// 테스터 신청 목록 조회 (mission_workflows 컬렉션에서 application_submitted 상태만 조회)
  Stream<List<TesterApplicationModel>> watchTesterApplications(String appId) {
    AppLogger.info('🔍 [대기목록] 조회 시작 - appId: $appId', 'MissionManagement');

    return _firestore
        .collection(_dailyMissionsCollection) // mission_workflows 컬렉션 사용
        .where('appId', isEqualTo: appId)
        .where('currentState', isEqualTo: 'application_submitted') // 신청 대기 상태만 조회
        .limit(100) // v2.13.1: 과도한 데이터 방지
        .snapshots()
        .handleError((error) {
          AppLogger.error('Firestore stream error (watchTesterApplications)', 'MissionManagement', error);
        })
        .map((snapshot) {
          AppLogger.info('📊 [대기목록] Firestore 조회 결과: ${snapshot.docs.length}개 문서', 'MissionManagement');

          // 각 문서 상세 정보 로그
          for (final doc in snapshot.docs) {
            final data = doc.data();
            AppLogger.info(
              '📄 [문서] ID: ${doc.id}\n'
              '   ├─ appId: ${data['appId']}\n'
              '   ├─ currentState: ${data['currentState']}\n'
              '   ├─ status: ${data['status']}\n'
              '   ├─ testerName: ${data['testerName']}\n'
              '   └─ appliedAt: ${data['appliedAt']}',
              'MissionManagement'
            );
          }

          final results = snapshot.docs
              .map((doc) => _convertMissionWorkflowToTesterApplication(doc.data(), doc.id))
              .toList();

          // 클라이언트 사이드 정렬 (appliedAt 기준 내림차순)
          results.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

          AppLogger.info('✅ [대기목록] 변환 완료: ${results.length}개 신청자', 'MissionManagement');
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
      AppLogger.info('🎯 [승인처리] 시작 - applicationId: $applicationId, status: ${status.name}', 'MissionManagement');

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

      AppLogger.info('📝 [승인처리] currentState 변경: application_submitted → $newState', 'MissionManagement');

      // Firestore 업데이트 전 문서 확인
      final docSnapshot = await _firestore.collection(_dailyMissionsCollection).doc(applicationId).get();
      if (!docSnapshot.exists) {
        AppLogger.error('❌ [승인처리] 문서를 찾을 수 없음: $applicationId', 'MissionManagement', null);
        throw Exception('Mission workflow document not found: $applicationId');
      }

      final beforeData = docSnapshot.data();
      AppLogger.info(
        '📄 [승인처리] 업데이트 전 데이터\n'
        '   ├─ currentState: ${beforeData?['currentState']}\n'
        '   ├─ appId: ${beforeData?['appId']}\n'
        '   └─ testerName: ${beforeData?['testerName']}',
        'MissionManagement'
      );

      await _firestore.collection(_dailyMissionsCollection).doc(applicationId).update({
        'currentState': newState,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': 'provider', // 실제 providerId로 교체 가능
        'reviewNote': reviewNote,
      });

      AppLogger.info('✅ [승인처리] Firestore 업데이트 완료 - $applicationId → $newState', 'MissionManagement');

      // 업데이트 후 문서 확인
      final afterSnapshot = await _firestore.collection(_dailyMissionsCollection).doc(applicationId).get();
      final afterData = afterSnapshot.data();
      AppLogger.info(
        '✨ [승인처리] 업데이트 후 데이터\n'
        '   ├─ currentState: ${afterData?['currentState']}\n'
        '   ├─ stateUpdatedAt: ${afterData?['stateUpdatedAt']}\n'
        '   └─ stateUpdatedBy: ${afterData?['stateUpdatedBy']}',
        'MissionManagement'
      );
    } catch (e) {
      AppLogger.error('❌ [승인처리] 실패', 'MissionManagement', e);
      rethrow;
    }
  }

  /// 승인된 테스터의 미션 시작 (approved → mission_in_progress)
  Future<void> startMissionForTester({
    required String workflowId,
  }) async {
    try {
      AppLogger.info('🚀 [미션시작] 시작 - workflowId: $workflowId', 'MissionManagement');

      await _firestore.collection(_dailyMissionsCollection).doc(workflowId).update({
        'currentState': 'mission_in_progress',
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'missionStartedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ [미션시작] 완료 - currentState: mission_in_progress', 'MissionManagement');
    } catch (e) {
      AppLogger.error('Failed to start mission for tester', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// v2.10.0: 일련번호 생성 헬퍼 (Transaction 사용)
  /// 형식: a{YYMMDD}-m{0001} 예: a251002-m0001
  Future<String> _generateSerialNumber(String appId, DateTime missionDate) async {
    try {
      // 날짜 포맷: YYMMDD
      final dateStr = '${missionDate.year.toString().substring(2)}${missionDate.month.toString().padLeft(2, '0')}${missionDate.day.toString().padLeft(2, '0')}';

      // appId 앞 6자리 (최소 6자리, 부족하면 패딩)
      final appPrefix = appId.length >= 6 ? appId.substring(0, 6) : appId.padRight(6, '0');

      // 카운터 문서 ID: {appId}_{YYMMDD}
      final counterDocId = '${appId}_$dateStr';
      final counterRef = _firestore.collection('mission_counters').doc(counterDocId);

      // Transaction으로 카운터 증가 (race condition 방지)
      final serialNumber = await _firestore.runTransaction<String>((transaction) async {
        final counterDoc = await transaction.get(counterRef);

        int nextCounter = 1;
        if (counterDoc.exists) {
          nextCounter = (counterDoc.data()?['counter'] ?? 0) + 1;
        }

        transaction.set(counterRef, {
          'counter': nextCounter,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 일련번호 생성: a{appPrefix}-{dateStr}-m{0001}
        final formattedCounter = nextCounter.toString().padLeft(4, '0');
        return 'a$appPrefix-$dateStr-m$formattedCounter';
      });

      AppLogger.info('🔢 Serial number generated: $serialNumber', 'MissionManagement');
      return serialNumber;
    } catch (e) {
      AppLogger.error('❌ Failed to generate serial number: $e', 'MissionManagement', e);
      // Fallback: 일련번호 생성 실패 시 타임스탬프 사용
      return 'a${appId.substring(0, 6)}-${DateTime.now().millisecondsSinceEpoch}';
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
      // v2.10.0: 일련번호 생성
      String? serialNumber;
      try {
        serialNumber = await _generateSerialNumber(appId, missionDate);
      } catch (e) {
        AppLogger.error('⚠️ Serial number generation failed, continuing without it', 'MissionManagement', e);
        // 일련번호 생성 실패해도 미션은 생성됨 (null 허용)
      }

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
        serialNumber: serialNumber, // v2.10.0
      );

      await docRef.set(mission.toFirestore());

      AppLogger.info('✅ Daily mission created: $testerId for ${missionDate.toString()} [${serialNumber ?? "no serial"}]', 'MissionManagementService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create daily mission', 'MissionManagementService', e);
      rethrow;
    }
  }

  /// 승인된 테스터 조회 (미션 시작 대기중) - mission_workflows에서 approved 상태만 조회
  Stream<List<TesterApplicationModel>> watchApprovedTesters(String appId) {
    AppLogger.info('🔍 [승인된테스터] 조회 시작 - appId: $appId', 'MissionManagement');

    return _firestore
        .collection(_dailyMissionsCollection) // mission_workflows 컬렉션
        .where('appId', isEqualTo: appId)
        .where('currentState', isEqualTo: 'approved') // 승인됨, 미션 시작 대기중
        .limit(100) // v2.13.1: 과도한 데이터 방지
        .snapshots()
        .handleError((error) {
          AppLogger.error('Firestore stream error (watchApprovedTesters)', 'MissionManagement', error);
        })
        .map((snapshot) {
          AppLogger.info('📊 [승인된테스터] Firestore 조회 결과: ${snapshot.docs.length}개', 'MissionManagement');

          final results = snapshot.docs
              .map((doc) => _convertMissionWorkflowToTesterApplication(doc.data(), doc.id))
              .toList();

          results.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

          AppLogger.info('✅ [승인된테스터] 변환 완료: ${results.length}개', 'MissionManagement');
          return results;
        });
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
    AppLogger.info('📋 [watchTesterTodayMissions] 조회 시작 - testerId=$testerId', 'MissionManagement');

    return _firestore
        .collection(_dailyMissionsCollection)
        .where('testerId', isEqualTo: testerId)
        .where('currentState', whereIn: [
          'application_submitted',    // 신청 완료 (승인 대기중)
          'approved',                 // 승인됨 (Firebase 실제 값)
          'in_progress',              // 미션 진행중 (미션 시작 후)
          'testing_completed',        // 테스트 완료 (10분 완료 후)
          'mission_in_progress',      // 미션 진행중 (레거시)
          'daily_mission_started',    // 일일 미션 시작 (레거시)
          'daily_mission_completed'   // 일일 미션 완료 (레거시)
        ])
        .snapshots()
        .map((snapshot) {
          AppLogger.info('📋 [watchTesterTodayMissions] ${snapshot.docs.length}개 미션 조회됨', 'MissionManagement');

          for (final doc in snapshot.docs) {
            final data = doc.data();
            AppLogger.info(
              '  - ${doc.id}: currentState=${data['currentState']}, startedAt=${data['startedAt']}, completedAt=${data['completedAt']}',
              'MissionManagement'
            );
          }

          return snapshot.docs
            .map((doc) {
              // MissionWorkflowModel을 DailyMissionModel로 변환
              final workflowData = MissionWorkflowModel.fromFirestore(doc);
              return DailyMissionModel(
                id: workflowData.id,
                appId: workflowData.appId,
                testerId: workflowData.testerId,
                missionDate: workflowData.appliedAt, // appliedAt을 missionDate로 사용
                status: _convertWorkflowStateToDailyMissionStatus(workflowData.currentState),
                missionTitle: workflowData.appName.isNotEmpty
                    ? '${workflowData.appName} 테스트'
                    : '일일 테스트 미션',
                missionDescription: workflowData.appName.isNotEmpty
                    ? '${workflowData.appName} 앱의 주요 기능들을 테스트하고 발견된 이슈를 리포트해주세요.'
                    : '앱의 주요 기능들을 테스트하고 발견된 이슈를 리포트해주세요.',
                baseReward: workflowData.dailyReward > 0
                    ? workflowData.dailyReward
                    : 5000,
                workflowId: workflowData.id,
                currentState: workflowData.currentState.code, // 실제 currentState 전달
                startedAt: workflowData.startedAt,       // v2.8.8: startedAt 추가
                completedAt: workflowData.completedAt,   // v2.8.8: completedAt 추가
              );
            })
            .toList();
        });
  }

  /// MissionWorkflowState를 DailyMissionStatus로 변환하는 헬퍼 메서드
  DailyMissionStatus _convertWorkflowStateToDailyMissionStatus(MissionWorkflowState state) {
    switch (state) {
      case MissionWorkflowState.applicationSubmitted:
        return DailyMissionStatus.pending; // 승인 대기중
      case MissionWorkflowState.applicationApproved:
        return DailyMissionStatus.inProgress; // 승인됨 (미션 시작 가능)
      case MissionWorkflowState.inProgress:           // v2.8+ 미션 진행중
      case MissionWorkflowState.testingCompleted:     // v2.8+ 테스트 완료
      case MissionWorkflowState.missionInProgress:
      case MissionWorkflowState.dailyMissionStarted:
        return DailyMissionStatus.inProgress;
      case MissionWorkflowState.dailyMissionCompleted:
        return DailyMissionStatus.completed;
      default:
        return DailyMissionStatus.pending;
    }
  }

  /// 완료된 미션 조회 (승인 대기중)
  /// v2.11.0: completed 상태만 조회 (승인 전)
  Stream<List<DailyMissionModel>> watchCompletedMissions(String appId) {
    return _firestore
        .collection(_dailyMissionsCollection)
        .where('appId', isEqualTo: appId)
        .where('status', isEqualTo: DailyMissionStatus.completed.name)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyMissionModel.fromFirestore(doc))
            .toList());
  }

  /// v2.11.0: 종료된 미션 조회 (settled 상태)
  Stream<List<DailyMissionModel>> watchSettledMissions(String appId) {
    return _firestore
        .collection(_dailyMissionsCollection)
        .where('appId', isEqualTo: appId)
        .where('status', isEqualTo: DailyMissionStatus.settled.name)
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
        case DailyMissionStatus.settled: // v2.11.0: 종료/정산 상태
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

  /// 공급자가 삭제 요청 목록 조회
  Stream<List<MissionDeletionModel>> watchDeletionRequests(String providerId) {
    return _firestore
        .collection('mission_deletions')
        .where('providerId', isEqualTo: providerId)
        .where('providerAcknowledged', isEqualTo: false)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MissionDeletionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// 공급자가 삭제 확인 및 영구 삭제
  Future<void> acknowledgeDeletion({
    required String deletionId,
    required String workflowId,
  }) async {
    try {
      // 1. mission_deletions 업데이트 (확인 완료)
      await _firestore.collection('mission_deletions').doc(deletionId).update({
        'providerAcknowledged': true,
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });

      // 2. mission_workflows 영구 삭제
      await _firestore.collection('mission_workflows').doc(workflowId).delete();

      AppLogger.info(
        'Mission deletion acknowledged and workflow deleted\n'
        '   ├─ deletionId: $deletionId\n'
        '   └─ workflowId: $workflowId',
        'MissionManagementService'
      );
    } catch (e) {
      AppLogger.error('Failed to acknowledge deletion', 'MissionManagementService', e);
      rethrow;
    }
  }
}