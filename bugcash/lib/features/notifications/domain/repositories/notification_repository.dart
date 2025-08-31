import '../models/notification_model.dart';

abstract class NotificationRepository {
  // Notification CRUD operations
  Future<List<NotificationModel>> getNotifications(String userId, {int limit = 50});
  Future<NotificationModel?> getNotificationById(String id);
  Future<void> createNotification(NotificationModel notification);
  Future<void> updateNotification(NotificationModel notification);
  Future<void> deleteNotification(String id);
  
  // Bulk operations
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteReadNotifications(String userId);
  
  // FCM Token operations
  Future<void> saveFcmToken(String userId, String token);
  Future<String?> getFcmToken(String userId);
  Future<void> deleteFcmToken(String userId);
  
  // Notification settings
  Future<NotificationSettings> getNotificationSettings(String userId);
  Future<void> updateNotificationSettings(String userId, NotificationSettings settings);
  
  // Local notification operations
  Future<void> scheduleLocalNotification(NotificationModel notification);
  Future<void> cancelLocalNotification(int id);
  Future<void> cancelAllLocalNotifications();
  
  // Statistics and analytics
  Future<Map<String, int>> getNotificationStats(String userId);
  Future<List<NotificationModel>> getUnreadNotifications(String userId);
  Future<int> getUnreadNotificationCount(String userId);
  
  // Real-time updates
  Stream<List<NotificationModel>> watchNotifications(String userId);
  Stream<int> watchUnreadCount(String userId);
  Stream<NotificationSettings> watchNotificationSettings(String userId);
}