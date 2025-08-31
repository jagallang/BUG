class UserProfile {
  final String userId;
  final String username;
  final String email;
  final String? displayName;
  final String? profileImageUrl;
  final String? bio;
  final String? location;
  final String? website;
  final String? githubUsername;
  final String? linkedinProfile;
  final List<String> skills;
  final List<String> interests;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final bool isProfilePublic;
  final UserStats stats;
  
  const UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    this.displayName,
    this.profileImageUrl,
    this.bio,
    this.location,
    this.website,
    this.githubUsername,
    this.linkedinProfile,
    this.skills = const [],
    this.interests = const [],
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
    this.isProfilePublic = true,
    required this.stats,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'location': location,
      'website': website,
      'githubUsername': githubUsername,
      'linkedinProfile': linkedinProfile,
      'skills': skills,
      'interests': interests,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isProfilePublic': isProfilePublic,
      'stats': stats.toJson(),
    };
  }
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
      location: json['location'],
      website: json['website'],
      githubUsername: json['githubUsername'],
      linkedinProfile: json['linkedinProfile'],
      skills: List<String>.from(json['skills'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isProfilePublic: json['isProfilePublic'] ?? true,
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }
  
  UserProfile copyWith({
    String? userId,
    String? username,
    String? email,
    String? displayName,
    String? profileImageUrl,
    String? bio,
    String? location,
    String? website,
    String? githubUsername,
    String? linkedinProfile,
    List<String>? skills,
    List<String>? interests,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? isProfilePublic,
    UserStats? stats,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      githubUsername: githubUsername ?? this.githubUsername,
      linkedinProfile: linkedinProfile ?? this.linkedinProfile,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      stats: stats ?? this.stats,
    );
  }
  
  String get displayNameOrUsername => displayName ?? username;
  
  String get initials {
    final name = displayNameOrUsername;
    if (name.isEmpty) return 'U';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId;
  
  @override
  int get hashCode => userId.hashCode;
  
  @override
  String toString() {
    return 'UserProfile(userId: $userId, username: $username, email: $email)';
  }
}

class UserStats {
  final int totalPoints;
  final int completedMissions;
  final int activeMissions;
  final int bugReportsSubmitted;
  final int rank;
  final String? currentBadge;
  final Map<String, int> categoryStats;
  final List<String> achievements;
  final double successRate;
  final DateTime joinDate;
  
  const UserStats({
    this.totalPoints = 0,
    this.completedMissions = 0,
    this.activeMissions = 0,
    this.bugReportsSubmitted = 0,
    this.rank = 0,
    this.currentBadge,
    this.categoryStats = const {},
    this.achievements = const [],
    this.successRate = 0.0,
    required this.joinDate,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'completedMissions': completedMissions,
      'activeMissions': activeMissions,
      'bugReportsSubmitted': bugReportsSubmitted,
      'rank': rank,
      'currentBadge': currentBadge,
      'categoryStats': categoryStats,
      'achievements': achievements,
      'successRate': successRate,
      'joinDate': joinDate.toIso8601String(),
    };
  }
  
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalPoints: json['totalPoints'] ?? 0,
      completedMissions: json['completedMissions'] ?? 0,
      activeMissions: json['activeMissions'] ?? 0,
      bugReportsSubmitted: json['bugReportsSubmitted'] ?? 0,
      rank: json['rank'] ?? 0,
      currentBadge: json['currentBadge'],
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
      achievements: List<String>.from(json['achievements'] ?? []),
      successRate: (json['successRate'] ?? 0.0).toDouble(),
      joinDate: DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  UserStats copyWith({
    int? totalPoints,
    int? completedMissions,
    int? activeMissions,
    int? bugReportsSubmitted,
    int? rank,
    String? currentBadge,
    Map<String, int>? categoryStats,
    List<String>? achievements,
    double? successRate,
    DateTime? joinDate,
  }) {
    return UserStats(
      totalPoints: totalPoints ?? this.totalPoints,
      completedMissions: completedMissions ?? this.completedMissions,
      activeMissions: activeMissions ?? this.activeMissions,
      bugReportsSubmitted: bugReportsSubmitted ?? this.bugReportsSubmitted,
      rank: rank ?? this.rank,
      currentBadge: currentBadge ?? this.currentBadge,
      categoryStats: categoryStats ?? this.categoryStats,
      achievements: achievements ?? this.achievements,
      successRate: successRate ?? this.successRate,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}

class NotificationSettings {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool missionUpdates;
  final bool rankingUpdates;
  final bool newMissionAlerts;
  final bool weeklyDigest;
  
  const NotificationSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.missionUpdates = true,
    this.rankingUpdates = false,
    this.newMissionAlerts = true,
    this.weeklyDigest = true,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'missionUpdates': missionUpdates,
      'rankingUpdates': rankingUpdates,
      'newMissionAlerts': newMissionAlerts,
      'weeklyDigest': weeklyDigest,
    };
  }
  
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      missionUpdates: json['missionUpdates'] ?? true,
      rankingUpdates: json['rankingUpdates'] ?? false,
      newMissionAlerts: json['newMissionAlerts'] ?? true,
      weeklyDigest: json['weeklyDigest'] ?? true,
    );
  }
  
  NotificationSettings copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? missionUpdates,
    bool? rankingUpdates,
    bool? newMissionAlerts,
    bool? weeklyDigest,
  }) {
    return NotificationSettings(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      missionUpdates: missionUpdates ?? this.missionUpdates,
      rankingUpdates: rankingUpdates ?? this.rankingUpdates,
      newMissionAlerts: newMissionAlerts ?? this.newMissionAlerts,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
    );
  }
}