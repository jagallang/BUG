import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/provider_model.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../data/repositories/provider_dashboard_repository_impl.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';

// Repository Provider
final providerDashboardRepositoryProvider = Provider<ProviderDashboardRepository>((ref) {
  return ProviderDashboardRepositoryImpl();
});

// Current Provider ID (would come from authentication)
final currentProviderIdProvider = StateProvider<String?>((ref) => null);

// Provider Info Providers
final providerInfoProvider = StreamProvider.family<ProviderModel?, String>((ref, providerId) {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return repository.watchProviderInfo(providerId);
});

final providerInfoStateProvider = FutureProvider.family.autoDispose<ProviderModel?, String>((ref, providerId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getProviderInfo(providerId);
});

// Apps Providers  
final providerAppsProvider = FutureProvider.family.autoDispose<List<AppModel>, String>((ref, providerId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getProviderApps(providerId);
});

// 더미 데이터로 하드코딩된 테스트용 Provider
final dummyAppsProvider = FutureProvider.family.autoDispose<List<AppModel>, String>((ref, providerId) async {
  AppLogger.info('🔧 Dummy Apps Provider - Creating hardcoded test data', 'DummyAppsProvider');
  
  // 인위적 지연을 추가하여 로딩 상태 테스트
  await Future.delayed(const Duration(milliseconds: 500));
  
  return [
    AppModel(
      id: 'dummy_app_1',
      providerId: providerId,
      appName: '버그캐시 테스트 앱 1',
      description: '이것은 테스트용 더미 앱입니다. UI 컴포넌트들이 올바르게 렌더링되는지 확인하기 위한 샘플 데이터입니다.',
      category: AppCategory.productivity,
      type: AppType.android,
      version: '1.0.0',
      status: AppStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      screenshotUrls: const [],
      totalMissions: 3,
      activeMissions: 1,
      completedMissions: 2,
      totalBugReports: 5,
      totalTesters: 12,
      averageRating: 4.2,
      totalRatings: 8,
      totalDownloads: 150,
      metadata: const {},
      iconUrl: 'https://via.placeholder.com/100x100/4CAF50/FFFFFF?text=T1',
    ),
    AppModel(
      id: 'dummy_app_2',
      providerId: providerId,
      appName: '게임 테스터 앱',
      description: '게임 카테고리의 테스트 앱으로 검토 중 상태입니다.',
      category: AppCategory.game,
      type: AppType.ios,
      version: '2.1.0',
      status: AppStatus.review,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      screenshotUrls: const [],
      totalMissions: 7,
      activeMissions: 3,
      completedMissions: 4,
      totalBugReports: 2,
      totalTesters: 25,
      averageRating: 4.8,
      totalRatings: 15,
      totalDownloads: 320,
      metadata: const {},
      iconUrl: 'https://via.placeholder.com/100x100/FF5722/FFFFFF?text=G2',
    ),
    AppModel(
      id: 'dummy_app_3',
      providerId: providerId,
      appName: '교육용 앱',
      description: '교육 카테고리 앱으로 현재 초안 상태입니다. 아직 개발 중인 앱입니다.',
      category: AppCategory.education,
      type: AppType.web,
      version: '0.9.0',
      status: AppStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      screenshotUrls: const [],
      totalMissions: 1,
      activeMissions: 1,
      completedMissions: 0,
      totalBugReports: 0,
      totalTesters: 3,
      averageRating: 0.0,
      totalRatings: 0,
      totalDownloads: 0,
      metadata: const {},
      iconUrl: 'https://via.placeholder.com/100x100/2196F3/FFFFFF?text=E3',
    ),
    AppModel(
      id: 'dummy_app_4',
      providerId: providerId,
      appName: '일시정지된 앱',
      description: '현재 일시정지 상태인 앱입니다. 테스트를 위해 잠시 중단된 상태입니다.',
      category: AppCategory.utility,
      type: AppType.android,
      version: '1.5.0',
      status: AppStatus.paused,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      screenshotUrls: const [],
      totalMissions: 5,
      activeMissions: 0,
      completedMissions: 5,
      totalBugReports: 8,
      totalTesters: 18,
      averageRating: 3.9,
      totalRatings: 12,
      totalDownloads: 89,
      metadata: const {},
      iconUrl: 'https://via.placeholder.com/100x100/9E9E9E/FFFFFF?text=U4',
    ),
  ];
});

