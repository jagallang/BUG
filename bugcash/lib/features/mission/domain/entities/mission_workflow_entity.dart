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
  final List<DailyMissionInteractionEntity> dailyInteractions; // v2.16.0

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
    this.totalDays = 10,  // v2.18.0: 14 → 10 (권장 기본값)
    this.dailyReward = 5000,
    this.completedDays = 0,
    this.dailyInteractions = const [], // v2.16.0
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

  /// v2.16.0: 특정 Day가 활성화되었는지 확인 (제출 가능 여부)
  /// Day 1은 항상 활성화, 이후 Day는 이전 Day 승인 시 활성화
  bool isDayUnlocked(int dayNumber) {
    // Day 1은 항상 활성화
    if (dayNumber == 1) return true;

    // 이전 Day 승인 여부 확인
    try {
      final previousDay = dailyInteractions.firstWhere(
        (i) => i.dayNumber == dayNumber - 1,
      );
      return previousDay.providerApproved;
    } catch (e) {
      // 이전 Day interaction이 없으면 잠김
      return false;
    }
  }

  /// v2.16.0: 특정 Day의 현재 상태 조회
  DayStatus getDayStatus(int dayNumber) {
    try {
      final interaction = dailyInteractions.firstWhere(
        (i) => i.dayNumber == dayNumber,
      );

      // 승인됨
      if (interaction.providerApproved) return DayStatus.approved;

      // 제출됨 (검토 대기)
      if (interaction.testerCompleted) return DayStatus.submitted;

      // 활성화 여부 확인
      if (isDayUnlocked(dayNumber)) return DayStatus.unlocked;

      // 잠김
      return DayStatus.locked;
    } catch (e) {
      // interaction이 없는 경우
      if (isDayUnlocked(dayNumber)) return DayStatus.unlocked;
      return DayStatus.locked;
    }
  }

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
    List<DailyMissionInteractionEntity>? dailyInteractions, // v2.16.0
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
      dailyInteractions: dailyInteractions ?? this.dailyInteractions, // v2.16.0
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

  /// v2.22.0: 일일 미션 완료 (공급자 검토 대기)
  dailyMissionCompleted,

  /// v2.25.04: 일일 미션 승인 완료 (다음 날 미션 생성 대기)
  dailyMissionApproved,

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
      case MissionWorkflowStatus.dailyMissionCompleted: // v2.22.0
        return 'daily_mission_completed';
      case MissionWorkflowStatus.dailyMissionApproved: // v2.25.04
        return 'daily_mission_approved';
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
      case 'mission_in_progress': // v2.110.1: MissionWorkflowService에서 설정하는 상태 매핑
        return MissionWorkflowStatus.inProgress;
      case 'daily_mission_started': // v2.35.1: Day 진행 중 상태 매핑
        return MissionWorkflowStatus.inProgress;
      case 'testing_completed':
        return MissionWorkflowStatus.testingCompleted;
      case 'daily_mission_completed': // v2.22.0
        return MissionWorkflowStatus.dailyMissionCompleted;
      case 'daily_mission_approved': // v2.25.04
        return MissionWorkflowStatus.dailyMissionApproved;
      case 'submission_completed':
        return MissionWorkflowStatus.submissionCompleted;
      case 'project_completed': // v2.40.0: 최종 완료 상태 (Day 10까지 모두 승인 완료)
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
      case MissionWorkflowStatus.dailyMissionCompleted: // v2.22.0
        return '검토 대기';
      case MissionWorkflowStatus.dailyMissionApproved: // v2.25.04
        return '검토 완료'; // v2.37.0: "승인 완료" → "검토 완료" (명확성 향상 + 중복 회피)
      case MissionWorkflowStatus.submissionCompleted:
        return '제출 완료';
      case MissionWorkflowStatus.rejected:
        return '거부됨';
      case MissionWorkflowStatus.cancelled:
        return '취소됨';
    }
  }
}

/// v2.16.0: Daily Mission Interaction Entity (Domain Layer)
/// 일일 미션 진행 상황을 나타내는 엔티티
class DailyMissionInteractionEntity extends Equatable {
  final int dayNumber;
  final DateTime date;

  // 테스터 액션
  final bool testerStarted;
  final DateTime? testerStartedAt;
  final bool testerCompleted;
  final DateTime? testerCompletedAt;
  final String? testerFeedback;
  final List<String> testerScreenshots;
  final Map<String, dynamic> testerData;

  // 공급자 액션
  final bool providerApproved;
  final DateTime? providerApprovedAt;
  final String? providerFeedback;
  final int? providerRating;

  // 리워드
  final int dailyReward;
  final bool rewardPaid;
  final DateTime? rewardPaidAt;

  const DailyMissionInteractionEntity({
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

  @override
  List<Object?> get props => [
        dayNumber,
        date,
        testerCompleted,
        providerApproved,
        rewardPaid,
      ];
}

/// v2.16.0: Daily Mission 상태
/// 일일 미션의 현재 진행 상태를 나타냄
enum DayStatus {
  /// 잠김 (이전 날짜 미완료)
  locked,

  /// 활성화 (제출 가능)
  unlocked,

  /// 제출됨 (검토 대기)
  submitted,

  /// 승인됨
  approved,
}
