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
      
      state = state.copyWith(
        availableMissions: availableMissions,
        activeMissions: activeMissions,
        completedMissions: completedMissions,
      );
    } catch (e) {
      debugPrint('Failed to load missions: $e');
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

  // Real Firestore query methods (replacing mock data generation)
  Future<List<MissionCard>> _getAvailableMissionsFromFirestore() async {
    try {
      AppLogger.debug('🔍 Loading available missions from Firestore...', 'TesterDashboard');
      final missionCards = <MissionCard>[];
      
      // 1. 일반 미션들 가져오기
      final missionsSnapshot = await FirebaseFirestore.instance
          .collection('missions')
          .where('status', isEqualTo: 'active')
          .limit(10)
          .get();
      
      AppLogger.info('📊 Found ${missionsSnapshot.docs.length} regular missions', 'TesterDashboard');
      
      for (final doc in missionsSnapshot.docs) {
        try {
          final data = doc.data();
          final missionCard = MissionCard(
            id: doc.id,
            title: data['title'] ?? '미션 제목',
            description: data['description'] ?? '미션 설명',
            appName: data['company'] ?? '회사명',
            type: _parseMissionType(data['type']),
            rewardPoints: _getIntValue(data['reward']) ?? 0,
            estimatedMinutes: _getIntValue(data['estimatedMinutes']) ?? 60,
            status: MissionStatus.active,
            deadline: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
            requiredSkills: (data['requirements'] as List<dynamic>?)?.cast<String>() ?? ['테스팅'],
            currentParticipants: _getIntValue(data['currentParticipants']) ?? 0,
            maxParticipants: _getIntValue(data['maxParticipants']) ?? 10,
            progress: 0,
            difficulty: MissionDifficulty.medium,
            isProviderApp: false,
            originalAppData: null,
          );
          missionCards.add(missionCard);
        } catch (e) {
          AppLogger.error('❌ Error parsing mission ${doc.id}', 'TesterDashboard', e);
        }
      }
      
      // 2. Provider Apps를 미션으로 변환해서 추가 (활성화된 앱만)
      final providerAppsSnapshot = await FirebaseFirestore.instance
          .collection('provider_apps')
          .limit(20)
          .get();

      AppLogger.info('📱 Found ${providerAppsSnapshot.docs.length} provider apps', 'TesterDashboard');
      AppLogger.info('📱 Document IDs: ${providerAppsSnapshot.docs.map((doc) => doc.id).toList()}', 'TesterDashboard');

      for (final doc in providerAppsSnapshot.docs) {
        try {
          final data = doc.data();
          final appName = data['appName'] ?? 'Unknown App';
          AppLogger.info('🔍 Processing app: ${doc.id}, name: $appName', 'TesterDashboard');
          AppLogger.info('📱 Full data for $appName: ${data.toString()}', 'TesterDashboard');

          final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
          AppLogger.info('📊 Metadata for $appName: ${metadata.toString()}', 'TesterDashboard');

          // 활성화된 앱만 표시 (기본값은 true)
          final isActive = metadata['isActive'];
          AppLogger.info('✅ App $appName (${doc.id}) - isActive: $isActive', 'TesterDashboard');
          if (isActive == false) {
            AppLogger.info('❌ Skipping app $appName (${doc.id}) because isActive is false', 'TesterDashboard');
            continue;
          }

          // appName이 null이거나 비어있는지 확인
          if (data['appName'] == null || data['appName'].toString().isEmpty) {
            AppLogger.info('⚠️ App ${doc.id} has null or empty appName, skipping', 'TesterDashboard');
            continue;
          }

          // 메타데이터에서 단가 정보 가져오기
          final price = metadata['price'] ?? 0;

          final missionCard = MissionCard(
            id: 'provider_app_${doc.id}',
            title: '${data['appName'] ?? '앱'} 테스팅',
            description: data['description'] ?? '앱 테스팅 및 피드백 제공',
            appName: data['appName'] ?? '앱',
            type: MissionType.functional,
            rewardPoints: _getIntValue(price) ?? 5000,
            estimatedMinutes: _getIntValue(metadata['testTime']) ?? 30,
            status: MissionStatus.active,
            deadline: DateTime.now().add(const Duration(days: 30)),
            requiredSkills: ['앱 테스팅', '피드백 작성'],
            currentParticipants: _getIntValue(data['activeTesters']) ?? 0,
            maxParticipants: _getIntValue(metadata['participantCount']) ?? 50,
            progress: 0,
            difficulty: MissionDifficulty.medium,
            isProviderApp: true,
            originalAppData: data,
          );
          missionCards.add(missionCard);
          AppLogger.info('✅ Successfully added mission for app $appName (${doc.id})', 'TesterDashboard');
        } catch (e) {
          AppLogger.error('❌ Error parsing provider app ${doc.id}', 'TesterDashboard', e);
        }
      }
      
      AppLogger.info('✅ Total missions loaded: ${missionCards.length}', 'TesterDashboard');
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