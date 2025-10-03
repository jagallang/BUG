import 'package:equatable/equatable.dart';

/// Mission Workflow Entity (Domain Layer)
/// 비즈니스 로직의 핵심 엔티티 - Firestore나 다른 구현 세부사항과 독립적
class MissionWorkflowEntity extends Equatable {
  final String id;
  final String appId;
  final String appName;
  final String testerId;
  final String testerName;
  final String testerEmail;
  final String providerId;
  final String providerName;
  final MissionWorkflowStatus status;
  final DateTime appliedAt;
  final DateTime? approvedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String experience;
  final String motivation;
  final int totalDays;
  final int dailyReward;
  final int completedDays;

  const MissionWorkflowEntity({
    required this.id,
    required this.appId,
    required this.appName,
    required this.testerId,
    required this.testerName,
    required this.testerEmail,
    required this.providerId,
    required this.providerName,
    required this.status,
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

  /// 미션이 진행 가능한 상태인지 확인
  bool get canStart => status == MissionWorkflowStatus.approved;

  /// 미션이 진행 중인지 확인
  bool get isInProgress => status == MissionWorkflowStatus.inProgress;

  /// 미션이 완료되었는지 확인
  bool get isCompleted => status == MissionWorkflowStatus.submissionCompleted;

  /// 완료율 계산
  double get completionRate => totalDays > 0 ? completedDays / totalDays : 0.0;

  /// 예상 총 보상 계산
  int get estimatedTotalReward => dailyReward * totalDays;

  MissionWorkflowEntity copyWith({
    String? id,
    String? appId,
    String? appName,
    String? testerId,
    String? testerName,
    String? testerEmail,
    String? providerId,
    String? providerName,
    MissionWorkflowStatus? status,
    DateTime? appliedAt,
    DateTime? approvedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? experience,
    String? motivation,
    int? totalDays,
    int? dailyReward,
    int? completedDays,
  }) {
    return MissionWorkflowEntity(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      testerId: testerId ?? this.testerId,
      testerName: testerName ?? this.testerName,
      testerEmail: testerEmail ?? this.testerEmail,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      experience: experience ?? this.experience,
      motivation: motivation ?? this.motivation,
      totalDays: totalDays ?? this.totalDays,
      dailyReward: dailyReward ?? this.dailyReward,
      completedDays: completedDays ?? this.completedDays,
    );
  }

  @override
  List<Object?> get props => [
        id,
        appId,
        testerId,
        status,
        appliedAt,
        approvedAt,
        startedAt,
        completedAt,
        completedDays,
      ];
}

/// Mission Workflow 상태 (Clean Architecture - UI나 Firestore와 독립적)
enum MissionWorkflowStatus {
  /// 신청 제출됨 (승인 대기)
  applicationSubmitted,

  /// 승인됨 (미션 시작 대기)
  approved,

  /// 미션 진행 중
  inProgress,

  /// 테스트 완료 (제출 대기)
  testingCompleted,

  /// 제출 완료
  submissionCompleted,

  /// 거부됨
  rejected,

  /// 취소됨
  cancelled;

  /// Firestore currentState 문자열로 변환
  String toFirestoreString() {
    switch (this) {
      case MissionWorkflowStatus.applicationSubmitted:
        return 'application_submitted';
      case MissionWorkflowStatus.approved:
        return 'approved';
      case MissionWorkflowStatus.inProgress:
        return 'in_progress';
      case MissionWorkflowStatus.testingCompleted:
        return 'testing_completed';
      case MissionWorkflowStatus.submissionCompleted:
        return 'submission_completed';
      case MissionWorkflowStatus.rejected:
        return 'rejected';
      case MissionWorkflowStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Firestore currentState 문자열에서 변환
  static MissionWorkflowStatus fromFirestoreString(String state) {
    switch (state) {
      case 'application_submitted':
        return MissionWorkflowStatus.applicationSubmitted;
      case 'approved':
        return MissionWorkflowStatus.approved;
      case 'in_progress':
        return MissionWorkflowStatus.inProgress;
      case 'testing_completed':
        return MissionWorkflowStatus.testingCompleted;
      case 'submission_completed':
        return MissionWorkflowStatus.submissionCompleted;
      case 'rejected':
        return MissionWorkflowStatus.rejected;
      case 'cancelled':
        return MissionWorkflowStatus.cancelled;
      default:
        return MissionWorkflowStatus.applicationSubmitted;
    }
  }

  /// UI 표시용 한글 이름
  String get displayName {
    switch (this) {
      case MissionWorkflowStatus.applicationSubmitted:
        return '승인 대기';
      case MissionWorkflowStatus.approved:
        return '승인됨';
      case MissionWorkflowStatus.inProgress:
        return '진행 중';
      case MissionWorkflowStatus.testingCompleted:
        return '테스트 완료';
      case MissionWorkflowStatus.submissionCompleted:
        return '제출 완료';
      case MissionWorkflowStatus.rejected:
        return '거부됨';
      case MissionWorkflowStatus.cancelled:
        return '취소됨';
    }
  }
}
