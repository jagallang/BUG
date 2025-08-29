class UserRanking {
  final String userId;
  final String username;
  final String? profileImage;
  final int totalPoints;
  final int completedMissions;
  final int rank;
  final String? badge;
  final DateTime lastActive;
  final Map<String, int> categoryPoints;
  
  const UserRanking({
    required this.userId,
    required this.username,
    this.profileImage,
    required this.totalPoints,
    required this.completedMissions,
    required this.rank,
    this.badge,
    required this.lastActive,
    this.categoryPoints = const {},
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profileImage': profileImage,
      'totalPoints': totalPoints,
      'completedMissions': completedMissions,
      'rank': rank,
      'badge': badge,
      'lastActive': lastActive.toIso8601String(),
      'categoryPoints': categoryPoints,
    };
  }
  
  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profileImage'],
      totalPoints: json['totalPoints'] ?? 0,
      completedMissions: json['completedMissions'] ?? 0,
      rank: json['rank'] ?? 0,
      badge: json['badge'],
      lastActive: DateTime.parse(json['lastActive']),
      categoryPoints: Map<String, int>.from(json['categoryPoints'] ?? {}),
    );
  }
  
  String get rankSuffix {
    switch (rank % 10) {
      case 1:
        return '${rank}st';
      case 2:
        return '${rank}nd';
      case 3:
        return '${rank}rd';
      default:
        return '${rank}th';
    }
  }
  
  String get badgeEmoji {
    switch (badge) {
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
        return '🥉';
      case 'rising_star':
        return '⭐';
      case 'bug_hunter':
        return '🐛';
      case 'security_expert':
        return '🛡️';
      default:
        return '';
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRanking &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          rank == other.rank;
  
  @override
  int get hashCode => userId.hashCode ^ rank.hashCode;
  
  @override
  String toString() {
    return 'UserRanking(userId: $userId, username: $username, rank: $rank, totalPoints: $totalPoints)';
  }
}

class RankingFilter {
  final String period; // 'daily', 'weekly', 'monthly', 'all'
  final String category; // 'all', 'bug_hunting', 'security', 'ui_ux', etc.
  final int limit;
  
  const RankingFilter({
    this.period = 'all',
    this.category = 'all', 
    this.limit = 50,
  });
  
  RankingFilter copyWith({
    String? period,
    String? category,
    int? limit,
  }) {
    return RankingFilter(
      period: period ?? this.period,
      category: category ?? this.category,
      limit: limit ?? this.limit,
    );
  }
  
  @override
  String toString() {
    return 'RankingFilter(period: $period, category: $category, limit: $limit)';
  }
}