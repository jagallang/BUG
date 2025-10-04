import 'package:cloud_firestore/cloud_firestore.dart';

/// 미션 워크플로우 상태 정의
enum MissionWorkflowState {
  // 1단계: 미션 신청
  applicationSubmitted('application_submitted', '신청 완료'),
  applicationApproved('application_approved', '신청 승인'),
  applicationRejected('application_rejected', '신청 거부'),

  // 2단계: 일일 미션
  inProgress('in_progress', '미션 진행중'),           // v2.8+ 새 상태
  testingCompleted('testing_completed', '테스트 완료'), // v2.8+ 10분 완료
  missionInProgress('mission_in_progress', '미션 진행중'),
  dailyMissionStarted('daily_mission_started', '일일 미션 시작'),
  dailyMissionCompleted('daily_mission_completed', '일일 미션 완료'),
  dailyMissionApproved('daily_mission_approved', '일일 미션 승인'),

  // 3단계: 프로젝트 완료
  projectCompleted('project_completed', '프로젝트 완료'),
  projectApproved('project_approved', '프로젝트 승인'),
  projectFinalized('project_finalized', '최종 완료'),

  // 특수 상태
  paused('paused', '일시 중지'),
  cancelled('cancelled', '취소됨');

  final String code;
  final String displayName;

  const MissionWorkflowState(this.code, this.displayName);

  static MissionWorkflowState fromCode(String code) {
    // Firebase 실제 데이터 "approved"를 applicationApproved로 매핑
    if (code == 'approved') {
      return MissionWorkflowState.applicationApproved;
    }

    return MissionWorkflowState.values.firstWhere(
      (state) => state.code == code,
      orElse: () => MissionWorkflowState.applicationSubmitted,
    );
  }
}

/// 일일 미션 인터랙션 모델
class DailyMissionInteraction {
  final String id;
  final String missionId;
  final String testerId;
  final String providerId;
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

