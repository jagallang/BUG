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

    print('🔵 [MissionNotifier] Polling started for provider: $providerId');

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

  /// 폴링 시작 (앱별 미션용 - Provider 대시보드)
  void startPollingForApp(String appId, String providerId) {
    _currentUserId = providerId;
    _isProvider = true;

    AppLogger.info('Starting polling for app: $appId (provider: $providerId)', 'MissionNotifier');

    // 초기 로드
    refreshMissions();

    // 30초마다 자동 갱신
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      refreshMissions();
    });
  }

  /// 폴링 중지
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    AppLogger.info('Polling stopped', 'MissionNotifier');
  }

  /// 수동 새로고침
  Future<void> refreshMissions() async {
    if (_currentUserId == null) {
      print('⚠️ [MissionNotifier] Cannot refresh: userId is null');
      return;
    }

    try {
      print('🔄 [MissionNotifier] Refreshing missions...');
      print('   ├─ userId: $_currentUserId');
      print('   └─ isProvider: $_isProvider');

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

      state = MissionState.loaded(missions: missions);

      print('✅ [MissionNotifier] Missions refreshed: ${missions.length} items');
    } catch (e) {
      print('❌ [MissionNotifier] Failed to refresh missions: $e');
      state = MissionState.error(
        message: 'Failed to load missions: ${e.toString()}',
        exception: e,
      );
    }
  }

  // ========================================
  // Command Methods (낙관적 업데이트)
  // ========================================

  /// 미션 승인 (낙관적 업데이트)
  Future<void> approveMission(String missionId) async {
    try {
      AppLogger.info('Approving mission: $missionId', 'MissionNotifier');

      // 1. 즉시 UI 업데이트 (낙관적)
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

          state = MissionState.loaded(missions: updatedMissions);
        },
        orElse: () {},
      );

      // 2. 백그라운드 동기화
      await _approveMissionUseCase.execute(missionId);

      // 3. 서버 데이터로 재검증
      await refreshMissions();

      AppLogger.info('Mission approved successfully: $missionId', 'MissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to approve mission', 'MissionNotifier', e);

      // 롤백 - 서버 데이터로 복원
      await refreshMissions();

      rethrow;
    }
  }

  /// 미션 거부 (낙관적 업데이트)
  Future<void> rejectMission(String missionId, String reason) async {
    try {
      AppLogger.info('Rejecting mission: $missionId', 'MissionNotifier');

      // 1. 즉시 UI 업데이트 (낙관적)
      state.maybeWhen(
        loaded: (missions, isRefreshing) {
          final updatedMissions = missions
              .where((m) => m.id != missionId) // 목록에서 제거
              .toList();

          state = MissionState.loaded(missions: updatedMissions);
        },
        orElse: () {},
      );

      // 2. 백그라운드 동기화
      await _rejectMissionUseCase.execute(missionId, reason);

      // 3. 서버 데이터로 재검증
      await refreshMissions();

      AppLogger.info('Mission rejected successfully: $missionId', 'MissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to reject mission', 'MissionNotifier', e);

      // 롤백
      await refreshMissions();

      rethrow;
    }
  }

  /// 미션 시작 (낙관적 업데이트)
  Future<void> startMission(String missionId) async {
    try {
      AppLogger.info('Starting mission: $missionId', 'MissionNotifier');

      // 1. 즉시 UI 업데이트 (낙관적)
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

          state = MissionState.loaded(missions: updatedMissions);
        },
        orElse: () {},
      );

      // 2. 백그라운드 동기화
      await _startMissionUseCase.execute(missionId);

      // 3. 서버 데이터로 재검증
      await refreshMissions();

      AppLogger.info('Mission started successfully: $missionId', 'MissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to start mission', 'MissionNotifier', e);

      // 롤백
      await refreshMissions();

      rethrow;
    }
  }
}
