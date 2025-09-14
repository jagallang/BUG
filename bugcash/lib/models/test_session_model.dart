import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 테스트 세션 상태
enum TestSessionStatus {
  pending,        // 신청 대기
  approved,       // 승인됨 - 테스트 시작 가능
  active,         // 진행 중
  completed,      // 완료
  cancelled,      // 취소
  rejected,       // 거부됨
  paused,         // 일시정지
}

/// 일일 테스트 상태
enum DailyTestStatus {
  pending,        // 대기 중
  submitted,      // 제출됨 - 승인 대기
  approved,       // 승인됨
  rejected,       // 거부됨 - 재제출 필요
  skipped,        // 건너뛰기
}

/// 일일 테스트 진행 상황
class DailyTestProgress extends Equatable {
  final int day;                    // 1-14일차
  final DateTime scheduledDate;     // 예정일
  final DailyTestStatus status;
  final DateTime? submittedAt;      // 제출 시간
  final DateTime? approvedAt;       // 승인 시간
  final String? feedbackFromTester; // 테스터 피드백
  final String? feedbackFromProvider; // 공급자 피드백
  final List<String> screenshots;  // 스크린샷 URLs
  final int testDurationMinutes;    // 테스트 소요 시간
  final Map<String, dynamic> metadata; // 추가 데이터

  const DailyTestProgress({
    required this.day,
    required this.scheduledDate,
    required this.status,
    this.submittedAt,
    this.approvedAt,
    this.feedbackFromTester,
    this.feedbackFromProvider,
    this.screenshots = const [],
    this.testDurationMinutes = 0,
    this.metadata = const {},
  });

  factory DailyTestProgress.fromFirestore(Map<String, dynamic> data) {
    return DailyTestProgress(
      day: data['day'] ?? 1,
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      status: DailyTestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DailyTestStatus.pending,
      ),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      feedbackFromTester: data['feedbackFromTester'],
      feedbackFromProvider: data['feedbackFromProvider'],
      screenshots: List<String>.from(data['screenshots'] ?? []),
      testDurationMinutes: data['testDurationMinutes'] ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'day': day,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status.name,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'feedbackFromTester': feedbackFromTester,
      'feedbackFromProvider': feedbackFromProvider,
      'screenshots': screenshots,
      'testDurationMinutes': testDurationMinutes,
      'metadata': metadata,
    };
  }

  DailyTestProgress copyWith({
    int? day,
    DateTime? scheduledDate,
    DailyTestStatus? status,
    DateTime? submittedAt,
    DateTime? approvedAt,
    String? feedbackFromTester,
    String? feedbackFromProvider,
    List<String>? screenshots,
    int? testDurationMinutes,
    Map<String, dynamic>? metadata,
  }) {
    return DailyTestProgress(
      day: day ?? this.day,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      feedbackFromTester: feedbackFromTester ?? this.feedbackFromTester,
      feedbackFromProvider: feedbackFromProvider ?? this.feedbackFromProvider,
      screenshots: screenshots ?? this.screenshots,
      testDurationMinutes: testDurationMinutes ?? this.testDurationMinutes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    day,
    scheduledDate,
    status,
    submittedAt,
    approvedAt,
    feedbackFromTester,
    feedbackFromProvider,
    screenshots,
    testDurationMinutes,
    metadata,
  ];
}

/// 14일 테스트 세션 모델
class TestSession extends Equatable {
  final String id;
  final String missionId;
  final String testerId;
  final String providerId;
  final String appId;
  final TestSessionStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;        // 테스트 시작일
  final DateTime? completedAt;      // 완료일
  final DateTime? approvedAt;       // 승인일
  final List<DailyTestProgress> dailyProgress; // 14일간의 진행상황
  final int totalRewardPoints;      // 총 보상 포인트
  final int earnedPoints;           // 획득 포인트
  final Map<String, dynamic> sessionMetadata; // 세션 메타데이터

  const TestSession({
    required this.id,
    required this.missionId,
    required this.testerId,
    required this.providerId,
    required this.appId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.approvedAt,
    required this.dailyProgress,
    required this.totalRewardPoints,
    this.earnedPoints = 0,
    this.sessionMetadata = const {},
  });

  factory TestSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestSession(
      id: doc.id,
      missionId: data['missionId'] ?? '',
      testerId: data['testerId'] ?? '',
      providerId: data['providerId'] ?? '',
      appId: data['appId'] ?? '',
      status: TestSessionStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TestSessionStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      dailyProgress: (data['dailyProgress'] as List<dynamic>?)
          ?.map((item) => DailyTestProgress.fromFirestore(
              Map<String, dynamic>.from(item)))
          .toList() ?? [],
      totalRewardPoints: data['totalRewardPoints'] ?? 0,
      earnedPoints: data['earnedPoints'] ?? 0,
      sessionMetadata: Map<String, dynamic>.from(data['sessionMetadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'missionId': missionId,
      'testerId': testerId,
      'providerId': providerId,
      'appId': appId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'dailyProgress': dailyProgress.map((progress) => progress.toFirestore()).toList(),
      'totalRewardPoints': totalRewardPoints,
      'earnedPoints': earnedPoints,
      'sessionMetadata': sessionMetadata,
    };
  }

  /// 진행률 계산 (0.0 ~ 1.0)
  double get progressPercentage {
    if (dailyProgress.isEmpty) return 0.0;

    final completedDays = dailyProgress
        .where((day) => day.status == DailyTestStatus.approved)
        .length;

    return completedDays / dailyProgress.length;
  }

  /// 현재 활성화된 테스트 일차
  int get currentDay {
    if (status != TestSessionStatus.active) return 0;

    final today = DateTime.now();
    final startDate = startedAt ?? createdAt;
    final daysSinceStart = today.difference(startDate).inDays + 1;

    return daysSinceStart > 14 ? 14 : daysSinceStart;
  }

  /// 오늘 테스트해야 할 일차 반환
  DailyTestProgress? get todayTest {
    final currentDayNum = currentDay;
    if (currentDayNum <= 0 || currentDayNum > 14) return null;

    return dailyProgress.firstWhere(
      (day) => day.day == currentDayNum,
      orElse: () => DailyTestProgress(
        day: currentDayNum,
        scheduledDate: DateTime.now(),
        status: DailyTestStatus.pending,
      ),
    );
  }

  /// 완료된 일수
  int get completedDays {
    return dailyProgress
        .where((day) => day.status == DailyTestStatus.approved)
        .length;
  }

  /// 남은 일수
  int get remainingDays {
    return 14 - completedDays;
  }

  TestSession copyWith({
    String? id,
    String? missionId,
    String? testerId,
    String? providerId,
    String? appId,
    TestSessionStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? approvedAt,
    List<DailyTestProgress>? dailyProgress,
    int? totalRewardPoints,
    int? earnedPoints,
    Map<String, dynamic>? sessionMetadata,
  }) {
    return TestSession(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      testerId: testerId ?? this.testerId,
      providerId: providerId ?? this.providerId,
      appId: appId ?? this.appId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      totalRewardPoints: totalRewardPoints ?? this.totalRewardPoints,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      sessionMetadata: sessionMetadata ?? this.sessionMetadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    missionId,
    testerId,
    providerId,
    appId,
    status,
    createdAt,
    startedAt,
    completedAt,
    approvedAt,
    dailyProgress,
    totalRewardPoints,
    earnedPoints,
    sessionMetadata,
  ];
}