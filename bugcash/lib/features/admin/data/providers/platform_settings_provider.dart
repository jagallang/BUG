import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 플랫폼 설정 캐시 데이터
class PlatformSettingsCache {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  PlatformSettingsCache({
    required this.data,
    required this.cachedAt,
  });

  bool get isExpired {
    // 5분 TTL
    return DateTime.now().difference(cachedAt).inMinutes >= 5;
  }
}

/// 플랫폼 설정 Provider
/// Cloud Function getPlatformSettings를 호출하여 설정값을 가져오고 캐싱함
class PlatformSettingsNotifier extends StateNotifier<Map<String, PlatformSettingsCache>> {
  final FirebaseFunctions _functions;

  PlatformSettingsNotifier({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
        super({});

  /// 출금 설정 가져오기
  Future<Map<String, dynamic>> getWithdrawalSettings() async {
    return await _getSettings('withdrawal');
  }

  /// 보상 설정 가져오기
  Future<Map<String, dynamic>> getRewardsSettings() async {
    return await _getSettings('rewards');
  }

  /// 플랫폼 수수료 설정 가져오기
  Future<Map<String, dynamic>> getPlatformSettings() async {
    return await _getSettings('platform');
  }

  /// 어뷰징 방지 설정 가져오기
  Future<Map<String, dynamic>> getAbusePreventionSettings() async {
    return await _getSettings('abuse_prevention');
  }

  /// 설정 가져오기 (캐싱 로직 포함)
  Future<Map<String, dynamic>> _getSettings(String settingType) async {
    // 캐시 확인
    final cached = state[settingType];
    if (cached != null && !cached.isExpired) {
      debugPrint('✅ PlatformSettings - 캐시된 $settingType 설정 사용');
      return cached.data;
    }

    try {
      debugPrint('🔄 PlatformSettings - $settingType 설정 로드 중...');

      final callable = _functions.httpsCallable('getPlatformSettings');
      final result = await callable.call({'settingType': settingType});

      final data = Map<String, dynamic>.from(result.data);

      // 캐시 저장
      state = {
        ...state,
        settingType: PlatformSettingsCache(
          data: data,
          cachedAt: DateTime.now(),
        ),
      };

      debugPrint('✅ PlatformSettings - $settingType 설정 로드 완료');
      return data;
    } catch (e) {
      debugPrint('❌ PlatformSettings - $settingType 설정 로드 실패: $e');

      // 기본값 반환
      return _getDefaultSettings(settingType);
    }
  }

  /// 캐시 초기화 (설정 변경 후 강제 새로고침 필요 시)
  void clearCache([String? settingType]) {
    if (settingType != null) {
      state = {...state}..remove(settingType);
      debugPrint('🗑️ PlatformSettings - $settingType 캐시 삭제');
    } else {
      state = {};
      debugPrint('🗑️ PlatformSettings - 전체 캐시 삭제');
    }
  }

  /// 기본 설정값 (Cloud Function 실패 시 폴백)
  Map<String, dynamic> _getDefaultSettings(String settingType) {
    switch (settingType) {
      case 'withdrawal':
        return {
          'minAmount': 30000,
          'allowedUnits': 10000,
          'feeRate': 0.18,
          'autoApprove': false,
          'processingDays': 5,
        };
      case 'rewards':
        return {
          'signupBonus': {'enabled': true, 'amount': 5000},
          'projectCompletionBonus': {
            'enabled': true,
            'testerAmount': 1000,
            'providerAmount': 1000,
          },
          'dailyMissionReward': {'enabled': true, 'baseAmount': 50},
        };
      case 'platform':
        return {
          'appRegistration': {'cost': 5000},
          'missionCreation': {'cost': 1000},
          'commissionRate': {'tester': 0.03, 'provider': 0.03},
        };
      case 'abuse_prevention':
        return {
          'multiAccountDetection': {'enabled': true},
          'withdrawalRestrictions': {'maxDailyWithdrawals': 3},
          'pointAbuseDetection': {'enabled': true},
        };
      default:
        return {};
    }
  }
}

/// Provider 정의
final platformSettingsProvider =
    StateNotifierProvider<PlatformSettingsNotifier, Map<String, PlatformSettingsCache>>((ref) {
  return PlatformSettingsNotifier();
});

/// 편의 Provider - 출금 설정
final withdrawalSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final notifier = ref.watch(platformSettingsProvider.notifier);
  return await notifier.getWithdrawalSettings();
});

/// 편의 Provider - 보상 설정
final rewardsSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final notifier = ref.watch(platformSettingsProvider.notifier);
  return await notifier.getRewardsSettings();
});
