import 'package:flutter/foundation.dart';
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
  dailyMissionRejected('daily_mission_rejected', '일일 미션 거절'), // v2.22.0

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

  // v2.112.0: 리워드 필드 Deprecated (하위 호환성만 유지)
  final int? dailyReward;
  final bool? rewardPaid;
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
    this.dailyReward, // v2.112.0: Optional
    this.rewardPaid, // v2.112.0: Optional
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
      dailyReward: data['dailyReward'], // v2.112.0: Nullable
      rewardPaid: data['rewardPaid'], // v2.112.0: Nullable
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
  final String? appUrl; // v2.186.37: 앱 설치 링크 (테스터가 미션진행상황 페이지에서 확인)
  final String testerId;
  final String testerName;
  final String testerEmail;
  final String? googleEmail; // v2.186.35: 구글플레이 테스터 등록용 이메일
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
    this.appUrl, // v2.186.37
    required this.testerId,
    required this.testerName,
    required this.testerEmail,
    this.googleEmail, // v2.186.35
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
      appUrl: data['appUrl'], // v2.186.37
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      googleEmail: data['googleEmail'], // v2.186.35
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
      'appUrl': appUrl, // v2.186.37
      'testerId': testerId,
      'testerName': testerName,
      'testerEmail': testerEmail,
      'googleEmail': googleEmail, // v2.186.35
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
    // v2.28.6: currentDay 기반 unlock 확인으로 변경
    debugPrint('🔍 [getDayStatus] dayNumber: $dayNumber');
    debugPrint('   ├─ currentDay: $currentDay');
    debugPrint('   ├─ Total dailyInteractions: ${dailyInteractions.length}');

    try {
      final interaction = dailyInteractions.firstWhere(
        (i) => i.dayNumber == dayNumber,
      );

      debugPrint('   ├─ ✅ Found interaction for Day $dayNumber');
      debugPrint('   │  ├─ testerCompleted: ${interaction.testerCompleted}');
      debugPrint('   │  ├─ providerApproved: ${interaction.providerApproved}');

      // 승인됨
      if (interaction.providerApproved) {
        debugPrint('   └─ 📗 APPROVED');
        return DayStatus.approved;
      }

      // 제출됨 (검토 대기)
      if (interaction.testerCompleted) {
        debugPrint('   └─ 📤 SUBMITTED');
        return DayStatus.submitted;
      }

      // v2.28.6: 공급자가 currentDay를 증가시켜야만 unlock
      // 공급자가 "다음 날 미션 만들기" 버튼 클릭 → currentDay 증가 → unlock
      if (dayNumber > currentDay) {
        debugPrint('   └─ 🔒 LOCKED (v2.28.6 - dayNumber > currentDay)');
        return DayStatus.locked;
      }

      // 이전 Day 승인 확인
      if (isDayUnlocked(dayNumber)) {
        debugPrint('   └─ 🔓 UNLOCKED (dayNumber <= currentDay && prev approved)');
        return DayStatus.unlocked;
      }

      // 잠김
      debugPrint('   └─ 🔒 LOCKED (prev day not approved)');
      return DayStatus.locked;
    } catch (e) {
      // v2.28.3: interaction이 없으면 항상 잠김
      // 공급자가 미션을 생성해야만 dailyInteractions에 추가됨
      // 이전 Day가 승인되었어도, 다음 Day 미션이 생성되기 전까지는 잠김 상태
      debugPrint('   ├─ ❌ No interaction found (catch block)');
      debugPrint('   └─ 🔒 LOCKED (v2.28.3 - no interaction)');
      return DayStatus.locked;
    }
  }
}

/// 일일 미션의 진행 상태
///
/// v2.12.0: 테스터가 각 Day를 진행하면서 거치는 상태 전환
/// v2.186.30: 상태 전환 흐름 및 조건 문서화
///
/// 상태 전환 흐름: locked → unlocked → submitted → approved
enum DayStatus {
  /// 잠김 - 이전 Day가 아직 승인되지 않아 접근 불가
  ///
  /// **조건**:
  /// - 이전 Day의 `providerApproved`가 `false` 또는 `null`
  /// - Day 1이 아니고, 이전 Day가 미승인 상태
  ///
  /// **UI 동작**:
  /// - 잠금 아이콘 표시
  /// - 클릭 불가, 회색 처리
  locked,

  /// 활성화 - 테스터가 미션을 시작하고 제출할 수 있는 상태
  ///
  /// **조건**:
  /// - Day 1인 경우 (첫 번째 미션)
  /// - 이전 Day가 승인된 경우 (`providerApproved == true`)
  ///
  /// **UI 동작**:
  /// - "시작하기" 또는 "제출하기" 버튼 활성화
  /// - 미션 상세 페이지 접근 가능
  unlocked,

  /// 제출됨 - 테스터가 리포트를 제출하고 공급자 검토 대기중
  ///
  /// **조건**:
  /// - `testerCompleted == true`
  /// - `providerApproved == null` (아직 미검토)
  ///
  /// **UI 동작**:
  /// - "검토 대기" 상태 표시
  /// - 노란색/주황색 표시
  /// - 재제출 불가 (공급자 거부 시 unlocked로 복귀)
  submitted,

  /// 승인됨 - 공급자가 검토하고 승인 완료
  ///
  /// **조건**:
  /// - `providerApproved == true`
  /// - 공급자의 승인 처리 완료
  ///
  /// **UI 동작**:
  /// - 체크 아이콘 표시, 녹색 배경
  /// - 다음 Day가 자동으로 `unlocked` 상태로 전환
  /// - 해당 Day 수정 불가
  approved,
}