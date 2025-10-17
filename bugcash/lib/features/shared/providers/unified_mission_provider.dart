import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unified_mission_model.dart';
import '../../../core/services/mission_workflow_service.dart';

// 🎯 중앙 집중식 통합 미션 관리 Provider
// 모든 미션 관련 상태를 단일 Provider에서 관리하여 실시간 동기화 보장

// 1. 전체 미션 StreamProvider (실시간 감시)
final unifiedMissionsStreamProvider = StreamProvider<List<UnifiedMissionModel>>((ref) {
  debugPrint('🌟 UNIFIED_PROVIDER: 전체 미션 스트림 시작 - mission_workflows 컬렉션 사용');

  return FirebaseFirestore.instance
      .collection('mission_workflows')
      .snapshots()
      .map((snapshot) {
        debugPrint('🌟 UNIFIED_PROVIDER: ${snapshot.docs.length}개 미션 워크플로우 데이터 수신');

        final results = snapshot.docs.map((doc) {
          try {
            return UnifiedMissionModel.fromFirestore(doc);
          } catch (e) {
            debugPrint('🚨 UNIFIED_PROVIDER: 데이터 파싱 오류 - ${doc.id}: $e');
            // 기본값으로 fallback (mission_workflows 필드명에 맞게 수정)
            final data = doc.data();
            return UnifiedMissionModel(
              id: doc.id,
              appId: data['appId'] ?? '',
              appName: data['appName'] ?? '알 수 없는 앱',
              testerId: data['testerId'] ?? '',
              testerName: data['testerName'] ?? '',
              testerEmail: data['testerEmail'] ?? '',
              providerId: data['providerId'] ?? '',
              status: data['currentState'] ?? data['status'] ?? 'pending', // mission_workflows는 currentState 사용
              experience: data['experience'] ?? '',
              motivation: data['motivation'] ?? '',
              appliedAt: data['appliedAt']?.toDate() ?? DateTime.now(),
            );
          }
        }).toList();

        // 클라이언트 사이드 정렬 (appliedAt 기준 내림차순)
        results.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        return results;
      });
});

// 2. 공급자별 미션 필터링 Provider
final providerMissionsProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, providerId) {
  debugPrint('🏢 UNIFIED_PROVIDER: 공급자($providerId) 미션 필터링 - mission_workflows 컬렉션 사용');

  return FirebaseFirestore.instance
      .collection('mission_workflows')
      .where('providerId', isEqualTo: providerId)
      .snapshots()
      .map((snapshot) {
        debugPrint('🏢 UNIFIED_PROVIDER: 공급자 $providerId - ${snapshot.docs.length}개 미션 워크플로우 발견');

        final results = snapshot.docs.map((doc) => UnifiedMissionModel.fromFirestore(doc)).toList();

        // 클라이언트 사이드 정렬 (appliedAt 기준 내림차순)
        results.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        return results;
      });
});

// 3. 앱별 테스터 신청 Provider (최적화된 검색)
final appTestersStreamProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, appId) {
  if (kDebugMode) {
    debugPrint('📱 UNIFIED_PROVIDER: 앱($appId) 테스터 신청 조회 - mission_workflows 컬렉션 사용');
  }

  // 정규화된 appId로 직접 검색 (가장 효율적)
  final normalizedAppId = appId.replaceAll('provider_app_', '');

  return FirebaseFirestore.instance
      .collection('mission_workflows')
      .where('appId', isEqualTo: normalizedAppId)
      .snapshots()
      .map((snapshot) {
        if (kDebugMode) {
          debugPrint('📱 앱 $normalizedAppId - ${snapshot.docs.length}개 미션 워크플로우 발견');
        }

        return snapshot.docs
            .map((doc) => UnifiedMissionModel.fromFirestore(doc))
            .toList();
      });
});

// 4. 테스터별 미션 Provider
// v2.28.0: cleanArchTesterMissionProvider와 충돌 방지를 위해 이름 변경
final unifiedTesterMissionsProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, testerId) {
  debugPrint('👤 UNIFIED_PROVIDER: 테스터($testerId) 미션 조회 - mission_workflows 컬렉션 사용');

  return FirebaseFirestore.instance
      .collection('mission_workflows')
      .where('testerId', isEqualTo: testerId)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        debugPrint('👤 UNIFIED_PROVIDER: 테스터 $testerId - ${snapshot.docs.length}개 미션 워크플로우');

        // 클라이언트에서 appliedAt 기준으로 정렬 (최신순)
        final missions = snapshot.docs
            .map((doc) => UnifiedMissionModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        return missions;
      });
});

