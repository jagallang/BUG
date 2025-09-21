import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/shared/models/mission_workflow_model.dart';
import '../utils/logger.dart';

/// 미션 워크플로우 서비스
/// 테스터-공급자 간 미션 상호작용 관리
class MissionWorkflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1단계: 미션 신청 생성
  Future<String> createMissionApplication({
    required String appId,
    required String appName,
    required String testerId,
    required String testerName,
    required String testerEmail,
    required String providerId,
    required String providerName,
    required String experience,
    required String motivation,
    int totalDays = 14,
    int dailyReward = 5000,
  }) async {
    try {
      AppLogger.info('Creating mission application for $appName by $testerName', 'MissionWorkflow');

      final workflow = MissionWorkflowModel(
        id: '',
        appId: appId,
        appName: appName,
        testerId: testerId,
        testerName: testerName,
        testerEmail: testerEmail,
        providerId: providerId,
        providerName: providerName,
        currentState: MissionWorkflowState.applicationSubmitted,
        stateUpdatedAt: DateTime.now(),
        stateUpdatedBy: testerId,
        appliedAt: DateTime.now(),
        experience: experience,
        motivation: motivation,
        totalDays: totalDays,
        dailyReward: dailyReward,
      );

      final docRef = await _firestore
          .collection('mission_workflows')
          .add(workflow.toFirestore());

      // 공급자에게 알림 전송
      await _sendNotificationToProvider(
        providerId: providerId,
        title: '새로운 테스터 신청',
        message: '$testerName님이 $appName 테스트를 신청했습니다.',
        data: {
          'workflowId': docRef.id,
          'testerId': testerId,
          'testerName': testerName,
        },
      );

      AppLogger.info('Mission application created: ${docRef.id}', 'MissionWorkflow');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create mission application', e.toString());
      rethrow;
    }
  }

  // 2단계: 신청 승인/거부
  Future<void> processMissionApplication({
    required String workflowId,
    required bool approved,
    required String processedBy,
    String? feedback,
  }) async {
    try {
      AppLogger.info('Processing mission application $workflowId: ${approved ? "approved" : "rejected"}', 'MissionWorkflow');

      final newState = approved
          ? MissionWorkflowState.applicationApproved
          : MissionWorkflowState.applicationRejected;

      final updateData = {
        'currentState': newState.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': processedBy,
      };

      if (approved) {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
        updateData['approvedBy'] = processedBy;
        updateData['startedAt'] = FieldValue.serverTimestamp();
        updateData['currentDay'] = 1;

        // 첫 날 일일 미션 생성
        await _createDailyMission(workflowId, 1);
      }

      if (feedback != null) {
        updateData['metadata.approvalFeedback'] = feedback;
      }

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update(updateData);

      // 테스터에게 알림 전송
      final workflow = await getMissionWorkflow(workflowId);
      await _sendNotificationToTester(
        testerId: workflow.testerId,
        title: approved ? '신청이 승인되었습니다!' : '신청이 거부되었습니다',
        message: approved
            ? '${workflow.appName} 테스트를 시작할 수 있습니다.'
            : '${workflow.appName} 테스트 신청이 거부되었습니다.',
        data: {'workflowId': workflowId},
      );

      AppLogger.info('Mission application processed successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to process mission application', e.toString());
      rethrow;
    }
  }

  // 3단계: 일일 미션 생성
  Future<void> _createDailyMission(String workflowId, int dayNumber) async {
    try {
      final workflow = await getMissionWorkflow(workflowId);

      final interaction = DailyMissionInteraction(
        id: '${workflowId}_day_$dayNumber',
        missionId: workflowId,
        testerId: workflow.testerId,
        providerId: workflow.providerId,
        dayNumber: dayNumber,
        date: DateTime.now(),
        dailyReward: workflow.dailyReward,
      );

      // dailyInteractions 배열에 추가
      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update({
        'dailyInteractions': FieldValue.arrayUnion([interaction.toFirestore()]),
        'currentState': MissionWorkflowState.missionInProgress.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Daily mission created for day $dayNumber', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to create daily mission', e.toString());
      rethrow;
    }
  }

  // 4단계: 테스터가 일일 미션 시작
  Future<void> startDailyMission({
    required String workflowId,
    required String testerId,
    required int dayNumber,
  }) async {
    try {
      AppLogger.info('Tester $testerId starting daily mission day $dayNumber', 'MissionWorkflow');

      final workflow = await getMissionWorkflow(workflowId);
      final interactions = List<Map<String, dynamic>>.from(workflow.dailyInteractions.map((i) => i.toFirestore()));

      // 해당 날짜의 interaction 찾기 및 업데이트
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['testerStarted'] = true;
          interactions[i]['testerStartedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        }
      }

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update({
        'dailyInteractions': interactions,
        'currentState': MissionWorkflowState.dailyMissionStarted.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': testerId,
      });

      AppLogger.info('Daily mission started successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to start daily mission', e.toString());
      rethrow;
    }
  }

  // 5단계: 테스터가 일일 미션 완료
  Future<void> completeDailyMission({
    required String workflowId,
    required String testerId,
    required int dayNumber,
    required String feedback,
    List<String>? screenshots,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      AppLogger.info('Tester $testerId completing daily mission day $dayNumber', 'MissionWorkflow');

      final workflow = await getMissionWorkflow(workflowId);
      final interactions = List<Map<String, dynamic>>.from(workflow.dailyInteractions.map((i) => i.toFirestore()));

      // 해당 날짜의 interaction 찾기 및 업데이트
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['testerCompleted'] = true;
          interactions[i]['testerCompletedAt'] = Timestamp.fromDate(DateTime.now());
          interactions[i]['testerFeedback'] = feedback;
          interactions[i]['testerScreenshots'] = screenshots ?? [];
          interactions[i]['testerData'] = additionalData ?? {};
          break;
        }
      }

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update({
        'dailyInteractions': interactions,
        'currentState': MissionWorkflowState.dailyMissionCompleted.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': testerId,
      });

      // 공급자에게 알림
      await _sendNotificationToProvider(
        providerId: workflow.providerId,
        title: '일일 미션 완료',
        message: '${workflow.testerName}님이 ${dayNumber}일차 미션을 완료했습니다.',
        data: {
          'workflowId': workflowId,
          'dayNumber': dayNumber,
        },
      );

      AppLogger.info('Daily mission completed successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to complete daily mission', e.toString());
      rethrow;
    }
  }

  // 6단계: 공급자가 일일 미션 승인
  Future<void> approveDailyMission({
    required String workflowId,
    required String providerId,
    required int dayNumber,
    String? providerFeedback,
    int? rating,
  }) async {
    try {
      AppLogger.info('Provider $providerId approving daily mission day $dayNumber', 'MissionWorkflow');

      final workflow = await getMissionWorkflow(workflowId);
      final interactions = List<Map<String, dynamic>>.from(workflow.dailyInteractions.map((i) => i.toFirestore()));

      // 해당 날짜의 interaction 찾기 및 업데이트
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['providerApproved'] = true;
          interactions[i]['providerApprovedAt'] = Timestamp.fromDate(DateTime.now());
          interactions[i]['providerFeedback'] = providerFeedback;
          interactions[i]['providerRating'] = rating;
          interactions[i]['rewardPaid'] = true;
          interactions[i]['rewardPaidAt'] = Timestamp.fromDate(DateTime.now());
          break;
        }
      }

      // 리워드 계산
      final earnedReward = workflow.totalEarnedReward + workflow.dailyReward;
      final paidReward = workflow.totalPaidReward + workflow.dailyReward;

      final updateData = {
        'dailyInteractions': interactions,
        'currentState': MissionWorkflowState.dailyMissionApproved.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': providerId,
        'totalEarnedReward': earnedReward,
        'totalPaidReward': paidReward,
      };

      // 다음 날 미션 생성 (마지막 날이 아니면)
      if (dayNumber < workflow.totalDays) {
        await _createDailyMission(workflowId, dayNumber + 1);
        updateData['currentDay'] = dayNumber + 1;
        updateData['currentState'] = MissionWorkflowState.missionInProgress.code;
      } else {
        // 모든 미션 완료
        updateData['currentState'] = MissionWorkflowState.projectCompleted.code;
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update(updateData);

      // 테스터에게 알림
      await _sendNotificationToTester(
        testerId: workflow.testerId,
        title: '일일 미션 승인!',
        message: '${dayNumber}일차 미션이 승인되었습니다. ${workflow.dailyReward}원이 지급되었습니다.',
        data: {
          'workflowId': workflowId,
          'dayNumber': dayNumber,
          'reward': workflow.dailyReward,
        },
      );

      AppLogger.info('Daily mission approved successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to approve daily mission', e.toString());
      rethrow;
    }
  }

  // 7단계: 프로젝트 최종 승인
  Future<void> finalizeProject({
    required String workflowId,
    required String providerId,
    String? finalFeedback,
    int? finalRating,
    int? bonusReward,
  }) async {
    try {
      AppLogger.info('Finalizing project $workflowId', 'MissionWorkflow');

      final updateData = {
        'currentState': MissionWorkflowState.projectFinalized.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': providerId,
        'finalizedAt': FieldValue.serverTimestamp(),
        'finalFeedback': finalFeedback,
        'finalRating': finalRating,
      };

      if (bonusReward != null && bonusReward > 0) {
        final workflow = await getMissionWorkflow(workflowId);
        updateData['totalEarnedReward'] = workflow.totalEarnedReward + bonusReward;
        updateData['totalPaidReward'] = workflow.totalPaidReward + bonusReward;
        updateData['metadata.bonusReward'] = bonusReward;
      }

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update(updateData);

      AppLogger.info('Project finalized successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to finalize project', e.toString());
      rethrow;
    }
  }

  // 워크플로우 조회
  Future<MissionWorkflowModel> getMissionWorkflow(String workflowId) async {
    try {
      final doc = await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .get();

      if (!doc.exists) {
        throw Exception('Mission workflow not found');
      }

      return MissionWorkflowModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to get mission workflow', e.toString());
      rethrow;
    }
  }

  // 앱별 워크플로우 스트림
  Stream<List<MissionWorkflowModel>> getAppWorkflows(String appId) {
    return _firestore
        .collection('mission_workflows')
        .where('appId', isEqualTo: appId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissionWorkflowModel.fromFirestore(doc))
            .toList());
  }

  // 테스터별 워크플로우 스트림
  Stream<List<MissionWorkflowModel>> getTesterWorkflows(String testerId) {
    return _firestore
        .collection('mission_workflows')
        .where('testerId', isEqualTo: testerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissionWorkflowModel.fromFirestore(doc))
            .toList());
  }

  // 공급자별 워크플로우 스트림
  Stream<List<MissionWorkflowModel>> getProviderWorkflows(String providerId) {
    return _firestore
        .collection('mission_workflows')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissionWorkflowModel.fromFirestore(doc))
            .toList());
  }

  // 알림 전송 헬퍼 메서드
  Future<void> _sendNotificationToProvider({
    required String providerId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': providerId,
        'userType': 'provider',
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.warning('Failed to send notification to provider', 'MissionWorkflow');
    }
  }

  Future<void> _sendNotificationToTester({
    required String testerId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': testerId,
        'userType': 'tester',
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.warning('Failed to send notification to tester', 'MissionWorkflow');
    }
  }
}