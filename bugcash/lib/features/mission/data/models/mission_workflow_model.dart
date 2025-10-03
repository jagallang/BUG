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
  });

  /// Firestore DocumentSnapshot에서 Model 생성
  factory MissionWorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

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
    );
  }
}
