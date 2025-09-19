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

  // Firestore에서 데이터 읽기
  factory UnifiedMissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnifiedMissionModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      appName: data['appName'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      providerId: data['providerId'] ?? '',
      status: data['status'] ?? 'pending',
      experience: data['experience'] ?? '',
      motivation: data['motivation'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      dailyPoints: data['dailyPoints'] ?? 5000,
      totalPoints: data['totalPoints'] ?? 0,
      currentDay: data['currentDay'] ?? 0,
      totalDays: data['totalDays'] ?? 14,
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      todayCompleted: data['todayCompleted'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      requirements: List<String>.from(data['requirements'] ?? []),
      feedback: data['feedback'],
      rating: data['rating'],
    );
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