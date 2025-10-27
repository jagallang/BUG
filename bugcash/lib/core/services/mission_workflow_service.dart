import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  /// v2.112.0: dailyReward 파라미터 제거 (최종 포인트만 사용)
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
    // v2.112.0: dailyReward 제거
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
        // v2.112.0: dailyReward 제거
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

      // v2.25.19: Day 1이 생성되었으므로 바로 in_progress 상태로 전환
      final newState = approved
          ? MissionWorkflowState.missionInProgress  // application_approved → in_progress
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

        // v2.25.18: totalDays 만큼 모든 일일 미션 미리 생성
        final workflow = await getMissionWorkflow(workflowId);

        AppLogger.info(
          '📝 Generating dailyInteractions: workflowId=$workflowId, totalDays=${workflow.totalDays}',
          'MissionWorkflow'
        );

        final startDate = DateTime.now();
        final allDayMissions = List.generate(workflow.totalDays, (index) {
          return {
            'dayNumber': index + 1,
            'date': startDate.add(Duration(days: index)),
            'testerStarted': false,
            'testerCompleted': false,
            'testerScreenshots': [],
            'testerData': {},
            'providerApproved': false,
            // v2.117.0: dailyReward/rewardPaid 필드 제거 (최종 완료 시에만 포인트 지급)
          };
        });
        updateData['dailyInteractions'] = allDayMissions;

        AppLogger.info('✅ Created ${allDayMissions.length} daily missions for totalDays=${workflow.totalDays}', 'MissionWorkflow');
      }

      if (feedback != null) {
        updateData['metadata.approvalFeedback'] = feedback;
      }

      // v2.108.2: Firestore 업데이트 전 로깅
      AppLogger.info(
        '💾 Updating Firestore: workflowId=$workflowId, updateData keys=${updateData.keys.join(", ")}',
        'MissionWorkflow'
      );

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update(updateData);

      // v2.108.2: 업데이트 후 검증
      final updatedWorkflow = await getMissionWorkflow(workflowId);
      AppLogger.info(
        '✅ Firestore updated successfully: dailyInteractions count=${updatedWorkflow.dailyInteractions.length}, currentState=${updatedWorkflow.currentState.code}',
        'MissionWorkflow'
      );

      // 테스터에게 알림 전송
      await _sendNotificationToTester(
        testerId: updatedWorkflow.testerId,
        title: approved ? '신청이 승인되었습니다!' : '신청이 거부되었습니다',
        message: approved
            ? '${updatedWorkflow.appName} 테스트를 시작할 수 있습니다.'
            : '${updatedWorkflow.appName} 테스트 신청이 거부되었습니다.',
        data: {'workflowId': workflowId},
      );

      AppLogger.info('Mission application processed successfully', 'MissionWorkflow');
    } catch (e, stackTrace) {
      // v2.108.2: 에러 발생 시 스택 트레이스 포함
      AppLogger.error(
        'Failed to process mission application: $e\nStack trace: $stackTrace',
        e.toString()
      );
      rethrow;
    }
  }

  // v2.25.18: _createDailyMission 함수 삭제
  // 모든 Day 미션은 최초 승인 시 한 번에 생성되므로 개별 생성 함수는 더 이상 필요 없음

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
      final now = DateTime.now();
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['testerStarted'] = true;
          interactions[i]['testerStartedAt'] = now;
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
      final now = DateTime.now();
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['testerCompleted'] = true;
          interactions[i]['testerCompletedAt'] = now;
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

      // v2.26.1: Firestore에서 직접 읽어서 Timestamp 변환 문제 해결 (approveDailyMission과 동일)
      final docSnapshot = await _firestore.collection('mission_workflows').doc(workflowId).get();
      if (!docSnapshot.exists) {
        throw Exception('Workflow not found');
      }

      final data = docSnapshot.data()!;
      final interactions = List<Map<String, dynamic>>.from(data['dailyInteractions'] ?? []);

      // v2.26.1: 모든 interaction의 Timestamp를 DateTime으로 변환
      for (var interaction in interactions) {
        _convertTimestampsToDateTime(interaction);
      }

      // v2.25.18: dailyInteractions는 이제 최초 승인 시 생성되므로 여기서는 검증만 수행
      if (interactions.isEmpty) {
        AppLogger.error(
          '❌ dailyInteractions is empty - this should not happen after v2.25.18',
          'MissionWorkflow'
        );
        throw Exception('dailyInteractions가 비어있습니다. 미션 신청 승인이 올바르게 처리되지 않았습니다.');
      }

      // 해당 날짜의 interaction 찾기 및 업데이트
      bool found = false;
      final now = DateTime.now();
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['testerCompleted'] = true;
          interactions[i]['testerCompletedAt'] = now;
          interactions[i]['testerFeedback'] = feedback;
          interactions[i]['testerScreenshots'] = screenshots ?? [];
          interactions[i]['testerData'] = additionalData ?? {};
          found = true;

          AppLogger.info(
            '✅ [v2.26.1] Day $dayNumber 업데이트 완료\n'
            '   ├─ Screenshots: ${screenshots?.length ?? 0}개\n'
            '   ├─ Feedback: ${feedback.substring(0, feedback.length > 30 ? 30 : feedback.length)}...\n'
            '   └─ AdditionalData: ${additionalData?.keys.join(", ") ?? "없음"}',
            'MissionWorkflow'
          );
          break;
        }
      }

      if (!found) {
        AppLogger.error(
          '❌ Day $dayNumber not found in dailyInteractions\n'
          '   └─ Available days: ${interactions.map((i) => i['dayNumber']).toList()}',
          'MissionWorkflow'
        );
        throw Exception('Day $dayNumber not found in dailyInteractions');
      }

      AppLogger.info(
        '🔄 [v2.26.1] Firestore 업데이트 시작\n'
        '   ├─ workflowId: $workflowId\n'
        '   ├─ dayNumber: $dayNumber\n'
        '   └─ state: dailyMissionCompleted',
        'MissionWorkflow'
      );

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update({
        'dailyInteractions': interactions,
        'currentState': MissionWorkflowState.dailyMissionCompleted.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': testerId,
      });

      // v2.26.1: workflow 정보는 docSnapshot에서 가져오기
      final providerId = data['providerId'] as String;
      final testerName = data['testerName'] as String? ?? '테스터';

      // 공급자에게 알림
      await _sendNotificationToProvider(
        providerId: providerId,
        title: '일일 미션 완료',
        message: '$testerName님이 $dayNumber일차 미션을 완료했습니다.',
        data: {
          'workflowId': workflowId,
          'dayNumber': dayNumber,
        },
      );

      AppLogger.info('✅ [v2.26.1] Daily mission completed successfully', 'MissionWorkflow');
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

      // v2.25.09: Firestore 문서를 직접 읽어서 Timestamp 변환 문제 해결
      final docSnapshot = await _firestore.collection('mission_workflows').doc(workflowId).get();
      if (!docSnapshot.exists) {
        throw Exception('Workflow not found');
      }

      final data = docSnapshot.data()!;
      final interactions = List<Map<String, dynamic>>.from(data['dailyInteractions'] ?? []);

      // 모든 interaction의 Timestamp를 DateTime으로 변환
      for (var interaction in interactions) {
        _convertTimestampsToDateTime(interaction);
      }

      // 해당 날짜의 interaction 찾기 및 업데이트
      final now = DateTime.now();
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['providerApproved'] = true;
          interactions[i]['providerApprovedAt'] = now;
          // v2.25.04: null 값 처리 (Firestore Invalid Argument 방지)
          if (providerFeedback != null && providerFeedback.isNotEmpty) {
            interactions[i]['providerFeedback'] = providerFeedback;
          }
          if (rating != null) {
            interactions[i]['providerRating'] = rating;
          }
          // v2.117.0: rewardPaid/rewardPaidAt 제거 (일일 포인트 지급 없음, 최종 완료 시에만 포인트 지급)
          break;
        }
      }

      // v2.112.0: 리워드 계산 로직 단순화
      final totalDays = data['totalDays'] ?? 10;

      // v2.25.14: completedDays 계산 (승인된 일일 미션 개수)
      final completedDays = interactions.where((i) => i['providerApproved'] == true).length;

      // 최종 완료 여부 확인
      final isFinalDay = dayNumber >= totalDays;

      // v2.25.04: 다음 날 미션 자동 생성 제거 (공급자가 수동으로 생성)
      final updateData = {
        'dailyInteractions': interactions,
        'currentState': isFinalDay
            ? MissionWorkflowState.projectCompleted.code
            : MissionWorkflowState.dailyMissionApproved.code,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': providerId,
        'completedDays': completedDays, // v2.25.14
        // v2.112.0: totalEarnedReward, totalPaidReward 제거
      };

      // 마지막 날인 경우에만 완료 처리
      if (isFinalDay) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update(updateData);

      // v2.170.0: 프로젝트 종료 시 projects 컬렉션 상태도 'closed'로 업데이트
      if (isFinalDay) {
        try {
          final appId = data['appId'] as String;
          await _firestore
              .collection('projects')
              .doc(appId)
              .update({
            'status': 'closed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          AppLogger.info('✅ Project $appId status updated to closed', 'MissionWorkflow');
        } catch (e) {
          AppLogger.error('❌ Failed to update project status: $e', 'MissionWorkflow');
          // 에러가 발생해도 workflow 업데이트는 성공했으므로 계속 진행
        }
      }

      // v2.131.0: 자동 포인트 지급 제거 (UI에서 명시적으로 호출)
      // 포인트 지급은 payFinalRewardOnly() 함수를 통해 UI에서 별도로 실행
      // if (isFinalDay) {
      //   try {
      //     await _payFinalReward(workflowId, data);
      //     AppLogger.info('✅ Final reward payment completed for workflow $workflowId', 'MissionWorkflow');
      //   } catch (e) {
      //     AppLogger.error('❌ Failed to pay final reward', 'MissionWorkflow', e);
      //   }
      // }

      // 테스터에게 알림
      await _sendNotificationToTester(
        testerId: data['testerId'] ?? '',
        title: isFinalDay ? '미션 최종 승인!' : '일일 미션 승인!',
        message: isFinalDay
            ? '$dayNumber일차 미션이 승인되었습니다. 공급자가 포인트 지급을 진행합니다.'
            : '$dayNumber일차 미션이 승인되었습니다. 다음 미션을 진행해주세요.',
        data: {
          'workflowId': workflowId,
          'dayNumber': dayNumber,
          'isFinalDay': isFinalDay,
        },
      );

      AppLogger.info('Daily mission approved successfully', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to approve daily mission', e.toString());
      rethrow;
    }
  }

  // v2.25.18: createNextDayMission 함수 삭제
  // 모든 Day 미션은 최초 승인 시 생성되므로 이 함수는 더 이상 필요 없음

  // v2.25.19: 이미 생성된 다음 날 미션 활성화 (currentDay만 업데이트)
  Future<void> activateNextDayMission({
    required String workflowId,
    required String providerId,
  }) async {
    try {
      final workflow = await getMissionWorkflow(workflowId);

      AppLogger.info(
        'Provider $providerId activating day ${workflow.currentDay + 1} '
        '(current state: ${workflow.currentState.code}, dailyInteractions count: ${workflow.dailyInteractions.length})',
        'MissionWorkflow'
      );

      // v2.108.2: dailyInteractions 배열이 비어있으면 자동 생성 (v2.25.18 이전 승인 미션 복구)
      if (workflow.dailyInteractions.isEmpty) {
        AppLogger.warning(
          '⚠️ dailyInteractions is empty for workflow $workflowId. Auto-generating ${workflow.totalDays} daily missions...',
          'MissionWorkflow'
        );

        final startDate = DateTime.now();
        final allDayMissions = List.generate(workflow.totalDays, (index) {
          return {
            'dayNumber': index + 1,
            'date': startDate.add(Duration(days: index)),
            'testerStarted': false,
            'testerCompleted': false,
            'testerScreenshots': [],
            'testerData': {},
            'providerApproved': false,
            'dailyReward': workflow.dailyReward,
            'rewardPaid': false,
          };
        });

        await _firestore
            .collection('mission_workflows')
            .doc(workflowId)
            .update({'dailyInteractions': allDayMissions});

        AppLogger.info(
          '✅ Auto-generated ${allDayMissions.length} daily missions successfully',
          'MissionWorkflow'
        );
      }

      // v2.108.3: 신청 승인 상태 포함 (Firestore "approved" → applicationApproved)
      final allowedStates = [
        MissionWorkflowState.applicationApproved,   // Firestore "approved" (Day 1 시작용)
        MissionWorkflowState.missionInProgress,     // "mission_in_progress" (Day 1 시작용)
        MissionWorkflowState.dailyMissionApproved,  // "daily_mission_approved" (Day 2+ 시작용)
      ];

      if (!allowedStates.contains(workflow.currentState)) {
        throw Exception(
          '미션 시작 불가: ${workflow.currentState.displayName} 상태입니다. '
          '(승인 완료 또는 일일 미션 승인 상태여야 합니다)'
        );
      }

      final nextDayNumber = workflow.currentDay + 1;

      // 마지막 날 초과 체크
      if (nextDayNumber > workflow.totalDays) {
        throw Exception('모든 미션이 완료되었습니다. (총 ${workflow.totalDays}일)');
      }

      // v2.29.0: currentDay 업데이트 + 자동 승인 처리
      // Day는 이미 dailyInteractions에 생성되어 있으므로 currentDay만 업데이트
      // 공급자가 미션 만들기를 했으므로 바로 dailyMissionStarted 상태로 변경 (자동 승인)
      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update({
        'currentDay': nextDayNumber,
        'currentState': MissionWorkflowState.dailyMissionStarted.code,  // v2.29.0: missionInProgress → dailyMissionStarted
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': providerId,
      });

      AppLogger.info('✅ Day $nextDayNumber activated successfully (auto-approved)', 'MissionWorkflow');
    } catch (e) {
      AppLogger.error('Failed to activate next day mission', e.toString());
      rethrow;
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
      final now = DateTime.now();
      for (int i = 0; i < interactions.length; i++) {
        if (interactions[i]['dayNumber'] == dayNumber) {
          interactions[i]['providerApproved'] = false;
          interactions[i]['providerApprovedAt'] = now;
          interactions[i]['providerFeedback'] = rejectionReason;
          // v2.25.06: null 값 제거 (배열 내부에서 null 지원 안 됨)
          interactions[i].remove('providerRating');
          interactions[i]['rewardPaid'] = false;
          interactions[i].remove('rewardPaidAt');
          // v2.22.0: 재제출 가능하도록 testerCompleted를 false로 변경
          interactions[i]['testerCompleted'] = false;
          interactions[i].remove('testerCompletedAt');
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
        message: '$dayNumber일차 미션이 거절되었습니다. 사유: $rejectionReason',
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

      await _firestore
          .collection('mission_workflows')
          .doc(workflowId)
          .update(updateData);

      // 최종 완료 보상 계산 - 앱 데이터에서 finalCompletionPoints 가져오기
      final workflow = await getMissionWorkflow(workflowId);
      final appDoc = await _firestore.collection('projects').doc(workflow.appId).get();
      int finalReward = 0;

      if (appDoc.exists) {
        final appData = appDoc.data()!;
        final rewards = appData['rewards'] as Map<String, dynamic>?;
        finalReward = (rewards?['finalCompletionPoints'] as int?) ?? 0;
      }

      // v2.104.0: 에스크로 시스템 연동 - 최종 완료 시 에스크로에서 포인트 지급
      final testerId = workflow.testerId;
      if (testerId.isNotEmpty) {
        try {
          final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
          final payoutFunction = functions.httpsCallable('payoutFromEscrow');

          // 최종 완료 포인트
          if (finalReward > 0) {
            await payoutFunction.call({
              'appId': workflow.appId,
              'testerId': testerId,
              'testerName': workflow.testerName,
              'amount': finalReward,
              'description': '프로젝트 최종 완료: ${workflow.appName}',
              'metadata': {
                'workflowId': workflowId,
                'appId': workflow.appId,
                'appName': workflow.appName,
                'rewardType': 'final',
              },
            });
            AppLogger.info('Final reward $finalReward paid from escrow to tester $testerId', 'MissionWorkflow');
          }

          // 보너스 포인트
          if (bonusReward != null && bonusReward > 0) {
            await payoutFunction.call({
              'appId': workflow.appId,
              'testerId': testerId,
              'testerName': workflow.testerName,
              'amount': bonusReward,
              'description': '우수 성과 보너스: ${workflow.appName}',
              'metadata': {
                'workflowId': workflowId,
                'appId': workflow.appId,
                'appName': workflow.appName,
                'rewardType': 'bonus',
                'finalRating': finalRating,
              },
            });
            AppLogger.info('Bonus reward $bonusReward paid from escrow to tester $testerId', 'MissionWorkflow');
          }

          // totalEarnedReward, totalPaidReward 업데이트
          int totalReward = finalReward + (bonusReward ?? 0);
          if (totalReward > 0) {
            await _firestore.collection('mission_workflows').doc(workflowId).update({
              'totalEarnedReward': workflow.totalEarnedReward + totalReward,
              'totalPaidReward': workflow.totalPaidReward + totalReward,
              if (bonusReward != null && bonusReward > 0) 'metadata.bonusReward': bonusReward,
            });
          }
        } catch (e) {
          AppLogger.error('Failed to pay final/bonus reward to tester', 'MissionWorkflow', e);
          // 포인트 지급 실패해도 프로젝트 완료는 진행
        }
      }

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

  /// v2.112.0: 최종 미션 완료 시 에스크로에서 포인트 지급
  /// Firebase Function을 호출하여 안전하게 포인트 지급
  Future<void> _payFinalReward(
    String workflowId,
    Map<String, dynamic> workflowData,
  ) async {
    try {
      final appId = workflowData['appId'] as String;
      final testerId = workflowData['testerId'] as String;
      final testerName = workflowData['testerName'] as String? ?? '테스터';
      final appName = workflowData['appName'] as String? ?? '';

      // 1. projects 컬렉션에서 finalCompletionPoints 조회 (rewards/metadata에서)
      final normalizedAppId = appId.replaceAll('provider_app_', '');
      final projectDoc = await _firestore
          .collection('projects')
          .doc(normalizedAppId)
          .get();

      if (!projectDoc.exists) {
        throw Exception('Project not found: $normalizedAppId');
      }

      final projectData = projectDoc.data()!;
      final rewards = projectData['rewards'] as Map<String, dynamic>?;
      final metadata = projectData['metadata'] as Map<String, dynamic>?;

      // rewards.finalCompletionPoints 우선, metadata.finalCompletionPoints 폴백
      final finalPoints = rewards?['finalCompletionPoints'] as int? ??
                         metadata?['finalCompletionPoints'] as int? ??
                         10000;

      // v2.166.0: appId 로깅 강화
      AppLogger.info(
        '💰 Final reward payment initiated\n'
        '   ├─ workflowId: $workflowId\n'
        '   ├─ appId: $appId (normalized: $normalizedAppId)\n'
        '   ├─ testerId: $testerId\n'
        '   ├─ amount: $finalPoints\n'
        '   └─ appName: $appName',
        'MissionWorkflow'
      );

      // 2. Firebase Function 호출: payoutFromEscrow
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable('payoutFromEscrow');

      AppLogger.info(
        '📤 Calling payoutFromEscrow with appId: $appId',
        'MissionWorkflow'
      );

      await callable.call({
        'appId': appId,
        'testerId': testerId,
        'testerName': testerName,
        'amount': finalPoints,
        'description': '$appName 미션 최종 완료 보상',
        'metadata': {
          'workflowId': workflowId,
          'rewardType': 'final',
          'allDaysCompleted': true,
        },
      });

      AppLogger.info(
        '✅ Final reward paid successfully: $finalPoints P',
        'MissionWorkflow'
      );
    } catch (e) {
      AppLogger.error(
        '❌ Failed to pay final reward: $e',
        'MissionWorkflow'
      );
      rethrow;
    }
  }

  /// v2.131.0: UI에서 명시적으로 호출 - 에스크로 포인트 지급만 수행
  Future<void> payFinalRewardOnly({required String workflowId}) async {
    final doc = await _firestore.collection('mission_workflows').doc(workflowId).get();
    if (!doc.exists) {
      throw Exception('Workflow not found: $workflowId');
    }
    final data = doc.data()!;
    await _payFinalReward(workflowId, data);
  }

  // v2.25.09: Timestamp를 DateTime으로 변환하는 헬퍼 메서드
  void _convertTimestampsToDateTime(Map<String, dynamic> interaction) {
    final timestampFields = [
      'date',
      'testerStartedAt',
      'testerCompletedAt',
      'providerApprovedAt',
      'rewardPaidAt',
    ];

    for (final field in timestampFields) {
      if (interaction[field] is Timestamp) {
        interaction[field] = (interaction[field] as Timestamp).toDate();
      }
    }
  }
}