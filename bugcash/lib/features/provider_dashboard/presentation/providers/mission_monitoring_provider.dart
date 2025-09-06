import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/mission_model.dart';

// Mission Status Enum
enum MissionStatus {
  draft,
  active,
  inProgress,
  review,
  completed,
  cancelled,
}

// Mission Monitoring State
class MissionMonitoringState {
  final List<MissionMonitoringData> missions;
  final bool isLoading;
  final String? error;
  final bool isAutoRefreshEnabled;
  final DateTime? lastUpdated;
  final Map<String, MissionStatistics> statistics;

  MissionMonitoringState({
    required this.missions,
    required this.isLoading,
    this.error,
    required this.isAutoRefreshEnabled,
    this.lastUpdated,
    required this.statistics,
  });

  factory MissionMonitoringState.initial() {
    return MissionMonitoringState(
      missions: [],
      isLoading: false,
      isAutoRefreshEnabled: true,
      statistics: {},
    );
  }

  MissionMonitoringState copyWith({
    List<MissionMonitoringData>? missions,
    bool? isLoading,
    String? error,
    bool? isAutoRefreshEnabled,
    DateTime? lastUpdated,
    Map<String, MissionStatistics>? statistics,
  }) {
    return MissionMonitoringState(
      missions: missions ?? this.missions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAutoRefreshEnabled: isAutoRefreshEnabled ?? this.isAutoRefreshEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      statistics: statistics ?? this.statistics,
    );
  }
}

// Mission Monitoring Data Model
class MissionMonitoringData {
  final String id;
  final String title;
  final MissionStatus status;
  final int totalParticipants;
  final int activeParticipants;
  final int completedCount;
  final int pendingReviews;
  final double progressPercentage;
  final DateTime createdAt;
  final DateTime? deadline;
  final int rewardPoints;
  final MissionType type;

  MissionMonitoringData({
    required this.id,
    required this.title,
    required this.status,
    required this.totalParticipants,
    required this.activeParticipants,
    required this.completedCount,
    required this.pendingReviews,
    required this.progressPercentage,
    required this.createdAt,
    this.deadline,
    required this.rewardPoints,
    required this.type,
  });
}

// Mission Statistics Model
class MissionStatistics {
  final int totalSubmissions;
  final int approvedSubmissions;
  final int rejectedSubmissions;
  final double averageCompletionTime;
  final double averageQualityScore;
  final List<HourlyActivity> hourlyActivity;
  final Map<String, int> issueTypeDistribution;
  final List<TesterPerformance> topPerformers;

  MissionStatistics({
    required this.totalSubmissions,
    required this.approvedSubmissions,
    required this.rejectedSubmissions,
    required this.averageCompletionTime,
    required this.averageQualityScore,
    required this.hourlyActivity,
    required this.issueTypeDistribution,
    required this.topPerformers,
  });
}

// Hourly Activity Model
class HourlyActivity {
  final DateTime hour;
  final int submissions;
  final int reviews;
  final int approvals;

  HourlyActivity({
    required this.hour,
    required this.submissions,
    required this.reviews,
    required this.approvals,
  });
}

// Tester Performance Model
class TesterPerformance {
  final String testerId;
  final String testerName;
  final int submissionsCount;
  final double qualityScore;
  final double completionRate;
  final Duration averageTime;

  TesterPerformance({
    required this.testerId,
    required this.testerName,
    required this.submissionsCount,
    required this.qualityScore,
    required this.completionRate,
    required this.averageTime,
  });
}

// Mission Monitoring Provider
final missionMonitoringProvider = 
    StateNotifierProvider<MissionMonitoringNotifier, MissionMonitoringState>((ref) {
  return MissionMonitoringNotifier(ref);
});

