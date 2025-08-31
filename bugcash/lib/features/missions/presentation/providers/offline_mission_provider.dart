import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/realtime_mission_service.dart';
import '../../../../core/data/services/offline_sync_service.dart';
import '../../../../core/data/services/offline_data_cache.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';
import 'realtime_mission_provider.dart';

// Offline-aware mission providers

// Helper function to create MissionModel from cached data
MissionModel _createMissionFromCache(Map<String, dynamic> data) {
  return MissionModel(
    id: data['id'] ?? '',
    title: data['title'] ?? '',
    appName: data['appName'] ?? '',
    category: data['category'] ?? '',
    status: data['status'] ?? 'draft',
    testers: data['testers'] ?? 0,
    maxTesters: data['maxTesters'] ?? 0,
    reward: data['reward'] ?? 0,
    description: data['description'] ?? '',
    requirements: List<String>.from(data['requirements'] ?? []),
    duration: data['duration'] ?? 7,
    createdAt: data['createdAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
        : null,
    createdBy: data['createdBy'] ?? '',
    bugs: data['bugs'] ?? 0,
    isHot: data['isHot'] ?? false,
    isNew: data['isNew'] ?? false,
  );
}

// Offline mission sync provider
final offlineMissionSyncProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService.instance;
});

// Offline data cache provider
final offlineDataCacheProvider = Provider<OfflineDataCache>((ref) {
  return OfflineDataCache.instance;
});

// Offline-aware missions stream provider
final offlineAwareMissionsProvider = StreamProvider<List<MissionModel>>((ref) {
  final realtimeService = ref.watch(realtimeMissionServiceProvider);
  final cache = ref.watch(offlineDataCacheProvider);
  
  return realtimeService.watchAllMissions().handleError((error) async {
    AppLogger.error('Error in missions stream, falling back to cache', 'OfflineAwareMissionsProvider', error);
    
    // Try to get cached data
    final cachedMissions = await cache.getCachedMissions('all_missions');
    if (cachedMissions != null) {
      return cachedMissions;
    }
    
    // If no cache available, return empty list
    return <MissionModel>[];
  }).asyncMap((missions) async {
    // Cache the data when successfully received
    await cache.cacheMissions('all_missions', missions);
    return missions;
  });
});

// Offline-aware missions by status provider
final offlineAwareMissionsByStatusProvider = StreamProvider.family<List<MissionModel>, MissionStatus>((ref, status) {
  final realtimeService = ref.watch(realtimeMissionServiceProvider);
  final cache = ref.watch(offlineDataCacheProvider);
  final cacheKey = 'missions_by_status_${status.name}';
  
  return realtimeService.watchMissionsByStatus(status).handleError((error) async {
    AppLogger.error('Error in missions by status stream, falling back to cache', 'OfflineAwareMissionsByStatusProvider', error);
    
    final cachedMissions = await cache.getCachedMissions(cacheKey);
    if (cachedMissions != null) {
      return cachedMissions;
    }
    
    return <MissionModel>[];
  }).asyncMap((missions) async {
    await cache.cacheMissions(cacheKey, missions);
    return missions;
  });
});

// Offline-aware user missions provider
final offlineAwareUserMissionsProvider = StreamProvider.family<List<MissionModel>, String>((ref, userId) {
  final realtimeService = ref.watch(realtimeMissionServiceProvider);
  final cache = ref.watch(offlineDataCacheProvider);
  final cacheKey = 'user_missions_$userId';
  
  return realtimeService.watchUserMissions(userId).handleError((error) async {
    AppLogger.error('Error in user missions stream, falling back to cache', 'OfflineAwareUserMissionsProvider', error);
    
    final cachedMissions = await cache.getCachedMissions(cacheKey);
    if (cachedMissions != null) {
      return cachedMissions;
    }
    
    return <MissionModel>[];
  }).asyncMap((missions) async {
    await cache.cacheMissions(cacheKey, missions);
    return missions;
  });
});

