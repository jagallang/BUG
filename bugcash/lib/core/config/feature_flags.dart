import 'package:flutter/foundation.dart';

/// Feature Flag 시스템
/// 새로운 기능을 안전하게 활성화/비활성화하기 위한 설정
class FeatureFlags {
  /// 새로운 미션관리 시스템 활성화 여부
  static const bool enableNewMissionManagement = true;

  /// 기존 미션관리 시스템 백업 유지 여부
  static const bool enableLegacyMissionManagement = true;

  /// 개발 모드에서만 활성화되는 기능들
  static const bool enableDebugMode = true;

  /// A/B 테스트를 위한 사용자 비율 (0.0 ~ 1.0)
  static const double newMissionManagementRolloutPercentage = 1.0;

  /// 관리자만 새로운 기능에 접근 가능한지 여부
  static const bool restrictToAdminOnly = false;

  /// 환경별 설정
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;

  /// 새로운 미션관리 기능 사용 가능 여부 체크
  static bool canUseNewMissionManagement({
    required String userId,
    bool isAdmin = false,
  }) {
    // Feature Flag가 비활성화된 경우
    if (!enableNewMissionManagement) return false;

    // 관리자만 사용 가능한 경우
    if (restrictToAdminOnly && !isAdmin) return false;

    // A/B 테스트 비율 체크 (사용자 ID 기반 해싱)
    if (newMissionManagementRolloutPercentage < 1.0) {
      final userHash = userId.hashCode.abs() % 100;
      final threshold = (newMissionManagementRolloutPercentage * 100).round();
      if (userHash >= threshold) return false;
    }

    return true;
  }

  /// 기존 미션관리 기능 사용 가능 여부 체크
  static bool canUseLegacyMissionManagement() {
    return enableLegacyMissionManagement;
  }

  /// 디버그 로깅 활성화 여부
  static bool get enableDebugLogging => isDevelopment && enableDebugMode;

  /// 개발용 테스트 기능 활성화 여부
  static bool get enableTestFeatures => isDevelopment && enableDebugMode;
}

/// Feature Flag 상태를 관리하는 싱글톤 클래스
class FeatureFlagManager {
  static final FeatureFlagManager _instance = FeatureFlagManager._internal();
  factory FeatureFlagManager() => _instance;
  FeatureFlagManager._internal();

  // 런타임에 변경 가능한 Feature Flag들
  final Map<String, bool> _runtimeFlags = {
    'new_mission_management': FeatureFlags.enableNewMissionManagement,
    'legacy_mission_management': FeatureFlags.enableLegacyMissionManagement,
    'debug_mode': FeatureFlags.enableDebugMode,
  };

  /// Flag 값 가져오기
  bool getFlag(String flagName) {
    return _runtimeFlags[flagName] ?? false;
  }

  /// Flag 값 설정 (개발/테스트 용도)
  void setFlag(String flagName, bool value) {
    if (FeatureFlags.isDevelopment) {
      _runtimeFlags[flagName] = value;
    }
  }

  /// 모든 Flag 상태 리셋
  void resetToDefaults() {
    if (FeatureFlags.isDevelopment) {
      _runtimeFlags['new_mission_management'] = FeatureFlags.enableNewMissionManagement;
      _runtimeFlags['legacy_mission_management'] = FeatureFlags.enableLegacyMissionManagement;
      _runtimeFlags['debug_mode'] = FeatureFlags.enableDebugMode;
    }
  }

  /// 현재 설정된 모든 Flag 상태 출력 (디버그용)
  Map<String, bool> getAllFlags() {
    return Map.from(_runtimeFlags);
  }
}

/// Feature Flag 상태를 확인하는 유틸리티 함수들
class FeatureFlagUtils {
  /// 새로운 미션관리 기능 활성화 여부 (안전한 체크)
  static bool shouldUseNewMissionManagement({
    required String userId,
    bool isAdmin = false,
  }) {
    try {
      return FeatureFlags.canUseNewMissionManagement(
        userId: userId,
        isAdmin: isAdmin,
      );
    } catch (e) {
      // 에러 발생 시 안전하게 기존 시스템 사용
      return false;
    }
  }

  /// 기존 미션관리 기능 활성화 여부 (백업용)
  static bool shouldUseLegacyMissionManagement() {
    try {
      return FeatureFlags.canUseLegacyMissionManagement();
    } catch (e) {
      // 에러 발생 시 기본적으로 기존 시스템 사용
      return true;
    }
  }

  /// 로깅 메시지 출력 (Feature Flag 기반)
  static void logFeatureUsage(String feature, String userId) {
    if (FeatureFlags.enableDebugLogging) {
      debugPrint('[FeatureFlag] $feature used by user: $userId at ${DateTime.now()}');
    }
  }
}