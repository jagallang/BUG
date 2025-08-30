// Provider Dashboard Repository Mock Implementation
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../domain/models/provider_model.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';

class ProviderDashboardRepositoryImpl implements ProviderDashboardRepository {
  
  ProviderDashboardRepositoryImpl();

  static const String _providersCollection = 'providers';
  static const String _appsCollection = 'provider_apps';
  static const String _missionsCollection = 'missions';
  static const String _bugReportsCollection = 'bug_reports';
  static const String _activitiesCollection = 'provider_activities';
  static const String _testersCollection = 'users';

  @override
  Future<ProviderModel?> getProviderInfo(String providerId) async {
    try {
      // Mock 데이터 반환
      await Future.delayed(const Duration(milliseconds: 500));
      
      return ProviderModel(
        id: providerId,
        companyName: 'BugCash Inc.',
        contactEmail: 'provider@bugcash.com',
        contactPerson: 'John Doe',
        phoneNumber: '010-1234-5678',
        status: ProviderStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        appIds: const ['app1', 'app2', 'app3'],
        settings: const {
          'notifications': true,
          'autoApproval': false,
          'maxBudget': 10000000,
        },
        totalBudget: 10000000,
        usedBudget: 5420000,
        totalMissions: 15,
        activeMissions: 3,
        averageRating: 4.7,
        totalTesters: 128,
        website: 'https://bugcash.com',
        description: 'Leading bug testing platform provider',
      );
    } catch (e) {
      AppLogger.error('Failed to get provider info', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProviderInfo(String providerId, Map<String, dynamic> data) async {
    try {
      // Mock 업데이트 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.info('Provider info updated (Mock): $providerId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update provider info', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProviderStatus(String providerId, ProviderStatus status) async {
    try {
      // Mock 상태 업데이트
      await Future.delayed(const Duration(milliseconds: 200));
      
      AppLogger.info('Provider status updated (Mock): $providerId to ${status.name}', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update provider status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProviderApps(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Mock 앱 목록 반환
      return [
        {
          'id': 'app1',
          'name': 'ShopApp',
          'description': 'E-commerce mobile application',
          'version': '2.1.0',
          'platform': ['android', 'ios'],
          'status': 'active',
          'createdAt': DateTime.now().subtract(const Duration(days: 30)),
        },
        {
          'id': 'app2', 
          'name': 'FoodDelivery',
          'description': 'Food delivery service app',
          'version': '1.5.2',
          'platform': ['android'],
          'status': 'testing',
          'createdAt': DateTime.now().subtract(const Duration(days: 15)),
        },
        {
          'id': 'app3',
          'name': 'FitnessTracker',
          'description': 'Health and fitness tracking application',
          'version': '3.0.1',
          'platform': ['ios'],
          'status': 'paused',
          'createdAt': DateTime.now().subtract(const Duration(days: 60)),
        },
      ];
    } catch (e) {
      AppLogger.error('Failed to get provider apps', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProviderApp(String appId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final apps = await getProviderApps('mock_provider');
      return apps.firstWhere((app) => app['id'] == appId, orElse: () => {});
    } catch (e) {
      AppLogger.error('Failed to get provider app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> registerApp(Map<String, dynamic> app) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final appId = 'app_${DateTime.now().millisecondsSinceEpoch}';
      AppLogger.info('App registered (Mock): $appId', 'ProviderDashboardRepository');
      return appId;
    } catch (e) {
      AppLogger.error('Failed to register app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateApp(String appId, Map<String, dynamic> updates) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      AppLogger.info('App updated (Mock): $appId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteApp(String appId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.info('App deleted (Mock): $appId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to delete app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProviderMissions(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock 미션 목록 반환
      return [
        {
          'id': 'mission1',
          'title': 'ShopApp 결제 기능 테스트',
          'description': '새로운 결제 시스템의 안정성을 검증해주세요',
          'appId': 'app1',
          'appName': 'ShopApp',
          'type': 'featureTesting',
          'status': 'active',
          'reward': 250,
          'maxTesters': 10,
          'currentTesters': 7,
          'deadline': DateTime.now().add(const Duration(days: 5)),
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        },
        {
          'id': 'mission2',
          'title': 'FoodDelivery UI/UX 개선 테스트',
          'description': '새로운 인터페이스의 사용성을 평가해주세요',
          'appId': 'app2',
          'appName': 'FoodDelivery',
          'type': 'usabilityTest',
          'status': 'completed',
          'reward': 180,
          'maxTesters': 15,
          'currentTesters': 15,
          'deadline': DateTime.now().subtract(const Duration(days: 1)),
          'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        },
      ];
    } catch (e) {
      AppLogger.error('Failed to get provider missions', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> createMission(Map<String, dynamic> mission) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final missionId = 'mission_${DateTime.now().millisecondsSinceEpoch}';
      AppLogger.info('Mission created (Mock): $missionId', 'ProviderDashboardRepository');
      return missionId;
    } catch (e) {
      AppLogger.error('Failed to create mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateMission(String missionId, Map<String, dynamic> updates) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      AppLogger.info('Mission updated (Mock): $missionId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteMission(String missionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.info('Mission deleted (Mock): $missionId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to delete mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBugReports(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Mock 버그 리포트 목록
      return [
        {
          'id': 'bug1',
          'title': 'ShopApp 결제 버튼 클릭 안됨',
          'description': 'iOS에서 결제 버튼을 누르면 반응이 없습니다.',
          'severity': 'high',
          'status': 'open',
          'appId': 'app1',
          'appName': 'ShopApp',
          'testerId': 'tester1',
          'testerName': '김테스터',
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
          'screenshots': ['screenshot1.jpg', 'screenshot2.jpg'],
        },
        {
          'id': 'bug2',
          'title': 'FoodDelivery 주문 내역 표시 오류',
          'description': '주문 내역 페이지에서 가격이 잘못 표시됩니다.',
          'severity': 'medium',
          'status': 'in_progress',
          'appId': 'app2',
          'appName': 'FoodDelivery',
          'testerId': 'tester2',
          'testerName': '이테스터',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'screenshots': ['bug_report1.png'],
        },
      ];
    } catch (e) {
      AppLogger.error('Failed to get bug reports', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Mock 대시보드 통계
      return {
        'totalMissions': 15,
        'activeMissions': 3,
        'completedMissions': 12,
        'totalTesters': 128,
        'activeTesters': 45,
        'totalBugReports': 89,
        'openBugReports': 12,
        'resolvedBugReports': 77,
        'totalSpent': 5420000,
        'thisMonthSpent': 1200000,
        'averageRating': 4.7,
        'completionRate': 0.85,
        'responseTime': 24.5, // hours
      };
    } catch (e) {
      AppLogger.error('Failed to get dashboard stats', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivities(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      
      // Mock 최근 활동
      return [
        {
          'id': 'activity1',
          'type': 'bug_report',
          'title': '새로운 버그 리포트',
          'description': '김테스터님이 ShopApp에서 결제 오류를 발견했습니다.',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
          'priority': 'high',
        },
        {
          'id': 'activity2',
          'type': 'mission_completed',
          'title': '미션 완료',
          'description': 'FoodDelivery UI/UX 테스트 미션이 완료되었습니다.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'priority': 'medium',
        },
        {
          'id': 'activity3',
          'type': 'tester_joined',
          'title': '새로운 테스터 참여',
          'description': '박테스터님이 ShopApp 테스트에 참여했습니다.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
          'priority': 'low',
        },
      ];
    } catch (e) {
      AppLogger.error('Failed to get recent activities', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  // Stream methods - Mock implementation
  @override
  Stream<Map<String, dynamic>> streamDashboardStats(String providerId) {
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getDashboardStats(providerId);
    }).asyncMap((future) => future);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamProviderMissions(String providerId) {
    return Stream.periodic(const Duration(seconds: 15), (_) async {
      return await getProviderMissions(providerId);
    }).asyncMap((future) => future);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamBugReports(String providerId) {
    return Stream.periodic(const Duration(seconds: 20), (_) async {
      return await getBugReports(providerId);
    }).asyncMap((future) => future);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamRecentActivities(String providerId) {
    return Stream.periodic(const Duration(seconds: 10), (_) async {
      return await getRecentActivities(providerId);
    }).asyncMap((future) => future);
  }

  @override
  Future<Map<String, dynamic>?> getTesterProfile(String testerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Mock 테스터 프로필
      return {
        'id': testerId,
        'name': '김테스터',
        'email': 'tester@example.com',
        'rating': 4.8,
        'completedMissions': 45,
        'specialties': ['UI/UX', '모바일 앱', '버그 발견'],
        'joinedAt': DateTime.now().subtract(const Duration(days: 120)),
      };
    } catch (e) {
      AppLogger.error('Failed to get tester profile', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }
}