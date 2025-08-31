import 'package:cloud_firestore/cloud_firestore.dart';

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
  survey,         // 설문조사
  feedback,       // 피드백 수집
  functional,     // 기능 테스트
  uiUx,         // UI/UX 테스트
  performance,   // 성능 테스트
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