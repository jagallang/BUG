import 'package:cloud_firestore/cloud_firestore.dart';

/// 미션 관리 페이즈 (공급자 기준)
enum MissionPhase {
  testerRecruitment, // 앱테스터 모집
  dailyMissions,     // 오늘미션 관리
  completedMissions, // 완료미션 관리
  settlement,        // 정산
}

/// 일일 미션 상태
enum DailyMissionStatus {
  pending,       // 대기중
  inProgress,    // 진행중
  completed,     // 완료 요청
  approved,      // 승인됨
  rejected,      // 거부됨
}

/// 테스터 신청 상태
enum TesterApplicationStatus {
  pending,   // 대기중
  approved,  // 승인됨
  rejected,  // 거부됨
}

/// 미션 관리 메인 모델
class MissionManagementModel {
  final String id;
  final String appId;
  final String providerId;
  final MissionPhase currentPhase;
  final bool isActive;
  final DateTime startDate;
  final int testPeriodDays;
  final DateTime? endDate;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  MissionManagementModel({
    required this.id,
    required this.appId,
    required this.providerId,
    required this.currentPhase,
    required this.isActive,
    required this.startDate,
    this.testPeriodDays = 14,
    this.endDate,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory MissionManagementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionManagementModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      providerId: data['providerId'] ?? '',
      currentPhase: MissionPhase.values.firstWhere(
        (phase) => phase.name == data['currentPhase'],
        orElse: () => MissionPhase.testerRecruitment,
      ),
      isActive: data['isActive'] ?? false,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      testPeriodDays: data['testPeriodDays'] ?? 14,
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      settings: data['settings'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'providerId': providerId,
      'currentPhase': currentPhase.name,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'testPeriodDays': testPeriodDays,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MissionManagementModel copyWith({
    String? id,
    String? appId,
    String? providerId,
    MissionPhase? currentPhase,
    bool? isActive,
    DateTime? startDate,
    int? testPeriodDays,
    DateTime? endDate,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MissionManagementModel(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      providerId: providerId ?? this.providerId,
      currentPhase: currentPhase ?? this.currentPhase,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      testPeriodDays: testPeriodDays ?? this.testPeriodDays,
      endDate: endDate ?? this.endDate,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 14일이 완료되었는지 확인
  bool get isTestPeriodCompleted {
    final endDateCalculated = endDate ?? startDate.add(Duration(days: testPeriodDays));
    return DateTime.now().isAfter(endDateCalculated);
  }

  /// 현재 진행 일수
  int get currentDays {
    return DateTime.now().difference(startDate).inDays + 1;
  }

  /// 남은 일수
  int get remainingDays {
    final endDateCalculated = endDate ?? startDate.add(Duration(days: testPeriodDays));
    final remaining = endDateCalculated.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }
}

/// 테스터 신청 모델
class TesterApplicationModel {
  final String id;
  final String appId;
  final String testerId;
  final String testerName;
  final String testerEmail;
  final TesterApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final Map<String, dynamic> testerProfile;

  TesterApplicationModel({
    required this.id,
    required this.appId,
    required this.testerId,
    required this.testerName,
    required this.testerEmail,
    required this.status,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewNote,
    this.testerProfile = const {},
  });

  factory TesterApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TesterApplicationModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      status: TesterApplicationStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => TesterApplicationStatus.pending,
      ),
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewNote: data['reviewNote'],
      testerProfile: data['testerProfile'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'testerId': testerId,
      'testerName': testerName,
      'testerEmail': testerEmail,
      'status': status.name,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNote': reviewNote,
      'testerProfile': testerProfile,
    };
  }
}

/// 일일 미션 모델
class DailyMissionModel {
  final String id;
  final String appId;
  final String testerId;
  final DateTime missionDate;
  final DailyMissionStatus status;
  final String missionTitle;
  final String missionDescription;
  final int baseReward;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final String? completionNote;
  final String? reviewNote;
  final List<String> attachments;

  // 워크플로우 연동 필드
  final String? workflowId;
  final int? dayNumber;
  final String? currentState; // mission_workflows의 실제 currentState (application_submitted, approved, mission_in_progress 등)

  // v2.10.0: 일련번호 시스템
  final String? serialNumber; // 형식: a{YYMMDD}-m{0001} 예: a251002-m0001

  // 삭제 관련 필드
  final String? deletionReason;
  final DateTime? deletedAt;
  final bool deletionAcknowledged;

  DailyMissionModel({
    required this.id,
    required this.appId,
    required this.testerId,
    required this.missionDate,
    required this.status,
    required this.missionTitle,
    required this.missionDescription,
    required this.baseReward,
    this.startedAt,
    this.completedAt,
    this.approvedAt,
    this.completionNote,
    this.reviewNote,
    this.attachments = const [],
    this.workflowId,
    this.dayNumber,
    this.currentState,
    this.serialNumber, // v2.10.0
    this.deletionReason,
    this.deletedAt,
    this.deletionAcknowledged = false,
  });

  factory DailyMissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyMissionModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      testerId: data['testerId'] ?? '',
      missionDate: (data['missionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DailyMissionStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => DailyMissionStatus.pending,
      ),
      missionTitle: data['missionTitle'] ?? '',
      missionDescription: data['missionDescription'] ?? '',
      baseReward: data['baseReward'] ?? 0,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      completionNote: data['completionNote'],
      reviewNote: data['reviewNote'],
      attachments: List<String>.from(data['attachments'] ?? []),
      workflowId: data['workflowId'],
      dayNumber: data['dayNumber'],
      currentState: data['currentState'],
      serialNumber: data['serialNumber'], // v2.10.0: 기존 데이터는 null
      deletionReason: data['deletionReason'],
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletionAcknowledged: data['deletionAcknowledged'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'testerId': testerId,
      'missionDate': Timestamp.fromDate(missionDate),
      'status': status.name,
      'missionTitle': missionTitle,
      'missionDescription': missionDescription,
      'baseReward': baseReward,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'completionNote': completionNote,
      'reviewNote': reviewNote,
      'attachments': attachments,
      'workflowId': workflowId,
      'dayNumber': dayNumber,
      'currentState': currentState,
      if (serialNumber != null) 'serialNumber': serialNumber, // v2.10.0: null이 아닐 때만 저장
      'deletionReason': deletionReason,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletionAcknowledged': deletionAcknowledged,
    };
  }

  /// 오늘 미션인지 확인
  bool get isToday {
    final today = DateTime.now();
    return missionDate.year == today.year &&
           missionDate.month == today.month &&
           missionDate.day == today.day;
  }

  /// 완료된 미션인지 확인
  bool get isCompleted {
    return status == DailyMissionStatus.approved;
  }
}

/// 정산 모델
class MissionSettlementModel {
  final String id;
  final String appId;
  final String testerId;
  final String testerName;
  final int totalDays;
  final int completedMissions;
  final int totalBaseReward;
  final int bonusReward;
  final int finalAmount;
  final bool isPaid;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? paymentNote;
  final DateTime calculatedAt;

  MissionSettlementModel({
    required this.id,
    required this.appId,
    required this.testerId,
    required this.testerName,
    required this.totalDays,
    required this.completedMissions,
    required this.totalBaseReward,
    required this.bonusReward,
    required this.finalAmount,
    required this.isPaid,
    this.paidAt,
    this.paymentMethod,
    this.paymentNote,
    required this.calculatedAt,
  });

  factory MissionSettlementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionSettlementModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      totalDays: data['totalDays'] ?? 0,
      completedMissions: data['completedMissions'] ?? 0,
      totalBaseReward: data['totalBaseReward'] ?? 0,
      bonusReward: data['bonusReward'] ?? 0,
      finalAmount: data['finalAmount'] ?? 0,
      isPaid: data['isPaid'] ?? false,
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'],
      paymentNote: data['paymentNote'],
      calculatedAt: (data['calculatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'testerId': testerId,
      'testerName': testerName,
      'totalDays': totalDays,
      'completedMissions': completedMissions,
      'totalBaseReward': totalBaseReward,
      'bonusReward': bonusReward,
      'finalAmount': finalAmount,
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paymentMethod': paymentMethod,
      'paymentNote': paymentNote,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
    };
  }

  /// 완료율 계산
  double get completionRate {
    return totalDays > 0 ? (completedMissions / totalDays) : 0.0;
  }
}

/// 미션 삭제 모델
class MissionDeletionModel {
  final String deletionId;
  final String workflowId;
  final String testerId;
  final String testerName;
  final String providerId;
  final String appId;
  final String appName;
  final String missionTitle;
  final int dayNumber;
  final String deletionReason;
  final DateTime deletedAt;
  final bool providerAcknowledged;
  final DateTime? acknowledgedAt;

  MissionDeletionModel({
    required this.deletionId,
    required this.workflowId,
    required this.testerId,
    required this.testerName,
    required this.providerId,
    required this.appId,
    required this.appName,
    required this.missionTitle,
    required this.dayNumber,
    required this.deletionReason,
    required this.deletedAt,
    this.providerAcknowledged = false,
    this.acknowledgedAt,
  });

  factory MissionDeletionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionDeletionModel(
      deletionId: doc.id,
      workflowId: data['workflowId'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      providerId: data['providerId'] ?? '',
      appId: data['appId'] ?? '',
      appName: data['appName'] ?? '',
      missionTitle: data['missionTitle'] ?? '',
      dayNumber: data['dayNumber'] ?? 0,
      deletionReason: data['deletionReason'] ?? '',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      providerAcknowledged: data['providerAcknowledged'] ?? false,
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowId': workflowId,
      'testerId': testerId,
      'testerName': testerName,
      'providerId': providerId,
      'appId': appId,
      'appName': appName,
      'missionTitle': missionTitle,
      'dayNumber': dayNumber,
      'deletionReason': deletionReason,
      'deletedAt': Timestamp.fromDate(deletedAt),
      'providerAcknowledged': providerAcknowledged,
      'acknowledgedAt': acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
    };
  }
}