// 5. 상태별 필터링 Provider (FutureProvider로 변경)
final missionsByStatusProvider = Provider.family<AsyncValue<List<UnifiedMissionModel>>, MissionStatusFilter>((ref, status) {
  debugPrint('🏷️ UNIFIED_PROVIDER: 상태별 필터링 - $status');

  final allMissions = ref.watch(unifiedMissionsStreamProvider);

  return allMissions.when(
    data: (missions) {
      List<UnifiedMissionModel> filtered;
      switch (status) {
        case MissionStatusFilter.pending:
          filtered = missions.where((m) => m.status == 'pending').toList();
          break;
        case MissionStatusFilter.approved:
          filtered = missions.where((m) => m.status == 'approved').toList();
          break;
        case MissionStatusFilter.inProgress:
          filtered = missions.where((m) => m.status == 'in_progress').toList();
          break;
        case MissionStatusFilter.completed:
          filtered = missions.where((m) => m.status == 'completed').toList();
          break;
        case MissionStatusFilter.rejected:
          filtered = missions.where((m) => m.status == 'rejected').toList();
          break;
        case MissionStatusFilter.all:
          filtered = missions;
          break;
      }

      debugPrint('🏷️ UNIFIED_PROVIDER: $status 상태 미션 ${filtered.length}개');
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) {
      debugPrint('🚨 UNIFIED_PROVIDER: 상태별 필터링 오류 - $error');
      return AsyncValue.error(error, stack);
    },
  );
});

// 6. 통합 미션 관리 StateNotifier
final unifiedMissionNotifierProvider = StateNotifierProvider<UnifiedMissionNotifier, UnifiedMissionState>((ref) {
  return UnifiedMissionNotifier(ref);
});

// 통합 미션 상태 클래스
class UnifiedMissionState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> metadata;

  const UnifiedMissionState({
    this.isLoading = false,
    this.error,
    this.metadata = const {},
  });

  UnifiedMissionState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedMissionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      metadata: metadata ?? this.metadata,
    );
  }
}

// 통합 미션 관리 Notifier
class UnifiedMissionNotifier extends StateNotifier<UnifiedMissionState> {
  // ignore: unused_field
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MissionWorkflowService _workflowService = MissionWorkflowService();

  UnifiedMissionNotifier(this._ref) : super(const UnifiedMissionState());

  // 🔄 테스터 미션 신청 (새로운 워크플로우 시스템 사용)
  Future<void> applyForMission({
    required String appId,
    required String appName,
    required String testerId,
    required String testerName,
    required String testerEmail,
    required String providerId,
    required String providerName,
    required String experience,
    required String motivation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('📝 UNIFIED_PROVIDER: 새로운 워크플로우로 미션 신청 시작 - $appName by $testerName');

      // v2.112.0: Removed dailyReward fetching (reward system simplification)
      // Projects에서 finalCompletionPoints만 사용 (dailyReward 제거)

      // 새로운 MissionWorkflowService를 사용하여 워크플로우 생성
      final workflowId = await _workflowService.createMissionApplication(
        appId: appId,
        appName: appName,
        testerId: testerId,
        testerName: testerName,
        testerEmail: testerEmail,
        providerId: providerId,
        providerName: providerName,
        experience: experience,
        motivation: motivation,
        totalDays: 14, // 기본 14일
        // v2.117.0: dailyReward 파라미터 제거 (최종 완료 시에만 포인트 지급)
      );

      debugPrint('✅ UNIFIED_PROVIDER: 워크플로우 생성 성공 - ID: $workflowId (v2.117.0: 최종 포인트만 지급)');

      // 이미 MissionWorkflowService에서 mission_workflows에 저장했으므로 추가 저장 불필요
      debugPrint('✅ UNIFIED_PROVIDER: 워크플로우 ID $workflowId로 mission_workflows에 저장 완료');

      debugPrint('✅ UNIFIED_PROVIDER: 미션 신청 완료 - $appName (워크플로우: $workflowId)');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 미션 신청 실패 - $e');
      state = state.copyWith(isLoading: false, error: '미션 신청에 실패했습니다: $e');
      rethrow;
    }
  }

  // ✅ 테스터 승인/거부
  Future<void> updateTesterStatus({
    required String missionId,
    required String newStatus,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🔄 UNIFIED_PROVIDER: 테스터 상태 업데이트 - $missionId -> $newStatus');

      final updateData = {
        'currentState': newStatus, // mission_workflows는 currentState 필드 사용
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateUpdatedBy': 'provider', // 누가 업데이트했는지 기록
      };

      // 승인시 시작 시간 기록
      if (newStatus == 'approved') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('mission_workflows').doc(missionId).update(updateData);

      debugPrint('✅ UNIFIED_PROVIDER: 상태 업데이트 성공 - $missionId');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 상태 업데이트 실패 - $e');
      state = state.copyWith(isLoading: false, error: '상태 업데이트에 실패했습니다: $e');
      rethrow;
    }
  }

