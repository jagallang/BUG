import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';

enum MissionStatus {
  draft,
  active,
  completed,
  paused,
  cancelled,
}

class RealtimeMissionService {
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  
  static RealtimeMissionService? _instance;
  static RealtimeMissionService get instance => _instance ??= RealtimeMissionService._internal();

  RealtimeMissionService._internal()
      : _firestore = FirebaseFirestore.instance,
        _connectivity = Connectivity();

  static const String _missionsCollection = 'missions';
  static const String _userMissionsCollection = 'user_missions';
  
  final Map<String, StreamSubscription> _activeListeners = {};
  final StreamController<Map<String, dynamic>> _connectionController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get connectionStream => _connectionController.stream;

  // Initialize realtime listeners
  Future<void> initialize() async {
    await _initializeConnectionMonitoring();
    AppLogger.info('Realtime Mission Service initialized', 'RealtimeMissionService');
  }

  // Initialize connection monitoring
  Future<void> _initializeConnectionMonitoring() async {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final isConnected = result != ConnectivityResult.none;
      _connectionController.add({
        'isConnected': isConnected,
        'connectionType': result.name,
        'timestamp': DateTime.now(),
      });
      
      AppLogger.info('Connection status changed: $result', 'RealtimeMissionService');
      
      if (isConnected) {
        _reconnectListeners();
      } else {
        _pauseListeners();
      }
    });
  }

  // Watch all missions with real-time updates
  Stream<List<MissionModel>> watchAllMissions() {
    return _firestore
        .collection(_missionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          AppLogger.info('Received missions update: ${snapshot.docs.length} missions', 'RealtimeMissionService');
          
          return snapshot.docs.map((doc) {
            return MissionModel.fromFirestore(doc);
          }).toList();
        })
        .handleError((error) {
          AppLogger.error('Error watching missions', 'RealtimeMissionService', error);
        });
  }

  // Watch missions by status
  Stream<List<MissionModel>> watchMissionsByStatus(MissionStatus status) {
    return _firestore
        .collection(_missionsCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          AppLogger.info('Received missions update for status ${status.name}: ${snapshot.docs.length} missions', 'RealtimeMissionService');
          
          return snapshot.docs.map((doc) {
            return MissionModel.fromFirestore(doc);
          }).toList();
        })
        .handleError((error) {
          AppLogger.error('Error watching missions by status', 'RealtimeMissionService', error);
        });
  }

  // Watch user's participated missions
  Stream<List<MissionModel>> watchUserMissions(String userId) {
    return _firestore
        .collection(_userMissionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((userMissionSnapshot) async {
          if (userMissionSnapshot.docs.isEmpty) {
            return <MissionModel>[];
          }

          final missionIds = userMissionSnapshot.docs
              .map((doc) => doc.data()['missionId'] as String)
              .toList();

          // Get actual mission details
          final missionsSnapshot = await _firestore
              .collection(_missionsCollection)
              .where(FieldPath.documentId, whereIn: missionIds)
              .get();

          AppLogger.info('Received user missions update: ${missionsSnapshot.docs.length} missions', 'RealtimeMissionService');

          return missionsSnapshot.docs.map((doc) {
            return MissionModel.fromFirestore(doc);
          }).toList();
        })
        .handleError((error) {
          AppLogger.error('Error watching user missions', 'RealtimeMissionService', error);
        });
  }

  // Watch specific mission
  Stream<MissionModel?> watchMission(String missionId) {
    return _firestore
        .collection(_missionsCollection)
        .doc(missionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            AppLogger.warning('Mission not found: $missionId', 'RealtimeMissionService');
            return null;
          }

          AppLogger.info('Received mission update: $missionId', 'RealtimeMissionService');
          
          return MissionModel.fromFirestore(doc);
        })
        .handleError((error) {
          AppLogger.error('Error watching mission $missionId', 'RealtimeMissionService', error);
        });
  }

  // Watch mission participation status
  Stream<Map<String, dynamic>?> watchMissionParticipation(String userId, String missionId) {
    return _firestore
        .collection(_userMissionsCollection)
        .where('userId', isEqualTo: userId)
        .where('missionId', isEqualTo: missionId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;
          final data = {
            'id': doc.id,
            ...doc.data(),
          };

          AppLogger.info('Received participation update for mission $missionId', 'RealtimeMissionService');
          return data;
        })
        .handleError((error) {
          AppLogger.error('Error watching mission participation', 'RealtimeMissionService', error);
        });
  }

  // Watch mission statistics in real-time
  Stream<Map<String, int>> watchMissionStats() {
    return _firestore
        .collection(_missionsCollection)
        .snapshots()
        .map((snapshot) {
          final stats = <String, int>{};
          
          for (final doc in snapshot.docs) {
            final status = doc.data()['status'] as String?;
            if (status != null) {
              stats[status] = (stats[status] ?? 0) + 1;
            }
          }

          AppLogger.info('Received mission stats update', 'RealtimeMissionService');
          return stats;
        })
        .handleError((error) {
          AppLogger.error('Error watching mission stats', 'RealtimeMissionService', error);
        });
  }

  // Watch mission progress for user
  Stream<Map<String, dynamic>> watchMissionProgress(String userId, String missionId) {
    return _firestore
        .collection(_userMissionsCollection)
        .where('userId', isEqualTo: userId)
        .where('missionId', isEqualTo: missionId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return {
              'isParticipating': false,
              'progress': 0,
              'completedTasks': 0,
              'totalTasks': 0,
              'status': 'not_started',
            };
          }

          final doc = snapshot.docs.first;
          final data = doc.data();
          
          AppLogger.info('Received progress update for mission $missionId', 'RealtimeMissionService');
          
          return {
            'isParticipating': true,
            'progress': data['progress'] ?? 0,
            'completedTasks': data['completedTasks'] ?? 0,
            'totalTasks': data['totalTasks'] ?? 0,
            'status': data['status'] ?? 'in_progress',
            'startedAt': data['startedAt'],
            'completedAt': data['completedAt'],
          };
        })
        .handleError((error) {
          AppLogger.error('Error watching mission progress', 'RealtimeMissionService', error);
        });
  }

  // Start listening to mission updates with custom listener ID
  StreamSubscription<T> startListener<T>(String listenerId, Stream<T> stream, void Function(T) onData) {
    // Cancel existing listener if any
    stopListener(listenerId);

    final subscription = stream.listen(
      onData,
      onError: (error) {
        AppLogger.error('Listener error for $listenerId', 'RealtimeMissionService', error);
      },
    );

    _activeListeners[listenerId] = subscription;
    AppLogger.info('Started listener: $listenerId', 'RealtimeMissionService');
    
    return subscription;
  }

  // Stop specific listener
  void stopListener(String listenerId) {
    final subscription = _activeListeners.remove(listenerId);
    if (subscription != null) {
      subscription.cancel();
      AppLogger.info('Stopped listener: $listenerId', 'RealtimeMissionService');
    }
  }

  // Reconnect all listeners after connection restored
  void _reconnectListeners() {
    AppLogger.info('Reconnecting listeners after connection restored', 'RealtimeMissionService');
    // Listeners will automatically reconnect when streams are re-subscribed
  }

  // Pause listeners during connection loss
  void _pauseListeners() {
    AppLogger.info('Connection lost, listeners will pause', 'RealtimeMissionService');
    // Firebase handles offline scenarios automatically
  }

  // Update mission status (for testing purposes)
  Future<void> updateMissionStatus(String missionId, MissionStatus status) async {
    try {
      await _firestore.collection(_missionsCollection).doc(missionId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Mission status updated: $missionId -> ${status.name}', 'RealtimeMissionService');
    } catch (e) {
      AppLogger.error('Failed to update mission status', 'RealtimeMissionService', e);
      rethrow;
    }
  }

  // Update user mission progress
  Future<void> updateUserMissionProgress(String userId, String missionId, Map<String, dynamic> progressData) async {
    try {
      final docRef = _firestore
          .collection(_userMissionsCollection)
          .where('userId', isEqualTo: userId)
          .where('missionId', isEqualTo: missionId)
          .limit(1);

      final existing = await docRef.get();
      
      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          ...progressData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection(_userMissionsCollection).add({
          'userId': userId,
          'missionId': missionId,
          ...progressData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      AppLogger.info('User mission progress updated: $userId/$missionId', 'RealtimeMissionService');
    } catch (e) {
      AppLogger.error('Failed to update user mission progress', 'RealtimeMissionService', e);
      rethrow;
    }
  }

  // Get connection status
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  // Dispose all listeners and resources
  void dispose() {
    for (final subscription in _activeListeners.values) {
      subscription.cancel();
    }
    _activeListeners.clear();
    _connectionController.close();
    
    AppLogger.info('Realtime Mission Service disposed', 'RealtimeMissionService');
  }
}