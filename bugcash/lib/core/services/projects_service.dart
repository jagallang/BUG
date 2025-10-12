import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Projects collection 전용 서비스 클래스
/// dailyMissionPoints 실시간 동기화를 위한 최적화된 서비스
class ProjectsService {
  static final _firestore = FirebaseFirestore.instance;

  /// 특정 프로젝트의 dailyMissionPoints 값 조회
  static Future<int> getDailyMissionPoints(String appId) async {
    try {
      // appId 정규화 (provider_app_ 접두사 제거)
      final normalizedAppId = appId.replaceAll('provider_app_', '');

      debugPrint('🔍 PROJECTS_SERVICE: getDailyMissionPoints - appId=$normalizedAppId');

      final doc = await _firestore
          .collection('projects')
          .doc(normalizedAppId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final dailyMissionPoints = _extractDailyMissionPoints(data);

        debugPrint('✅ PROJECTS_SERVICE: Found dailyMissionPoints=$dailyMissionPoints for appId=$normalizedAppId');
        return dailyMissionPoints;
      } else {
        debugPrint('❌ PROJECTS_SERVICE: Project not found for appId=$normalizedAppId');
        return 5000; // 기본값
      }
    } catch (e) {
      debugPrint('🚨 PROJECTS_SERVICE: Error getting dailyMissionPoints - $e');
      return 5000; // 오류 시 기본값
    }
  }

  /// 특정 프로젝트의 dailyMissionPoints 실시간 스트림
  static Stream<int> watchDailyMissionPoints(String appId) {
    // appId 정규화 (provider_app_ 접두사 제거)
    final normalizedAppId = appId.replaceAll('provider_app_', '');

    debugPrint('📡 PROJECTS_SERVICE: watchDailyMissionPoints - appId=$normalizedAppId');

    return _firestore
        .collection('projects')
        .doc(normalizedAppId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            final dailyMissionPoints = _extractDailyMissionPoints(data);

            debugPrint('🔄 PROJECTS_SERVICE: Stream update - dailyMissionPoints=$dailyMissionPoints for appId=$normalizedAppId');
            return dailyMissionPoints;
          } else {
            debugPrint('❌ PROJECTS_SERVICE: Stream - Project not found for appId=$normalizedAppId');
            return 5000; // 기본값
          }
        });
  }

  /// 프로젝트 데이터에서 dailyMissionPoints 추출
  /// 여러 경로에서 값을 찾아서 반환 (하위 호환성)
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

  /// 프로젝트 존재 여부 확인
  static Future<bool> projectExists(String appId) async {
    try {
      final normalizedAppId = appId.replaceAll('provider_app_', '');
      final doc = await _firestore
          .collection('projects')
          .doc(normalizedAppId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('🚨 PROJECTS_SERVICE: Error checking project existence - $e');
      return false;
    }
  }

  /// 프로젝트 기본 정보 조회 (providerId, providerName 포함)
  static Future<Map<String, dynamic>?> getProjectInfo(String appId) async {
    try {
      final normalizedAppId = appId.replaceAll('provider_app_', '');
      final doc = await _firestore
          .collection('projects')
          .doc(normalizedAppId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('🚨 PROJECTS_SERVICE: Error getting project info - $e');
      return null;
    }
  }
}