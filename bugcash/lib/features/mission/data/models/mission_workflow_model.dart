import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/mission_workflow_entity.dart';

/// Mission Workflow Model (Data Layer)
/// Firestore 데이터와 Domain Entity 간 변환
class MissionWorkflowModel {
  final String id;
  final String appId;
  final String appName;
  final String testerId;
  final String testerName;
  final String testerEmail;
  final String providerId;
  final String providerName;
  final String currentState;
  final DateTime appliedAt;
  final DateTime? approvedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String experience;
  final String motivation;
  final int totalDays;
  final int dailyReward;
  final int completedDays;
  final List<DailyMissionInteractionModel> dailyInteractions; // v2.16.0

  const MissionWorkflowModel({
    required this.id,
    required this.appId,
    required this.appName,
    required this.testerId,
    required this.testerName,
    required this.testerEmail,
    required this.providerId,
    required this.providerName,
    required this.currentState,
    required this.appliedAt,
    this.approvedAt,
    this.startedAt,
    this.completedAt,
    required this.experience,
    required this.motivation,
    this.totalDays = 14,
    this.dailyReward = 5000,
    this.completedDays = 0,
    this.dailyInteractions = const [], // v2.16.0
  });

  /// Firestore DocumentSnapshot에서 Model 생성
  factory MissionWorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // v2.16.0: Daily interactions 파싱
    final interactionsList = (data['dailyInteractions'] as List<dynamic>?) ?? [];
    final interactions = interactionsList.map((item) {
      if (item is Map<String, dynamic>) {
        return DailyMissionInteractionModel.fromMap(item);
      }
      return DailyMissionInteractionModel.empty();
    }).toList();

