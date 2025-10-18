import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_missions_usecase.dart';
import '../../domain/usecases/approve_mission_usecase.dart';
import '../../domain/usecases/start_mission_usecase.dart';
import '../../domain/entities/mission_workflow_entity.dart';
import 'mission_state.dart';
import '../../../../core/utils/logger.dart';

/// Mission StateNotifier (Presentation Layer)
/// 폴링 기반 상태 관리 - 실시간 리스너 대신 주기적 갱신
class MissionStateNotifier extends StateNotifier<MissionState> {
  final GetMissionsUseCase _getMissionsUseCase;
  final ApproveMissionUseCase _approveMissionUseCase;
  final RejectMissionUseCase _rejectMissionUseCase;
  final StartMissionUseCase _startMissionUseCase;

  Timer? _pollingTimer;
  String? _currentUserId;
  String? _currentAppId;  // v2.20.0: 앱별 필터링용
  bool _isProvider;

  static const Duration _pollingInterval = Duration(seconds: 30);

  MissionStateNotifier({
    required GetMissionsUseCase getMissionsUseCase,
    required ApproveMissionUseCase approveMissionUseCase,
    required RejectMissionUseCase rejectMissionUseCase,
    required StartMissionUseCase startMissionUseCase,
  })  : _getMissionsUseCase = getMissionsUseCase,
        _approveMissionUseCase = approveMissionUseCase,
        _rejectMissionUseCase = rejectMissionUseCase,
        _startMissionUseCase = startMissionUseCase,
        _isProvider = false,
        super(const MissionState.initial());

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // ========================================
  // Polling System
  // ========================================

