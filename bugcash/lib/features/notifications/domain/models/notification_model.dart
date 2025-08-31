import 'package:equatable/equatable.dart';

enum NotificationType {
  mission,
  points,
  ranking,
  system,
  marketing,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? scheduledAt;
  final bool isRead;
  final bool isLocal;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.data,
    this.imageUrl,
    this.actionUrl,
    required this.createdAt,
    this.readAt,
    this.scheduledAt,
    this.isRead = false,
    this.isLocal = false,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? scheduledAt,
    bool? isRead,
    bool? isLocal,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'isRead': isRead,
      'isLocal': isLocal,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      data: json['data'],
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      isRead: json['isRead'] ?? false,
      isLocal: json['isLocal'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        priority,
        data,
        imageUrl,
        actionUrl,
        createdAt,
        readAt,
        scheduledAt,
        isRead,
        isLocal,
      ];
}

class NotificationSettings extends Equatable {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool missionNotifications;
  final bool pointsNotifications;
  final bool rankingNotifications;
  final bool systemNotifications;
  final bool marketingNotifications;
  final String? fcmToken;
  final DateTime? tokenUpdatedAt;

  const NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    this.missionNotifications = true,
    this.pointsNotifications = true,
    this.rankingNotifications = true,
    this.systemNotifications = true,
    this.marketingNotifications = false,
    this.fcmToken,
    this.tokenUpdatedAt,
  });

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? missionNotifications,
    bool? pointsNotifications,
    bool? rankingNotifications,
    bool? systemNotifications,
    bool? marketingNotifications,
    String? fcmToken,
    DateTime? tokenUpdatedAt,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      missionNotifications: missionNotifications ?? this.missionNotifications,
      pointsNotifications: pointsNotifications ?? this.pointsNotifications,
      rankingNotifications: rankingNotifications ?? this.rankingNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
      fcmToken: fcmToken ?? this.fcmToken,
      tokenUpdatedAt: tokenUpdatedAt ?? this.tokenUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'missionNotifications': missionNotifications,
      'pointsNotifications': pointsNotifications,
      'rankingNotifications': rankingNotifications,
      'systemNotifications': systemNotifications,
      'marketingNotifications': marketingNotifications,
      'fcmToken': fcmToken,
      'tokenUpdatedAt': tokenUpdatedAt?.toIso8601String(),
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? false,
      smsNotifications: json['smsNotifications'] ?? false,
      missionNotifications: json['missionNotifications'] ?? true,
      pointsNotifications: json['pointsNotifications'] ?? true,
      rankingNotifications: json['rankingNotifications'] ?? true,
      systemNotifications: json['systemNotifications'] ?? true,
      marketingNotifications: json['marketingNotifications'] ?? false,
      fcmToken: json['fcmToken'],
      tokenUpdatedAt: json['tokenUpdatedAt'] != null 
          ? DateTime.parse(json['tokenUpdatedAt']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
        pushNotifications,
        emailNotifications,
        smsNotifications,
        missionNotifications,
        pointsNotifications,
        rankingNotifications,
        systemNotifications,
        marketingNotifications,
        fcmToken,
        tokenUpdatedAt,
      ];
}