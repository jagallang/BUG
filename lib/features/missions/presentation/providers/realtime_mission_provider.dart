import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/realtime_mission_service.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';

// Realtime Mission Service Provider
final realtimeMissionServiceProvider = Provider<RealtimeMissionService>((ref) {
  return RealtimeMissionService.instance;
});

// Connection Status Provider
final connectionStatusProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.connectionStream;
});

// All Missions Stream Provider
final allMissionsStreamProvider = StreamProvider<List<MissionModel>>((ref) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.watchAllMissions();
});

// Missions by Status Stream Provider
final missionsByStatusStreamProvider = StreamProvider.family<List<MissionModel>, MissionStatus>((ref, status) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.watchMissionsByStatus(status);
});

// User Missions Stream Provider
final userMissionsStreamProvider = StreamProvider.family<List<MissionModel>, String>((ref, userId) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.watchUserMissions(userId);
});

// Single Mission Stream Provider
final missionStreamProvider = StreamProvider.family<MissionModel?, String>((ref, missionId) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.watchMission(missionId);
});

// Mission Participation Stream Provider
final missionParticipationStreamProvider = 
    StreamProvider.family<Map<String, dynamic>?, (String, String)>((ref, params) {
  final (userId, missionId) = params;
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.watchMissionParticipation(userId, missionId);
});

// Mission Progress Stream Provider
final missionProgressStreamProvider = 
    StreamProvider.family<Map<String, dynamic>, (String, String)>((ref, params) {
  final (userId, missionId) = params;
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.watchMissionProgress(userId, missionId);
});

// Mission Statistics Stream Provider
final missionStatsStreamProvider = StreamProvider<Map<String, int>>((ref) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return service.watchMissionStats();
});

// Realtime Mission Notifier for managing mission state
class RealtimeMissionNotifier extends StateNotifier<AsyncValue<List<MissionModel>>> {
  final RealtimeMissionService _service;
  
  static const String _currentUserId = 'demo_user'; // TODO: Get actual user ID

  RealtimeMissionNotifier(this._service) : super(const AsyncValue.loading()) {
    _initializeListeners();
  }

  void _initializeListeners() {
    // Start listening to all missions
    _service.startListener(
      'all_missions',
      _service.watchAllMissions(),
      (missions) {
        state = AsyncValue.data(missions);
        AppLogger.info('Missions updated: ${missions.length} missions', 'RealtimeMissionNotifier');
      },
    );
  }

  // Filter missions by status locally
  List<MissionModel> getMissionsByStatus(MissionStatus status) {
    return state.when(
      data: (missions) => missions.where((m) => m.status == status.name).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Get mission by ID
  MissionModel? getMissionById(String missionId) {
    return state.when(
      data: (missions) => missions.cast<MissionModel?>().firstWhere(
            (m) => m?.id == missionId,
            orElse: () => null,
          ),
      loading: () => null,
      error: (_, __) => null,
    );
  }

  // Update mission status
  Future<void> updateMissionStatus(String missionId, MissionStatus status) async {
    try {
      await _service.updateMissionStatus(missionId, status);
      AppLogger.info('Mission status updated: $missionId -> ${status.name}', 'RealtimeMissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to update mission status', 'RealtimeMissionNotifier', e);
      rethrow;
    }
  }

  // Update user mission progress
  Future<void> updateProgress(String missionId, Map<String, dynamic> progressData) async {
    try {
      await _service.updateUserMissionProgress(_currentUserId, missionId, progressData);
      AppLogger.info('Mission progress updated: $missionId', 'RealtimeMissionNotifier');
    } catch (e) {
      AppLogger.error('Failed to update mission progress', 'RealtimeMissionNotifier', e);
      rethrow;
    }
  }

  // Force refresh missions
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _initializeListeners();
  }

  @override
  void dispose() {
    _service.stopListener('all_missions');
    super.dispose();
  }
}

// Realtime Mission Provider
final realtimeMissionProvider = StateNotifierProvider<RealtimeMissionNotifier, AsyncValue<List<MissionModel>>>((ref) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return RealtimeMissionNotifier(service);
});

// Connection Status Notifier
class ConnectionStatusNotifier extends StateNotifier<Map<String, dynamic>> {
  final RealtimeMissionService _service;

  ConnectionStatusNotifier(this._service) : super({
    'isConnected': true,
    'connectionType': 'unknown',
    'timestamp': DateTime.now(),
    'reconnectAttempts': 0,
    'lastConnectedAt': DateTime.now(),
  }) {
    _initializeConnectionListener();
  }

