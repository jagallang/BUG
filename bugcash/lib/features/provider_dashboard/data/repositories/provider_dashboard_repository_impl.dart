// Provider Dashboard Repository Mock Implementation
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../domain/models/provider_model.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/data/datasources/mock_data_source.dart';

class ProviderDashboardRepositoryImpl implements ProviderDashboardRepository {
  final MockDataSource _mockDataSource;
  
  ProviderDashboardRepositoryImpl() : _mockDataSource = MockDataSourceImpl.instance;

  @override
  Future<ProviderModel?> getProviderInfo(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final data = _mockDataSource.getProviderProfile(providerId);
      if (data.isEmpty) return null;
      
      return ProviderModel.fromMap(providerId, data);
    } catch (e) {
      AppLogger.error('Failed to get provider info', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProviderInfo(String providerId, Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      _mockDataSource.updateProviderProfile(providerId, data);
      AppLogger.info('Provider info updated: $providerId', 'ProviderDashboardRepository');
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
  Future<List<AppModel>> getProviderApps(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final appDataList = _mockDataSource.getProviderApps(providerId);
      return appDataList.map((data) => AppModel.fromMap(data['id'], data)).toList();
    } catch (e) {
      AppLogger.error('Failed to get provider apps', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<AppModel?> getApp(String appId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final data = _mockDataSource.getApp(appId);
      if (data.isEmpty) return null;
      
      return AppModel.fromMap(appId, data);
    } catch (e) {
      AppLogger.error('Failed to get app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> createApp(AppModel app) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final appId = _mockDataSource.createApp(app.toMap());
      AppLogger.info('App created: $appId', 'ProviderDashboardRepository');
      return appId;
    } catch (e) {
      AppLogger.error('Failed to create app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateApp(String appId, Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      _mockDataSource.updateApp(appId, data);
      AppLogger.info('App updated: $appId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateAppStatus(String appId, AppStatus status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      _mockDataSource.updateApp(appId, {'status': status.name});
      AppLogger.info('App status updated: $appId to ${status.name}', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update app status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteApp(String appId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      _mockDataSource.deleteApp(appId);
      AppLogger.info('App deleted: $appId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to delete app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<MissionModel>> getProviderMissions(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final missionDataList = _mockDataSource.getProviderMissions(providerId);
      return missionDataList.map((data) => MissionModel.fromMap(data['id'], data)).toList();
    } catch (e) {
      AppLogger.error('Failed to get provider missions', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<MissionModel>> getAppMissions(String appId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final allMissions = _mockDataSource.getProviderMissions('provider1');
      final appMissions = allMissions.where((mission) => mission['appId'] == appId).toList();
      return appMissions.map((data) => MissionModel.fromMap(data['id'], data)).toList();
    } catch (e) {
      AppLogger.error('Failed to get app missions', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> createMission(MissionModel mission) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final missionId = 'mission_${DateTime.now().millisecondsSinceEpoch}';
      AppLogger.info('Mission created: $missionId', 'ProviderDashboardRepository');
      return missionId;
    } catch (e) {
      AppLogger.error('Failed to create mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateMission(String missionId, Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      AppLogger.info('Mission updated: $missionId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteMission(String missionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.info('Mission deleted: $missionId', 'ProviderDashboardRepository');
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
  Future<DashboardStats> getDashboardStats(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final data = _mockDataSource.getProviderDashboardStats(providerId);
      return DashboardStats.fromMap(data);
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


  @override
  Future<Map<String, dynamic>> getTesterProfile(String testerId) async {
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

  // Bug Report Management
  @override
  Future<List<Map<String, dynamic>>> getAppBugReports(String appId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockDataSource.getAppBugReports(appId);
    } catch (e) {
      AppLogger.error('Failed to get app bug reports', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateBugReportStatus(String reportId, String status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      AppLogger.info('Bug report status updated: $reportId to $status', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update bug report status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> addBugReportResponse(String reportId, String response) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      AppLogger.info('Bug report response added: $reportId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to add bug report response', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  // Analytics
  @override
  Future<Map<String, dynamic>> getAppAnalytics(String appId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      return _mockDataSource.getAppAnalytics(appId);
    } catch (e) {
      AppLogger.error('Failed to get app analytics', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMissionAnalytics(String missionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'views': 156,
        'applications': 23,
        'completions': 18,
        'bugReports': 5,
        'avgRating': 4.3,
        'avgCompletionTime': 2.5, // hours
      };
    } catch (e) {
      AppLogger.error('Failed to get mission analytics', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  // Real-time Streams
  @override
  Stream<ProviderModel> watchProviderInfo(String providerId) {
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getProviderInfo(providerId);
    }).asyncMap((future) => future).where((provider) => provider != null).cast<ProviderModel>();
  }

  @override
  Stream<List<AppModel>> watchProviderApps(String providerId) {
    return Stream.periodic(const Duration(seconds: 20), (_) async {
      return await getProviderApps(providerId);
    }).asyncMap((future) => future);
  }

  @override
  Stream<List<MissionModel>> watchProviderMissions(String providerId) {
    return Stream.periodic(const Duration(seconds: 15), (_) async {
      return await getProviderMissions(providerId);
    }).asyncMap((future) => future);
  }

  @override
  Stream<DashboardStats> watchDashboardStats(String providerId) {
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getDashboardStats(providerId);
    }).asyncMap((future) => future);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRecentActivities(String providerId) {
    return Stream.periodic(const Duration(seconds: 10), (_) async {
      return await getRecentActivities(providerId);
    }).asyncMap((future) => future);
  }

  // Tester Management
  @override
  Future<List<Map<String, dynamic>>> getProviderTesters(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        {
          'id': 'tester1',
          'name': '김테스터',
          'email': 'tester1@bugcash.com',
          'rating': 4.8,
          'completedMissions': 45,
          'specialties': ['UI/UX', '모바일 앱'],
        },
        {
          'id': 'tester2',
          'name': '이테스터',
          'email': 'tester2@bugcash.com',
          'rating': 4.6,
          'completedMissions': 32,
          'specialties': ['버그 발견', '성능 테스트'],
        },
      ];
    } catch (e) {
      AppLogger.error('Failed to get provider testers', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTesterHistory(String testerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      return [
        {
          'missionId': 'mission1',
          'missionTitle': 'ShopApp 결제 테스트',
          'completedAt': DateTime.now().subtract(const Duration(days: 3)),
          'rating': 5,
          'reward': 250,
        },
        {
          'missionId': 'mission2',
          'missionTitle': 'FoodDelivery UI 테스트',
          'completedAt': DateTime.now().subtract(const Duration(days: 7)),
          'rating': 4,
          'reward': 180,
        },
      ];
    } catch (e) {
      AppLogger.error('Failed to get tester history', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  // Financial Management
  @override
  Future<Map<String, dynamic>> getFinancialSummary(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'totalSpent': 5420000,
        'thisMonthSpent': 1200000,
        'pendingPayments': 350000,
        'avgCostPerMission': 280000,
        'totalMissions': 15,
        'costBreakdown': {
          'missionRewards': 4200000,
          'platformFees': 420000,
          'bonusPayments': 800000,
        }
      };
    } catch (e) {
      AppLogger.error('Failed to get financial summary', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentHistory(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        {
          'id': 'payment1',
          'amount': 250000,
          'type': 'mission_reward',
          'missionId': 'mission1',
          'status': 'completed',
          'paidAt': DateTime.now().subtract(const Duration(days: 2)),
        },
        {
          'id': 'payment2',
          'amount': 180000,
          'type': 'mission_reward',
          'missionId': 'mission2',
          'status': 'pending',
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
        },
      ];
    } catch (e) {
      AppLogger.error('Failed to get payment history', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> processPayment(String providerId, Map<String, dynamic> paymentData) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      AppLogger.info('Payment processed for provider: $providerId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to process payment', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }
}