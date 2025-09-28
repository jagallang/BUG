import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/provider_model.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../data/repositories/provider_dashboard_repository_impl.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../shared/providers/unified_mission_provider.dart';
import '../../../shared/models/unified_mission_model.dart';

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
final dashboardAppsProvider = FutureProvider.family.autoDispose<List<AppModel>, String>((ref, providerId) async {
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
  final appsAsync = ref.watch(dashboardAppsProvider(providerId));
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

// ========================================
// 🔔 실시간 알림 시스템 (Bidirectional Sync)
// ========================================

/// 🔔 공급자별 실시간 테스터 신청 알림 Provider
/// UnifiedMissionProvider를 사용하여 실시간 동기화
final providerRealtimeNotificationsProvider = StreamProvider.family<ProviderNotificationState, String>((ref, providerId) {
  if (kDebugMode) {
    debugPrint('🔔 PROVIDER_NOTIFICATIONS: 공급자($providerId) 실시간 알림 시작');
  }

  // UnifiedMissionProvider를 사용하여 공급자별 미션 스트림 구독
  final providerMissionsStream = ref.watch(providerMissionsProvider(providerId));

  return providerMissionsStream.when(
    data: (missions) {
      // 새로운 신청(pending) 카운트
      final newApplications = missions.where((m) => m.status == 'pending').length;

      // 진행중 미션 카운트
      final activeMissions = missions.where((m) => m.status == 'in_progress').length;

      // 완료된 미션 카운트
      final completedMissions = missions.where((m) => m.status == 'completed').length;

      // 최근 신청 (24시간 이내) - 임시로 createdAt 사용
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final recentApplications = missions.where((m) {
        // MissionModel에 appliedAt이 없으므로 createdAt 사용
        final createdAt = m.createdAt ?? DateTime.now();
        return createdAt.isAfter(yesterday) && m.status == 'pending';
      }).toList();

      // MissionModel을 UnifiedMissionModel로 변환하는 임시 리스트
      final List<UnifiedMissionModel> convertedRecentApplications = [];

      final notificationState = ProviderNotificationState(
        newApplicationsCount: newApplications,
        activeMissionsCount: activeMissions,
        completedMissionsCount: completedMissions,
        recentApplications: convertedRecentApplications,
        hasUnreadNotifications: newApplications > 0,
        lastUpdated: DateTime.now(),
        isConnected: true,
      );

      if (kDebugMode) {
        debugPrint('🔔 PROVIDER_NOTIFICATIONS: 상태 업데이트 - 신규 $newApplications, 진행중 $activeMissions, 완료 $completedMissions');
      }

      return Stream.value(notificationState);
    },
    loading: () => Stream.value(ProviderNotificationState.loading()),
    error: (error, stack) {
      debugPrint('🚨 PROVIDER_NOTIFICATIONS: 오류 - $error');
      return Stream.value(ProviderNotificationState.error(error.toString()));
    },
  );
});

/// 🔔 새로운 신청 감지 Provider (toast 알림용)
final newApplicationDetectorProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, providerId) {
  final providerMissions = ref.watch(providerMissionsProvider(providerId));

  return providerMissions.when(
    data: (missions) {
      // 최근 5분 이내 신청만 필터링 (toast 알림용) - 임시로 createdAt 사용
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final veryRecentApplications = missions.where((m) {
        final createdAt = m.createdAt ?? DateTime.now();
        return createdAt.isAfter(fiveMinutesAgo) && m.status == 'pending';
      }).toList();

      if (veryRecentApplications.isNotEmpty && kDebugMode) {
        debugPrint('🔔 NEW_APPLICATION_DETECTOR: ${veryRecentApplications.length}개 신규 신청 감지');
      }

      // MissionModel을 UnifiedMissionModel로 변환하는 임시 빈 리스트
      return Stream.value(<UnifiedMissionModel>[]);
    },
    loading: () => Stream.value(<UnifiedMissionModel>[]),
    error: (error, stack) => Stream.value(<UnifiedMissionModel>[]),
  );
});

/// 🔔 앱별 테스터 신청 실시간 Provider
final appTesterApplicationsProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, appId) {
  if (kDebugMode) {
    debugPrint('🔔 APP_TESTERS: 앱($appId) 테스터 신청 실시간 감시 시작');
  }

  // UnifiedMissionProvider의 앱별 테스터 스트림 사용
  final appTestersStream = ref.watch(appTestersStreamProvider(appId));

  return appTestersStream.when(
    data: (testers) {
      if (kDebugMode) {
        debugPrint('🔔 APP_TESTERS: 앱 $appId - ${testers.length}개 테스터 신청');
      }
      return Stream.value(testers);
    },
    loading: () => Stream.value(<UnifiedMissionModel>[]),
    error: (error, stack) {
      debugPrint('🚨 APP_TESTERS: 앱 $appId 테스터 조회 오류 - $error');
      return Stream.value(<UnifiedMissionModel>[]);
    },
  );
});

