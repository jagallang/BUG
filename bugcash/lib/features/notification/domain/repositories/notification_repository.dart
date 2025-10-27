import '../entities/notification_entity.dart';

/// v2.185.0: Notification Repository Interface (Domain Layer)
/// 알림 데이터 접근 인터페이스 (구현은 Data Layer에서)
abstract class NotificationRepository {
  /// 특정 사용자의 알림 목록 스트림 (실시간 업데이트)
  Stream<List<NotificationEntity>> watchNotificationsForUser(String userId);

  /// 특정 사용자의 미읽음 알림 개수 스트림
  Stream<int> watchUnreadCountForUser(String userId);

  /// 알림 ID로 단일 알림 조회
  Future<NotificationEntity?> getNotificationById(String notificationId);

  /// 알림 생성
  Future<void> createNotification(NotificationEntity notification);

  /// 여러 알림 일괄 생성 (다수 수신자)
  Future<void> createNotifications(List<NotificationEntity> notifications);

  /// 알림을 읽음으로 표시
  Future<void> markAsRead(String notificationId);

  /// 여러 알림을 읽음으로 표시
  Future<void> markAllAsRead(String userId);

  /// 알림 삭제
  Future<void> deleteNotification(String notificationId);

  /// 특정 사용자의 모든 알림 삭제
  Future<void> deleteAllNotificationsForUser(String userId);

  /// 관리자: 모든 알림 목록 조회 (페이징)
  /// limit: 한 번에 가져올 개수
  /// lastDoc: 마지막 문서 (페이징용)
  Future<List<NotificationEntity>> getAllNotifications({
    int limit = 50,
    String? afterNotificationId,
  });

  /// 관리자: 알림 발송 통계
  Future<Map<String, dynamic>> getNotificationStats();
}
