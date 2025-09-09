import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { tester, provider }

enum VerificationStatus { pending, verified, rejected }

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserType userType;
  final String? phoneNumber;
  final String country;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DateTime? lastLoginAt;
  final UserProfile? profile;
  final int level;
  final int completedMissions;
  final int points;
  
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.userType,
    this.phoneNumber,
    required this.country,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.lastLoginAt,
    this.profile,
    this.level = 1,
    this.completedMissions = 0,
    this.points = 0,
  });

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    UserType? userType,
    String? phoneNumber,
    String? country,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? lastLoginAt,
    UserProfile? profile,
    int? level,
    int? completedMissions,
    int? points,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profile: profile ?? this.profile,
      level: level ?? this.level,
      completedMissions: completedMissions ?? this.completedMissions,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoUrl,
      'userType': userType.name,
      'phoneNumber': phoneNumber,
      'country': country,
      'timezone': timezone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'profile': profile?.toMap(),
    };
  }

  factory UserEntity.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserEntity(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoURL'],
      userType: UserType.values.byName(data['userType'] ?? 'tester'),
      phoneNumber: data['phoneNumber'],
      country: data['country'] ?? '',
      timezone: data['timezone'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      profile: data['profile'] != null
          ? UserProfile.fromMap(data['profile'])
          : null,
      level: data['level'] ?? 1,
      completedMissions: data['completedMissions'] ?? 0,
      points: data['points'] ?? 0,
    );
  }
  
  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    userType,
    phoneNumber,
    country,
    timezone,
    createdAt,
    updatedAt,
    isActive,
    lastLoginAt,
    profile,
    level,
    completedMissions,
    points,
  ];
}

class UserProfile extends Equatable {
  final String? bio;
  final List<String> skills;
  final List<String> languages;
  final Map<String, dynamic> preferences;

  const UserProfile({
    this.bio,
    this.skills = const [],
    this.languages = const [],
    this.preferences = const {},
  });

  UserProfile copyWith({
    String? bio,
    List<String>? skills,
    List<String>? languages,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bio': bio,
      'skills': skills,
      'languages': languages,
      'preferences': preferences,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      bio: map['bio'],
      skills: List<String>.from(map['skills'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [bio, skills, languages, preferences];
}