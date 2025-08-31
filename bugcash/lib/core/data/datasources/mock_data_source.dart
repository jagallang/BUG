/// Mock Data Source - 모든 Mock 데이터를 중앙 관리
/// Clean Architecture의 Data Layer에 위치
abstract class MockDataSource {
  // Provider 관련 Mock 데이터
  Map<String, dynamic> getProviderProfile(String providerId);
  List<Map<String, dynamic>> getProviderApps(String providerId);
  List<Map<String, dynamic>> getProviderMissions(String providerId);
  List<Map<String, dynamic>> getProviderBugReports(String providerId);
  Map<String, dynamic> getProviderDashboardStats(String providerId);
  List<Map<String, dynamic>> getProviderRecentActivities(String providerId);
  
  // Tester 관련 Mock 데이터
  Map<String, dynamic> getTesterProfile(String testerId);
  List<Map<String, dynamic>> getTesterMissions(String testerId);
  List<Map<String, dynamic>> getTesterEarnings(String testerId);
  Map<String, dynamic> getTesterStats(String testerId);
  
  // Mission 관련 Mock 데이터
  List<Map<String, dynamic>> getAvailableMissions();
  Map<String, dynamic> getMissionDetails(String missionId);
  List<Map<String, dynamic>> getMissionParticipants(String missionId);
  
  // App 관련 Mock 데이터
  Map<String, dynamic> getApp(String appId);
  Map<String, dynamic> getAppDetails(String appId);
  List<Map<String, dynamic>> getAppBugReports(String appId);
  Map<String, dynamic> getAppAnalytics(String appId);
  String createApp(Map<String, dynamic> appData);
  void updateApp(String appId, Map<String, dynamic> data);
  void deleteApp(String appId);
  
  // Provider 업데이트 메서드
  void updateProviderProfile(String providerId, Map<String, dynamic> data);
  
  // Bug Report 관련 Mock 데이터
  Map<String, dynamic> getBugReportDetails(String reportId);
  List<Map<String, dynamic>> getBugReportComments(String reportId);
  
  // 인증 관련 Mock 데이터
  Map<String, dynamic>? authenticateUser(String email, String password);
  List<Map<String, dynamic>> getMockAccounts();
}

/// Mock Data Source 구현체
class MockDataSourceImpl implements MockDataSource {
  static final MockDataSourceImpl _instance = MockDataSourceImpl._internal();
  factory MockDataSourceImpl() => _instance;
  MockDataSourceImpl._internal();
  
  static MockDataSourceImpl get instance => _instance;
  
  // Mock 데이터 저장소
  final Map<String, Map<String, dynamic>> _providers = _initProviders();
  final Map<String, Map<String, dynamic>> _testers = _initTesters();
  final Map<String, Map<String, dynamic>> _apps = _initApps();
  final List<Map<String, dynamic>> _missions = _initMissions();
  final List<Map<String, dynamic>> _bugReports = _initBugReports();
  
  @override
  Map<String, dynamic> getProviderProfile(String providerId) {
    return _providers[providerId] ?? {
      'id': providerId,
      'companyName': 'BugCash Inc.',
      'contactEmail': 'provider@bugcash.com',
      'contactPerson': 'John Doe',
      'phoneNumber': '010-1234-5678',
      'status': 'approved',
      'createdAt': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      'totalBudget': 10000000,
      'usedBudget': 5420000,
      'totalMissions': 15,
      'activeMissions': 3,
      'averageRating': 4.7,
      'totalTesters': 128,
    };
  }
  
