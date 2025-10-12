import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// 실시간 동기화 서비스
/// projects.dailyMissionPoints ↔ mission_workflows.dailyReward 실시간 동기화
class RealtimeSyncService {
  static final _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _projectsSubscription;
  static final Map<String, int> _lastKnownDailyMissionPoints = {};

  /// 실시간 동기화 시작
  static void startRealtimeSync() {
    debugPrint('🔄 REALTIME_SYNC: 실시간 동기화 시작');

    // projects 컬렉션의 dailyMissionPoints 변경 감지
    _projectsSubscription = _firestore
        .collection('projects')
        .snapshots()
        .listen(_handleProjectsChange, onError: _handleError);
  }

  /// 실시간 동기화 중지
  static void stopRealtimeSync() {
    debugPrint('⏹️ REALTIME_SYNC: 실시간 동기화 중지');
    _projectsSubscription?.cancel();
    _projectsSubscription = null;
    _lastKnownDailyMissionPoints.clear();
  }

  /// projects 컬렉션 변경 감지 및 처리
  static void _handleProjectsChange(QuerySnapshot snapshot) async {
    debugPrint('📊 REALTIME_SYNC: Projects 컬렉션 변경 감지 - ${snapshot.docs.length}개 프로젝트');

    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.modified ||
          change.type == DocumentChangeType.added) {

        final doc = change.doc;
        final data = doc.data() as Map<String, dynamic>;
        final appId = doc.id;

        // dailyMissionPoints 값 추출
        final currentDailyMissionPoints = _extractDailyMissionPoints(data);
        final previousDailyMissionPoints = _lastKnownDailyMissionPoints[appId];

        // 값이 변경된 경우에만 동기화 실행
        if (previousDailyMissionPoints != currentDailyMissionPoints) {
          debugPrint('💰 REALTIME_SYNC: dailyMissionPoints 변경 감지 - appId=$appId, $previousDailyMissionPoints → $currentDailyMissionPoints');

          // 캐시 업데이트
          _lastKnownDailyMissionPoints[appId] = currentDailyMissionPoints;

          // mission_workflows 컬렉션 동기화
          await _syncMissionWorkflows(appId, currentDailyMissionPoints);
        }
      }
    }
  }

  /// mission_workflows 컬렉션 동기화
  static Future<void> _syncMissionWorkflows(String appId, int newDailyReward) async {
    try {
      debugPrint('🔄 REALTIME_SYNC: mission_workflows 동기화 시작 - appId=$appId, newDailyReward=$newDailyReward');

      // 해당 appId의 모든 mission_workflows 조회
      final workflowsSnapshot = await _firestore
          .collection('mission_workflows')
          .where('appId', isEqualTo: appId)
          .get();

      if (workflowsSnapshot.docs.isEmpty) {
        debugPrint('ℹ️ REALTIME_SYNC: appId=$appId에 대한 mission_workflows 없음');
        return;
      }

      // 배치 업데이트 준비
      final batch = _firestore.batch();
      int updateCount = 0;

      for (final doc in workflowsSnapshot.docs) {
        final data = doc.data();
        final currentDailyReward = data['dailyReward'] ?? 5000;

        // 실제로 변경이 필요한 경우에만 업데이트
        if (currentDailyReward != newDailyReward) {
          batch.update(doc.reference, {
            'dailyReward': newDailyReward,
            'syncedAt': FieldValue.serverTimestamp(),
            'syncedFrom': 'projects.dailyMissionPoints',
          });
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        debugPrint('✅ REALTIME_SYNC: $updateCount개 mission_workflows 동기화 완료 - appId=$appId');
      } else {
        debugPrint('ℹ️ REALTIME_SYNC: 동기화 불필요 - appId=$appId (이미 최신 상태)');
      }

    } catch (e) {
      debugPrint('🚨 REALTIME_SYNC: mission_workflows 동기화 실패 - appId=$appId, error=$e');
    }
  }

  /// projects 데이터에서 dailyMissionPoints 추출
  static int _extractDailyMissionPoints(Map<String, dynamic> data) {
    // 1순위: 직접 필드
    if (data['dailyMissionPoints'] != null) {
      return (data['dailyMissionPoints'] as num).toInt();
    }

    // 2순위: metadata 내부
    final metadata = data['metadata'] as Map<String, dynamic>?;
    if (metadata != null && metadata['dailyMissionPoints'] != null) {
      return (metadata['dailyMissionPoints'] as num).toInt();
    }

    // 3순위: rewards 내부
    final rewards = data['rewards'] as Map<String, dynamic>?;
    if (rewards != null && rewards['dailyMissionPoints'] != null) {
      return (rewards['dailyMissionPoints'] as num).toInt();
    }

    // 기본값
    return 5000;
  }

  /// 오류 처리
  static void _handleError(dynamic error) {
    debugPrint('🚨 REALTIME_SYNC: 실시간 동기화 오류 - $error');
  }

  /// 특정 appId 강제 동기화 (즉시 실행)
  static Future<void> forceSyncAppId(String appId) async {
    try {
      debugPrint('🔄 REALTIME_SYNC: 강제 동기화 시작 - appId=$appId');

      // projects 컬렉션에서 현재 dailyMissionPoints 조회
      final projectDoc = await _firestore
          .collection('projects')
          .doc(appId)
          .get();

      if (!projectDoc.exists) {
        debugPrint('❌ REALTIME_SYNC: 프로젝트 없음 - appId=$appId');
        return;
      }

      final data = projectDoc.data()!;
      final dailyMissionPoints = _extractDailyMissionPoints(data);

      // mission_workflows 동기화
      await _syncMissionWorkflows(appId, dailyMissionPoints);

      debugPrint('✅ REALTIME_SYNC: 강제 동기화 완료 - appId=$appId');

    } catch (e) {
      debugPrint('🚨 REALTIME_SYNC: 강제 동기화 실패 - appId=$appId, error=$e');
    }
  }

  /// 전체 프로젝트 강제 동기화 (초기화 시 사용)
  static Future<void> forceSyncAll() async {
    try {
      debugPrint('🔄 REALTIME_SYNC: 전체 강제 동기화 시작');

      final projectsSnapshot = await _firestore
          .collection('projects')
          .get();

      for (final doc in projectsSnapshot.docs) {
        final appId = doc.id;
        final data = doc.data();
        final dailyMissionPoints = _extractDailyMissionPoints(data);

        await _syncMissionWorkflows(appId, dailyMissionPoints);
      }

      debugPrint('✅ REALTIME_SYNC: 전체 강제 동기화 완료 - ${projectsSnapshot.docs.length}개 프로젝트');

    } catch (e) {
      debugPrint('🚨 REALTIME_SYNC: 전체 강제 동기화 실패 - error=$e');
    }
  }

  /// 현재 동기화 상태 확인
  static bool get isActive => _projectsSubscription != null;

  /// 캐시된 dailyMissionPoints 값들 조회 (디버깅용)
  static Map<String, int> get cachedValues => Map.from(_lastKnownDailyMissionPoints);
}