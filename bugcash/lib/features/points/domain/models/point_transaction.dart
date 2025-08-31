class PointTransaction {
  final String id;
  final String userId;
  final int amount;
  final String type; // 'earned', 'spent', 'bonus'
  final String source; // 'mission_complete', 'bug_report', 'daily_bonus', etc.
  final String? description;
  final String? missionId;
  final DateTime createdAt;

  const PointTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.source,
    this.description,
    this.missionId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'source': source,
      'description': description,
      'missionId': missionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: json['amount'] ?? 0,
      type: json['type'] ?? 'earned',
      source: json['source'] ?? '',
      description: json['description'],
      missionId: json['missionId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get displayAmount {
    final prefix = type == 'spent' ? '-' : '+';
    return '$prefix$amount P';
  }

  String get displayDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    
    switch (source) {
      case 'mission_complete':
        return '미션 완료 보상';
      case 'bug_report':
        return '버그 리포트 제출';
      case 'daily_bonus':
        return '일일 보너스';
      case 'referral':
        return '추천인 보너스';
      case 'purchase':
        return '아이템 구매';
      default:
        return '포인트 거래';
    }
  }
}