  @override
  List<Map<String, dynamic>> getProviderApps(String providerId) {
    return [
      {
        'id': 'app1',
        'providerId': providerId,
        'name': 'ShopApp',
        'description': 'E-commerce mobile application',
        'version': '2.1.0',
        'platform': ['android', 'ios'],
        'status': 'active',
        'category': 'shopping',
        'totalMissions': 8,
        'activeMissions': 2,
        'completedMissions': 6,
        'totalBugReports': 45,
        'totalTesters': 89,
        'averageRating': 4.6,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'app2',
        'providerId': providerId,
        'name': 'FoodDelivery',
        'description': 'Food delivery service app',
        'version': '1.5.2',
        'platform': ['android'],
        'status': 'testing',
        'category': 'food',
        'totalMissions': 4,
        'activeMissions': 1,
        'completedMissions': 3,
        'totalBugReports': 23,
        'totalTesters': 45,
        'averageRating': 4.3,
        'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      },
      {
        'id': 'app3',
        'providerId': providerId,
        'name': 'FitnessTracker',
        'description': 'Health and fitness tracking application',
        'version': '3.0.1',
        'platform': ['ios'],
        'status': 'paused',
        'category': 'health',
        'totalMissions': 3,
        'activeMissions': 0,
        'completedMissions': 3,
        'totalBugReports': 12,
        'totalTesters': 34,
        'averageRating': 4.8,
        'createdAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
      },
    ];
  }
  
  @override
  List<Map<String, dynamic>> getProviderMissions(String providerId) {
    return _missions.where((m) => m['providerId'] == providerId).toList();
  }
  
  @override
  List<Map<String, dynamic>> getProviderBugReports(String providerId) {
    final appIds = getProviderApps(providerId).map((app) => app['id']).toList();
    return _bugReports.where((report) => appIds.contains(report['appId'])).toList();
  }
  
  @override
  Map<String, dynamic> getProviderDashboardStats(String providerId) {
    final apps = getProviderApps(providerId);
    final missions = getProviderMissions(providerId);
    final bugReports = getProviderBugReports(providerId);
    
    return {
      'totalApps': apps.length,
      'activeApps': apps.where((a) => a['status'] == 'active').length,
      'totalMissions': missions.length,
      'activeMissions': missions.where((m) => m['status'] == 'active').length,
      'completedMissions': missions.where((m) => m['status'] == 'completed').length,
      'totalBugReports': bugReports.length,
      'openBugReports': bugReports.where((b) => b['status'] == 'open').length,
      'resolvedBugReports': bugReports.where((b) => b['status'] == 'resolved').length,
      'totalTesters': 128,
      'activeTesters': 45,
      'totalSpent': 5420000,
      'thisMonthSpent': 1200000,
      'averageRating': 4.7,
      'completionRate': 0.85,
    };
  }
  
  @override
  List<Map<String, dynamic>> getProviderRecentActivities(String providerId) {
    return [
      {
        'id': 'activity1',
        'type': 'bug_report',
        'title': '새로운 버그 리포트',
        'description': '김테스터님이 ShopApp에서 결제 오류를 발견했습니다.',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        'priority': 'high',
        'appId': 'app1',
        'testerId': 'tester1',
      },
      {
        'id': 'activity2',
        'type': 'mission_completed',
        'title': '미션 완료',
        'description': 'FoodDelivery UI/UX 테스트 미션이 완료되었습니다.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'priority': 'medium',
        'appId': 'app2',
        'missionId': 'mission2',
      },
      {
        'id': 'activity3',
        'type': 'tester_joined',
        'title': '새로운 테스터 참여',
        'description': '박테스터님이 ShopApp 테스트에 참여했습니다.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'priority': 'low',
        'appId': 'app1',
        'testerId': 'tester3',
      },
    ];
  }
  
  @override
  Map<String, dynamic> getTesterProfile(String testerId) {
    return _testers[testerId] ?? {
      'id': testerId,
      'name': '김테스터',
      'email': 'tester@example.com',
      'totalPoints': 15420,
      'monthlyPoints': 3280,
      'completedMissions': 87,
      'successRate': 0.94,
      'averageRating': 4.7,
      'level': 'advanced',
      'experiencePoints': 4250,
      'skills': ['UI/UX 테스트', '모바일 앱', '웹 테스트', '버그 발견'],
      'interests': ['게임', '소셜미디어', '쇼핑', '교육'],
      'joinedDate': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
    };
  }
  
  @override
  List<Map<String, dynamic>> getTesterMissions(String testerId) {
    // 테스터별 미션 필터링
    return _missions.where((m) {
      final participants = m['participants'] as List<String>? ?? [];
      return participants.contains(testerId);
    }).toList();
  }
  
  @override
  List<Map<String, dynamic>> getTesterEarnings(String testerId) {
    return [
      {
        'id': 'earning1',
        'testerId': testerId,
        'missionId': 'mission1',
        'missionTitle': 'ShopApp 버그 발견',
        'points': 300,
        'earnedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'type': 'mission_complete',
        'isPaid': false,
      },
      {
        'id': 'earning2',
        'testerId': testerId,
        'missionId': 'referral1',
        'missionTitle': '추천 보너스',
        'points': 500,
        'earnedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'type': 'referral',
        'isPaid': true,
      },
    ];
  }
  
  @override
  Map<String, dynamic> getTesterStats(String testerId) {
    final missions = getTesterMissions(testerId);
    final earnings = getTesterEarnings(testerId);
    
    return {
      'totalMissions': missions.length,
      'activeMissions': missions.where((m) => m['status'] == 'in_progress').length,
      'completedMissions': missions.where((m) => m['status'] == 'completed').length,
      'totalEarnings': earnings.fold<int>(0, (sum, e) => sum + (e['points'] as int)),
      'thisMonthEarnings': 3280,
      'thisWeekEarnings': 890,
      'todayEarnings': 180,
      'pendingPayments': 890,
      'successRate': 0.94,
      'averageRating': 4.7,
    };
  }
  
  @override
  List<Map<String, dynamic>> getAvailableMissions() {
    return _missions.where((m) => m['status'] == 'active').toList();
  }
  
  @override
  Map<String, dynamic> getMissionDetails(String missionId) {
    return _missions.firstWhere(
      (m) => m['id'] == missionId,
      orElse: () => {},
    );
  }
  
  @override
  List<Map<String, dynamic>> getMissionParticipants(String missionId) {
    final mission = getMissionDetails(missionId);
    final participantIds = mission['participants'] as List<String>? ?? [];
    
    return participantIds.map((id) => getTesterProfile(id)).toList();
  }
  
  @override
  Map<String, dynamic> getAppDetails(String appId) {
    return _apps[appId] ?? {};
  }
  
  @override
  List<Map<String, dynamic>> getAppBugReports(String appId) {
    return _bugReports.where((report) => report['appId'] == appId).toList();
  }
  
  @override
  Map<String, dynamic> getAppAnalytics(String appId) {
    final bugReports = getAppBugReports(appId);
    final missions = _missions.where((m) => m['appId'] == appId).toList();
    
    return {
      'totalMissions': missions.length,
      'activeMissions': missions.where((m) => m['status'] == 'active').length,
      'completedMissions': missions.where((m) => m['status'] == 'completed').length,
      'totalBugReports': bugReports.length,
      'criticalBugs': bugReports.where((b) => b['severity'] == 'critical').length,
      'resolvedBugs': bugReports.where((b) => b['status'] == 'resolved').length,
      'averageResolutionTime': 24.5,
      'testerSatisfaction': 4.6,
    };
  }
  
  @override
  Map<String, dynamic> getBugReportDetails(String reportId) {
    return _bugReports.firstWhere(
      (report) => report['id'] == reportId,
      orElse: () => {},
    );
  }
  
  @override
  List<Map<String, dynamic>> getBugReportComments(String reportId) {
    return [
      {
        'id': 'comment1',
        'reportId': reportId,
        'userId': 'provider1',
        'userName': '개발팀',
        'comment': '확인했습니다. 수정 중입니다.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': 'comment2',
        'reportId': reportId,
        'userId': 'tester1',
        'userName': '김테스터',
        'comment': '추가 정보 제공드립니다.',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      },
    ];
  }
  
  @override
  Map<String, dynamic>? authenticateUser(String email, String password) {
    final mockCredentials = {
      'provider1@bugcash.com': {'password': 'password123', 'uid': 'provider1', 'type': 'provider'},
      'provider2@bugcash.com': {'password': 'password123', 'uid': 'provider2', 'type': 'provider'},
      'provider3@bugcash.com': {'password': 'password123', 'uid': 'provider3', 'type': 'provider'},
      'tester1@bugcash.com': {'password': 'password123', 'uid': 'tester1', 'type': 'tester'},
      'tester2@bugcash.com': {'password': 'password123', 'uid': 'tester2', 'type': 'tester'},
      'tester3@bugcash.com': {'password': 'password123', 'uid': 'tester3', 'type': 'tester'},
      'tester4@bugcash.com': {'password': 'password123', 'uid': 'tester4', 'type': 'tester'},
    };
    
    final credentials = mockCredentials[email];
    if (credentials != null && credentials['password'] == password) {
      return {
        'uid': credentials['uid'],
        'email': email,
        'type': credentials['type'],
      };
    }
    return null;
  }
  
  @override
  List<Map<String, dynamic>> getMockAccounts() {
    return [
      {'type': 'provider', 'email': 'provider1@bugcash.com', 'password': 'password123'},
      {'type': 'provider', 'email': 'provider2@bugcash.com', 'password': 'password123'},
      {'type': 'provider', 'email': 'provider3@bugcash.com', 'password': 'password123'},
      {'type': 'tester', 'email': 'tester1@bugcash.com', 'password': 'password123'},
      {'type': 'tester', 'email': 'tester2@bugcash.com', 'password': 'password123'},
      {'type': 'tester', 'email': 'tester3@bugcash.com', 'password': 'password123'},
      {'type': 'tester', 'email': 'tester4@bugcash.com', 'password': 'password123'},
    ];
  }
  
  // Private initialization methods
  static Map<String, Map<String, dynamic>> _initProviders() {
    return {
      'provider1': {
        'id': 'provider1',
        'companyName': 'BugCash Inc.',
        'contactEmail': 'provider1@bugcash.com',
        'contactPerson': 'John Doe',
        'phoneNumber': '010-1234-5678',
      },
      'provider2': {
        'id': 'provider2',
        'companyName': 'Startup Dev',
        'contactEmail': 'provider2@bugcash.com',
        'contactPerson': 'Jane Smith',
        'phoneNumber': '010-2345-6789',
      },
      'provider3': {
        'id': 'provider3',
        'companyName': 'Enterprise QA',
        'contactEmail': 'provider3@bugcash.com',
        'contactPerson': 'Mike Johnson',
        'phoneNumber': '010-3456-7890',
      },
    };
  }
  
  static Map<String, Map<String, dynamic>> _initTesters() {
    return {
      'tester1': {
        'id': 'tester1',
        'name': '김테스터',
        'email': 'tester1@bugcash.com',
        'skills': ['일반 테스트'],
      },
      'tester2': {
        'id': 'tester2',
        'name': '이테스터',
        'email': 'tester2@bugcash.com',
        'skills': ['UI/UX 테스트'],
      },
      'tester3': {
        'id': 'tester3',
        'name': '박테스터',
        'email': 'tester3@bugcash.com',
        'skills': ['보안 테스트'],
      },
      'tester4': {
        'id': 'tester4',
        'name': '최테스터',
        'email': 'tester4@bugcash.com',
        'skills': ['버그 헌팅'],
      },
    };
  }
  
  static Map<String, Map<String, dynamic>> _initApps() {
    return {
      'app1': {
        'id': 'app1',
        'name': 'ShopApp',
        'providerId': 'provider1',
        'category': 'shopping',
      },
      'app2': {
        'id': 'app2',
        'name': 'FoodDelivery',
        'providerId': 'provider1',
        'category': 'food',
      },
      'app3': {
        'id': 'app3',
        'name': 'FitnessTracker',
        'providerId': 'provider2',
        'category': 'health',
      },
    };
  }
  
  static List<Map<String, dynamic>> _initMissions() {
    return [
      {
        'id': 'mission1',
        'title': 'ShopApp 결제 기능 테스트',
        'description': '새로운 결제 시스템의 안정성을 검증해주세요',
        'appId': 'app1',
        'providerId': 'provider1',
        'type': 'featureTesting',
        'status': 'active',
        'reward': 250,
        'maxTesters': 10,
        'participants': ['tester1', 'tester2'],
        'deadline': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'mission2',
        'title': 'FoodDelivery UI/UX 개선 테스트',
        'description': '새로운 인터페이스의 사용성을 평가해주세요',
        'appId': 'app2',
        'providerId': 'provider1',
        'type': 'usabilityTest',
        'status': 'completed',
        'reward': 180,
        'maxTesters': 15,
        'participants': ['tester1', 'tester3', 'tester4'],
        'deadline': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'createdAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
    ];
  }
  
  static List<Map<String, dynamic>> _initBugReports() {
    return [
      {
        'id': 'bug1',
        'title': 'ShopApp 결제 버튼 클릭 안됨',
        'description': 'iOS에서 결제 버튼을 누르면 반응이 없습니다.',
        'severity': 'high',
        'status': 'open',
        'appId': 'app1',
        'testerId': 'tester1',
        'testerName': '김테스터',
        'createdAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'screenshots': ['screenshot1.jpg', 'screenshot2.jpg'],
      },
      {
        'id': 'bug2',
        'title': 'FoodDelivery 주문 내역 표시 오류',
        'description': '주문 내역 페이지에서 가격이 잘못 표시됩니다.',
        'severity': 'medium',
        'status': 'in_progress',
        'appId': 'app2',
        'testerId': 'tester2',
        'testerName': '이테스터',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'screenshots': ['bug_report1.png'],
      },
    ];
  }

  // App CRUD 메서드들
  @override
  Map<String, dynamic> getApp(String appId) {
    return _apps[appId] ?? {};
  }

  @override
  String createApp(Map<String, dynamic> appData) {
    final appId = 'app_${DateTime.now().millisecondsSinceEpoch}';
    _apps[appId] = {
      'id': appId,
      ...appData,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    return appId;
  }

  @override
  void updateApp(String appId, Map<String, dynamic> data) {
    if (_apps.containsKey(appId)) {
      _apps[appId] = {
        ..._apps[appId]!,
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  void deleteApp(String appId) {
    _apps.remove(appId);
  }

  // Provider 업데이트 메서드
  @override
  void updateProviderProfile(String providerId, Map<String, dynamic> data) {
    if (_providers.containsKey(providerId)) {
      _providers[providerId] = {
        ..._providers[providerId]!,
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
  }
}