/// 🔔 공급자 대시보드 통합 알림 상태 관리
class ProviderNotificationNotifier extends StateNotifier<ProviderNotificationState> {
  ProviderNotificationNotifier() : super(ProviderNotificationState.initial());

  /// 알림 읽음 처리
  void markNotificationsAsRead() {
    state = state.copyWith(
      newApplicationsCount: 0,
      hasUnreadNotifications: false,
    );

    if (kDebugMode) {
      debugPrint('🔔 NOTIFICATION_MANAGER: 알림 읽음 처리 완료');
    }
  }

  /// 특정 신청 승인/거부 후 카운트 업데이트
  void updateAfterApplicationAction(String applicationId, String newStatus) {
    if (newStatus == 'approved' || newStatus == 'rejected') {
      final currentCount = state.newApplicationsCount;
      state = state.copyWith(
        newApplicationsCount: (currentCount - 1).clamp(0, 999),
        lastUpdated: DateTime.now(),
      );

      if (kDebugMode) {
        debugPrint('🔔 NOTIFICATION_MANAGER: 신청 처리 후 카운트 업데이트 - $applicationId -> $newStatus');
      }
    }
  }

  /// 연결 상태 업데이트
  void updateConnectionStatus(bool isConnected) {
    state = state.copyWith(
      isConnected: isConnected,
      lastUpdated: DateTime.now(),
    );
  }
}

final providerNotificationNotifierProvider = StateNotifierProvider<ProviderNotificationNotifier, ProviderNotificationState>((ref) {
  return ProviderNotificationNotifier();
});

/// 🔔 알림 상태 데이터 클래스
class ProviderNotificationState {
  final int newApplicationsCount;
  final int activeMissionsCount;
  final int completedMissionsCount;
  final List<UnifiedMissionModel> recentApplications;
  final bool hasUnreadNotifications;
  final bool isConnected;
  final DateTime lastUpdated;
  final String? error;

  const ProviderNotificationState({
    required this.newApplicationsCount,
    required this.activeMissionsCount,
    required this.completedMissionsCount,
    required this.recentApplications,
    required this.hasUnreadNotifications,
    required this.isConnected,
    required this.lastUpdated,
    this.error,
  });

  factory ProviderNotificationState.initial() {
    return ProviderNotificationState(
      newApplicationsCount: 0,
      activeMissionsCount: 0,
      completedMissionsCount: 0,
      recentApplications: const [],
      hasUnreadNotifications: false,
      isConnected: false,
      lastUpdated: DateTime.now(),
    );
  }

  factory ProviderNotificationState.loading() {
    return ProviderNotificationState(
      newApplicationsCount: 0,
      activeMissionsCount: 0,
      completedMissionsCount: 0,
      recentApplications: const [],
      hasUnreadNotifications: false,
      isConnected: false,
      lastUpdated: DateTime.now(),
    );
  }

  factory ProviderNotificationState.error(String errorMessage) {
    return ProviderNotificationState(
      newApplicationsCount: 0,
      activeMissionsCount: 0,
      completedMissionsCount: 0,
      recentApplications: const [],
      hasUnreadNotifications: false,
      isConnected: false,
      lastUpdated: DateTime.now(),
      error: errorMessage,
    );
  }

  ProviderNotificationState copyWith({
    int? newApplicationsCount,
    int? activeMissionsCount,
    int? completedMissionsCount,
    List<UnifiedMissionModel>? recentApplications,
    bool? hasUnreadNotifications,
    bool? isConnected,
    DateTime? lastUpdated,
    String? error,
  }) {
    return ProviderNotificationState(
      newApplicationsCount: newApplicationsCount ?? this.newApplicationsCount,
      activeMissionsCount: activeMissionsCount ?? this.activeMissionsCount,
      completedMissionsCount: completedMissionsCount ?? this.completedMissionsCount,
      recentApplications: recentApplications ?? this.recentApplications,
      hasUnreadNotifications: hasUnreadNotifications ?? this.hasUnreadNotifications,
      isConnected: isConnected ?? this.isConnected,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error ?? this.error,
    );
  }

  /// 총 알림 개수
  int get totalNotifications => newApplicationsCount;

  /// 알림 배지 표시 여부
  bool get shouldShowBadge => newApplicationsCount > 0;

  /// 연결 상태 텍스트
  String get connectionStatusText => isConnected ? '실시간 연결됨' : '연결 끊김';

  /// 마지막 업데이트 텍스트
  String get lastUpdatedText {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else {
      return '${difference.inHours}시간 전';
    }
  }

  @override
  String toString() {
    return 'ProviderNotificationState(newApplications: $newApplicationsCount, active: $activeMissionsCount, completed: $completedMissionsCount, connected: $isConnected)';
  }
}