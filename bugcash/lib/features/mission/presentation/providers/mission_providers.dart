import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mission_state.dart';
import 'mission_state_notifier.dart';
import '../../data/providers/mission_providers.dart';

// ========================================
// StateNotifier Provider
// ========================================

final missionStateNotifierProvider =
    StateNotifierProvider<MissionStateNotifier, MissionState>((ref) {
  final getMissionsUseCase = ref.read(getMissionsUseCaseProvider);
  final approveMissionUseCase = ref.read(approveMissionUseCaseProvider);
  final rejectMissionUseCase = ref.read(rejectMissionUseCaseProvider);
  final startMissionUseCase = ref.read(startMissionUseCaseProvider);

  return MissionStateNotifier(
    getMissionsUseCase: getMissionsUseCase,
    approveMissionUseCase: approveMissionUseCase,
    rejectMissionUseCase: rejectMissionUseCase,
    startMissionUseCase: startMissionUseCase,
  );
});

// ========================================
// Convenience Providers (특정 상황에 특화된 Provider)
// ========================================

/// 공급자용 미션 Provider
final providerMissionsProvider = StateNotifierProvider.family<
    MissionStateNotifier,
    MissionState,
    String>((ref, providerId) {
  final notifier = ref.read(missionStateNotifierProvider.notifier);

  // 폴링 시작
  notifier.startPollingForProvider(providerId);

  return notifier;
});

/// 테스터용 미션 Provider
final testerMissionsProvider = StateNotifierProvider.family<
    MissionStateNotifier,
    MissionState,
    String>((ref, testerId) {
  final notifier = ref.read(missionStateNotifierProvider.notifier);

  // 폴링 시작
  notifier.startPollingForTester(testerId);

  return notifier;
});
