import 'package:cloud_firestore/cloud_firestore.dart';

// 통합 미션 모델 - 모든 미션 관련 데이터를 단일 모델로 통합
class UnifiedMissionModel {
  final String id;
  final String appId;
  final String appName;
  final String testerId;
  final String testerName;
  final String testerEmail;
  final String providerId;
  final String status; // pending, approved, rejected, in_progress, completed
  final String experience;
  final String motivation;
  final DateTime appliedAt;
  final DateTime? processedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int dailyPoints;
  final int totalPoints;
  final int currentDay;
  final int totalDays;
  final double progressPercentage;
  final bool todayCompleted;
  final Map<String, dynamic> metadata;
  final List<String> requirements;
  final String? feedback;
  final int? rating;

  const UnifiedMissionModel({
    required this.id,
    required this.appId,
    required this.appName,
    required this.testerId,
    required this.testerName,
    required this.testerEmail,
    required this.providerId,
    required this.status,
    required this.experience,
    required this.motivation,
    required this.appliedAt,
    this.processedAt,
    this.startedAt,
    this.completedAt,
    this.dailyPoints = 5000,
    this.totalPoints = 0,
    this.currentDay = 0,
    this.totalDays = 14,
    this.progressPercentage = 0.0,
    this.todayCompleted = false,
    this.metadata = const {},
    this.requirements = const [],
    this.feedback,
    this.rating,
  });

  // 실제 미션 상태 결정 (status와 currentState 우선순위 적용)
  String get actualStatus {
    // 데이터 일관성 처리: status와 currentState가 다를 때 우선순위 적용
    if (status == 'completed' || completedAt != null) {
      return 'completed';
    }
    if (status == 'in_progress' || startedAt != null) {
      return 'in_progress';
    }
    return status;
  }

  // 사용자 친화적 상태 표시
  String get displayStatus {
    switch (actualStatus) {
      case 'pending':
        return '대기중';
      case 'approved':
        return '승인됨';
      case 'rejected':
        return '거절됨';
      case 'in_progress':
        return '진행중';
      case 'completed':
        return '완료됨';
      default:
        return status;
    }
  }

  // Firestore에서 데이터 읽기 (mission_workflows 컬렉션용)
  factory UnifiedMissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // currentState와 status 필드 모두 확인하여 우선순위 적용
    String resolvedStatus = data['status'] ?? 'pending';
    final currentState = data['currentState'] as String?;

    // currentState가 있으면 참고하여 status 보정
    if (currentState != null) {
      if (currentState.contains('completed') || currentState == 'mission_completed') {
        resolvedStatus = 'completed';
      } else if (currentState.contains('progress') || currentState == 'mission_started') {
        resolvedStatus = 'in_progress';
      } else if (currentState == 'application_approved') {
        resolvedStatus = 'approved';
      }
    }