  // 📈 진행률 업데이트
  Future<void> updateProgress({
    required String missionId,
    required int currentDay,
    required double progressPercentage,
    required bool todayCompleted,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('📈 UNIFIED_PROVIDER: 진행률 업데이트 - $missionId: $currentDay일차, $progressPercentage%');

      final updateData = {
        'currentDay': currentDay,
        'progressPercentage': progressPercentage,
        'todayCompleted': todayCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 완료 체크 (mission_workflows는 currentState 필드 사용)
      if (progressPercentage >= 100.0) {
        updateData['currentState'] = 'completed';
        updateData['completedAt'] = FieldValue.serverTimestamp();
      } else if (currentDay > 0) {
        updateData['currentState'] = 'in_progress';
      }

      await _firestore.collection('mission_workflows').doc(missionId).update(updateData);

      debugPrint('✅ UNIFIED_PROVIDER: 진행률 업데이트 성공');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 진행률 업데이트 실패 - $e');
      state = state.copyWith(isLoading: false, error: '진행률 업데이트에 실패했습니다: $e');
      rethrow;
    }
  }

  // 🗑️ 미션 삭제 (관리자용)
  Future<void> deleteMission(String missionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🗑️ UNIFIED_PROVIDER: 미션 삭제 - $missionId');

      await _firestore.collection('mission_workflows').doc(missionId).delete();

      debugPrint('✅ UNIFIED_PROVIDER: 미션 삭제 성공');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 미션 삭제 실패 - $e');
      state = state.copyWith(isLoading: false, error: '미션 삭제에 실패했습니다: $e');
      rethrow;
    }
  }

  // 🧹 잘못된 데이터 정리 (빈 appId 데이터 삭제)
  Future<void> cleanupInvalidMissions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🧹 UNIFIED_PROVIDER: 잘못된 미션 데이터 정리 시작');

      final querySnapshot = await _firestore.collection('mission_workflows').get();
      int deletedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final appId = data['appId']?.toString() ?? '';
        final testerName = data['testerName']?.toString() ?? '';
        final testerEmail = data['testerEmail']?.toString() ?? '';

        // appId가 빈 문자열이거나 testerName/Email이 없는 경우 삭제
        if (appId.isEmpty || testerName.isEmpty || testerEmail.isEmpty) {
          debugPrint('🗑️ CLEANUP: 삭제 대상 - ID=${doc.id}, appId="$appId", tester="$testerName"');
          await doc.reference.delete();
          deletedCount++;
        }
      }

      debugPrint('✅ UNIFIED_PROVIDER: 정리 완료 - $deletedCount개 문서 삭제됨');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 데이터 정리 실패 - $e');
      state = state.copyWith(isLoading: false, error: '데이터 정리에 실패했습니다: $e');
      rethrow;
    }
  }

  // 📊 통계 계산 (캐시된 결과 반환)
  Map<String, int> calculateStats(List<UnifiedMissionModel> missions) {
    final stats = {
      'total': missions.length,
      'pending': missions.where((m) => m.status == 'pending').length,
      'approved': missions.where((m) => m.status == 'approved').length,
      'inProgress': missions.where((m) => m.status == 'in_progress').length,
      'completed': missions.where((m) => m.status == 'completed').length,
      'rejected': missions.where((m) => m.status == 'rejected').length,
    };

    debugPrint('📊 UNIFIED_PROVIDER: 통계 계산 완료 - $stats');
    return stats;
  }

  // 🔍 미션 검색
  List<UnifiedMissionModel> searchMissions(List<UnifiedMissionModel> missions, String query) {
    if (query.isEmpty) return missions;

    final lowerQuery = query.toLowerCase();
    return missions.where((mission) {
      return mission.appName.toLowerCase().contains(lowerQuery) ||
             mission.testerName.toLowerCase().contains(lowerQuery) ||
             mission.testerEmail.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

// 7. 편의 Provider들 (기존 코드 호환성을 위해)

// 테스터 대시보드용 활성 미션 Provider
final activeMissionsForTesterProvider = Provider.family<AsyncValue<List<UnifiedMissionModel>>, String>((ref, testerId) {
  final testerMissions = ref.watch(unifiedTesterMissionsProvider(testerId));

  return testerMissions.when(
    data: (missions) {
      final activeMissions = missions.where((m) =>
        m.status == 'pending' ||
        m.status == 'approved' ||
        m.status == 'in_progress'
      ).toList();

      debugPrint('🎯 UNIFIED_PROVIDER: 테스터 $testerId 활성 미션 ${activeMissions.length}개');
      return AsyncValue.data(activeMissions);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// 공급자 대시보드용 대기중 신청 Provider
final pendingApplicationsForProviderProvider = Provider.family<AsyncValue<List<UnifiedMissionModel>>, String>((ref, providerId) {
  final providerMissions = ref.watch(providerMissionsProvider(providerId));

  return providerMissions.when(
    data: (missions) {
      final pendingMissions = missions.where((m) => m.status == 'pending').toList();
      debugPrint('⏳ UNIFIED_PROVIDER: 공급자 $providerId 대기중 신청 ${pendingMissions.length}개');
      return AsyncValue.data(pendingMissions);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});