// 간단한 앱 목록 Provider - 의존성 최소화
final simpleAppsProvider = FutureProvider.family.autoDispose<List<AppModel>, String>((ref, providerId) async {
  try {
    final repository = ref.watch(providerDashboardRepositoryProvider);
    return await repository.getProviderApps(providerId);
  } catch (e) {
    AppLogger.error('Simple apps provider error: $e', 'SimpleAppsProvider', e);
    return []; // 에러 발생 시 빈 리스트 반환
  }
});

final appProvider = FutureProvider.family<AppModel?, String>((ref, appId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getApp(appId);
});

// Missions Providers
final providerMissionsProvider = FutureProvider.family.autoDispose<List<MissionModel>, String>((ref, providerId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getProviderMissions(providerId);
});

final appMissionsProvider = FutureProvider.family<List<MissionModel>, String>((ref, appId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getAppMissions(appId);
});

// Bug Reports Providers
final providerBugReportsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, providerId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getBugReports(providerId);
});

final appBugReportsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, appId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getAppBugReports(appId);
});

// Dashboard Stats Provider
final dashboardStatsProvider = FutureProvider.family.autoDispose<DashboardStats, String>((ref, providerId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getDashboardStats(providerId);
});

// Recent Activities Provider
final recentActivitiesProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, providerId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getRecentActivities(providerId);
});

// App Analytics Provider
final appAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, appId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getAppAnalytics(appId);
});

// Mission Analytics Provider
final missionAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, missionId) async {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return await repository.getMissionAnalytics(missionId);
});

// Provider Operations Notifier
class ProviderOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final ProviderDashboardRepository _repository;

  ProviderOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  // Provider Management
  Future<void> updateProviderInfo(String providerId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProviderInfo(providerId, data);
      state = const AsyncValue.data(null);
      AppLogger.info('Provider info updated successfully: $providerId', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update provider info', 'ProviderOperations', e);
    }
  }

  Future<void> updateProviderStatus(String providerId, ProviderStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProviderStatus(providerId, status);
      state = const AsyncValue.data(null);
      AppLogger.info('Provider status updated: $providerId -> ${status.name}', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update provider status', 'ProviderOperations', e);
    }
  }

  // App Management
  Future<String?> createApp(AppModel app) async {
    state = const AsyncValue.loading();
    try {
      final appId = await _repository.createApp(app);
      state = const AsyncValue.data(null);
      AppLogger.info('App created successfully: $appId', 'ProviderOperations');
      return appId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to create app', 'ProviderOperations', e);
      return null;
    }
  }

  Future<void> updateApp(String appId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateApp(appId, data);
      state = const AsyncValue.data(null);
      AppLogger.info('App updated successfully: $appId', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update app', 'ProviderOperations', e);
    }
  }

  Future<void> updateAppStatus(String appId, AppStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAppStatus(appId, status);
      state = const AsyncValue.data(null);
      AppLogger.info('App status updated: $appId -> ${status.name}', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update app status', 'ProviderOperations', e);
    }
  }

  Future<void> deleteApp(String appId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteApp(appId);
      state = const AsyncValue.data(null);
      AppLogger.info('App deleted successfully: $appId', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to delete app', 'ProviderOperations', e);
    }
  }

  // Mission Management
  Future<String?> createMission(MissionModel mission) async {
    state = const AsyncValue.loading();
    try {
      final missionId = await _repository.createMission(mission);
      state = const AsyncValue.data(null);
      AppLogger.info('Mission created successfully: $missionId', 'ProviderOperations');
      return missionId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to create mission', 'ProviderOperations', e);
      return null;
    }
  }

  Future<void> updateMission(String missionId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateMission(missionId, data);
      state = const AsyncValue.data(null);
      AppLogger.info('Mission updated successfully: $missionId', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update mission', 'ProviderOperations', e);
    }
  }

  Future<void> deleteMission(String missionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteMission(missionId);
      state = const AsyncValue.data(null);
      AppLogger.info('Mission deleted successfully: $missionId', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to delete mission', 'ProviderOperations', e);
    }
  }

  // Bug Report Management
  Future<void> updateBugReportStatus(String reportId, String status) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBugReportStatus(reportId, status);
      state = const AsyncValue.data(null);
      AppLogger.info('Bug report status updated: $reportId -> $status', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update bug report status', 'ProviderOperations', e);
    }
  }

  Future<void> addBugReportResponse(String reportId, String response) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBugReportResponse(reportId, response);
      state = const AsyncValue.data(null);
      AppLogger.info('Bug report response added: $reportId', 'ProviderOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to add bug report response', 'ProviderOperations', e);
    }
  }
}

