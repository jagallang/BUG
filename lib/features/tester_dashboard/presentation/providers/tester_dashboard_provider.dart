import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Firebase 의존성 제거 - Mock 데이터만 사용
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/mission_model.dart';

// Tester Dashboard State
class TesterDashboardState {
  final TesterProfile? testerProfile;
  final List<MissionCard> availableMissions;
  final List<MissionCard> activeMissions;
  final List<MissionCard> completedMissions;
  final EarningsData? earningsData;
  final bool isLoading;
  final String? error;
  final int unreadNotifications;
  final DateTime? lastUpdated;

  TesterDashboardState({
    this.testerProfile,
    required this.availableMissions,
    required this.activeMissions,
    required this.completedMissions,
    this.earningsData,
    required this.isLoading,
    this.error,
    required this.unreadNotifications,
    this.lastUpdated,
  });

  factory TesterDashboardState.initial() {
    return TesterDashboardState(
      availableMissions: [],
      activeMissions: [],
      completedMissions: [],
      isLoading: false,
      unreadNotifications: 0,
    );
  }

  TesterDashboardState copyWith({
    TesterProfile? testerProfile,
    List<MissionCard>? availableMissions,
    List<MissionCard>? activeMissions,
    List<MissionCard>? completedMissions,
    EarningsData? earningsData,
    bool? isLoading,
    String? error,
    int? unreadNotifications,
    DateTime? lastUpdated,
  }) {
    return TesterDashboardState(
      testerProfile: testerProfile ?? this.testerProfile,
      availableMissions: availableMissions ?? this.availableMissions,
      activeMissions: activeMissions ?? this.activeMissions,
      completedMissions: completedMissions ?? this.completedMissions,
      earningsData: earningsData ?? this.earningsData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Tester Profile Model
class TesterProfile {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final int totalPoints;
  final int monthlyPoints;
  final int completedMissions;
  final double successRate;
  final double averageRating;
  final List<String> skills;
  final List<String> interests;
  final TesterLevel level;
  final int experiencePoints;
  final DateTime joinedDate;

  TesterProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.totalPoints,
    required this.monthlyPoints,
    required this.completedMissions,
    required this.successRate,
    required this.averageRating,
    required this.skills,
    required this.interests,
    required this.level,
    required this.experiencePoints,
    required this.joinedDate,
  });
}

// Tester Level Enum
enum TesterLevel {
  beginner,   // 초보 (0-999 XP)
  intermediate, // 중급 (1000-2999 XP)
  advanced,   // 고급 (3000-4999 XP)
  expert,     // 전문가 (5000+ XP)
}

// Mission Card Model
class MissionCard {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final int rewardPoints;
  final int estimatedMinutes;
  final MissionStatus status;
  final DateTime? deadline;
  final List<String> requiredSkills;
  final String appName;
  final String? appIcon;
  final int currentParticipants;
  final int maxParticipants;
  final double? progress; // For active missions
  final DateTime? startedAt; // For active missions
  final String? providerId;
  final MissionDifficulty difficulty;

  MissionCard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.rewardPoints,
    required this.estimatedMinutes,
    required this.status,
    this.deadline,
    required this.requiredSkills,
    required this.appName,
    this.appIcon,
    required this.currentParticipants,
    required this.maxParticipants,
    this.progress,
    this.startedAt,
    this.providerId,
    required this.difficulty,
  });
}


// Earnings Data Model
class EarningsData {
  final int totalEarnings;
  final int thisMonthEarnings;
  final int thisWeekEarnings;
  final int todayEarnings;
  final List<EarningHistory> recentHistory;
  final Map<String, int> earningsByType;
  final int pendingPayments;
  final DateTime? lastPayoutDate;

  EarningsData({
    required this.totalEarnings,
    required this.thisMonthEarnings,
    required this.thisWeekEarnings,
    required this.todayEarnings,
    required this.recentHistory,
    required this.earningsByType,
    required this.pendingPayments,
    this.lastPayoutDate,
  });
}