  void _initializeConnectionListener() {
    _service.startListener(
      'connection_status',
      _service.connectionStream,
      (connectionData) {
        state = {
          ...state,
          ...connectionData,
          'lastUpdated': DateTime.now(),
          'reconnectAttempts': connectionData['isConnected'] ? 0 : (state['reconnectAttempts'] ?? 0) + 1,
          'lastConnectedAt': connectionData['isConnected'] ? DateTime.now() : state['lastConnectedAt'],
        };
        
        AppLogger.info('Connection status updated: ${connectionData['isConnected']}', 'ConnectionStatusNotifier');
      },
    );
  }

  // Get connection status
  bool get isConnected => state['isConnected'] ?? false;
  String get connectionType => state['connectionType'] ?? 'unknown';
  int get reconnectAttempts => state['reconnectAttempts'] ?? 0;
  DateTime? get lastConnectedAt => state['lastConnectedAt'];

  // Manual connection check
  Future<void> checkConnection() async {
    final isConnected = await _service.isConnected();
    state = {
      ...state,
      'isConnected': isConnected,
      'lastChecked': DateTime.now(),
    };
  }

  @override
  void dispose() {
    _service.stopListener('connection_status');
    super.dispose();
  }
}

// Connection Status Provider
final connectionStatusNotifierProvider = StateNotifierProvider<ConnectionStatusNotifier, Map<String, dynamic>>((ref) {
  final service = ref.watch(realtimeMissionServiceProvider);
  return ConnectionStatusNotifier(service);
});

// Mission Progress Notifier for specific mission
class MissionProgressNotifier extends StateNotifier<Map<String, dynamic>> {
  final RealtimeMissionService _service;
  final String userId;
  final String missionId;

  MissionProgressNotifier(this._service, this.userId, this.missionId) : super({
    'isParticipating': false,
    'progress': 0,
    'completedTasks': 0,
    'totalTasks': 0,
    'status': 'not_started',
  }) {
    _initializeProgressListener();
  }

  void _initializeProgressListener() {
    _service.startListener(
      'mission_progress_${userId}_$missionId',
      _service.watchMissionProgress(userId, missionId),
      (progressData) {
        state = {
          ...state,
          ...progressData,
          'lastUpdated': DateTime.now(),
        };
        
        AppLogger.info('Mission progress updated for $missionId: ${progressData['progress']}%', 'MissionProgressNotifier');
      },
    );
  }

  // Update progress locally and sync
  Future<void> updateProgress({
    int? completedTasks,
    int? totalTasks,
    String? status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final progressData = <String, dynamic>{
        if (completedTasks != null) 'completedTasks': completedTasks,
        if (totalTasks != null) 'totalTasks': totalTasks,
        if (status != null) 'status': status,
        if (additionalData != null) ...additionalData,
      };

      // Calculate progress percentage
      if (completedTasks != null && totalTasks != null && totalTasks > 0) {
        progressData['progress'] = ((completedTasks / totalTasks) * 100).round();
      }

      await _service.updateUserMissionProgress(userId, missionId, progressData);
      
      AppLogger.info('Mission progress updated successfully for $missionId', 'MissionProgressNotifier');
    } catch (e) {
      AppLogger.error('Failed to update mission progress for $missionId', 'MissionProgressNotifier', e);
      rethrow;
    }
  }

  // Mark task as completed
  Future<void> completeTask(int taskIndex) async {
    final currentCompleted = state['completedTasks'] as int? ?? 0;
    final total = state['totalTasks'] as int? ?? 0;
    
    await updateProgress(
      completedTasks: currentCompleted + 1,
      totalTasks: total,
      status: (currentCompleted + 1 >= total) ? 'completed' : 'in_progress',
      additionalData: {
        'lastTaskCompleted': taskIndex,
        'completedAt': (currentCompleted + 1 >= total) ? DateTime.now().toIso8601String() : null,
      },
    );
  }

  // Start mission participation
  Future<void> startMission({int totalTasks = 1}) async {
    await updateProgress(
      completedTasks: 0,
      totalTasks: totalTasks,
      status: 'in_progress',
      additionalData: {
        'startedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _service.stopListener('mission_progress_${userId}_$missionId');
    super.dispose();
  }
}

// Mission Progress Provider Factory
final missionProgressNotifierProvider = StateNotifierProvider.family<MissionProgressNotifier, Map<String, dynamic>, (String, String)>((ref, params) {
  final (userId, missionId) = params;
  final service = ref.watch(realtimeMissionServiceProvider);
  return MissionProgressNotifier(service, userId, missionId);
});

// Convenience providers for common use cases
final activeMissionsProvider = Provider<AsyncValue<List<MissionModel>>>((ref) {
  return ref.watch(missionsByStatusStreamProvider(MissionStatus.active));
});

final completedMissionsProvider = Provider<AsyncValue<List<MissionModel>>>((ref) {
  return ref.watch(missionsByStatusStreamProvider(MissionStatus.completed));
});

final currentUserMissionsProvider = Provider<AsyncValue<List<MissionModel>>>((ref) {
  return ref.watch(userMissionsStreamProvider('demo_user')); // TODO: Get actual user ID
});