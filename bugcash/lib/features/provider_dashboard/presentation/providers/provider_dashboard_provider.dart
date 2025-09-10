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