  const DailyMissionInteraction({
    required this.id,
    required this.missionId,
    required this.testerId,
    required this.providerId,
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

  factory DailyMissionInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyMissionInteraction(
      id: doc.id,
      missionId: data['missionId'] ?? '',
      testerId: data['testerId'] ?? '',
      providerId: data['providerId'] ?? '',
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

  Map<String, dynamic> toFirestore() {
    return {
      'missionId': missionId,
      'testerId': testerId,
      'providerId': providerId,
      'dayNumber': dayNumber,
      'date': Timestamp.fromDate(date),
      'testerStarted': testerStarted,
      'testerStartedAt': testerStartedAt != null ? Timestamp.fromDate(testerStartedAt!) : null,
      'testerCompleted': testerCompleted,
      'testerCompletedAt': testerCompletedAt != null ? Timestamp.fromDate(testerCompletedAt!) : null,
      'testerFeedback': testerFeedback,
      'testerScreenshots': testerScreenshots,
      'testerData': testerData,
      'providerApproved': providerApproved,
      'providerApprovedAt': providerApprovedAt != null ? Timestamp.fromDate(providerApprovedAt!) : null,
      'providerFeedback': providerFeedback,
      'providerRating': providerRating,
      'dailyReward': dailyReward,
      'rewardPaid': rewardPaid,
      'rewardPaidAt': rewardPaidAt != null ? Timestamp.fromDate(rewardPaidAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DailyMissionInteraction copyWith({
    bool? testerStarted,
    DateTime? testerStartedAt,
    bool? testerCompleted,
    DateTime? testerCompletedAt,
    String? testerFeedback,
    List<String>? testerScreenshots,
    Map<String, dynamic>? testerData,
    bool? providerApproved,
    DateTime? providerApprovedAt,
    String? providerFeedback,
    int? providerRating,
    bool? rewardPaid,
    DateTime? rewardPaidAt,
  }) {
    return DailyMissionInteraction(
      id: id,
      missionId: missionId,
      testerId: testerId,
      providerId: providerId,
      dayNumber: dayNumber,
      date: date,
      testerStarted: testerStarted ?? this.testerStarted,
      testerStartedAt: testerStartedAt ?? this.testerStartedAt,
      testerCompleted: testerCompleted ?? this.testerCompleted,
      testerCompletedAt: testerCompletedAt ?? this.testerCompletedAt,
      testerFeedback: testerFeedback ?? this.testerFeedback,
      testerScreenshots: testerScreenshots ?? this.testerScreenshots,
      testerData: testerData ?? this.testerData,
      providerApproved: providerApproved ?? this.providerApproved,
      providerApprovedAt: providerApprovedAt ?? this.providerApprovedAt,
      providerFeedback: providerFeedback ?? this.providerFeedback,
      providerRating: providerRating ?? this.providerRating,
      dailyReward: dailyReward,
      rewardPaid: rewardPaid ?? this.rewardPaid,
      rewardPaidAt: rewardPaidAt ?? this.rewardPaidAt,
    );
  }
}

/// 미션 워크플로우 전체 모델
class MissionWorkflowModel {
  final String id;
  final String appId;
  final String appName;
  final String testerId;
  final String testerName;
  final String testerEmail;
  final String providerId;
  final String providerName;

  // 현재 상태
  final MissionWorkflowState currentState;
  final DateTime stateUpdatedAt;
  final String? stateUpdatedBy;

  // 신청 정보
  final DateTime appliedAt;
  final String experience;
  final String motivation;
  final DateTime? approvedAt;
  final String? approvedBy;

  // 미션 진행 정보
  final DateTime? startedAt;
  final int currentDay;
  final int totalDays;
  final List<DailyMissionInteraction> dailyInteractions;

  // 완료 정보
  final DateTime? completedAt;
  final DateTime? finalizedAt;
  final String? finalFeedback;
  final int? finalRating;

  // 리워드 정보
  final int dailyReward;
  final int totalEarnedReward;
  final int totalPaidReward;

  // 메타데이터
  final Map<String, dynamic> metadata;

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
    required this.stateUpdatedAt,
    this.stateUpdatedBy,
    required this.appliedAt,
    required this.experience,
    required this.motivation,
    this.approvedAt,
    this.approvedBy,
    this.startedAt,
    this.currentDay = 0,
    this.totalDays = 10,  // v2.18.0: 14 → 10 (권장 기본값)
    this.dailyInteractions = const [],
    this.completedAt,
    this.finalizedAt,
    this.finalFeedback,
    this.finalRating,
    this.dailyReward = 5000,
    this.totalEarnedReward = 0,
    this.totalPaidReward = 0,
    this.metadata = const {},
  });

  factory MissionWorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Daily interactions 파싱
    final interactionsList = (data['dailyInteractions'] as List<dynamic>?) ?? [];
    final interactions = interactionsList.map((item) {
      if (item is Map<String, dynamic>) {
        // Firestore 문서가 아닌 Map 데이터로 파싱
        return DailyMissionInteraction(
          id: item['id'] ?? '',
          missionId: item['missionId'] ?? doc.id,
          testerId: item['testerId'] ?? data['testerId'] ?? '',
          providerId: item['providerId'] ?? data['providerId'] ?? '',
          dayNumber: item['dayNumber'] ?? 1,
          date: (item['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          testerStarted: item['testerStarted'] ?? false,
          testerStartedAt: (item['testerStartedAt'] as Timestamp?)?.toDate(),
          testerCompleted: item['testerCompleted'] ?? false,
          testerCompletedAt: (item['testerCompletedAt'] as Timestamp?)?.toDate(),
          testerFeedback: item['testerFeedback'],
          testerScreenshots: List<String>.from(item['testerScreenshots'] ?? []),
          testerData: Map<String, dynamic>.from(item['testerData'] ?? {}),
          providerApproved: item['providerApproved'] ?? false,
          providerApprovedAt: (item['providerApprovedAt'] as Timestamp?)?.toDate(),
          providerFeedback: item['providerFeedback'],
          providerRating: item['providerRating'],
          dailyReward: item['dailyReward'] ?? 5000,
          rewardPaid: item['rewardPaid'] ?? false,
          rewardPaidAt: (item['rewardPaidAt'] as Timestamp?)?.toDate(),
        );
      }
      return null;
    }).whereType<DailyMissionInteraction>().toList();

    return MissionWorkflowModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      appName: data['appName'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      currentState: MissionWorkflowState.fromCode(data['currentState'] ?? 'application_submitted'),
      stateUpdatedAt: (data['stateUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stateUpdatedBy: data['stateUpdatedBy'],
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      experience: data['experience'] ?? '',
      motivation: data['motivation'] ?? '',
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      currentDay: data['currentDay'] ?? 0,
      totalDays: data['totalDays'] ?? 10,  // v2.18.0: 14 → 10
      dailyInteractions: interactions,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      finalizedAt: (data['finalizedAt'] as Timestamp?)?.toDate(),
      finalFeedback: data['finalFeedback'],
      finalRating: data['finalRating'],
      dailyReward: data['dailyReward'] ?? 5000,
      totalEarnedReward: data['totalEarnedReward'] ?? 0,
      totalPaidReward: data['totalPaidReward'] ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'appName': appName,
      'testerId': testerId,
      'testerName': testerName,
      'testerEmail': testerEmail,
      'providerId': providerId,
      'providerName': providerName,
      'currentState': currentState.code,
      'stateUpdatedAt': Timestamp.fromDate(stateUpdatedAt),
      'stateUpdatedBy': stateUpdatedBy,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'experience': experience,
      'motivation': motivation,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'currentDay': currentDay,
      'totalDays': totalDays,
      'dailyInteractions': dailyInteractions.map((i) => i.toFirestore()).toList(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'finalizedAt': finalizedAt != null ? Timestamp.fromDate(finalizedAt!) : null,
      'finalFeedback': finalFeedback,
      'finalRating': finalRating,
      'dailyReward': dailyReward,
      'totalEarnedReward': totalEarnedReward,
      'totalPaidReward': totalPaidReward,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // v2.12.0: 일일 미션 상태 관리 헬퍼 메서드

  /// 특정 Day가 활성화되었는지 확인 (제출 가능 여부)
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

  /// 특정 Day의 현재 상태 조회
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
}

/// v2.12.0: 일일 미션 상태
enum DayStatus {
  locked,     // 잠김 (이전 Day 미완료)
  unlocked,   // 활성화 (제출 가능)
  submitted,  // 제출됨 (검토 대기)
  approved,   // 승인됨
}