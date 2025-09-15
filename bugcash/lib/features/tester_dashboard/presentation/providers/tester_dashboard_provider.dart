import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/services/auth_service.dart';

// Tester Dashboard State
class TesterDashboardState {
  final TesterProfile? testerProfile;
  final List<MissionCard> availableMissions;
  final List<MissionCard> activeMissions;
  final List<MissionCard> completedMissions;
  final List<MissionApplicationStatus> pendingApplications;
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
    required this.pendingApplications,
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
      pendingApplications: [],
      isLoading: false,
      unreadNotifications: 0,
    );
  }

  TesterDashboardState copyWith({
    TesterProfile? testerProfile,
    List<MissionCard>? availableMissions,
    List<MissionCard>? activeMissions,
    List<MissionCard>? completedMissions,
    List<MissionApplicationStatus>? pendingApplications,
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
      pendingApplications: pendingApplications ?? this.pendingApplications,
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

      // Load pending applications
      final pendingApplications = await _getPendingApplications(testerId);

      // Start real-time subscriptions
      _startRealTimeUpdates(testerId);

      state = state.copyWith(
        isLoading: false,
        pendingApplications: pendingApplications,
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
      // Get user profile from Firestore
      final userProfile = await CurrentUserService.getUserProfile(testerId);

      if (userProfile != null) {
        final profile = TesterProfile(
          id: testerId,
          name: userProfile['displayName'] ?? userProfile['name'] ?? '사용자',
          email: userProfile['email'] ?? 'user@example.com',
          totalPoints: userProfile['totalPoints']?.toInt() ?? 0,
          monthlyPoints: userProfile['monthlyPoints']?.toInt() ?? 0,
          completedMissions: userProfile['completedMissions']?.toInt() ?? 0,
          successRate: (userProfile['successRate'] as num?)?.toDouble() ?? 0.0,
          averageRating: (userProfile['averageRating'] as num?)?.toDouble() ?? 0.0,
          skills: (userProfile['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['일반 테스트'],
          interests: (userProfile['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['앱 테스트'],
          level: _getTesterLevelFromString(userProfile['level'] as String?),
          experiencePoints: userProfile['experiencePoints']?.toInt() ?? 0,
          joinedDate: userProfile['createdAt'] != null
            ? (userProfile['createdAt'] as Timestamp).toDate()
            : DateTime.now().subtract(const Duration(days: 1)),
        );

        state = state.copyWith(testerProfile: profile);
      } else {
        // Fallback profile if user data not found
        final profile = TesterProfile(
          id: testerId,
          name: '사용자',
          email: 'user@example.com',
          totalPoints: 0,
          monthlyPoints: 0,
          completedMissions: 0,
          successRate: 0.0,
          averageRating: 0.0,
          skills: ['일반 테스트'],
          interests: ['앱 테스트'],
          level: TesterLevel.beginner,
          experiencePoints: 0,
          joinedDate: DateTime.now(),
        );

        state = state.copyWith(testerProfile: profile);
      }
    } catch (e) {
      debugPrint('Failed to load tester profile: $e');

      // Fallback profile in case of error
      final profile = TesterProfile(
        id: testerId,
        name: '사용자',
        email: 'user@example.com',
        totalPoints: 0,
        monthlyPoints: 0,
        completedMissions: 0,
        successRate: 0.0,
        averageRating: 0.0,
        skills: ['일반 테스트'],
        interests: ['앱 테스트'],
        level: TesterLevel.beginner,
        experiencePoints: 0,
        joinedDate: DateTime.now(),
      );

      state = state.copyWith(testerProfile: profile);
    }
  }

  TesterLevel _getTesterLevelFromString(String? levelString) {
    switch (levelString?.toLowerCase()) {
      case 'expert':
        return TesterLevel.expert;
      case 'advanced':
        return TesterLevel.advanced;
      case 'intermediate':
        return TesterLevel.intermediate;
      case 'beginner':
      default:
        return TesterLevel.beginner;
    }
  }

  Future<void> _loadMissions(String testerId) async {
    try {
      // Use real Firestore queries instead of mock data
      final availableMissions = await _getAvailableMissionsFromFirestore();
      final activeMissions = await _getActiveMissionsFromFirestore(testerId);
      final completedMissions = await _getCompletedMissionsFromFirestore(testerId);
      
      state = state.copyWith(
        availableMissions: availableMissions,
        activeMissions: activeMissions,
        completedMissions: completedMissions,
      );
    } catch (e) {
      debugPrint('Failed to load missions: $e');
    }
  }

  List<MissionCard> _generateAvailableMissions() {
    final missions = <MissionCard>[];
    // 앱테스터 모집을 주미션으로 변경
    final missionTypes = [MissionType.featureTesting, MissionType.usabilityTest, MissionType.bugReport];
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
        estimatedMinutes: 10, // 10분 테스트 기준으로 통일
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

  List<MissionCard> _generateCompletedMissions(String testerId) {  // ignore: unused_element
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
    final appNames = ['ShopApp', 'FoodDelivery', 'FitnessTracker', 'SocialChat', 'NewsReader'];
    final appName = appNames[index % appNames.length];
    
    switch (type) {
      case MissionType.featureTesting:
        return '$appName 앱테스터 모집 - 기능 테스트';
      case MissionType.usabilityTest:
        return '$appName 앱테스터 모집 - 사용성 평가';
      case MissionType.bugReport:
        return '$appName 앱테스터 모집 - 버그 리포트';
      default:
        return '$appName 앱테스터 모집';
    }
  }

  String _getMissionDescription(MissionType type, int index) {
    switch (type) {
      case MissionType.featureTesting:
        return '10분 내외로 앱 기능을 테스트하고 피드백을 제공해주세요. 2000포인트 지급';
      case MissionType.usabilityTest:
        return '10분 내외로 앱 사용성을 평가하고 개선 아이디어를 제공해주세요. 2000포인트 지급';
      case MissionType.bugReport:
        return '10분 내외로 앱 버그를 발견하고 상세한 리포트를 작성해주세요. 2000포인트 지급';
      default:
        return '10분 내외로 앱 테스트를 완료해주세요. 2000포인트 지급';
    }
  }

  List<String> _getSkillsForType(MissionType type) {
    switch (type) {
      case MissionType.featureTesting:
        return ['앱 테스트', '기능 검증', '모바일 경험'];
      case MissionType.usabilityTest:
        return ['앱 테스트', 'UX 평가', '사용성 분석'];
      case MissionType.bugReport:
        return ['앱 테스트', '버그 발견', '리포트 작성'];
      default:
        return ['앱 테스트', '일반 테스트'];
    }
  }

  int _getRewardByDifficulty(MissionDifficulty difficulty) {
    // 기본 2000포인트를 베이스로 난이도별 추가 보상
    switch (difficulty) {
      case MissionDifficulty.easy:
        return 2000;
      case MissionDifficulty.medium:
        return 2500;
      case MissionDifficulty.hard:
        return 3000;
      case MissionDifficulty.expert:
        return 4000;
    }
  }

  Future<void> _loadEarningsData(String testerId) async {
    try {
      final userId = CurrentUserService.getCurrentUserIdOrDefault();
      
      // Load earnings from Firestore
      final earningsSnapshot = await FirebaseFirestore.instance
          .collection('earnings')
          .where('userId', isEqualTo: userId)
          .orderBy('earnedAt', descending: true)
          .get();

      // Calculate totals
      int totalEarnings = 0;
      int thisMonthEarnings = 0;
      int thisWeekEarnings = 0;
      int todayEarnings = 0;
      int pendingPayments = 0;
      final Map<String, int> earningsByType = {};
      final List<EarningHistory> recentHistory = [];

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(now.year, now.month, now.day);

      for (var doc in earningsSnapshot.docs) {
        final data = doc.data();
        final points = (data['points'] ?? 0) as int;
        final earnedAt = (data['earnedAt'] as Timestamp).toDate();
        final type = data['type'] ?? 'missionComplete';
        final isPaid = data['isPaid'] ?? false;
        
        totalEarnings += points;
        
        if (earnedAt.isAfter(startOfMonth)) {
          thisMonthEarnings += points;
        }
        if (earnedAt.isAfter(startOfWeek)) {
          thisWeekEarnings += points;
        }
        if (earnedAt.isAfter(startOfDay)) {
          todayEarnings += points;
        }
        if (!isPaid) {
          pendingPayments += points;
        }

        // Count by type
        earningsByType[type] = (earningsByType[type] ?? 0) + points;

        // Add to recent history (limit to 10)
        if (recentHistory.length < 10) {
          recentHistory.add(EarningHistory(
            id: doc.id,
            missionTitle: data['missionTitle'] ?? 'Unknown Mission',
            points: points,
            earnedAt: earnedAt,
            type: EarningType.values.firstWhere(
              (e) => e.name == type,
              orElse: () => EarningType.missionComplete,
            ),
            isPaid: isPaid,
          ));
        }
      }

      // Get last payout date
      final payoutSnapshot = await FirebaseFirestore.instance
          .collection('payouts')
          .where('userId', isEqualTo: userId)
          .orderBy('paidAt', descending: true)
          .limit(1)
          .get();

      DateTime? lastPayoutDate;
      if (payoutSnapshot.docs.isNotEmpty) {
        lastPayoutDate = (payoutSnapshot.docs.first.data()['paidAt'] as Timestamp).toDate();
      }

      final earningsData = EarningsData(
        totalEarnings: totalEarnings,
        thisMonthEarnings: thisMonthEarnings,
        thisWeekEarnings: thisWeekEarnings,
        todayEarnings: todayEarnings,
        recentHistory: recentHistory,
        earningsByType: earningsByType,
        pendingPayments: pendingPayments,
        lastPayoutDate: lastPayoutDate,
      );
      
      state = state.copyWith(earningsData: earningsData);
    } catch (e) {
      debugPrint('Failed to load earnings data: $e');
    }
  }


  void _startRealTimeUpdates(String testerId) {
    // Firebase 실시간 업데이트 구독
    _refreshTimer?.cancel();
    
    // 사용자별 미션 업데이트 구독
    final userId = CurrentUserService.getCurrentUserIdOrDefault();
    
    // Available missions stream
    FirebaseFirestore.instance
        .collection('missions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      _loadMissions(testerId);
    });
    
    // User's active missions stream
    FirebaseFirestore.instance
        .collection('mission_participants')
        .where('testerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _loadMissions(testerId);
    });
    
    // Earnings updates
    FirebaseFirestore.instance
        .collection('earnings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _loadEarningsData(testerId);
    });
  }

  Future<void> joinMission(String missionId) async {
    try {
      final userId = CurrentUserService.getCurrentUserIdOrDefault();
      
      // Add user to mission participants
      await FirebaseFirestore.instance.collection('mission_participants').add({
        'missionId': missionId,
        'testerId': userId,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'progress': 0.0,
      });
      
      // Update mission participant count
      final missionDoc = FirebaseFirestore.instance.collection('missions').doc(missionId);
      await missionDoc.update({
        'testers': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh mission data
      final testerId = CurrentUserService.getCurrentUserIdOrDefault();
      await _loadMissions(testerId);
      
      debugPrint('Successfully joined mission: $missionId');
    } catch (e) {
      state = state.copyWith(error: '미션 참여에 실패했습니다: $e');
      debugPrint('Failed to join mission: $e');
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

  // Real Firestore query methods (replacing mock data generation)
  Future<List<MissionCard>> _getAvailableMissionsFromFirestore() async {
    try {
      print('MISSION_DEBUG: 🔍 Loading available missions from Firestore...');
      final missionCards = <MissionCard>[];
      
      // 1. 일반 미션들 가져오기
      final missionsSnapshot = await FirebaseFirestore.instance
          .collection('missions')
          .where('status', isEqualTo: 'active')
          .limit(10)
          .get();
      
      print('📊 Found ${missionsSnapshot.docs.length} regular missions');
      
      for (final doc in missionsSnapshot.docs) {
        try {
          final data = doc.data();
          final missionCard = MissionCard(
            id: doc.id,
            title: data['title'] ?? '미션 제목',
            description: data['description'] ?? '미션 설명',
            appName: data['company'] ?? '회사명',
            type: _parseMissionType(data['type']),
            rewardPoints: data['reward'] ?? 0,
            estimatedMinutes: 60,
            status: MissionStatus.active,
            deadline: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
            requiredSkills: (data['requirements'] as List<dynamic>?)?.cast<String>() ?? ['테스팅'],
            currentParticipants: data['currentParticipants'] ?? 0,
            maxParticipants: data['maxParticipants'] ?? 10,
            progress: 0,
            difficulty: MissionDifficulty.medium,
          );
          missionCards.add(missionCard);
        } catch (e) {
          print('❌ Error parsing mission ${doc.id}: $e');
        }
      }
      
      // 2. Provider Apps를 미션으로 변환해서 추가
      final providerAppsSnapshot = await FirebaseFirestore.instance
          .collection('provider_apps')
          .where('status', isEqualTo: 'active')
          .limit(20)
          .get();
      
      print('📱 Found ${providerAppsSnapshot.docs.length} provider apps');
      
      for (final doc in providerAppsSnapshot.docs) {
        try {
          final data = doc.data();
          final missionCard = MissionCard(
            id: 'provider_app_${doc.id}',
            title: '${data['appName'] ?? '앱'} 테스팅',
            description: data['description'] ?? '앱 테스팅 및 피드백 제공',
            appName: data['appName'] ?? '앱',
            type: MissionType.functional,
            rewardPoints: 5000,
            estimatedMinutes: 30,
            status: MissionStatus.active,
            deadline: DateTime.now().add(const Duration(days: 30)),
            requiredSkills: ['앱 테스팅', '피드백 작성'],
            currentParticipants: data['activeTesters'] ?? 0,
            maxParticipants: 50,
            progress: 0,
            difficulty: MissionDifficulty.medium,
          );
          missionCards.add(missionCard);
        } catch (e) {
          print('❌ Error parsing provider app ${doc.id}: $e');
        }
      }
      
      print('✅ Total missions loaded: ${missionCards.length}');
      return missionCards;
    } catch (e) {
      debugPrint('Failed to load available missions from Firestore: $e');
      return <MissionCard>[];
    }
  }
  
  MissionType _parseMissionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'functional':
        return MissionType.functional;
      case 'ui':
      case 'uiux':
        return MissionType.uiUx;
      case 'performance':
        return MissionType.performance;
      case 'security':
        return MissionType.security;
      case 'usability':
        return MissionType.usabilityTest;
      case 'bug':
      case 'bugreport':
        return MissionType.bugReport;
      case 'feature':
      case 'featuretesting':
        return MissionType.featureTesting;
      case 'performancetest':
        return MissionType.performanceTest;
      case 'survey':
        return MissionType.survey;
      case 'feedback':
        return MissionType.feedback;
      default:
        return MissionType.functional;
    }
  }
  
  MissionDifficulty _parseMissionDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return MissionDifficulty.easy;
      case 'medium':
        return MissionDifficulty.medium;
      case 'hard':
        return MissionDifficulty.hard;
      default:
        return MissionDifficulty.medium;
    }
  }

  Future<List<MissionCard>> _getActiveMissionsFromFirestore(String testerId) async {
    try {
      // Return empty list initially - will be populated with real data
      return <MissionCard>[];
    } catch (e) {
      debugPrint('Failed to load active missions from Firestore: $e');
      return <MissionCard>[];
    }
  }

  Future<List<MissionCard>> _getCompletedMissionsFromFirestore(String testerId) async {
    try {
      // Return empty list initially - will be populated with real data
      return <MissionCard>[];
    } catch (e) {
      debugPrint('Failed to load completed missions from Firestore: $e');
      return <MissionCard>[];
    }
  }

  Future<List<MissionApplicationStatus>> _getPendingApplications(String testerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('missionApplications')
          .where('testerId', isEqualTo: testerId)
          .orderBy('appliedAt', descending: true)
          .get();

      final applications = <MissionApplicationStatus>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        applications.add(MissionApplicationStatus(
          id: doc.id,
          missionId: data['missionId'] ?? '',
          providerId: data['providerId'] ?? '',
          status: _parseApplicationStatus(data['status'] ?? 'pending'),
          appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
          message: data['message'] ?? '',
          responseMessage: data['responseMessage'],
        ));
      }

      return applications;
    } catch (e) {
      debugPrint('Failed to load pending applications: $e');
      return <MissionApplicationStatus>[];
    }
  }

  ApplicationStatus _parseApplicationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'reviewing':
        return ApplicationStatus.reviewing;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'cancelled':
        return ApplicationStatus.cancelled;
      case 'pending':
      default:
        return ApplicationStatus.pending;
    }
  }
}

// Mission Application Status Model
class MissionApplicationStatus {
  final String id;
  final String missionId;
  final String providerId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String message;
  final String? responseMessage;

  MissionApplicationStatus({
    required this.id,
    required this.missionId,
    required this.providerId,
    required this.status,
    required this.appliedAt,
    this.reviewedAt,
    required this.message,
    this.responseMessage,
  });
}

// Application Status Enum
enum ApplicationStatus {
  pending,
  reviewing,
  accepted,
  rejected,
  cancelled,
}