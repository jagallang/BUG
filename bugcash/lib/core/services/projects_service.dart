import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Projects collection 전용 서비스 클래스
/// v2.112.0: finalCompletionPoints 조회를 위한 서비스
class ProjectsService {
  static final _firestore = FirebaseFirestore.instance;

  /// v2.112.0: 특정 프로젝트의 finalCompletionPoints 값 조회
  /// dailyMissionPoints는 Deprecated
  static Future<int> getFinalCompletionPoints(String appId) async {
    try {
      // appId 정규화 (provider_app_ 접두사 제거)
      final normalizedAppId = appId.replaceAll('provider_app_', '');

      debugPrint('🔍 PROJECTS_SERVICE: getFinalCompletionPoints - appId=$normalizedAppId');

      final doc = await _firestore
          .collection('projects')
          .doc(normalizedAppId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final finalPoints = (data['finalCompletionPoints'] as num?)?.toInt() ?? 10000;

        debugPrint('✅ PROJECTS_SERVICE: Found finalCompletionPoints=$finalPoints for appId=$normalizedAppId');
        return finalPoints;
      } else {
        debugPrint('❌ PROJECTS_SERVICE: Project not found for appId=$normalizedAppId');
        return 10000; // 기본값
      }
    } catch (e) {
      debugPrint('🚨 PROJECTS_SERVICE: Error getting finalCompletionPoints - $e');
      return 10000; // 오류 시 기본값
    }
  }

  /// v2.112.0: Deprecated - dailyMissionPoints 사용 안 함
  /// 하위 호환성을 위해 유지하되 0 반환
  @Deprecated('Use getFinalCompletionPoints instead')
  static Future<int> getDailyMissionPoints(String appId) async {
    debugPrint('⚠️ DEPRECATED: getDailyMissionPoints called, returning 0');
    return 0;
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