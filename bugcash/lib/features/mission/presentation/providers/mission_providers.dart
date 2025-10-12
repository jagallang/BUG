import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mission_state.dart';
import 'mission_state_notifier.dart';
import '../../data/providers/mission_providers.dart';

// ========================================
// v2.28.0: Clean Architecture Mission Providers
// ========================================
// ⚠️ 주의: unified_mission_provider.dart와 이름 충돌 방지를 위해
//          모든 Provider 이름에 'cleanArch' 접두어 사용

/// v2.28.0: 공급자용 미션 Provider (독립 인스턴스)
final cleanArchProviderMissionProvider = StateNotifierProvider.family.autoDispose<
    MissionStateNotifier,
    MissionState,
    String>((ref, providerId) {
  // ✅ 각 providerId마다 독립적인 StateNotifier 인스턴스 생성
  final notifier = MissionStateNotifier(
    getMissionsUseCase: ref.read(getMissionsUseCaseProvider),
    approveMissionUseCase: ref.read(approveMissionUseCaseProvider),
    rejectMissionUseCase: ref.read(rejectMissionUseCaseProvider),
    startMissionUseCase: ref.read(startMissionUseCaseProvider),
  );

  // 폴링 시작
  notifier.startPollingForProvider(providerId);

  // AutoDispose 시 정리
  ref.onDispose(() {
    notifier.stopPolling();
    // ❌ notifier.dispose() 제거 - AutoDispose가 자동으로 호출
  });

  return notifier;
});

/// v2.28.0: 테스터용 미션 Provider (독립 인스턴스)
final cleanArchTesterMissionProvider = StateNotifierProvider.family.autoDispose<
    MissionStateNotifier,
    MissionState,
    String>((ref, testerId) {
  // ✅ 각 testerId마다 독립적인 StateNotifier 인스턴스 생성
  final notifier = MissionStateNotifier(
    getMissionsUseCase: ref.read(getMissionsUseCaseProvider),
    approveMissionUseCase: ref.read(approveMissionUseCaseProvider),
    rejectMissionUseCase: ref.read(rejectMissionUseCaseProvider),
    startMissionUseCase: ref.read(startMissionUseCaseProvider),
  );

  // 폴링 시작
  notifier.startPollingForTester(testerId);

  // AutoDispose 시 정리
  ref.onDispose(() {
    notifier.stopPolling();
    // ❌ notifier.dispose() 제거 - AutoDispose가 자동으로 호출
  });

  return notifier;
});

/// v2.28.0: 앱별 미션 Provider (독립 인스턴스)
/// mission_management_page_v2.dart에서 사용
final cleanArchAppMissionProvider = StateNotifierProvider.family.autoDispose<
    MissionStateNotifier,
    MissionState,
    ({String appId, String providerId})>((ref, params) {
  // ✅ 각 (appId, providerId) 조합마다 독립적인 StateNotifier 인스턴스 생성
  final notifier = MissionStateNotifier(
    getMissionsUseCase: ref.read(getMissionsUseCaseProvider),
    approveMissionUseCase: ref.read(approveMissionUseCaseProvider),
    rejectMissionUseCase: ref.read(rejectMissionUseCaseProvider),
    startMissionUseCase: ref.read(startMissionUseCaseProvider),
  );

  // 앱별 폴링 시작
  notifier.startPollingForApp(params.appId, params.providerId);

  // AutoDispose 시 정리
  ref.onDispose(() {
    notifier.stopPolling();
    // ❌ notifier.dispose() 제거 - AutoDispose가 자동으로 호출
  });

  return notifier;
});