    return MissionWorkflowModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      appName: data['appName'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      currentState: data['currentState'] ?? 'application_submitted',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      experience: data['experience'] ?? '',
      motivation: data['motivation'] ?? '',
      totalDays: data['totalDays'] ?? 14,
      dailyReward: data['dailyReward'] ?? 5000,
      completedDays: data['completedDays'] ?? 0,
      dailyInteractions: interactions, // v2.16.0
    );
  }

  /// Map에서 Model 생성
  factory MissionWorkflowModel.fromMap(Map<String, dynamic> data, String id) {
    return MissionWorkflowModel(
      id: id,
      appId: data['appId'] ?? '',
      appName: data['appName'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      currentState: data['currentState'] ?? 'application_submitted',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      experience: data['experience'] ?? '',
      motivation: data['motivation'] ?? '',
      totalDays: data['totalDays'] ?? 14,
      dailyReward: data['dailyReward'] ?? 5000,
      completedDays: data['completedDays'] ?? 0,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'appName': appName,
      'testerId': testerId,
      'testerName': testerName,
      'testerEmail': testerEmail,
      'providerId': providerId,
      'providerName': providerName,
      'currentState': currentState,
      'appliedAt': Timestamp.fromDate(appliedAt),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'experience': experience,
      'motivation': motivation,
      'totalDays': totalDays,
      'dailyReward': dailyReward,
      'completedDays': completedDays,
      'dailyInteractions': dailyInteractions.map((i) => i.toFirestore()).toList(), // v2.17.2
      'stateUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Model → Entity 변환 (Data Layer → Domain Layer)
  MissionWorkflowEntity toEntity() {
    return MissionWorkflowEntity(
      id: id,
      appId: appId,
      appName: appName,
      testerId: testerId,
      testerName: testerName,
      testerEmail: testerEmail,
      providerId: providerId,
      providerName: providerName,
      status: MissionWorkflowStatus.fromFirestoreString(currentState),
      appliedAt: appliedAt,
      approvedAt: approvedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      experience: experience,
      motivation: motivation,
      totalDays: totalDays,
      dailyReward: dailyReward,
      completedDays: completedDays,
      dailyInteractions: dailyInteractions.map((m) => m.toEntity()).toList(), // v2.16.0
    );
  }

  /// Entity → Model 변환 (Domain Layer → Data Layer)
  factory MissionWorkflowModel.fromEntity(MissionWorkflowEntity entity) {
    return MissionWorkflowModel(
      id: entity.id,
      appId: entity.appId,
      appName: entity.appName,
      testerId: entity.testerId,
      testerName: entity.testerName,
      testerEmail: entity.testerEmail,
      providerId: entity.providerId,
      providerName: entity.providerName,
      currentState: entity.status.toFirestoreString(),
      appliedAt: entity.appliedAt,
      approvedAt: entity.approvedAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      experience: entity.experience,
      motivation: entity.motivation,
      totalDays: entity.totalDays,
      dailyReward: entity.dailyReward,
      completedDays: entity.completedDays,
      dailyInteractions: entity.dailyInteractions.map((e) => DailyMissionInteractionModel.fromEntity(e)).toList(), // v2.16.0
    );
  }
}

/// v2.16.0: Daily Mission Interaction Model (Data Layer)
/// Firestore 데이터와 DailyMissionInteractionEntity 간 변환
class DailyMissionInteractionModel {
  final int dayNumber;
  final DateTime date;
  final bool testerStarted;
  final DateTime? testerStartedAt;
  final bool testerCompleted;
  final DateTime? testerCompletedAt;
  final String? testerFeedback;
  final List<String> testerScreenshots;
  final Map<String, dynamic> testerData;
  final bool providerApproved;
  final DateTime? providerApprovedAt;
  final String? providerFeedback;
  final int? providerRating;
  final int dailyReward;
  final bool rewardPaid;
  final DateTime? rewardPaidAt;

  const DailyMissionInteractionModel({
    required this.dayNumber,
    required this.date,
    this.testerStarted = false,
    this.testerStartedAt,
    this.testerCompleted = false,
    this.testerCompletedAt,
    this.testerFeedback,
    this.testerScreenshots = const [],
    this.testerData = const {},
    this.providerApproved = false,
    this.providerApprovedAt,
    this.providerFeedback,
    this.providerRating,
    this.dailyReward = 5000,
    this.rewardPaid = false,
    this.rewardPaidAt,
  });

  /// Map에서 Model 생성
  factory DailyMissionInteractionModel.fromMap(Map<String, dynamic> data) {
    return DailyMissionInteractionModel(
      dayNumber: data['dayNumber'] ?? 1,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      testerStarted: data['testerStarted'] ?? false,
      testerStartedAt: (data['testerStartedAt'] as Timestamp?)?.toDate(),
      testerCompleted: data['testerCompleted'] ?? false,
      testerCompletedAt: (data['testerCompletedAt'] as Timestamp?)?.toDate(),
      testerFeedback: data['testerFeedback'],
      testerScreenshots: List<String>.from(data['testerScreenshots'] ?? []),
      testerData: Map<String, dynamic>.from(data['testerData'] ?? {}),
      providerApproved: data['providerApproved'] ?? false,
      providerApprovedAt: (data['providerApprovedAt'] as Timestamp?)?.toDate(),
      providerFeedback: data['providerFeedback'],
      providerRating: data['providerRating'],
      dailyReward: data['dailyReward'] ?? 5000,
      rewardPaid: data['rewardPaid'] ?? false,
      rewardPaidAt: (data['rewardPaidAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 빈 Model 생성
  factory DailyMissionInteractionModel.empty() {
    return DailyMissionInteractionModel(
      dayNumber: 1,
      date: DateTime.now(),
    );
  }

  /// Model → Entity 변환
  DailyMissionInteractionEntity toEntity() {
    return DailyMissionInteractionEntity(
      dayNumber: dayNumber,
      date: date,
      testerStarted: testerStarted,
      testerStartedAt: testerStartedAt,
      testerCompleted: testerCompleted,
      testerCompletedAt: testerCompletedAt,
      testerFeedback: testerFeedback,
      testerScreenshots: testerScreenshots,
      testerData: testerData,
      providerApproved: providerApproved,
      providerApprovedAt: providerApprovedAt,
      providerFeedback: providerFeedback,
      providerRating: providerRating,
      dailyReward: dailyReward,
      rewardPaid: rewardPaid,
      rewardPaidAt: rewardPaidAt,
    );
  }

  /// Entity → Model 변환
  factory DailyMissionInteractionModel.fromEntity(DailyMissionInteractionEntity entity) {
    return DailyMissionInteractionModel(
      dayNumber: entity.dayNumber,
      date: entity.date,
      testerStarted: entity.testerStarted,
      testerStartedAt: entity.testerStartedAt,
      testerCompleted: entity.testerCompleted,
      testerCompletedAt: entity.testerCompletedAt,
      testerFeedback: entity.testerFeedback,
      testerScreenshots: entity.testerScreenshots,
      testerData: entity.testerData,
      providerApproved: entity.providerApproved,
      providerApprovedAt: entity.providerApprovedAt,
      providerFeedback: entity.providerFeedback,
      providerRating: entity.providerRating,
      dailyReward: entity.dailyReward,
      rewardPaid: entity.rewardPaid,
      rewardPaidAt: entity.rewardPaidAt,
    );
  }

  /// Model → Firestore Map 변환 (v2.17.2)
  Map<String, dynamic> toFirestore() {
    return {
      'dayNumber': dayNumber,
      'date': Timestamp.fromDate(date),
      'testerStarted': testerStarted,
      if (testerStartedAt != null) 'testerStartedAt': Timestamp.fromDate(testerStartedAt!),
      'testerCompleted': testerCompleted,
      if (testerCompletedAt != null) 'testerCompletedAt': Timestamp.fromDate(testerCompletedAt!),
      if (testerFeedback != null) 'testerFeedback': testerFeedback,
      'testerScreenshots': testerScreenshots,
      'testerData': testerData,
      'providerApproved': providerApproved,
      if (providerApprovedAt != null) 'providerApprovedAt': Timestamp.fromDate(providerApprovedAt!),
      if (providerFeedback != null) 'providerFeedback': providerFeedback,
      if (providerRating != null) 'providerRating': providerRating,
      'dailyReward': dailyReward,
      'rewardPaid': rewardPaid,
      if (rewardPaidAt != null) 'rewardPaidAt': Timestamp.fromDate(rewardPaidAt!),
    };
  }
}
