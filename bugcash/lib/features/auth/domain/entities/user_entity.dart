import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { tester, provider, admin }

enum VerificationStatus { pending, verified, rejected }

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<UserType> roles; // 변경: 다중 역할 지원
  final UserType primaryRole; // 추가: 기본 역할
  final bool isAdmin; // 추가: 관리자 플래그
  final String? phoneNumber;
  final String country;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DateTime? lastLoginAt;
  final UserProfile? profile;
  final TesterProfile? testerProfile; // 추가: 테스터 프로필
  final ProviderProfile? providerProfile; // 추가: 공급자 프로필
  final int level;
  final int completedMissions;
  final int points;
  
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.roles,
    required this.primaryRole,
    this.isAdmin = false,
    this.phoneNumber,
    required this.country,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.lastLoginAt,
    this.profile,
    this.testerProfile,
    this.providerProfile,
    this.level = 1,
    this.completedMissions = 0,
    this.points = 0,
  });

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    List<UserType>? roles,
    UserType? primaryRole,
    bool? isAdmin,
    String? phoneNumber,
    String? country,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? lastLoginAt,
    UserProfile? profile,
    TesterProfile? testerProfile,
    ProviderProfile? providerProfile,
    int? level,
    int? completedMissions,
    int? points,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      roles: roles ?? this.roles,
      primaryRole: primaryRole ?? this.primaryRole,
      isAdmin: isAdmin ?? this.isAdmin,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profile: profile ?? this.profile,
      testerProfile: testerProfile ?? this.testerProfile,
      providerProfile: providerProfile ?? this.providerProfile,
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
      'roles': roles.map((role) => role.name).toList(),
      'primaryRole': primaryRole.name,
      'isAdmin': isAdmin,
      'phoneNumber': phoneNumber,
      'country': country,
      'timezone': timezone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'profile': profile?.toMap(),
      'testerProfile': testerProfile?.toMap(),
      'providerProfile': providerProfile?.toMap(),
      'level': level,
      'completedMissions': completedMissions,
      'points': points,
    };
  }

  factory UserEntity.fromFirestore(String uid, Map<String, dynamic> data) {
    List<UserType> roles = [];
    if (data['roles'] != null) {
      roles = (data['roles'] as List)
          .map((role) => UserType.values.byName(role))
          .toList();
    } else if (data['userType'] != null) {
      // 기존 데이터 호환성
      roles = [UserType.values.byName(data['userType'])];
    } else {
      roles = [UserType.tester];
    }

    UserType primaryRole;
    if (data['primaryRole'] != null) {
      primaryRole = UserType.values.byName(data['primaryRole']);
    } else {
      primaryRole = roles.first;
    }

    return UserEntity(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoURL'],
      roles: roles,
      primaryRole: primaryRole,
      isAdmin: data['isAdmin'] ?? false,
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
      testerProfile: data['testerProfile'] != null
          ? TesterProfile.fromMap(data['testerProfile'])
          : null,
      providerProfile: data['providerProfile'] != null
          ? ProviderProfile.fromMap(data['providerProfile'])
          : null,
      level: data['level'] ?? 1,
      completedMissions: data['completedMissions'] ?? 0,
      points: data['points'] ?? 0,
    );
  }

  // 다중 역할 지원 헬퍼 메서드
  bool hasRole(UserType role) => roles.contains(role);

  bool get isTester => hasRole(UserType.tester);
  bool get isProvider => hasRole(UserType.provider);
  bool get canSwitchRoles => roles.length > 1;

  List<UserType> get availableRoles => List.from(roles);

  // 역할별 프로필 접근 헬퍼
  bool get hasTesterProfile => testerProfile != null;
  bool get hasProviderProfile => providerProfile != null;

  // 기존 API 호환성을 위한 getter (deprecated)
  @Deprecated('Use primaryRole instead')
  UserType get userType => primaryRole;

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    roles,
    primaryRole,
    isAdmin,
    phoneNumber,
    country,
    timezone,
    createdAt,
    updatedAt,
    isActive,
    lastLoginAt,
    profile,
    testerProfile,
    providerProfile,
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