    return UnifiedMissionModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      appName: data['appName'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      providerId: data['providerId'] ?? '',
      status: resolvedStatus,
      experience: data['experience'] ?? '',
      motivation: data['motivation'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      dailyPoints: data['dailyReward'] ?? data['dailyPoints'] ?? 5000,
      totalPoints: data['totalEarnedReward'] ?? data['totalPoints'] ?? 0,
      currentDay: data['currentDay'] ?? 0,
      totalDays: data['totalDays'] ?? 14,
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      todayCompleted: data['todayCompleted'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      requirements: List<String>.from(data['requirements'] ?? []),
      feedback: data['feedback'] ?? data['finalFeedback'],
      rating: data['rating'] ?? data['finalRating'],
    );
  }

  // tester_applications 컬렉션에서 데이터 읽기 (실제 MissionService 구조에 맞춤)
  factory UnifiedMissionModel.fromTesterApplications(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final missionInfo = data['missionInfo'] as Map<String, dynamic>? ?? {};
    final progress = data['progress'] as Map<String, dynamic>? ?? {};

    // Field resolution for tester name - trying multiple field names for compatibility

    // 다양한 필드명 시도하여 테스터 이름 찾기
    String testerName = '테스터 정보 로딩 중...';
    final possibleNameFields = [
      data['testerName'],
      data['name'],
      data['userName'],
      data['displayName'],
      data['userDisplayName'],
      data['userInfo']?['name'],
      data['userInfo']?['displayName'],
      missionInfo['testerName'],
      missionInfo['name'],
    ];

    for (final field in possibleNameFields) {
      if (field != null && field.toString().isNotEmpty && field.toString() != 'null') {
        testerName = field.toString();
        break;
      }
    }

    // 테스터 이메일도 다양한 필드 시도
    String testerEmail = '';
    final possibleEmailFields = [
      data['testerEmail'],
      data['email'],
      data['userEmail'],
      data['userInfo']?['email'],
      missionInfo['testerEmail'],
      missionInfo['email'],
    ];

    for (final field in possibleEmailFields) {
      if (field != null && field.toString().isNotEmpty && field.toString() != 'null') {
        testerEmail = field.toString();
        break;
      }
    }

    return UnifiedMissionModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      appName: data['appName'] ?? missionInfo['appName'] ?? data['missionName'] ?? '앱 정보 로딩 중...',
      testerId: data['testerId'] ?? '',
      testerName: testerName,
      testerEmail: testerEmail,
      providerId: data['providerId'] ?? '',
      status: data['status'] ?? 'pending',
      experience: data['experience'] ?? '',
      motivation: data['motivation'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['statusUpdatedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      dailyPoints: (data['dailyReward'] ?? missionInfo['dailyReward']) ?? 5000,
      totalPoints: (progress['totalPoints'] as int?) ?? 0,
      currentDay: (progress['currentDay'] as int?) ?? 0,
      totalDays: (data['totalDays'] ?? missionInfo['totalDays']) ?? 14,
      progressPercentage: (progress['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      todayCompleted: (progress['todayCompleted'] as bool?) ?? false,
      metadata: Map<String, dynamic>.from(data),
      requirements: List<String>.from((data['requirements'] ?? missionInfo['requirements']) ?? []),
      feedback: progress['latestFeedback'] as String?,
      rating: (progress['averageRating'] as num?)?.toInt(),
    );
  }

  // app_testers 컬렉션에서 데이터 읽기 (확장된 구조 - 기존 호환성)
  factory UnifiedMissionModel.fromAppTesters(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final testerInfo = data['testerInfo'] as Map<String, dynamic>? ?? {};
    final testingProgress = data['testingProgress'] as Map<String, dynamic>? ?? {};
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

    return UnifiedMissionModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      appName: metadata['appName'] ?? '앱 정보 로딩 중...',
      testerId: data['testerId'] ?? '',
      testerName: testerInfo['name'] ?? '테스터 정보 로딩 중...',
      testerEmail: testerInfo['email'] ?? '',
      providerId: data['providerId'] ?? '',
      status: data['status'] ?? 'pending',
      experience: testerInfo['experience'] ?? '',
      motivation: testerInfo['motivation'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      dailyPoints: (metadata['reward'] as int?) ?? 5000,
      totalPoints: (testingProgress['bugsReported'] as int?) ?? 0,
      currentDay: (testingProgress['currentDay'] as int?) ?? 0,
      totalDays: (testingProgress['totalDays'] as int?) ?? 14,
      progressPercentage: _calculateProgress(testingProgress),
      todayCompleted: _checkTodayCompleted(data['dailyInteractions']),
      metadata: Map<String, dynamic>.from(data['deviceInfo'] ?? {}),
      requirements: const [],
      feedback: _getLatestFeedback(data['dailyInteractions']),
      rating: (metadata['finalRating'] as num?)?.toInt(),
    );
  }

  // 진행률 계산 도우미
  static double _calculateProgress(Map<String, dynamic> testingProgress) {
    final currentDay = (testingProgress['currentDay'] as int?) ?? 0;
    final totalDays = (testingProgress['totalDays'] as int?) ?? 14;
    return totalDays > 0 ? (currentDay / totalDays * 100).clamp(0.0, 100.0) : 0.0;
  }

  // 오늘 완료 여부 확인
  static bool _checkTodayCompleted(dynamic dailyInteractions) {
    if (dailyInteractions is! List) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    for (var interaction in dailyInteractions) {
      if (interaction is Map<String, dynamic> &&
          interaction['date'] == today) {
        return interaction['testerSubmitted'] == true;
      }
    }
    return false;
  }

  // 최신 피드백 가져오기
  static String? _getLatestFeedback(dynamic dailyInteractions) {
    if (dailyInteractions is! List || dailyInteractions.isEmpty) return null;

    // 최신순으로 정렬하여 가장 최근 피드백 반환
    final interactions = dailyInteractions
        .whereType<Map<String, dynamic>>()
        .toList();

    interactions.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    for (var interaction in interactions) {
      final feedback = interaction['feedback'] as String?;
      if (feedback != null && feedback.isNotEmpty) {
        return feedback;
      }
    }
    return null;
  }

  // Firestore에 데이터 저장
  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'appName': appName,
      'testerId': testerId,
      'testerName': testerName,
      'testerEmail': testerEmail,
      'providerId': providerId,
      'status': status,
      'experience': experience,
      'motivation': motivation,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'dailyPoints': dailyPoints,
      'totalPoints': totalPoints,
      'currentDay': currentDay,
      'totalDays': totalDays,
      'progressPercentage': progressPercentage,
      'todayCompleted': todayCompleted,
      'metadata': metadata,
      'requirements': requirements,
      'feedback': feedback,
      'rating': rating,
    };
  }

  // 상태별 색상 반환
  MissionStatusColor get statusColor {
    switch (status) {
      case 'pending':
        return MissionStatusColor.orange;
      case 'approved':
      case 'in_progress':
        return MissionStatusColor.blue;
      case 'completed':
        return MissionStatusColor.green;
      case 'rejected':
        return MissionStatusColor.red;
      default:
        return MissionStatusColor.grey;
    }
  }

  // 상태별 텍스트 반환
  String get statusText {
    switch (status) {
      case 'pending':
        return '신청 대기';
      case 'approved':
        return '승인됨';
      case 'in_progress':
        return '진행 중';
      case 'completed':
        return '완료';
      case 'rejected':
        return '거부';
      default:
        return '알 수 없음';
    }
  }

  // 테스터 대시보드용 MissionCard로 변환
  MissionCard toMissionCard() {
    return MissionCard(
      appName: appName,
      currentDay: currentDay,
      totalDays: totalDays,
      dailyPoints: dailyPoints,
      todayCompleted: todayCompleted,
    );
  }

  // 복사본 생성 (불변성 유지)
  UnifiedMissionModel copyWith({
    String? id,
    String? appId,
    String? appName,
    String? testerId,
    String? testerName,
    String? testerEmail,
    String? providerId,
    String? status,
    String? experience,
    String? motivation,
    DateTime? appliedAt,
    DateTime? processedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? dailyPoints,
    int? totalPoints,
    int? currentDay,
    int? totalDays,
    double? progressPercentage,
    bool? todayCompleted,
    Map<String, dynamic>? metadata,
    List<String>? requirements,
    String? feedback,
    int? rating,
  }) {
    return UnifiedMissionModel(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      testerId: testerId ?? this.testerId,
      testerName: testerName ?? this.testerName,
      testerEmail: testerEmail ?? this.testerEmail,
      providerId: providerId ?? this.providerId,
      status: status ?? this.status,
      experience: experience ?? this.experience,
      motivation: motivation ?? this.motivation,
      appliedAt: appliedAt ?? this.appliedAt,
      processedAt: processedAt ?? this.processedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      dailyPoints: dailyPoints ?? this.dailyPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      currentDay: currentDay ?? this.currentDay,
      totalDays: totalDays ?? this.totalDays,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      metadata: metadata ?? this.metadata,
      requirements: requirements ?? this.requirements,
      feedback: feedback ?? this.feedback,
      rating: rating ?? this.rating,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedMissionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          currentDay == other.currentDay &&
          progressPercentage == other.progressPercentage;

  @override
  int get hashCode => id.hashCode ^ status.hashCode ^ currentDay.hashCode;

  @override
  String toString() {
    return 'UnifiedMissionModel{id: $id, appName: $appName, testerName: $testerName, status: $status, progress: $progressPercentage%}';
  }
}

// 상태별 색상 enum
enum MissionStatusColor {
  orange,
  blue,
  green,
  red,
  grey,
}

// 기존 MissionCard 호환성을 위한 클래스
class MissionCard {
  final String appName;
  final int currentDay;
  final int totalDays;
  final int dailyPoints;
  final bool todayCompleted;

  const MissionCard({
    required this.appName,
    required this.currentDay,
    required this.totalDays,
    required this.dailyPoints,
    required this.todayCompleted,
  });
}

// 미션 상태 필터링을 위한 enum
enum MissionStatusFilter {
  all,
  pending,
  approved,
  inProgress,
  completed,
  rejected,
}

// 뷰 타입 구분을 위한 enum
enum MissionViewType {
  tester,    // 테스터 관점
  provider,  // 공급자 관점
}