// Earning History Model
class EarningHistory {
  final String id;
  final String missionTitle;
  final int points;
  final DateTime earnedAt;
  final EarningType type;
  final bool isPaid;

  EarningHistory({
    required this.id,
    required this.missionTitle,
    required this.points,
    required this.earnedAt,
    required this.type,
    required this.isPaid,
  });
}

// Earning Type Enum
enum EarningType {
  missionComplete,
  bonus,
  referral,
  achievement,
}

// Tester Dashboard Provider
final testerDashboardProvider = 
    StateNotifierProvider<TesterDashboardNotifier, TesterDashboardState>((ref) {
  return TesterDashboardNotifier(ref);
});

class TesterDashboardNotifier extends StateNotifier<TesterDashboardState> {
  final Ref _ref;
  // Firebase 의존성 제거 - Mock 데이터만 사용
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _refreshTimer;
  StreamSubscription? _missionsSubscription;
  StreamSubscription? _profileSubscription;

  TesterDashboardNotifier(this._ref) : super(TesterDashboardState.initial());

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _missionsSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadTesterData(String testerId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load tester profile
      await _loadTesterProfile(testerId);
      
      // Load missions
      await _loadMissions(testerId);
      
      // Load earnings data
      await _loadEarningsData(testerId);
      
      // Start real-time subscriptions
      _startRealTimeUpdates(testerId);
      
      state = state.copyWith(
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '데이터를 불러오는데 실패했습니다: $e',
      );
    }
  }

  Future<void> _loadTesterProfile(String testerId) async {
    try {
      // Mock tester profile - replace with actual Firestore query
      final profile = TesterProfile(
        id: testerId,
        name: '김테스터',
        email: 'tester@example.com',
        totalPoints: 15420,
        monthlyPoints: 3280,
        completedMissions: 87,
        successRate: 0.94,
        averageRating: 4.7,
        skills: ['UI/UX 테스트', '모바일 앱', '웹 테스트', '버그 발견'],
        interests: ['게임', '소셜미디어', '쇼핑', '교육'],
        level: TesterLevel.advanced,
        experiencePoints: 4250,
        joinedDate: DateTime.now().subtract(const Duration(days: 180)),
      );
      
      state = state.copyWith(testerProfile: profile);
    } catch (e) {
      print('Failed to load tester profile: $e');
    }
  }

  Future<void> _loadMissions(String testerId) async {
    try {
      // Generate mock missions - replace with actual Firestore queries
      final availableMissions = _generateAvailableMissions();
      final activeMissions = _generateActiveMissions(testerId);
      final completedMissions = _generateCompletedMissions(testerId);
      
      state = state.copyWith(
        availableMissions: availableMissions,
        activeMissions: activeMissions,
        completedMissions: completedMissions,
      );
    } catch (e) {
      print('Failed to load missions: $e');
    }
  }

  List<MissionCard> _generateAvailableMissions() {
    final missions = <MissionCard>[];
    final missionTypes = [MissionType.bugReport, MissionType.featureTesting, MissionType.usabilityTest];
    final appNames = ['ShopApp', 'FoodDelivery', 'FitnessTracker', 'SocialChat', 'NewsReader'];
    final difficulties = [MissionDifficulty.easy, MissionDifficulty.medium, MissionDifficulty.hard];
    
    for (int i = 0; i < 10; i++) {
      final type = missionTypes[i % missionTypes.length];
      final difficulty = difficulties[i % difficulties.length];
      final rewardPoints = _getRewardByDifficulty(difficulty);
      
      missions.add(MissionCard(
        id: 'mission_$i',
        title: _getMissionTitle(type, i),
        description: _getMissionDescription(type, i),
        type: type,
        rewardPoints: rewardPoints,
        estimatedMinutes: 15 + (i % 45),
        status: MissionStatus.active,
        deadline: DateTime.now().add(Duration(days: 3 + (i % 7))),
        requiredSkills: _getSkillsForType(type),
        appName: appNames[i % appNames.length],
        currentParticipants: i % 15,
        maxParticipants: 20,
        difficulty: difficulty,
      ));
    }
    
    return missions;
  }

  List<MissionCard> _generateActiveMissions(String testerId) {
    return [
      MissionCard(
        id: 'active_1',
        title: 'ShopApp 결제 기능 테스트',
        description: '새로운 결제 시스템의 안정성을 검증해주세요',
        type: MissionType.featureTesting,
        rewardPoints: 250,
        estimatedMinutes: 45,
        status: MissionStatus.inProgress,
        deadline: DateTime.now().add(const Duration(days: 2)),
        requiredSkills: ['결제 시스템', 'UI 테스트'],
        appName: 'ShopApp',
        currentParticipants: 5,
        maxParticipants: 10,
        progress: 0.65,
        startedAt: DateTime.now().subtract(const Duration(hours: 8)),
        difficulty: MissionDifficulty.medium,
      ),
      MissionCard(
        id: 'active_2',
        title: 'FoodDelivery 앱 사용성 개선',
        description: '주문 과정의 사용자 경험을 평가해주세요',
        type: MissionType.usabilityTest,
        rewardPoints: 180,
        estimatedMinutes: 30,
        status: MissionStatus.inProgress,
        deadline: DateTime.now().add(const Duration(days: 1)),
        requiredSkills: ['UX 평가', '모바일 앱'],
        appName: 'FoodDelivery',
        currentParticipants: 8,
        maxParticipants: 15,
        progress: 0.35,
        startedAt: DateTime.now().subtract(const Duration(hours: 4)),
        difficulty: MissionDifficulty.easy,
      ),
    ];
  }

  List<MissionCard> _generateCompletedMissions(String testerId) {
    return [
      MissionCard(
        id: 'completed_1',
        title: 'SocialChat 알림 버그 찾기',
        description: '알림이 제대로 표시되지 않는 문제를 발견했습니다',
        type: MissionType.bugReport,
        rewardPoints: 300,
        estimatedMinutes: 25,
        status: MissionStatus.completed,
        requiredSkills: ['버그 발견', '알림 시스템'],
        appName: 'SocialChat',
        currentParticipants: 12,
        maxParticipants: 15,
        difficulty: MissionDifficulty.medium,
      ),
    ];
  }

  String _getMissionTitle(MissionType type, int index) {
    switch (type) {
      case MissionType.bugReport:
        return ['앱 크래시 버그 찾기', '로그인 오류 발견', '결제 실패 이슈'][index % 3];
      case MissionType.featureTesting:
        return ['새 기능 테스트', '업데이트 검증', '기능 안정성 확인'][index % 3];
      case MissionType.usabilityTest:
        return ['사용성 평가', 'UX 개선 제안', '인터페이스 검토'][index % 3];
      default:
        return '일반 테스트 미션';
    }
  }

  String _getMissionDescription(MissionType type, int index) {
    switch (type) {
      case MissionType.bugReport:
        return '앱에서 발생하는 오류나 버그를 찾아 상세한 리포트를 작성해주세요';
      case MissionType.featureTesting:
        return '새로 추가된 기능이 올바르게 작동하는지 테스트해주세요';
      case MissionType.usabilityTest:
        return '앱의 사용자 경험을 평가하고 개선점을 제안해주세요';
      default:
        return '테스트 미션을 완료해주세요';
    }
  }

  List<String> _getSkillsForType(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return ['버그 발견', '테스트 케이스 작성'];
      case MissionType.featureTesting:
        return ['기능 테스트', 'QA'];
      case MissionType.usabilityTest:
        return ['UX 평가', '사용성 테스트'];
      default:
        return ['일반 테스트'];
    }
  }

  int _getRewardByDifficulty(MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return 100 + (DateTime.now().millisecondsSinceEpoch % 50);
      case MissionDifficulty.medium:
        return 200 + (DateTime.now().millisecondsSinceEpoch % 100);
      case MissionDifficulty.hard:
        return 350 + (DateTime.now().millisecondsSinceEpoch % 150);
      case MissionDifficulty.expert:
        return 500 + (DateTime.now().millisecondsSinceEpoch % 200);
    }
  }

  Future<void> _loadEarningsData(String testerId) async {
    try {
      // Mock earnings data - replace with actual Firestore query
      final earningsData = EarningsData(
        totalEarnings: 15420,
        thisMonthEarnings: 3280,
        thisWeekEarnings: 890,
        todayEarnings: 180,
        recentHistory: _generateEarningHistory(),
        earningsByType: {
          'bugReport': 8500,
          'featureTesting': 4200,
          'usabilityTest': 2100,
          'survey': 620,
        },
        pendingPayments: 890,
        lastPayoutDate: DateTime.now().subtract(const Duration(days: 15)),
      );
      
      state = state.copyWith(earningsData: earningsData);
    } catch (e) {
      print('Failed to load earnings data: $e');
    }
  }

  List<EarningHistory> _generateEarningHistory() {
    return [
      EarningHistory(
        id: '1',
        missionTitle: 'ShopApp 버그 발견',
        points: 300,
        earnedAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: EarningType.missionComplete,
        isPaid: false,
      ),
      EarningHistory(
        id: '2',
        missionTitle: '추천 보너스',
        points: 500,
        earnedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: EarningType.referral,
        isPaid: true,
      ),
      EarningHistory(
        id: '3',
        missionTitle: 'FoodDelivery UX 테스트',
        points: 180,
        earnedAt: DateTime.now().subtract(const Duration(days: 2)),
        type: EarningType.missionComplete,
        isPaid: true,
      ),
    ];
  }

  void _startRealTimeUpdates(String testerId) {
    // Firebase 의존성 제거 - Mock 업데이트만 사용
    // 실시간 업데이트 시뮬레이션을 위한 주기적 새로고침
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Mock 데이터 주기적 업데이트
      _loadMissions(testerId);
      _loadTesterProfile(testerId);
    });
  }

  Future<void> joinMission(String missionId) async {
    try {
      // Add mission to active missions
      final mission = state.availableMissions.firstWhere((m) => m.id == missionId);
      final activeMission = MissionCard(
        id: mission.id,
        title: mission.title,
        description: mission.description,
        type: mission.type,
        rewardPoints: mission.rewardPoints,
        estimatedMinutes: mission.estimatedMinutes,
        status: MissionStatus.inProgress,
        deadline: mission.deadline,
        requiredSkills: mission.requiredSkills,
        appName: mission.appName,
        appIcon: mission.appIcon,
        currentParticipants: mission.currentParticipants + 1,
        maxParticipants: mission.maxParticipants,
        progress: 0.0,
        startedAt: DateTime.now(),
        difficulty: mission.difficulty,
      );
      
      final updatedAvailable = state.availableMissions.where((m) => m.id != missionId).toList();
      final updatedActive = [...state.activeMissions, activeMission];
      
      state = state.copyWith(
        availableMissions: updatedAvailable,
        activeMissions: updatedActive,
      );
    } catch (e) {
      state = state.copyWith(error: '미션 참여에 실패했습니다: $e');
    }
  }

  Future<void> updateMissionProgress(String missionId, double progress) async {
    try {
      final updatedActive = state.activeMissions.map((mission) {
        if (mission.id == missionId) {
          return MissionCard(
            id: mission.id,
            title: mission.title,
            description: mission.description,
            type: mission.type,
            rewardPoints: mission.rewardPoints,
            estimatedMinutes: mission.estimatedMinutes,
            status: mission.status,
            deadline: mission.deadline,
            requiredSkills: mission.requiredSkills,
            appName: mission.appName,
            appIcon: mission.appIcon,
            currentParticipants: mission.currentParticipants,
            maxParticipants: mission.maxParticipants,
            progress: progress,
            startedAt: mission.startedAt,
            difficulty: mission.difficulty,
          );
        }
        return mission;
      }).toList();
      
      state = state.copyWith(activeMissions: updatedActive);
    } catch (e) {
      state = state.copyWith(error: '진행률 업데이트에 실패했습니다: $e');
    }
  }

  void markAllNotificationsRead() {
    state = state.copyWith(unreadNotifications: 0);
  }

  Future<void> refreshData(String testerId) async {
    await loadTesterData(testerId);
  }
}