// Provider Operations Provider
final providerOperationsProvider = StateNotifierProvider<ProviderOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return ProviderOperationsNotifier(repository);
});

// App Filter State Provider
final appFilterProvider = StateProvider<AppStatus?>((ref) => null);

// Mission Filter State Provider  
final missionFilterProvider = StateProvider<String?>((ref) => null);

// Bug Report Filter State Provider
final bugReportFilterProvider = StateProvider<String?>((ref) => null);

// Dashboard Tab State Provider
final dashboardTabProvider = StateProvider<int>((ref) => 0);

// Selected App Provider
final selectedAppProvider = StateProvider<String?>((ref) => null);

// Selected Mission Provider
final selectedMissionProvider = StateProvider<String?>((ref) => null);

// Filtered Apps Provider
final filteredAppsProvider = Provider.family<AsyncValue<List<AppModel>>, String>((ref, providerId) {
  final appsAsync = ref.watch(providerAppsProvider(providerId));
  final filter = ref.watch(appFilterProvider);

  return appsAsync.when(
    data: (apps) {
      if (filter == null) {
        return AsyncValue.data(apps);
      }
      final filteredApps = apps.where((app) => app.status == filter).toList();
      return AsyncValue.data(filteredApps);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Filtered Missions Provider
final filteredMissionsProvider = Provider.family<AsyncValue<List<MissionModel>>, String>((ref, providerId) {
  final missionsAsync = ref.watch(providerMissionsProvider(providerId));
  final filter = ref.watch(missionFilterProvider);

  return missionsAsync.when(
    data: (missions) {
      if (filter == null) {
        return AsyncValue.data(missions);
      }
      final filteredMissions = missions.where((mission) => mission.status == filter).toList();
      return AsyncValue.data(filteredMissions);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Dashboard Quick Actions Provider
class QuickActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ProviderDashboardRepository _repository;

  QuickActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> publishApp(String appId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAppStatus(appId, AppStatus.active);
      state = const AsyncValue.data(null);
      AppLogger.info('App published successfully: $appId', 'QuickActions');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to publish app', 'QuickActions', e);
    }
  }

  Future<void> pauseApp(String appId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAppStatus(appId, AppStatus.paused);
      state = const AsyncValue.data(null);
      AppLogger.info('App paused successfully: $appId', 'QuickActions');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to pause app', 'QuickActions', e);
    }
  }

  Future<void> activateMission(String missionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateMission(missionId, {'status': 'active'});
      state = const AsyncValue.data(null);
      AppLogger.info('Mission activated successfully: $missionId', 'QuickActions');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to activate mission', 'QuickActions', e);
    }
  }

  Future<void> completeMission(String missionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateMission(missionId, {'status': 'completed'});
      state = const AsyncValue.data(null);
      AppLogger.info('Mission completed successfully: $missionId', 'QuickActions');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to complete mission', 'QuickActions', e);
    }
  }
}

final quickActionsProvider = StateNotifierProvider<QuickActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(providerDashboardRepositoryProvider);
  return QuickActionsNotifier(repository);
});