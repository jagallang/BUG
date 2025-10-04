import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shared/models/mission_workflow_model.dart';
import '../utils/logger.dart';

/// MissionWorkflowService Provider
final missionWorkflowServiceProvider = Provider<MissionWorkflowService>((ref) {
  return MissionWorkflowService();
});

/// 미션 워크플로우 서비스
/// 테스터-공급자 간 미션 상호작용 관리
class MissionWorkflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1단계: 미션 신청 생성 (자동 providerId 조회 포함)
  /// v2.18.0: totalDays 기본값 14일 → 10일 변경 (권장값)
  Future<String> createMissionApplication({
    required String appId,
    required String appName,
    required String testerId,
    required String testerName,
    required String testerEmail,
    String? providerId, // 옵셔널로 변경 - 자동 조회 기능 추가
    String? providerName, // 옵셔널로 변경 - 자동 조회 기능 추가
    required String experience,
    required String motivation,
    int totalDays = 10,  // v2.18.0: 14 → 10 (권장 기본값)
    int dailyReward = 5000,
  }) async {
    try {
      // Input validation
      if (appId.isEmpty) throw ArgumentError('appId cannot be empty');
      if (appName.isEmpty) throw ArgumentError('appName cannot be empty');
      if (testerId.isEmpty) throw ArgumentError('testerId cannot be empty');
      if (testerName.isEmpty) throw ArgumentError('testerName cannot be empty');

      AppLogger.info(
        '🔥 [미션신청] 생성 시작\n'
        '   ├─ appId (입력): $appId\n'
        '   ├─ appName: $appName\n'
        '   ├─ testerId: $testerId\n'
        '   └─ testerName: $testerName',
        'MissionWorkflow'
      );

      // 🔍 자동 providerId 조회 기능 (projects 컬렉션에서)
      String safeProviderId = providerId ?? '';
      String safeProviderName = providerName ?? '';

      if (safeProviderId.isEmpty || safeProviderName.isEmpty) {
        AppLogger.info('Auto-looking up provider info from projects collection for appId: $appId', 'MissionWorkflow');

        // appId에서 'provider_app_' 접두사 제거
        final normalizedAppId = appId.replaceAll('provider_app_', '');
        AppLogger.info('   ├─ normalizedAppId: $normalizedAppId', 'MissionWorkflow');

        try {
          final projectDoc = await _firestore.collection('projects').doc(normalizedAppId).get();
          if (projectDoc.exists) {
            final projectData = projectDoc.data()!;
            safeProviderId = projectData['providerId'] ?? '';
            safeProviderName = projectData['providerName'] ?? projectData['appName'] ?? 'Unknown Provider';

            AppLogger.info('✅ Auto-lookup successful: providerId=$safeProviderId, providerName=$safeProviderName', 'MissionWorkflow');
          } else {
            AppLogger.error('❌ Project not found in projects collection: $normalizedAppId', 'MissionWorkflow');
            throw ArgumentError('Project not found for appId: $appId');
          }
        } catch (e) {
          AppLogger.error('❌ Failed to auto-lookup provider info: $e', 'MissionWorkflow');
          throw ArgumentError('Failed to lookup provider info for appId: $appId');
        }
      }

      // Final validation
      if (safeProviderId.isEmpty) throw ArgumentError('providerId could not be determined for appId: $appId');
      if (safeProviderName.isEmpty) safeProviderName = 'Unknown Provider';

      final workflow = MissionWorkflowModel(
        id: '',
        appId: appId,
        appName: appName,
        testerId: testerId,
        testerName: testerName,
        testerEmail: testerEmail,
        providerId: safeProviderId,
        providerName: safeProviderName,
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

      AppLogger.info(
        '✅ [미션신청] Firestore 저장 완료\n'
        '   ├─ workflowId: ${docRef.id}\n'
        '   ├─ appId (저장됨): $appId\n'
        '   ├─ currentState: ${workflow.currentState.code}\n'
        '   └─ providerId: $safeProviderId',
        'MissionWorkflow'
      );

      // 공급자에게 알림 전송
      await _sendNotificationToProvider(
        providerId: safeProviderId,
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

  // v2.13.0: 테스터가 일일 미션 완료 시간만 기록 (제출 없이)
  /// 완료 버튼 클릭 시 호출 - testerCompletedAt만 기록하고 상태를 testing_completed로 변경
  Future<void> markDailyMissionCompleted({
    required String workflowId,
    required String testerId,
    required int dayNumber,
  }) async {
    try {
      AppLogger.info('Tester $testerId marking daily mission day $dayNumber as completed (without submission)', 'MissionWorkflow');

      final workflow = await getMissionWorkflow(workflowId);
      final interactions = List<Map<String, dynamic>>.from(workflow.dailyInteractions.map((i) => i.toFirestore()));

      // 해당 날짜의 interaction 찾기 및 업데이트
      bool found = false;
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['testerCompleted'] = true;
          interactions[i]['testerCompletedAt'] = Timestamp.fromDate(DateTime.now());
          found = true;
          break;
        }
      }

      if (!found) {
        throw Exception('Daily interaction not found for day $dayNumber');
      }

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update({
        'dailyInteractions': interactions,
        'currentState': MissionWorkflowState.testingCompleted.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': testerId,
      });

      AppLogger.info('Daily mission marked as completed (testing_completed state)', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to mark daily mission as completed', e.toString());
      rethrow;
    }
  }

  // v2.9.0: 테스터가 일일 미션 제출 (공급자 질문 답변 + 버그리포트)
  Future<void> submitDailyMission({
    required String workflowId,
    required int dayNumber,
    required String feedback,
    required List<String> screenshots,
    String? bugReport, // v2.9.0: 버그 리포트
    Map<String, String>? questionAnswers, // v2.9.0: 공급자 질문 답변
  }) async {
    final workflow = await getMissionWorkflow(workflowId);

    // v2.9.0: 추가 데이터 구성
    final additionalData = <String, dynamic>{
      if (bugReport != null && bugReport.isNotEmpty) 'bugReport': bugReport,
      if (questionAnswers != null && questionAnswers.isNotEmpty) 'questionAnswers': questionAnswers,
    };

    return completeDailyMission(
      workflowId: workflowId,
      testerId: workflow.testerId,
      dayNumber: dayNumber,
      feedback: feedback,
      screenshots: screenshots,
      additionalData: additionalData.isNotEmpty ? additionalData : null,
    );
  }

  // 5단계: 테스터가 일일 미션 완료 (제출과 함께)
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
      var interactions = List<Map<String, dynamic>>.from(workflow.dailyInteractions.map((i) => i.toFirestore()));

      // v2.17.2: dailyInteractions가 비어있으면 초기화
      if (interactions.isEmpty) {
        AppLogger.warning(
          '⚠️ dailyInteractions is empty, auto-initializing for totalDays=${workflow.totalDays}',
          'MissionWorkflow'
        );

        final startDate = workflow.startedAt ?? DateTime.now();
        interactions = List.generate(workflow.totalDays, (index) {
          return {
            'dayNumber': index + 1,
            'date': Timestamp.fromDate(startDate.add(Duration(days: index))),
            'testerStarted': false,
            'testerStartedAt': null,
            'testerCompleted': false,
            'testerCompletedAt': null,
            'testerFeedback': null,
            'testerScreenshots': [],
            'testerData': {},
            'providerApproved': false,
            'providerApprovedAt': null,
            'providerFeedback': null,
            'providerRating': null,
            'dailyReward': workflow.dailyReward,
            'rewardPaid': false,
            'rewardPaidAt': null,
          };
        });

        AppLogger.info(
          '✅ Created ${interactions.length} daily interaction slots',
          'MissionWorkflow'
        );
      }

      // 해당 날짜의 interaction 찾기 및 업데이트
      bool found = false;
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['testerCompleted'] = true;
          interactions[i]['testerCompletedAt'] = Timestamp.fromDate(DateTime.now());
          interactions[i]['testerFeedback'] = feedback;
          interactions[i]['testerScreenshots'] = screenshots ?? [];
          interactions[i]['testerData'] = additionalData ?? {};
          found = true;

          AppLogger.info(
            '✅ Updated day $dayNumber with ${screenshots?.length ?? 0} screenshots',
            'MissionWorkflow'
          );
          break;
        }
      }

      if (!found) {
        AppLogger.error(
          '❌ Day $dayNumber not found in dailyInteractions',
          'MissionWorkflow'
        );
        throw Exception('Day $dayNumber not found in dailyInteractions');
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

      AppLogger.info('✅ Daily mission completed successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('❌ Failed to complete daily mission: $e', 'MissionWorkflow');
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

      // v2.25.04: 다음 날 미션 자동 생성 제거 (공급자가 수동으로 생성)
      final updateData = {
        'dailyInteractions': interactions,
        'currentState': dayNumber >= workflow.totalDays
            ? MissionWorkflowState.projectCompleted.code
            : MissionWorkflowState.dailyMissionApproved.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': providerId,
        'totalEarnedReward': earnedReward,
        'totalPaidReward': paidReward,
      };

      // 마지막 날인 경우에만 완료 처리
      if (dayNumber >= workflow.totalDays) {
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

  // v2.25.04: 공급자가 다음 날 미션 수동 생성
  Future<void> createNextDayMission({
    required String workflowId,
    required String providerId,
  }) async {
    try {
      AppLogger.info('Provider $providerId creating next day mission', 'MissionWorkflow');

      final workflow = await getMissionWorkflow(workflowId);

      // 현재 상태 확인: dailyMissionApproved 상태여야 함
      if (workflow.currentState != MissionWorkflowState.dailyMissionApproved) {
        throw Exception('다음 날 미션은 이전 미션 승인 후에만 생성 가능합니다 (현재 상태: ${workflow.currentState.displayName})');
      }

      // 다음 날 번호 계산
      final nextDayNumber = workflow.currentDay + 1;

      // 마지막 날 초과 체크
      if (nextDayNumber > workflow.totalDays) {
        throw Exception('모든 미션이 완료되었습니다. (총 ${workflow.totalDays}일)');
      }

      // 다음 날 미션이 이미 존재하는지 확인
      final existingInteraction = workflow.dailyInteractions.firstWhere(
        (interaction) => interaction.dayNumber == nextDayNumber,
        orElse: () => throw StateError('NotFound'),
      );

      if (existingInteraction.id != 'NotFound') {
        throw Exception('Day $nextDayNumber 미션이 이미 존재합니다');
      }

      // 다음 날 미션 생성
      await _createDailyMission(workflowId, nextDayNumber);

      // currentDay 업데이트
      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update({
        'currentDay': nextDayNumber,
        'currentState': MissionWorkflowState.missionInProgress.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': providerId,
      });

      AppLogger.info('Next day mission (Day $nextDayNumber) created successfully', 'MissionWorkflow');
    } catch (e) {
      if (e is StateError) {
        // existingInteraction을 찾지 못한 경우 (정상 - 미션 생성 진행)
        AppLogger.info('No existing mission found, proceeding with creation', 'MissionWorkflow');

        final workflow = await getMissionWorkflow(workflowId);
        final nextDayNumber = workflow.currentDay + 1;

        await _createDailyMission(workflowId, nextDayNumber);

        await _firestore
            .collection('mission_workflows')
            .doc(workflowId)
            .update({
          'currentDay': nextDayNumber,
          'currentState': MissionWorkflowState.missionInProgress.code,
          'stateUpdatedAt': FieldValue.serverTimestamp(),
          'stateUpdatedBy': providerId,
        });

        AppLogger.info('Next day mission (Day $nextDayNumber) created successfully', 'MissionWorkflow');
      } else {
        AppLogger.error('Failed to create next day mission', e.toString());
        rethrow;
      }
    }
  }

  // v2.22.0: 공급자가 일일 미션 거절
  Future<void> rejectDailyMission({
    required String workflowId,
    required String providerId,
    required int dayNumber,
    required String rejectionReason,
  }) async {
    try {
      AppLogger.info('Provider $providerId rejecting daily mission day $dayNumber', 'MissionWorkflow');

      final workflow = await getMissionWorkflow(workflowId);
      final interactions = List<Map<String, dynamic>>.from(workflow.dailyInteractions.map((i) => i.toFirestore()));

      // 해당 날짜의 interaction 찾기 및 업데이트
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['providerApproved'] = false;
          interactions[i]['providerApprovedAt'] = Timestamp.fromDate(DateTime.now());
          interactions[i]['providerFeedback'] = rejectionReason;
          interactions[i]['providerRating'] = null;
          interactions[i]['rewardPaid'] = false;
          interactions[i]['rewardPaidAt'] = null;
          // v2.22.0: 재제출 가능하도록 testerCompleted를 false로 변경
          interactions[i]['testerCompleted'] = false;
          interactions[i]['testerCompletedAt'] = null;
          break;
        }
      }

      final updateData = {
        'dailyInteractions': interactions,
        'currentState': MissionWorkflowState.dailyMissionRejected.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': providerId,
      };

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update(updateData);

      // 테스터에게 거절 알림
      await _sendNotificationToTester(
        testerId: workflow.testerId,
        title: '일일 미션 거절됨',
        message: '${dayNumber}일차 미션이 거절되었습니다. 사유: $rejectionReason',
        data: {
          'workflowId': workflowId,
          'dayNumber': dayNumber,
          'rejectionReason': rejectionReason,
        },
      );

      AppLogger.info('✅ Daily mission rejected successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('❌ Failed to reject daily mission: $e', 'MissionWorkflow');
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

  // 워크플로우 조회 (단발성)
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

  // v2.11.2: 워크플로우 실시간 스트림 (단일 문서)
  /// 단일 워크플로우의 실시간 변경사항을 감지하는 스트림
  /// Firestore 문서가 변경될 때마다 자동으로 업데이트됨
  Stream<MissionWorkflowModel> watchMissionWorkflow(String workflowId) {
    return _firestore
        .collection('mission_workflows')
        .doc(workflowId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception('Mission workflow not found: $workflowId');
          }
          return MissionWorkflowModel.fromFirestore(doc);
        });
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