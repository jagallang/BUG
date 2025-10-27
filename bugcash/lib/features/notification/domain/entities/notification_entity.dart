import 'package:equatable/equatable.dart';

/// v2.185.0: Notification Entity (Domain Layer)
/// 알림 시스템의 핵심 비즈니스 엔티티
class NotificationEntity extends Equatable {
  final String id;
  final String recipientId;
  final String recipientRole; // 'tester', 'provider', 'admin', 'all'
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data; // 추가 데이터 (missionId, appId, dayNumber 등)
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String sentBy; // 'system' or userId

  const NotificationEntity({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    required this.isRead,
    required this.createdAt,
    this.readAt,
    required this.sentBy,
  });

  /// 알림이 미션 관련인지 확인
  bool get isMissionRelated => data.containsKey('missionId');

  /// 알림이 포인트 관련인지 확인
  bool get isPointsRelated => data.containsKey('points');

  /// 알림 클릭 시 이동할 URL (선택적)
  String? get actionUrl => data['actionUrl'] as String?;

  /// 복사본 생성 (읽음 상태 변경 등)
  NotificationEntity copyWith({
    String? id,
    String? recipientId,
    String? recipientRole,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? sentBy,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      sentBy: sentBy ?? this.sentBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        recipientId,
        recipientRole,
        type,
        title,
        message,
        data,
        isRead,
        createdAt,
        readAt,
        sentBy,
      ];
}

/// v2.185.0: 알림 유형
enum NotificationType {
  system, // 시스템 공지
  missionApplied, // 미션 신청됨
  missionApproved, // 미션 승인됨
  missionRejected, // 미션 거부됨
  missionStarted, // 미션 시작됨
  daySubmitted, // Day 제출됨
  dayApproved, // Day 승인됨
  dayRejected, // Day 거부됨
  missionCompleted, // 미션 완료됨
  pointsAwarded, // 포인트 지급됨
  adminMessage, // 관리자 메시지
  custom, // 커스텀 알림
}

/// v2.185.0: NotificationType 확장 - 문자열 변환
extension NotificationTypeExtension on NotificationType {
  /// Firestore 저장용 문자열 변환
  String toFirestoreString() {
    switch (this) {
      case NotificationType.system:
        return 'system';
      case NotificationType.missionApplied:
        return 'mission_applied';
      case NotificationType.missionApproved:
        return 'mission_approved';
      case NotificationType.missionRejected:
        return 'mission_rejected';
      case NotificationType.missionStarted:
        return 'mission_started';
      case NotificationType.daySubmitted:
        return 'day_submitted';
      case NotificationType.dayApproved:
        return 'day_approved';
      case NotificationType.dayRejected:
        return 'day_rejected';
      case NotificationType.missionCompleted:
        return 'mission_completed';
      case NotificationType.pointsAwarded:
        return 'points_awarded';
      case NotificationType.adminMessage:
        return 'admin_message';
      case NotificationType.custom:
        return 'custom';
    }
  }

  /// Firestore 문자열에서 NotificationType으로 변환
  static NotificationType fromFirestoreString(String value) {
    switch (value) {
      case 'system':
        return NotificationType.system;
      case 'mission_applied':
        return NotificationType.missionApplied;
      case 'mission_approved':
        return NotificationType.missionApproved;
      case 'mission_rejected':
        return NotificationType.missionRejected;
      case 'mission_started':
        return NotificationType.missionStarted;
      case 'day_submitted':
        return NotificationType.daySubmitted;
      case 'day_approved':
        return NotificationType.dayApproved;
      case 'day_rejected':
        return NotificationType.dayRejected;
      case 'mission_completed':
        return NotificationType.missionCompleted;
      case 'points_awarded':
        return NotificationType.pointsAwarded;
      case 'admin_message':
        return NotificationType.adminMessage;
      case 'custom':
      default:
        return NotificationType.custom;
    }
  }

  /// 사용자에게 표시할 한글 이름
  String get displayName {
    switch (this) {
      case NotificationType.system:
        return '시스템 공지';
      case NotificationType.missionApplied:
        return '미션 신청';
      case NotificationType.missionApproved:
        return '미션 승인';
      case NotificationType.missionRejected:
        return '미션 거부';
      case NotificationType.missionStarted:
        return '미션 시작';
      case NotificationType.daySubmitted:
        return 'Day 제출';
      case NotificationType.dayApproved:
        return 'Day 승인';
      case NotificationType.dayRejected:
        return 'Day 거부';
      case NotificationType.missionCompleted:
        return '미션 완료';
      case NotificationType.pointsAwarded:
        return '포인트 지급';
      case NotificationType.adminMessage:
        return '관리자 메시지';
      case NotificationType.custom:
        return '알림';
    }
  }

  /// 알림 아이콘 이모지
  String get emoji {
    switch (this) {
      case NotificationType.system:
        return '📢';
      case NotificationType.missionApplied:
        return '📝';
      case NotificationType.missionApproved:
        return '✅';
      case NotificationType.missionRejected:
        return '❌';
      case NotificationType.missionStarted:
        return '🚀';
      case NotificationType.daySubmitted:
        return '📋';
      case NotificationType.dayApproved:
        return '✨';
      case NotificationType.dayRejected:
        return '⚠️';
      case NotificationType.missionCompleted:
        return '🎉';
      case NotificationType.pointsAwarded:
        return '💰';
      case NotificationType.adminMessage:
        return '👨‍💼';
      case NotificationType.custom:
        return '🔔';
    }
  }
}
