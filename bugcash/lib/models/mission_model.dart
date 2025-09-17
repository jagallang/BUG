import 'package:cloud_firestore/cloud_firestore.dart';

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

enum MissionStatus {
  draft,
  active,
  inProgress,
  completed,
  paused,
  cancelled,
}

enum MissionType {
  bugReport,      // 버그 리포트
  featureTesting, // 기능 테스트
  usabilityTest,  // 사용성 테스트
  performanceTest, // 성능 테스트
  performance,     // 성능 테스트 (별칭)
  survey,         // 설문조사
  feedback,       // 피드백 수집
  functional,     // 기능 테스트 (featureTesting과 통합 가능)
  uiUx,          // UI/UX 테스트
  security,      // 보안 테스트
  compatibility, // 호환성 테스트
  accessibility, // 접근성 테스트
  localization,  // 지역화 테스트
}

enum MissionDifficulty {
  easy,
  medium,
  hard,
  expert,
}

enum MissionPriority {
  low,      // 낮음
  medium,   // 보통
  high,     // 높음
  urgent,   // 긴급
}

enum MissionComplexity {
  easy,     // 쉬움
  medium,   // 보통
  hard,     // 어려움
  expert,   // 전문가
}

class MissionModel {
  final String id;
  final String title;
  final String appName;
  final String category;
  final String status;
  final int testers;
  final int maxTesters;
  final int reward;
  final String description;
  final List<String> requirements;
  final int duration;
  final DateTime? createdAt;
  final String createdBy;
  final int bugs;
  final bool isHot;
  final bool isNew;

  MissionModel({
    required this.id,
    required this.title,
    required this.appName,
    required this.category,
    required this.status,
    required this.testers,
    required this.maxTesters,
    required this.reward,
    required this.description,
    required this.requirements,
    required this.duration,
    this.createdAt,
    required this.createdBy,
    required this.bugs,
    required this.isHot,
    required this.isNew,
  });

