import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/logger.dart';

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
// v2.19.0: 동적 필드 추가 (deadlineText, participantsText, testPeriodDays, currentTesters, maxTesters)
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
  final bool isProviderApp; // Provider 앱 여부
  final Map<String, dynamic>? originalAppData; // 원본 앱 데이터

  // v2.19.0: 동적 텍스트 필드 추가
  final int currentTesters;      // 현재 테스터 수
  final int maxTesters;          // 최대 테스터 수
  final int testPeriodDays;      // 테스트 기간 (일)
  final String deadlineText;     // "바로 진행" 또는 "모집 마감"
  final String participantsText; // "3/5" 또는 "대기 중"

  // v2.20.01: 신청 여부 표시
  final bool isApplied;          // 테스터가 이미 신청했는지 여부

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
    this.isProviderApp = false,
    this.originalAppData,
    // v2.19.0: 새 필드 기본값
    this.currentTesters = 0,
    this.maxTesters = 5,
    this.testPeriodDays = 10,
    this.deadlineText = '바로 진행',
    this.participantsText = '대기 중',
    // v2.20.01: 신청 여부 기본값
    this.isApplied = false,
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

      // Start real-time subscriptions for PRD collections
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
          name: _getStringValue(userProfile['displayName']) ??
                _getStringValue(userProfile['name']) ?? '사용자',
          email: _getStringValue(userProfile['email']) ?? 'user@example.com',
          totalPoints: _getIntValue(userProfile['totalPoints']) ?? 0,
          monthlyPoints: _getIntValue(userProfile['monthlyPoints']) ?? 0,
          completedMissions: _getIntValue(userProfile['completedMissions']) ?? 0,
          successRate: _getDoubleValue(userProfile['successRate']) ?? 0.0,
          averageRating: _getDoubleValue(userProfile['averageRating']) ?? 0.0,
          skills: _getStringListValue(userProfile['skills']) ?? ['일반 테스트'],
          interests: _getStringListValue(userProfile['interests']) ?? ['앱 테스트'],
          level: _getTesterLevelFromString(_getStringValue(userProfile['level'])),
          experiencePoints: _getIntValue(userProfile['experiencePoints']) ?? 0,
          joinedDate: _getDateTimeValue(userProfile['createdAt']) ??
                     DateTime.now().subtract(const Duration(days: 1)),
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

      // v2.20.01: 테스터가 신청한 미션 목록 조회
      final appliedAppIds = await _getAppliedMissionAppIds(testerId);

      // v2.20.01: availableMissions에 isApplied 플래그 추가
      final missionsWithAppliedStatus = availableMissions.map((mission) {
        final isApplied = appliedAppIds.contains(mission.id);
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
          progress: mission.progress,
          startedAt: mission.startedAt,
          providerId: mission.providerId,
          difficulty: mission.difficulty,
          isProviderApp: mission.isProviderApp,
          originalAppData: mission.originalAppData,
          currentTesters: mission.currentTesters,
          maxTesters: mission.maxTesters,
          testPeriodDays: mission.testPeriodDays,
          deadlineText: mission.deadlineText,
          participantsText: mission.participantsText,
          isApplied: isApplied,  // v2.20.01: 신청 여부 설정
        );
      }).toList();

      state = state.copyWith(
        availableMissions: missionsWithAppliedStatus,
        activeMissions: activeMissions,
        completedMissions: completedMissions,
      );
    } catch (e) {
      debugPrint('Failed to load missions: $e');
    }
  }

  /// v2.20.01: 테스터가 신청한 미션의 appId 목록 조회
  Future<Set<String>> _getAppliedMissionAppIds(String testerId) async {
    try {
      final appliedWorkflows = await FirebaseFirestore.instance
          .collection('mission_workflows')
          .where('testerId', isEqualTo: testerId)
          .get();

      final appIds = appliedWorkflows.docs
          .map((doc) {
            final appId = doc.data()['appId'] as String?;
            // provider_app_ 접두사 제거
            return appId?.replaceAll('provider_app_', '') ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      AppLogger.info('✅ Tester applied missions: ${appIds.length} apps', 'TesterDashboard');
      return appIds;
    } catch (e) {
      AppLogger.error('Failed to get applied mission app IDs', 'TesterDashboard', e);
      return <String>{};
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
    // PRD 기준 Firebase 실시간 업데이트 구독
    _refreshTimer?.cancel();

    final userId = CurrentUserService.getCurrentUserIdOrDefault();

    // Projects stream (status='open')
    FirebaseFirestore.instance
        .collection('projects')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .listen((snapshot) {
      _loadMissions(testerId);
    });

    // User's applications stream
    FirebaseFirestore.instance
        .collection('applications')
        .where('testerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _loadMissions(testerId);
    });

    // User's enrollments stream
    FirebaseFirestore.instance
        .collection('enrollments')
        .where('testerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _loadMissions(testerId);
    });

    // Points transactions updates (PRD 기준)
    FirebaseFirestore.instance
        .collection('points_transactions')
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
            isProviderApp: mission.isProviderApp,
            originalAppData: mission.originalAppData,
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

  // PRD에 따른 새로운 projects 컬렉션 사용
  Future<List<MissionCard>> _getAvailableMissionsFromFirestore() async {
    try {
      AppLogger.debug('🔍 Loading available projects from Firestore...', 'TesterDashboard');
      final missionCards = <MissionCard>[];

      // PRD 기준: projects 컬렉션에서 status='open'인 프로젝트들 가져오기
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      AppLogger.info('📊 Found ${projectsSnapshot.docs.length} open projects', 'TesterDashboard');

      for (final doc in projectsSnapshot.docs) {
        try {
          final data = doc.data();

          // PRD 기반 프로젝트 데이터 파싱
          final appName = data['appName'] ?? '알 수 없는 앱';
          final type = data['type'] ?? 'app'; // app 또는 mission
          final difficulty = data['difficulty'] ?? 'medium';
          final platform = data['platform'] ?? 'android';
          final category = data['category'] ?? 'general';

          // v2.19.0: 리워드 계산 (PRD 기준) - metadata 우선, rewards 폴백
          final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
          final rewards = data['rewards'] as Map<String, dynamic>? ?? {};

          // 일일 리워드 계산
          final dailyMissionPoints = _getIntValue(metadata['dailyMissionPoints']) ??
                                    _getIntValue(rewards['dailyMissionPoints']) ?? 100;
          final finalCompletionPoints = _getIntValue(metadata['finalCompletionPoints']) ??
                                        _getIntValue(rewards['finalCompletionPoints']) ?? 1000;
          final bonusPoints = _getIntValue(metadata['bonusPoints']) ??
                             _getIntValue(rewards['bonusPoints']) ?? 0;

          // 테스트 기간
          final testPeriod = _getIntValue(metadata['testPeriod']) ??
                            _getIntValue(data['testPeriodDays']) ?? 10;

          // 총 리워드 = (일일 × 기간) + 완료 보너스 + 추가 보너스
          final totalReward = (dailyMissionPoints * testPeriod) + finalCompletionPoints + bonusPoints;

          // v2.19.0: 테스터 수 계산
          final maxTestersValue = _getIntValue(metadata['maxTesters']) ??
                                  _getIntValue(metadata['participantCount']) ??
                                  _getIntValue(data['maxTesters']) ?? 5;
          final currentTestersValue = _getIntValue(data['currentTesters']) ?? 0;

          // v2.19.0: 마감 및 참여자 텍스트 생성
          final deadlineText = currentTestersValue >= maxTestersValue ? '모집 마감' : '바로 진행';
          final participantsText = '$currentTestersValue/$maxTestersValue';

          final missionCard = MissionCard(
            id: doc.id,
            title: '$appName 테스팅 프로젝트',
            description: data['description'] ?? '$appName을 테스트하고 피드백을 제공해주세요.',
            appName: appName,
            type: type == 'mission' ? MissionType.featureTesting : MissionType.functional,
            rewardPoints: totalReward,
            estimatedMinutes: testPeriod * 20, // 테스트 기간 * 20분
            status: MissionStatus.active,
            deadline: DateTime.now().add(Duration(days: testPeriod)),
            requiredSkills: _getRequiredSkills(data),
            currentParticipants: currentTestersValue,
            maxParticipants: maxTestersValue,
            progress: 0,
            difficulty: _parseDifficulty(difficulty),
            isProviderApp: true,
            // v2.19.0: 새 필드 추가
            currentTesters: currentTestersValue,
            maxTesters: maxTestersValue,
            testPeriodDays: testPeriod,
            deadlineText: deadlineText,
            participantsText: participantsText,
            originalAppData: {
              'projectId': doc.id,
              'providerId': data['providerId'],
              'type': type,
              'platform': platform,
              'category': category,
              'appStoreUrl': data['appStoreUrl'],
              'testingGuidelines': data['testingGuidelines'],
              'requirements': data['requirements'],
              'specializations': data['requirements']?['specializations'],
            },
          );

          missionCards.add(missionCard);
          AppLogger.info('✅ Added project: $appName (${doc.id})', 'TesterDashboard');
        } catch (e) {
          AppLogger.error('❌ Error parsing project ${doc.id}', 'TesterDashboard', e);
        }
      }

      AppLogger.info('✅ Total projects loaded: ${missionCards.length}', 'TesterDashboard');
      return missionCards;
    } catch (e) {
      debugPrint('Failed to load available projects from Firestore: $e');
      return <MissionCard>[];
    }
  }


  Future<List<MissionCard>> _getActiveMissionsFromFirestore(String testerId) async {
    try {
      final activeMissions = <MissionCard>[];

      // 1. 테스터 신청 정보 가져오기 (mission_workflows 에서 pending, approved, testing_completed, settled 상태)
      final missionWorkflows = await FirebaseFirestore.instance
          .collection('mission_workflows')
          .where('testerId', isEqualTo: testerId)
          .where('currentState', whereIn: ['application_submitted', 'approved', 'in_progress', 'testing_completed', 'settled'])
          .get();

      debugPrint('🔍 ACTIVE_MISSIONS: 총 ${missionWorkflows.docs.length}개 워크플로우 조회됨');

      // 2. 각 미션 워크플로우에 대해 미션 카드 생성
      for (final workflowDoc in missionWorkflows.docs) {
        final workflowData = workflowDoc.data();
        final appId = workflowData['appId'];
        final currentState = workflowData['currentState'] ?? 'pending';

        debugPrint('🔍 WORKFLOW: id=${workflowDoc.id}, appId=$appId, currentState=$currentState');

        // Projects 에서 앱 정보 가져오기 (appId가 projects의 문서 ID이므로)
        try {
          final lookupId = appId.replaceAll('provider_app_', '');
          debugPrint('🔍 PROJECT_LOOKUP: appId=$appId, 찾는 문서=$lookupId');

          final projectDoc = await FirebaseFirestore.instance
              .collection('projects')
              .doc(lookupId)
              .get();

          debugPrint('🔍 PROJECT_LOOKUP: exists=${projectDoc.exists}');

          if (projectDoc.exists) {
            final projectData = projectDoc.data()!;
            final appName = workflowData['appName'] ?? projectData['appName'] ?? 'Unknown App';

            // 미션 카드 생성
            final missionCard = MissionCard(
              id: 'mission_workflow_${workflowDoc.id}', // 고유 ID
              title: '$appName 테스트 미션',
              description: _getStatusDescription(currentState),
              type: MissionType.featureTesting,
              rewardPoints: _getRewardPoints(currentState, workflowData),
              estimatedMinutes: (workflowData['totalDays'] ?? 14) * 20, // 일일 예상 시간
              status: _getMissionStatus(currentState),
              deadline: _getDeadline(workflowData),
              requiredSkills: ['앱테스트', '버그리포트'],
              appName: appName,
              currentParticipants: 1,
              maxParticipants: 1,
              progress: _getProgress(workflowData),
              difficulty: MissionDifficulty.easy,
              providerId: workflowData['providerId'] ?? '',
              isProviderApp: true,
              originalAppData: {
                'workflowId': workflowDoc.id,
                'currentState': currentState,
                'appliedAt': workflowData['appliedAt'],
                'appId': appId,
                'isFromMissionWorkflow': true,
                'currentDay': workflowData['currentDay'] ?? 0,
                'totalDays': workflowData['totalDays'] ?? 14,
                'dailyReward': workflowData['dailyReward'] ?? 5000,
              },
            );

            activeMissions.add(missionCard);
          } else {
            // Fallback: projects 문서가 없을 때도 workflow 데이터로 카드 생성
            debugPrint('❌ PROJECT_NOT_FOUND: appId=$appId의 projects 문서 없음! Fallback으로 카드 생성');

            final appName = workflowData['appName'] ?? 'Unknown App';

            final missionCard = MissionCard(
              id: 'mission_workflow_${workflowDoc.id}',
              title: '$appName 테스트 미션',
              description: _getStatusDescription(currentState),
              type: MissionType.featureTesting,
              rewardPoints: _getRewardPoints(currentState, workflowData),
              estimatedMinutes: (workflowData['totalDays'] ?? 14) * 20,
              status: _getMissionStatus(currentState),
              deadline: _getDeadline(workflowData),
              requiredSkills: ['앱테스트', '버그리포트'],
              appName: appName,
              currentParticipants: 1,
              maxParticipants: 1,
              progress: _getProgress(workflowData),
              difficulty: MissionDifficulty.easy,
              providerId: workflowData['providerId'] ?? '',
              isProviderApp: true,
              originalAppData: {
                'workflowId': workflowDoc.id,
                'currentState': currentState,
                'appliedAt': workflowData['appliedAt'],
                'appId': appId,
                'isFromMissionWorkflow': true,
                'currentDay': workflowData['currentDay'] ?? 0,
                'totalDays': workflowData['totalDays'] ?? 14,
                'dailyReward': workflowData['dailyReward'] ?? 5000,
              },
            );

            activeMissions.add(missionCard);
            debugPrint('✅ FALLBACK_CARD_CREATED: $appName 카드 추가됨');
          }
        } catch (e) {
          debugPrint('Failed to load project data for appId: $appId, error: $e');
        }
      }

      // 3. 정식 할당된 미션들도 가져오기 (mission_assignments에서)
      try {
        final assignedMissions = await FirebaseFirestore.instance
            .collection('mission_assignments')
            .where('testerId', isEqualTo: testerId)
            .where('status', whereIn: ['assigned', 'in_progress'])
            .get();

        for (final assignmentDoc in assignedMissions.docs) {
          final assignmentData = assignmentDoc.data();
          final missionId = assignmentData['missionId'];

          // 미션 정보 가져오기
          final missionDoc = await FirebaseFirestore.instance
              .collection('test_missions')
              .doc(missionId)
              .get();

          if (missionDoc.exists) {
            final missionData = missionDoc.data()!;

            final missionCard = MissionCard(
              id: 'formal_mission_${assignmentDoc.id}',
              title: missionData['title'] ?? 'Test Mission',
              description: missionData['description'] ?? '',
              type: MissionType.functional,
              rewardPoints: 10000, // 정식 미션은 더 높은 보상
              estimatedMinutes: 60,
              status: assignmentData['status'] == 'assigned' ? MissionStatus.active : MissionStatus.inProgress,
              deadline: (missionData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
              requiredSkills: ['미션완료', '리포트제출'],
              appName: 'App Mission', // 앱 이름은 별도로 조회 필요
              currentParticipants: missionData['assignedCount'] ?? 0,
              maxParticipants: missionData['assignedCount'] ?? 0,
              difficulty: MissionDifficulty.medium,
              providerId: assignmentData['appId'] ?? '',
              isProviderApp: false,
              originalAppData: {
                'assignmentId': assignmentDoc.id,
                'missionId': missionId,
                'assignmentStatus': assignmentData['status'],
                'assignedAt': assignmentData['assignedAt'],
                'isFromMissionAssignment': true,
              },
            );

            activeMissions.add(missionCard);
          }
        }
      } catch (e) {
        debugPrint('Failed to load assigned missions: $e');
      }

      return activeMissions;
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
          .collection('mission_workflows')
          .where('testerId', isEqualTo: testerId)
          .get();

      final applications = <MissionApplicationStatus>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        applications.add(MissionApplicationStatus(
          id: doc.id,
          missionId: data['appId'] ?? '', // mission_workflows에서 appId가 missionId 역할
          providerId: data['providerId'] ?? '',
          status: _parseApplicationStatus(data['currentState'] ?? data['status'] ?? 'pending'),
          appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reviewedAt: (data['stateUpdatedAt'] as Timestamp?)?.toDate(),
          message: data['motivation'] ?? '', // 신청 시 동기
          responseMessage: data['finalFeedback'] ?? '', // 최종 피드백
        ));
      }

      // 클라이언트에서 appliedAt 기준으로 정렬 (최신순)
      applications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

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

  // Safe type conversion helper methods
  String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  int? _getIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  double? _getDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  List<String>? _getStringListValue(dynamic value) {
    if (value == null) return null;
    if (value is List<dynamic>) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List<String>) return value;
    return null;
  }

  DateTime? _getDateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // PRD 기준 헬퍼 함수들
  List<String> _getRequiredSkills(Map<String, dynamic> data) {
    final requirements = data['requirements'] as Map<String, dynamic>? ?? {};
    final specializations = requirements['specializations'] as List<dynamic>? ?? [];
    final platforms = requirements['platforms'] as List<dynamic>? ?? [];

    final skills = <String>['앱 테스팅'];
    skills.addAll(specializations.map((s) => s.toString()));
    skills.addAll(platforms.map((p) => p.toString()));

    return skills.take(3).toList(); // 최대 3개로 제한
  }

  MissionDifficulty _parseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return MissionDifficulty.easy;
      case 'hard':
        return MissionDifficulty.hard;
      case 'expert':
        return MissionDifficulty.expert;
      case 'medium':
      default:
        return MissionDifficulty.medium;
    }
  }

  // mission_workflows 특화 헬퍼 메서드들
  String _getStatusDescription(String currentState) {
    switch (currentState) {
      case 'application_submitted':
        return '신청 승인 대기 중입니다. 공급자의 승인을 기다려주세요.';
      case 'approved':
        return '승인되었습니다! 테스트를 시작할 수 있습니다.';
      case 'in_progress':
        return '테스트를 진행해주세요. 앱을 사용하며 버그나 개선사항을 리포트해주세요.';
      case 'completed':
        return '테스트가 완료되었습니다. 수고하셨습니다!';
      case 'rejected':
        return '신청이 거절되었습니다.';
      default:
        return '상태를 확인 중입니다.';
    }
  }

  int _getRewardPoints(String currentState, Map<String, dynamic> workflowData) {
    switch (currentState) {
      case 'application_submitted':
        return 0; // 승인 전에는 0
      case 'approved':
      case 'in_progress':
      case 'completed':
        return (workflowData['totalEarnedReward'] ?? workflowData['dailyReward'] ?? 5000) as int;
      default:
        return 0;
    }
  }

  MissionStatus _getMissionStatus(String currentState) {
    switch (currentState) {
      case 'application_submitted':
        return MissionStatus.draft;
      case 'approved':
      case 'in_progress':
        return MissionStatus.active;
      case 'completed':
        return MissionStatus.completed;
      case 'rejected':
        return MissionStatus.cancelled;
      default:
        return MissionStatus.draft;
    }
  }

  DateTime _getDeadline(Map<String, dynamic> workflowData) {
    final startedAt = workflowData['startedAt'];
    final totalDays = workflowData['totalDays'] ?? 14;

    if (startedAt != null && startedAt is Timestamp) {
      return startedAt.toDate().add(Duration(days: totalDays));
    }

    final appliedAt = workflowData['appliedAt'];
    if (appliedAt != null && appliedAt is Timestamp) {
      return appliedAt.toDate().add(Duration(days: totalDays + 7)); // 승인 기간 추가
    }

    return DateTime.now().add(Duration(days: totalDays));
  }

  double? _getProgress(Map<String, dynamic> workflowData) {
    final currentDay = workflowData['currentDay'] ?? 0;
    final totalDays = workflowData['totalDays'] ?? 14;

    if (totalDays == 0) return 0.0;
    return (currentDay / totalDays * 100).clamp(0.0, 100.0);
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