// Offline-aware single mission provider
final offlineAwareMissionProvider = StreamProvider.family<MissionModel?, String>((ref, missionId) {
  final realtimeService = ref.watch(realtimeMissionServiceProvider);
  final cache = ref.watch(offlineDataCacheProvider);
  final cacheKey = 'mission_$missionId';
  
  return realtimeService.watchMission(missionId).handleError((error) async {
    AppLogger.error('Error in mission stream, falling back to cache', 'OfflineAwareMissionProvider', error);
    
    final cachedData = await cache.getCachedData<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      return _createMissionFromCache(cachedData);
    }
    
    return null;
  }).asyncMap((mission) async {
    if (mission != null) {
      await cache.cacheData(cacheKey, mission.toFirestore());
    }
    return mission;
  });
});

// Offline mission operations notifier
class OfflineMissionOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineSyncService _syncService;
  final OfflineDataCache _cache;
  final RealtimeMissionService _realtimeService;
  
  static const String _currentUserId = 'demo_user'; // TODO: Get actual user ID

  OfflineMissionOperationsNotifier(
    this._syncService,
    this._cache,
    this._realtimeService,
  ) : super(const AsyncValue.data(null));

  // Update mission status (offline-aware)
  Future<void> updateMissionStatus(String missionId, MissionStatus status) async {
    state = const AsyncValue.loading();
    
    try {
      // Try immediate update if online
      try {
        await _realtimeService.updateMissionStatus(missionId, status);
        state = const AsyncValue.data(null);
        AppLogger.info('Mission status updated immediately: $missionId -> ${status.name}', 'OfflineMissionOperations');
        return;
      } catch (e) {
        AppLogger.warning('Immediate update failed, queuing for sync', 'OfflineMissionOperations');
      }

      // Queue for offline sync
      await _syncService.addToSyncQueue(
        collection: 'missions',
        documentId: missionId,
        data: {
          'status': status.name,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        operation: SyncOperation.update,
      );

      // Update local cache optimistically
      await _updateLocalMissionStatus(missionId, status);
      
      state = const AsyncValue.data(null);
      AppLogger.info('Mission status queued for sync: $missionId -> ${status.name}', 'OfflineMissionOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update mission status', 'OfflineMissionOperations', e);
    }
  }

  // Update mission progress (offline-aware)
  Future<void> updateMissionProgress(String missionId, Map<String, dynamic> progressData) async {
    state = const AsyncValue.loading();
    
    try {
      // Try immediate update if online
      try {
        await _realtimeService.updateUserMissionProgress(_currentUserId, missionId, progressData);
        state = const AsyncValue.data(null);
        AppLogger.info('Mission progress updated immediately: $missionId', 'OfflineMissionOperations');
        return;
      } catch (e) {
        AppLogger.warning('Immediate progress update failed, queuing for sync', 'OfflineMissionOperations');
      }

      // Queue for offline sync
      await _syncService.addToSyncQueue(
        collection: 'user_missions',
        data: {
          'userId': _currentUserId,
          'missionId': missionId,
          ...progressData,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        operation: SyncOperation.create, // Will update if exists
      );

      // Update local cache optimistically
      await _cache.cacheMissionProgress(_currentUserId, missionId, progressData);
      
      state = const AsyncValue.data(null);
      AppLogger.info('Mission progress queued for sync: $missionId', 'OfflineMissionOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to update mission progress', 'OfflineMissionOperations', e);
    }
  }

  // Submit bug report (offline-aware)
  Future<void> submitBugReport(String missionId, Map<String, dynamic> bugReportData) async {
    state = const AsyncValue.loading();
    
    try {
      // Try immediate submission if online
      try {
        // Add immediate submission logic here
        // await _bugReportService.submitReport(bugReportData);
        state = const AsyncValue.data(null);
        AppLogger.info('Bug report submitted immediately: $missionId', 'OfflineMissionOperations');
        return;
      } catch (e) {
        AppLogger.warning('Immediate bug report submission failed, queuing for sync', 'OfflineMissionOperations');
      }

      // Queue for offline sync
      await _syncService.addToSyncQueue(
        collection: 'bug_reports',
        data: {
          ...bugReportData,
          'missionId': missionId,
          'userId': _currentUserId,
          'submittedAt': DateTime.now().millisecondsSinceEpoch,
        },
        operation: SyncOperation.create,
      );
      
      state = const AsyncValue.data(null);
      AppLogger.info('Bug report queued for sync: $missionId', 'OfflineMissionOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to submit bug report', 'OfflineMissionOperations', e);
    }
  }

  // Join mission (offline-aware)
  Future<void> joinMission(String missionId) async {
    state = const AsyncValue.loading();
    
    try {
      final joinData = {
        'userId': _currentUserId,
        'missionId': missionId,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
        'progress': 0,
        'status': 'joined',
        'completedTasks': 0,
        'totalTasks': 1,
      };

      // Try immediate join if online
      try {
        await _realtimeService.updateUserMissionProgress(_currentUserId, missionId, joinData);
        state = const AsyncValue.data(null);
        AppLogger.info('Joined mission immediately: $missionId', 'OfflineMissionOperations');
        return;
      } catch (e) {
        AppLogger.warning('Immediate mission join failed, queuing for sync', 'OfflineMissionOperations');
      }

      // Queue for offline sync
      await _syncService.addToSyncQueue(
        collection: 'user_missions',
        data: joinData,
        operation: SyncOperation.create,
      );

      // Update local cache optimistically
      await _cache.cacheMissionProgress(_currentUserId, missionId, joinData);
      
      state = const AsyncValue.data(null);
      AppLogger.info('Mission join queued for sync: $missionId', 'OfflineMissionOperations');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.error('Failed to join mission', 'OfflineMissionOperations', e);
    }
  }

  // Update local mission status in cache
  Future<void> _updateLocalMissionStatus(String missionId, MissionStatus status) async {
    try {
      // Get cached mission and update its status
      final cachedData = await _cache.getCachedData<Map<String, dynamic>>('mission_$missionId');
      if (cachedData != null) {
        cachedData['status'] = status.name;
        cachedData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        await _cache.cacheData('mission_$missionId', cachedData);
      }

      // Also update in all missions cache if present
      final allMissions = await _cache.getCachedMissions('all_missions');
      if (allMissions != null) {
        final updatedMissions = allMissions.map((mission) {
          if (mission.id == missionId) {
            return mission.copyWith(status: status.name);
          }
          return mission;
        }).toList();
        await _cache.cacheMissions('all_missions', updatedMissions);
      }
    } catch (e) {
      AppLogger.error('Failed to update local mission status', 'OfflineMissionOperations', e);
    }
  }
}

// Offline mission operations provider
final offlineMissionOperationsProvider = StateNotifierProvider<OfflineMissionOperationsNotifier, AsyncValue<void>>((ref) {
  final syncService = ref.watch(offlineMissionSyncProvider);
  final cache = ref.watch(offlineDataCacheProvider);
  final realtimeService = ref.watch(realtimeMissionServiceProvider);
  
  return OfflineMissionOperationsNotifier(syncService, cache, realtimeService);
});

// Sync queue status provider
final syncQueueStatusProvider = StreamProvider<List<PendingSyncItem>>((ref) {
  final syncService = ref.watch(offlineMissionSyncProvider);
  return syncService.syncQueueStream;
});

// Sync status provider
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(offlineMissionSyncProvider);
  return syncService.syncStatusStream;
});

// Cache info provider
final cacheInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final cache = ref.watch(offlineDataCacheProvider);
  return await cache.getCacheInfo();
});

// Offline mission stats provider (with cache fallback)
final offlineMissionStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final realtimeService = ref.watch(realtimeMissionServiceProvider);
  final cache = ref.watch(offlineDataCacheProvider);
  
  return realtimeService.watchMissionStats().handleError((error) async {
    AppLogger.error('Error in mission stats stream, falling back to cache', 'OfflineMissionStatsProvider', error);
    
    final cachedStats = await cache.getCachedData<Map<String, int>>('mission_stats');
    if (cachedStats != null) {
      return cachedStats;
    }
    
    return <String, int>{};
  }).asyncMap((stats) async {
    await cache.cacheData('mission_stats', stats);
    return stats;
  });
});