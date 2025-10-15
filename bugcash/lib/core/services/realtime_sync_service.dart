import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

// v2.112.0: DEPRECATED - This service is no longer needed after reward system simplification
// dailyMissionPoints has been removed from the reward system
// This class is kept for backward compatibility but all sync methods are disabled

/// 실시간 동기화 서비스 (v2.112.0: DEPRECATED)
/// ⚠️ WARNING: This service is deprecated and will be removed in a future version
/// dailyMissionPoints synchronization is no longer needed
class RealtimeSyncService {
  static final _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _projectsSubscription;
  static final Map<String, int> _lastKnownDailyMissionPoints = {};

  /// v2.112.0: DEPRECATED - No longer performs any synchronization
  static void startRealtimeSync() {
    debugPrint('⚠️ REALTIME_SYNC (v2.112.0): DEPRECATED - Sync service disabled');
    debugPrint('   dailyMissionPoints synchronization is no longer needed');
    // v2.112.0: Sync logic removed, method kept for backward compatibility
  }

  /// v2.112.0: DEPRECATED - No subscriptions to cancel
  static void stopRealtimeSync() {
    debugPrint('⚠️ REALTIME_SYNC (v2.112.0): DEPRECATED - Stop called (no-op)');
    _projectsSubscription?.cancel();
    _projectsSubscription = null;
    _lastKnownDailyMissionPoints.clear();
  }

  /// v2.112.0: DEPRECATED - Method kept for backward compatibility only
  static void _handleProjectsChange(QuerySnapshot snapshot) async {
    debugPrint('⚠️ REALTIME_SYNC (v2.112.0): DEPRECATED - _handleProjectsChange called but disabled');
    // v2.112.0: All sync logic removed
  }

  /// v2.112.0: DEPRECATED - No synchronization performed
  static Future<void> _syncMissionWorkflows(String appId, int newDailyReward) async {
    debugPrint('⚠️ REALTIME_SYNC (v2.112.0): DEPRECATED - _syncMissionWorkflows called but disabled');
    // v2.112.0: Sync logic removed
  }

  /// v2.112.0: DEPRECATED - dailyMissionPoints no longer used
  static int _extractDailyMissionPoints(Map<String, dynamic> data) {
    debugPrint('⚠️ REALTIME_SYNC (v2.112.0): DEPRECATED - _extractDailyMissionPoints called');
    return 0; // v2.112.0: Always return 0
  }

  /// 오류 처리
  static void _handleError(dynamic error) {
    debugPrint('🚨 REALTIME_SYNC: 실시간 동기화 오류 - $error');
  }

  /// v2.112.0: DEPRECATED - No synchronization performed
  static Future<void> forceSyncAppId(String appId) async {
    debugPrint('⚠️ REALTIME_SYNC (v2.112.0): DEPRECATED - forceSyncAppId called for $appId (no-op)');
    // v2.112.0: Sync logic removed
  }

  /// v2.112.0: DEPRECATED - No synchronization performed
  static Future<void> forceSyncAll() async {
    debugPrint('⚠️ REALTIME_SYNC (v2.112.0): DEPRECATED - forceSyncAll called (no-op)');
    // v2.112.0: Sync logic removed
  }

  /// 현재 동기화 상태 확인
  static bool get isActive => _projectsSubscription != null;

  /// 캐시된 dailyMissionPoints 값들 조회 (디버깅용)
  static Map<String, int> get cachedValues => Map.from(_lastKnownDailyMissionPoints);
}