  factory MissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionModel(
      id: doc.id,
      title: data['title'] ?? '',
      appName: data['appName'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'draft',
      testers: data['testers'] ?? 0,
      maxTesters: data['maxTesters'] ?? 0,
      reward: data['reward'] ?? 0,
      description: data['description'] ?? '',
      requirements: List<String>.from(data['requirements'] ?? []),
      duration: data['duration'] ?? 7,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      bugs: data['bugs'] ?? 0,
      isHot: data['isHot'] ?? false,
      isNew: data['isNew'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'appName': appName,
      'category': category,
      'status': status,
      'testers': testers,
      'maxTesters': maxTesters,
      'reward': reward,
      'description': description,
      'requirements': requirements,
      'duration': duration,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'bugs': bugs,
      'isHot': isHot,
      'isNew': isNew,
    };
  }

  MissionModel copyWith({
    String? id,
    String? title,
    String? appName,
    String? category,
    String? status,
    int? testers,
    int? maxTesters,
    int? reward,
    String? description,
    List<String>? requirements,
    int? duration,
    DateTime? createdAt,
    String? createdBy,
    int? bugs,
    bool? isHot,
    bool? isNew,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      appName: appName ?? this.appName,
      category: category ?? this.category,
      status: status ?? this.status,
      testers: testers ?? this.testers,
      maxTesters: maxTesters ?? this.maxTesters,
      reward: reward ?? this.reward,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      bugs: bugs ?? this.bugs,
      isHot: isHot ?? this.isHot,
      isNew: isNew ?? this.isNew,
    );
  }

  factory MissionModel.fromMap(String id, Map<String, dynamic> data) {
    return MissionModel(
      id: id,
      title: data['title'] ?? '',
      appName: data['appName'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'draft',
      testers: data['testers'] ?? 0,
      maxTesters: data['maxTesters'] ?? 10,
      reward: data['reward'] ?? 0,
      requirements: List<String>.from(data['requirements'] ?? []),
      duration: data['duration'] ?? 7,
      createdAt: data['createdAt'] is String 
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      bugs: data['bugs'] ?? 0,
      isHot: data['isHot'] ?? false,
      isNew: data['isNew'] ?? true,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int points;
  final String level;
  final int completedMissions;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.points,
    required this.level,
    required this.completedMissions,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      points: data['points'] ?? 0,
      level: data['level'] ?? 'bronze',
      completedMissions: data['completedMissions'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'points': points,
      'level': level,
      'completedMissions': completedMissions,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

// Extended Mission class for Firestore integration
class Mission {
  final String id;
  final String providerId;
  final String appId;
  final String title;
  final String description;
  final MissionType type;
  final MissionPriority priority;
  final MissionComplexity complexity;
  final MissionDifficulty difficulty;
  final MissionStatus status;
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? participation;
  final Map<String, dynamic>? timeline;
  final Map<String, dynamic>? rewards;
  final List<Map<String, dynamic>>? attachments;
  final Map<String, dynamic>? testingGuidelines;
  final Map<String, dynamic>? analytics;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? completedAt;

  const Mission({
    required this.id,
    required this.providerId,
    required this.appId,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.complexity,
    required this.difficulty,
    required this.status,
    this.requirements,
    this.participation,
    this.timeline,
    this.rewards,
    this.attachments,
    this.testingGuidelines,
    this.analytics,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.completedAt,
  });

  factory Mission.fromFirestore(Map<String, dynamic> data) {
    return Mission(
      id: data['id'] ?? '',
      providerId: data['providerId'] ?? '',
      appId: data['appId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: MissionType.values.byName(data['type'] ?? 'functional'),
      priority: MissionPriority.values.byName(data['priority'] ?? 'medium'),
      complexity: MissionComplexity.values.byName(data['complexity'] ?? 'medium'),
      difficulty: MissionDifficulty.values.byName(data['difficulty'] ?? 'medium'),
      status: MissionStatus.values.byName(data['status'] ?? 'draft'),
      requirements: data['requirements'] as Map<String, dynamic>?,
      participation: data['participation'] as Map<String, dynamic>?,
      timeline: data['timeline'] as Map<String, dynamic>?,
      rewards: data['rewards'] as Map<String, dynamic>?,
      attachments: data['attachments'] != null 
          ? List<Map<String, dynamic>>.from(data['attachments'])
          : null,
      testingGuidelines: data['testingGuidelines'] as Map<String, dynamic>?,
      analytics: data['analytics'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      publishedAt: data['publishedAt'] != null 
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'appId': appId,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'complexity': complexity.name,
      'difficulty': difficulty.name,
      'status': status.name,
      'requirements': requirements,
      'participation': participation,
      'timeline': timeline,
      'rewards': rewards,
      'attachments': attachments,
      'testingGuidelines': testingGuidelines,
      'analytics': analytics,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Mission copyWith({
    String? id,
    String? providerId,
    String? appId,
    String? title,
    String? description,
    MissionType? type,
    MissionPriority? priority,
    MissionComplexity? complexity,
    MissionDifficulty? difficulty,
    MissionStatus? status,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? participation,
    Map<String, dynamic>? timeline,
    Map<String, dynamic>? rewards,
    List<Map<String, dynamic>>? attachments,
    Map<String, dynamic>? testingGuidelines,
    Map<String, dynamic>? analytics,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? completedAt,
  }) {
    return Mission(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      appId: appId ?? this.appId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      complexity: complexity ?? this.complexity,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      requirements: requirements ?? this.requirements,
      participation: participation ?? this.participation,
      timeline: timeline ?? this.timeline,
      rewards: rewards ?? this.rewards,
      attachments: attachments ?? this.attachments,
      testingGuidelines: testingGuidelines ?? this.testingGuidelines,
      analytics: analytics ?? this.analytics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Convenience getters
  double get baseReward => (rewards?['baseReward'] as num?)?.toDouble() ?? 0.0;
  double get bonusReward => (rewards?['bonusReward'] as num?)?.toDouble() ?? 0.0;
  double get totalReward => baseReward + bonusReward;
  
  int get maxTesters => participation?['maxTesters'] ?? 0;
  int get currentTesters => participation?['currentTesters'] ?? 0;
  
  DateTime? get startDate => timeline?['startDate'] != null 
      ? (timeline!['startDate'] as Timestamp).toDate()
      : null;
  
  DateTime? get endDate => timeline?['endDate'] != null 
      ? (timeline!['endDate'] as Timestamp).toDate()
      : null;
  
  int get testingDuration => timeline?['testingDuration'] ?? 7;
  int get reportingDuration => timeline?['reportingDuration'] ?? 3;
  
  List<String> get platforms => requirements?['platforms'] != null 
      ? List<String>.from(requirements!['platforms'])
      : <String>[];
      
  List<String> get devices => requirements?['devices'] != null 
      ? List<String>.from(requirements!['devices'])
      : <String>[];
      
  String get experienceLevel => requirements?['experience'] ?? 'beginner';
  double get minRating => (requirements?['minRating'] as num?)?.toDouble() ?? 0.0;
  
  int get views => analytics?['views'] ?? 0;
  int get applications => analytics?['applications'] ?? 0;
  double get acceptanceRate => (analytics?['acceptanceRate'] as num?)?.toDouble() ?? 0.0;
}

// Daily Mission Progress Model
class DailyMissionProgress {
  final String missionId;
  final String testerId;
  final DateTime date;
  final int dayNumber;
  final double progressPercentage;
  final bool isCompleted;
  final bool isToday;
  final String status; // 'pending', 'in_progress', 'completed', 'missed'
  final List<String> completedTasks;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  
  const DailyMissionProgress({
    required this.missionId,
    required this.testerId,
    required this.date,
    required this.dayNumber,
    required this.progressPercentage,
    required this.isCompleted,
    required this.isToday,
    required this.status,
    required this.completedTasks,
    this.notes,
    this.startedAt,
    this.completedAt,
  });
  
  factory DailyMissionProgress.fromFirestore(Map<String, dynamic> data) {
    return DailyMissionProgress(
      missionId: data['missionId'] ?? '',
      testerId: data['testerId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      dayNumber: data['dayNumber'] ?? 1,
      progressPercentage: (data['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      isCompleted: data['isCompleted'] ?? false,
      isToday: _isToday((data['date'] as Timestamp).toDate()),
      status: data['status'] ?? 'pending',
      completedTasks: List<String>.from(data['completedTasks'] ?? []),
      notes: data['notes'],
      startedAt: data['startedAt'] != null 
          ? (data['startedAt'] as Timestamp).toDate() 
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'missionId': missionId,
      'testerId': testerId,
      'date': Timestamp.fromDate(date),
      'dayNumber': dayNumber,
      'progressPercentage': progressPercentage,
      'isCompleted': isCompleted,
      'status': status,
      'completedTasks': completedTasks,
      'notes': notes,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
  
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  String get formattedDate {
    return '${date.month}월 ${date.day}일';
  }
  
  String get dayLabel {
    return '$dayNumber일차';
  }
  
  String get fullLabel {
    return '$formattedDate $dayLabel';
  }
  
  DailyMissionProgress copyWith({
    String? missionId,
    String? testerId,
    DateTime? date,
    int? dayNumber,
    double? progressPercentage,
    bool? isCompleted,
    String? status,
    List<String>? completedTasks,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return DailyMissionProgress(
      missionId: missionId ?? this.missionId,
      testerId: testerId ?? this.testerId,
      date: date ?? this.date,
      dayNumber: dayNumber ?? this.dayNumber,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isCompleted: isCompleted ?? this.isCompleted,
      isToday: _isToday(date ?? this.date),
      status: status ?? this.status,
      completedTasks: completedTasks ?? this.completedTasks,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// Enhanced Mission Card with Daily Progress
class MissionCardWithProgress {
  final String id;
  final String title;
  final String appName;
  final MissionType type;
  final int rewardPoints;
  final int estimatedMinutes;
  final DateTime? deadline;
  final DateTime? startedAt;
  final double overallProgress;
  final List<DailyMissionProgress> dailyProgress;
  
  const MissionCardWithProgress({
    required this.id,
    required this.title,
    required this.appName,
    required this.type,
    required this.rewardPoints,
    required this.estimatedMinutes,
    this.deadline,
    this.startedAt,
    required this.overallProgress,
    required this.dailyProgress,
  });
  
  DailyMissionProgress? get todayProgress {
    return dailyProgress.where((progress) => progress.isToday).firstOrNull;
  }
  
  DailyMissionProgress? get nextPendingProgress {
    final pendingProgress = dailyProgress
        .where((progress) => progress.status == 'pending' || progress.status == 'in_progress')
        .toList();
    
    if (pendingProgress.isEmpty) return null;
    
    pendingProgress.sort((a, b) => a.date.compareTo(b.date));
    return pendingProgress.first;
  }
  
  int get totalDays => dailyProgress.length;
  int get completedDays => dailyProgress.where((p) => p.isCompleted).length;
  int get remainingDays => totalDays - completedDays;
  
  double get calculatedOverallProgress {
    if (totalDays == 0) return 0.0;
    return completedDays / totalDays;
  }
  
  double get actualOverallProgress => calculatedOverallProgress;
  
  bool get hasToday => todayProgress != null;
  bool get isTodayCompleted => todayProgress?.isCompleted ?? false;
  bool get shouldShowToday => hasToday && !isTodayCompleted;
}

// Mission Application Status
enum MissionApplicationStatus {
  pending,    // 신청 대기 중
  reviewing,  // 검토 중
  accepted,   // 수락됨
  rejected,   // 거부됨
  cancelled,  // 신청 취소됨
}

// Mission Application Model
class MissionApplication {
  final String id;
  final String missionId;
  final String testerId;
  final String providerId;
  final String testerName;
  final String testerEmail;
  final String? testerProfile;
  final MissionApplicationStatus status;
  final String? message; // 테스터의 신청 메시지
  final String? responseMessage; // 공급자의 응답 메시지
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final Map<String, dynamic>? testerInfo; // 테스터 추가 정보
  
  const MissionApplication({
    required this.id,
    required this.missionId,
    required this.testerId,
    required this.providerId,
    required this.testerName,
    required this.testerEmail,
    this.testerProfile,
    required this.status,
    this.message,
    this.responseMessage,
    required this.appliedAt,
    this.reviewedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.testerInfo,
  });
  
  factory MissionApplication.fromFirestore(Map<String, dynamic> data) {
    return MissionApplication(
      id: data['id'] ?? '',
      missionId: data['missionId'] ?? '',
      testerId: data['testerId'] ?? '',
      providerId: data['providerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      testerProfile: data['testerProfile'],
      status: MissionApplicationStatus.values.byName(data['status'] ?? 'pending'),
      message: data['message'],
      responseMessage: data['responseMessage'],
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      acceptedAt: data['acceptedAt'] != null 
          ? (data['acceptedAt'] as Timestamp).toDate() 
          : null,
      rejectedAt: data['rejectedAt'] != null 
          ? (data['rejectedAt'] as Timestamp).toDate() 
          : null,
      testerInfo: data['testerInfo'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'missionId': missionId,
      'testerId': testerId,
      'providerId': providerId,
      'testerName': testerName,
      'testerEmail': testerEmail,
      'testerProfile': testerProfile,
      'status': status.name,
      'message': message,
      'responseMessage': responseMessage,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'testerInfo': testerInfo,
    };
  }
  
  MissionApplication copyWith({
    String? id,
    String? missionId,
    String? testerId,
    String? providerId,
    String? testerName,
    String? testerEmail,
    String? testerProfile,
    MissionApplicationStatus? status,
    String? message,
    String? responseMessage,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    Map<String, dynamic>? testerInfo,
  }) {
    return MissionApplication(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      testerId: testerId ?? this.testerId,
      providerId: providerId ?? this.providerId,
      testerName: testerName ?? this.testerName,
      testerEmail: testerEmail ?? this.testerEmail,
      testerProfile: testerProfile ?? this.testerProfile,
      status: status ?? this.status,
      message: message ?? this.message,
      responseMessage: responseMessage ?? this.responseMessage,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      testerInfo: testerInfo ?? this.testerInfo,
    );
  }
}

// Mission Notification Model
enum NotificationType {
  missionApplication,     // 미션 신청 관련
  applicationAccepted,    // 신청 수락됨
  applicationRejected,    // 신청 거부됨
  missionStarted,        // 미션 시작
  missionCompleted,      // 미션 완료
  missionExpired,        // 미션 만료
  paymentReceived,       // 결제 받음
  systemMessage,         // 시스템 메시지
}

class MissionNotification {
  final String id;
  final String recipientId; // 수신자 ID
  final String senderId;    // 발신자 ID
  final NotificationType type;
  final String title;
  final String message;
  final String? missionId;
  final String? applicationId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data; // 추가 데이터
  
  const MissionNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.missionId,
    this.applicationId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
  });
  
  factory MissionNotification.fromFirestore(Map<String, dynamic> data) {
    return MissionNotification(
      id: data['id'] ?? '',
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: NotificationType.values.byName(data['type'] ?? 'systemMessage'),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      missionId: data['missionId'],
      applicationId: data['applicationId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate() 
          : null,
      data: data['data'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type.name,
      'title': title,
      'message': message,
      'missionId': missionId,
      'applicationId': applicationId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
    };
  }
  
  MissionNotification copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    NotificationType? type,
    String? title,
    String? message,
    String? missionId,
    String? applicationId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return MissionNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      missionId: missionId ?? this.missionId,
      applicationId: applicationId ?? this.applicationId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }
}

// Mission Card Model (기존 유지)
class MissionCard {
  final String id;
  final String title;
  final String description;
  final String appName;
  final MissionType type;
  final int rewardPoints;
  final int estimatedMinutes;
  final DateTime? deadline;
  final DateTime? startedAt;
  final double? progress;
  final MissionStatus status;
  final List<String> requiredSkills;
  final int currentParticipants;
  final int maxParticipants;
  final MissionDifficulty difficulty;
  final bool isProviderApp;
  final Map<String, dynamic>? originalAppData;
  final String? providerId;
  final DateTime? completedAt;
  final double? averageRating;

  const MissionCard({
    required this.id,
    required this.title,
    required this.description,
    required this.appName,
    required this.type,
    required this.rewardPoints,
    required this.estimatedMinutes,
    this.deadline,
    this.startedAt,
    this.progress,
    required this.status,
    required this.requiredSkills,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.difficulty,
    required this.isProviderApp,
    this.originalAppData,
    this.providerId,
    this.completedAt,
    this.averageRating,
  });
}