class MissionMonitoringNotifier extends StateNotifier<MissionMonitoringState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _refreshTimer;
  StreamSubscription? _missionSubscription;

  MissionMonitoringNotifier(this._ref) : super(MissionMonitoringState.initial()) {
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _missionSubscription?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    if (state.isAutoRefreshEnabled) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (state.isAutoRefreshEnabled) {
          refreshData();
        }
      });
    }
  }

  void toggleAutoRefresh() {
    state = state.copyWith(isAutoRefreshEnabled: !state.isAutoRefreshEnabled);
    if (state.isAutoRefreshEnabled) {
      _startAutoRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  Future<void> loadMissions(String providerId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Subscribe to real-time updates
      _missionSubscription?.cancel();
      _missionSubscription = _firestore
          .collection('missions')
          .where('providerId', isEqualTo: providerId)
          .snapshots()
          .listen((snapshot) {
        final missions = snapshot.docs.map((doc) {
          final data = doc.data();
          return _createMissionMonitoringData(doc.id, data);
        }).toList();

        // Sort by creation date (newest first)
        missions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        state = state.copyWith(
          missions: missions,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );

        // Load statistics for active missions
        for (final mission in missions.where((m) => 
            m.status == MissionStatus.active || 
            m.status == MissionStatus.inProgress)) {
          _loadMissionStatistics(mission.id);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '미션 데이터를 불러오는데 실패했습니다: $e',
      );
    }
  }

  MissionMonitoringData _createMissionMonitoringData(String id, Map<String, dynamic> data) {
    // Mock data for demonstration - replace with actual data parsing
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    return MissionMonitoringData(
      id: id,
      title: data['title'] ?? 'Mission $id',
      status: _parseStatus(data['status'] ?? 'active'),
      totalParticipants: data['maxParticipants'] ?? 10,
      activeParticipants: (random % 8) + 1,
      completedCount: random % 5,
      pendingReviews: random % 3,
      progressPercentage: (random % 100) / 100,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      rewardPoints: data['rewardPoints'] ?? 100,
      type: _parseMissionType(data['type'] ?? 'bugReport'),
    );
  }

  MissionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return MissionStatus.draft;
      case 'active':
        return MissionStatus.active;
      case 'inprogress':
      case 'in_progress':
        return MissionStatus.inProgress;
      case 'review':
        return MissionStatus.review;
      case 'completed':
        return MissionStatus.completed;
      case 'cancelled':
        return MissionStatus.cancelled;
      default:
        return MissionStatus.active;
    }
  }

  MissionType _parseMissionType(String type) {
    switch (type) {
      case 'bugReport':
        return MissionType.bugReport;
      case 'featureTesting':
        return MissionType.featureTesting;
      case 'usabilityTest':
        return MissionType.usabilityTest;
      case 'performanceTest':
        return MissionType.performanceTest;
      case 'survey':
        return MissionType.survey;
      case 'feedback':
        return MissionType.feedback;
      default:
        return MissionType.bugReport;
    }
  }

  Future<void> _loadMissionStatistics(String missionId) async {
    try {
      // Mock statistics data - replace with actual Firestore queries
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      
      final statistics = MissionStatistics(
        totalSubmissions: 15 + (random % 30),
        approvedSubmissions: 10 + (random % 20),
        rejectedSubmissions: random % 5,
        averageCompletionTime: 25.5 + (random % 20),
        averageQualityScore: 0.7 + (random % 30) / 100,
        hourlyActivity: _generateHourlyActivity(),
        issueTypeDistribution: {
          'UI/UX': 5 + (random % 10),
          'Crash': 2 + (random % 5),
          'Performance': 3 + (random % 8),
          'Feature': 4 + (random % 6),
          'Other': 1 + (random % 3),
        },
        topPerformers: _generateTopPerformers(),
      );

      final updatedStats = Map<String, MissionStatistics>.from(state.statistics);
      updatedStats[missionId] = statistics;
      
      state = state.copyWith(statistics: updatedStats);
    } catch (e) {
      debugPrint('Failed to load statistics for mission $missionId: $e');
    }
  }

  List<HourlyActivity> _generateHourlyActivity() {
    final activities = <HourlyActivity>[];
    final now = DateTime.now();
    
    for (int i = 23; i >= 0; i--) {
      final hour = now.subtract(Duration(hours: i));
      final random = hour.millisecondsSinceEpoch % 10;
      
      activities.add(HourlyActivity(
        hour: hour,
        submissions: random,
        reviews: (random * 0.7).round(),
        approvals: (random * 0.5).round(),
      ));
    }
    
    return activities;
  }

  List<TesterPerformance> _generateTopPerformers() {
    final performers = <TesterPerformance>[];
    final names = ['김철수', '이영희', '박민수', '정수진', '최동훈'];
    
    for (int i = 0; i < 5; i++) {
      performers.add(TesterPerformance(
        testerId: 'tester_${i + 1}',
        testerName: names[i],
        submissionsCount: 10 - i * 2,
        qualityScore: 0.95 - (i * 0.05),
        completionRate: 1.0 - (i * 0.1),
        averageTime: Duration(minutes: 20 + i * 5),
      ));
    }
    
    return performers;
  }

  void selectMission(String missionId) {
    // Load detailed statistics for the selected mission
    _loadMissionStatistics(missionId);
  }

  Future<void> refreshData() async {
    if (state.missions.isNotEmpty) {
      final providerId = state.missions.first.id; // This should be the actual provider ID
      await loadMissions(providerId);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}