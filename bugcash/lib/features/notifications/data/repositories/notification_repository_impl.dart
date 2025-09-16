import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../../core/utils/logger.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationRepositoryImpl({
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  static const String _notificationsCollection = 'notifications';
  static const String _usersCollection = 'users';
  static const String _settingsSubcollection = 'notification_settings';

  @override
  Future<List<NotificationModel>> getNotifications(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get notifications', 'NotificationRepository', e);
      
      // Return demo data on error
      return _getDemoNotifications(userId);
    }
  }

  @override
  Future<NotificationModel?> getNotificationById(String id) async {
    try {
      final docSnapshot = await _firestore
          .collection(_notificationsCollection)
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        return NotificationModel.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data()!,
        });
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get notification by id', 'NotificationRepository', e);
      return null;
    }
  }

  @override
  Future<void> createNotification(NotificationModel notification) async {
    try {
      final docRef = _firestore.collection(_notificationsCollection).doc(notification.id);
      final data = notification.toJson();
      data.remove('id'); // Remove ID from data as it's used as document ID
      
      await docRef.set(data);
      AppLogger.info('Notification created successfully', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to create notification', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> updateNotification(NotificationModel notification) async {
    try {
      final data = notification.toJson();
      data.remove('id');
      
      await _firestore
          .collection(_notificationsCollection)
          .doc(notification.id)
          .update(data);
      
      AppLogger.info('Notification updated successfully', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to update notification', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _firestore.collection(_notificationsCollection).doc(id).delete();
      AppLogger.info('Notification deleted successfully', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to delete notification', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': DateTime.now().toIso8601String(),
          });
      
      AppLogger.info('Notification marked as read', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to mark notification as read', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      AppLogger.info('All notifications marked as read', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> deleteReadNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.info('Read notifications deleted', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to delete read notifications', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settingsSubcollection)
          .doc('notification_settings')
          .set({
            'fcmToken': token,
            'tokenUpdatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
      
      AppLogger.info('FCM token saved successfully', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to save FCM token', 'NotificationRepository', e);
    }
  }

  @override
  Future<String?> getFcmToken(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settingsSubcollection)
          .doc('notification_settings')
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()?['fcmToken'];
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get FCM token', 'NotificationRepository', e);
      return null;
    }
  }

  @override
  Future<void> deleteFcmToken(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settingsSubcollection)
          .doc('notification_settings')
          .update({
            'fcmToken': FieldValue.delete(),
            'tokenUpdatedAt': FieldValue.delete(),
          });
      
      AppLogger.info('FCM token deleted successfully', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to delete FCM token', 'NotificationRepository', e);
    }
  }

  @override
  Future<NotificationSettings> getNotificationSettings(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settingsSubcollection)
          .doc('notification_settings')
          .get();

      if (docSnapshot.exists) {
        return NotificationSettings.fromJson(docSnapshot.data()!);
      }
      
      // Return default settings if none exist
      const defaultSettings = NotificationSettings();
      await updateNotificationSettings(userId, defaultSettings);
      return defaultSettings;
    } catch (e) {
      AppLogger.error('Failed to get notification settings', 'NotificationRepository', e);
      return const NotificationSettings();
    }
  }

  @override
  Future<void> updateNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settingsSubcollection)
          .doc('notification_settings')
          .set(settings.toJson(), SetOptions(merge: true));
      
      AppLogger.info('Notification settings updated successfully', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to update notification settings', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> scheduleLocalNotification(NotificationModel notification) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'bugcash_channel',
        'BugCash Notifications',
        channelDescription: 'Notifications from BugCash app',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: notification.actionUrl,
      );
      
      AppLogger.info('Local notification scheduled', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to schedule local notification', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> cancelLocalNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      AppLogger.info('Local notification cancelled', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to cancel local notification', 'NotificationRepository', e);
    }
  }

  @override
  Future<void> cancelAllLocalNotifications() async {
    try {
      await _localNotifications.cancelAll();
      AppLogger.info('All local notifications cancelled', 'NotificationRepository');
    } catch (e) {
      AppLogger.error('Failed to cancel all local notifications', 'NotificationRepository', e);
    }
  }

  @override
  Future<Map<String, int>> getNotificationStats(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final stats = <String, int>{};
      for (final doc in querySnapshot.docs) {
        final type = doc.data()['type'] as String;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      AppLogger.error('Failed to get notification stats', 'NotificationRepository', e);
      return {};
    }
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get unread notifications', 'NotificationRepository', e);
      return [];
    }
  }

  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get unread notification count', 'NotificationRepository', e);
      return 0;
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<NotificationSettings> watchNotificationSettings(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_settingsSubcollection)
        .doc('notification_settings')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return NotificationSettings.fromJson(doc.data()!);
          }
          return const NotificationSettings();
        });
  }

  // Demo data for offline/error scenarios
  List<NotificationModel> _getDemoNotifications(String userId) {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'demo_1',
        userId: userId,
        title: '🎉 새로운 미션이 등록되었습니다!',
        body: '카카오톡 버그 찾기 미션을 확인해보세요. 완료 시 1000 포인트를 획득할 수 있습니다.',
        type: NotificationType.mission,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 1)),
        data: const {'missionId': 'demo_mission_1'},
      ),
      NotificationModel(
        id: 'demo_2',
        userId: userId,
        title: '💰 포인트가 지급되었습니다',
        body: 'Instagram 버그 리포트 미션 완료로 800 포인트를 획득하셨습니다!',
        type: NotificationType.points,
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
        readAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'demo_3',
        userId: userId,
        title: '🏆 랭킹이 상승했습니다!',
        body: '축하합니다! 현재 랭킹이 15위로 상승했습니다.',
        type: NotificationType.ranking,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
        readAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}