class TesterProfile extends Equatable {
  final List<String> preferredCategories;
  final List<String> devices;
  final String? experience;
  final double rating;
  final int completedTests;
  final Map<String, dynamic> testingPreferences;
  final VerificationStatus verificationStatus;

  const TesterProfile({
    this.preferredCategories = const [],
    this.devices = const [],
    this.experience,
    this.rating = 0.0,
    this.completedTests = 0,
    this.testingPreferences = const {},
    this.verificationStatus = VerificationStatus.pending,
  });

  TesterProfile copyWith({
    List<String>? preferredCategories,
    List<String>? devices,
    String? experience,
    double? rating,
    int? completedTests,
    Map<String, dynamic>? testingPreferences,
    VerificationStatus? verificationStatus,
  }) {
    return TesterProfile(
      preferredCategories: preferredCategories ?? this.preferredCategories,
      devices: devices ?? this.devices,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      completedTests: completedTests ?? this.completedTests,
      testingPreferences: testingPreferences ?? this.testingPreferences,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredCategories': preferredCategories,
      'devices': devices,
      'experience': experience,
      'rating': rating,
      'completedTests': completedTests,
      'testingPreferences': testingPreferences,
      'verificationStatus': verificationStatus.name,
    };
  }

  factory TesterProfile.fromMap(Map<String, dynamic> map) {
    return TesterProfile(
      preferredCategories: List<String>.from(map['preferredCategories'] ?? []),
      devices: List<String>.from(map['devices'] ?? []),
      experience: map['experience'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      completedTests: map['completedTests'] ?? 0,
      testingPreferences: Map<String, dynamic>.from(map['testingPreferences'] ?? {}),
      verificationStatus: VerificationStatus.values.byName(
        map['verificationStatus'] ?? 'pending'
      ),
    );
  }

  @override
  List<Object?> get props => [
    preferredCategories,
    devices,
    experience,
    rating,
    completedTests,
    testingPreferences,
    verificationStatus,
  ];
}

class ProviderProfile extends Equatable {
  final String? companyName;
  final String? website;
  final String? businessType;
  final List<String> appCategories;
  final String? contactInfo;
  final double rating;
  final int publishedApps;
  final Map<String, dynamic> businessInfo;
  final VerificationStatus verificationStatus;

  const ProviderProfile({
    this.companyName,
    this.website,
    this.businessType,
    this.appCategories = const [],
    this.contactInfo,
    this.rating = 0.0,
    this.publishedApps = 0,
    this.businessInfo = const {},
    this.verificationStatus = VerificationStatus.pending,
  });

  ProviderProfile copyWith({
    String? companyName,
    String? website,
    String? businessType,
    List<String>? appCategories,
    String? contactInfo,
    double? rating,
    int? publishedApps,
    Map<String, dynamic>? businessInfo,
    VerificationStatus? verificationStatus,
  }) {
    return ProviderProfile(
      companyName: companyName ?? this.companyName,
      website: website ?? this.website,
      businessType: businessType ?? this.businessType,
      appCategories: appCategories ?? this.appCategories,
      contactInfo: contactInfo ?? this.contactInfo,
      rating: rating ?? this.rating,
      publishedApps: publishedApps ?? this.publishedApps,
      businessInfo: businessInfo ?? this.businessInfo,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'website': website,
      'businessType': businessType,
      'appCategories': appCategories,
      'contactInfo': contactInfo,
      'rating': rating,
      'publishedApps': publishedApps,
      'businessInfo': businessInfo,
      'verificationStatus': verificationStatus.name,
    };
  }

  factory ProviderProfile.fromMap(Map<String, dynamic> map) {
    return ProviderProfile(
      companyName: map['companyName'],
      website: map['website'],
      businessType: map['businessType'],
      appCategories: List<String>.from(map['appCategories'] ?? []),
      contactInfo: map['contactInfo'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      publishedApps: map['publishedApps'] ?? 0,
      businessInfo: Map<String, dynamic>.from(map['businessInfo'] ?? {}),
      verificationStatus: VerificationStatus.values.byName(
        map['verificationStatus'] ?? 'pending'
      ),
    );
  }

  @override
  List<Object?> get props => [
    companyName,
    website,
    businessType,
    appCategories,
    contactInfo,
    rating,
    publishedApps,
    businessInfo,
    verificationStatus,
  ];
}