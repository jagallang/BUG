import 'package:cloud_firestore/cloud_firestore.dart';

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