  /// 폴링 시작 (공급자용)
  void startPollingForProvider(String providerId) {
    _currentUserId = providerId;
    _isProvider = true;

    AppLogger.info('Polling started for provider: $providerId', 'MissionNotifier');

    // 초기 로드
    refreshMissions();

    // 30초마다 자동 갱신
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      refreshMissions();
    });
  }

  /// 폴링 시작 (테스터용)
  void startPollingForTester(String testerId) {
    _currentUserId = testerId;
    _isProvider = false;

    AppLogger.info('Starting polling for tester: $testerId', 'MissionNotifier');

    // 초기 로드
    refreshMissions();

    // 30초마다 자동 갱신
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      refreshMissions();
    });
  }

  /// v2.20.0: 폴링 시작 (앱별 미션용 - Provider 대시보드)
  void startPollingForApp(String appId, String providerId) {
    _currentUserId = providerId;
    _currentAppId = appId;  // v2.20.0: appId 저장하여 필터링에 사용
    _isProvider = true;

    debugPrint('🔵 [MissionNotifier] Polling started for app: $appId (provider: $providerId)');

    // 초기 로드
    refreshMissions();

    // 30초마다 자동 갱신
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      refreshMissions();
    });
  }

  /// v2.20.0: 폴링 중지 및 초기화
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentAppId = null;  // v2.20.0: appId 초기화
    AppLogger.info('Polling stopped', 'MissionNotifier');
  }

  /// v2.20.0: 수동 새로고침 (appId 필터링 추가)
  /// v2.24.6: 캐시 무효화 추가 (항상 최신 데이터 로드)
  /// v2.27.1: mounted 체크 추가 (disposed 상태에서 state 변경 방지)
  Future<void> refreshMissions() async {
    // v2.27.1: disposed 체크
    if (!mounted) {
      debugPrint('⚠️ [MissionNotifier] Cannot refresh: already disposed');
      return;
    }

    if (_currentUserId == null) {
      debugPrint('⚠️ [MissionNotifier] Cannot refresh: userId is null');
      return;
    }

    try {
      debugPrint('🔄 [MissionNotifier] Refreshing missions...');
      debugPrint('   ├─ userId: $_currentUserId');
      debugPrint('   ├─ appId: $_currentAppId');
      debugPrint('   └─ isProvider: $_isProvider');

      // v2.24.6: 캐시 무효화 (항상 최신 데이터 로드)
      if (_isProvider) {
        _getMissionsUseCase.invalidateProviderCache(_currentUserId!);
        debugPrint('   └─ 🗑️ Provider cache invalidated');
      } else {
        _getMissionsUseCase.invalidateTesterCache(_currentUserId!);
        debugPrint('   └─ 🗑️ Tester cache invalidated');
      }

      // v2.27.1: mounted 재확인 (Timer에서 호출되므로)
      if (!mounted) return;

      // 백그라운드 새로고침 표시
      state.maybeWhen(
        loaded: (missions, _) => state = MissionState.loaded(
          missions: missions,
          isRefreshing: true,
        ),
        orElse: () => state = const MissionState.loading(),
      );

      // 데이터 로드
      final missions = _isProvider
          ? await _getMissionsUseCase.getProviderMissions(_currentUserId!)
          : await _getMissionsUseCase.getTesterMissions(_currentUserId!);

      // v2.28.0: 비동기 작업 후 mounted 재확인
      if (!mounted) return;

      // v2.20.0: appId로 필터링 (앱별 미션 관리 페이지용)
      final filteredMissions = _currentAppId != null
          ? missions.where((m) => m.appId == _currentAppId || m.appId == 'provider_app_$_currentAppId').toList()
          : missions;

      state = MissionState.loaded(missions: filteredMissions);

      debugPrint('✅ [MissionNotifier] Missions refreshed');
      debugPrint('   ├─ Total loaded: ${missions.length} items');
      debugPrint('   └─ Filtered for appId: ${filteredMissions.length} items');
    } catch (e) {
      debugPrint('❌ [MissionNotifier] Failed to refresh missions: $e');

      // v2.28.0: 에러 처리 시에도 mounted 체크
      if (!mounted) return;

      state = MissionState.error(
        message: 'Failed to load missions: ${e.toString()}',
        exception: e,
      );
    }
  }

  // ========================================
  // Command Methods (낙관적 업데이트)
  // ========================================

  /// v2.28.0: 미션 승인 (낙관적 업데이트 + mounted 체크)
  Future<void> approveMission(String missionId) async {
    if (!mounted) return;  // v2.28.0: disposed 체크

    try {
      AppLogger.info('Approving mission: $missionId', 'MissionNotifier');

      // 1. 즉시 UI 업데이트 (낙관적)
      if (!mounted) return;  // v2.28.0: state 변경 전 재확인

      state.maybeWhen(
        loaded: (missions, isRefreshing) {
          final updatedMissions = missions.map((m) {
            if (m.id == missionId) {
              return m.copyWith(
                status: MissionWorkflowStatus.approved,
                approvedAt: DateTime.now(),
              );
            }
            return m;
          }).toList();

          if (mounted) state = MissionState.loaded(missions: updatedMissions);
        },
        orElse: () {},
      );

      // 2. 백그라운드 동기화
      if (!mounted) return;  // v2.28.0: UseCase 호출 전
      await _approveMissionUseCase.execute(missionId);

      // 3. 서버 데이터로 재검증
      if (!mounted) return;  // v2.28.0: refreshMissions 전
      await refreshMissions();

      AppLogger.info('Mission approved successfully: $missionId', 'MissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to approve mission', 'MissionNotifier', e);

      // 롤백 - 서버 데이터로 복원
      if (mounted) await refreshMissions();

      rethrow;
    }
  }

  /// v2.28.0: 미션 거부 (낙관적 업데이트 + mounted 체크)
  Future<void> rejectMission(String missionId, String reason) async {
    if (!mounted) return;  // v2.28.0: disposed 체크

    try {
      AppLogger.info('Rejecting mission: $missionId', 'MissionNotifier');

      // 1. 즉시 UI 업데이트 (낙관적)
      if (!mounted) return;  // v2.28.0: state 변경 전 재확인

      state.maybeWhen(
        loaded: (missions, isRefreshing) {
          final updatedMissions = missions
              .where((m) => m.id != missionId) // 목록에서 제거
              .toList();

          if (mounted) state = MissionState.loaded(missions: updatedMissions);
        },
        orElse: () {},
      );

      // 2. 백그라운드 동기화
      if (!mounted) return;  // v2.28.0: UseCase 호출 전
      await _rejectMissionUseCase.execute(missionId, reason);

      // 3. 서버 데이터로 재검증
      if (!mounted) return;  // v2.28.0: refreshMissions 전
      await refreshMissions();

      AppLogger.info('Mission rejected successfully: $missionId', 'MissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to reject mission', 'MissionNotifier', e);

      // 롤백
      if (mounted) await refreshMissions();

      rethrow;
    }
  }

  /// v2.28.0: 미션 시작 (낙관적 업데이트 + mounted 체크)
  Future<void> startMission(String missionId) async {
    if (!mounted) return;  // v2.28.0: disposed 체크

    try {
      AppLogger.info('Starting mission: $missionId', 'MissionNotifier');

      // 1. 즉시 UI 업데이트 (낙관적)
      if (!mounted) return;  // v2.28.0: state 변경 전 재확인

      state.maybeWhen(
        loaded: (missions, isRefreshing) {
          final updatedMissions = missions.map((m) {
            if (m.id == missionId) {
              return m.copyWith(
                status: MissionWorkflowStatus.inProgress,
                startedAt: DateTime.now(),
              );
            }
            return m;
          }).toList();

          if (mounted) state = MissionState.loaded(missions: updatedMissions);
        },
        orElse: () {},
      );

      // 2. 백그라운드 동기화
      if (!mounted) return;  // v2.28.0: UseCase 호출 전
      await _startMissionUseCase.execute(missionId);

      // 3. 서버 데이터로 재검증
      if (!mounted) return;  // v2.28.0: refreshMissions 전
      await refreshMissions();

      AppLogger.info('Mission started successfully: $missionId', 'MissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to start mission', 'MissionNotifier', e);

      // 롤백
      if (mounted) await refreshMissions();

      rethrow;
    }
  }
}
