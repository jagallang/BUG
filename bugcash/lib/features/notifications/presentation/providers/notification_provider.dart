import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/services/fcm_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/auth_service.dart';

// Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

// FCM Service Provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService.instance;
});

// Notification List Provider
final notificationListProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

// Unread Notification Count Provider
final unreadNotificationCountProvider = StateNotifierProvider<UnreadCountNotifier, AsyncValue<int>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return UnreadCountNotifier(repository);
});

// Notification Settings Provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<NotificationSettings>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationSettingsNotifier(repository);
});

// FCM Token Provider
final fcmTokenProvider = StateNotifierProvider<FCMTokenNotifier, AsyncValue<String?>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final fcmService = ref.watch(fcmServiceProvider);
  return FCMTokenNotifier(repository, fcmService);
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;
  // Get current user ID dynamically
  String get _currentUserId => CurrentUserService.getCurrentUserIdOrDefault();

  NotificationNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _repository.getNotifications(_currentUserId);
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      AppLogger.error('Failed to load notifications', 'NotificationNotifier', e);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      
      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });
      
      AppLogger.info('Notification marked as read', 'NotificationNotifier');
    } catch (e) {
      AppLogger.error('Failed to mark notification as read', 'NotificationNotifier', e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead(_currentUserId);
      
      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notification) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });
      
      AppLogger.info('All notifications marked as read', 'NotificationNotifier');
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read', 'NotificationNotifier', e);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      
      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications
            .where((notification) => notification.id != notificationId)
            .toList();
        state = AsyncValue.data(updatedNotifications);
      });
      
      AppLogger.info('Notification deleted', 'NotificationNotifier');
    } catch (e) {
      AppLogger.error('Failed to delete notification', 'NotificationNotifier', e);
    }
  }

  Future<void> deleteReadNotifications() async {
    try {
      await _repository.deleteReadNotifications(_currentUserId);
      
      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications
            .where((notification) => !notification.isRead)
            .toList();
        state = AsyncValue.data(updatedNotifications);
      });
      
      AppLogger.info('Read notifications deleted', 'NotificationNotifier');
    } catch (e) {
      AppLogger.error('Failed to delete read notifications', 'NotificationNotifier', e);
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    try {
      await _repository.createNotification(notification);
      
      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = [notification, ...notifications];
        state = AsyncValue.data(updatedNotifications);
      });
      
      AppLogger.info('Notification added', 'NotificationNotifier');
    } catch (e) {
      AppLogger.error('Failed to add notification', 'NotificationNotifier', e);
    }
  }
}

class UnreadCountNotifier extends StateNotifier<AsyncValue<int>> {
  final NotificationRepository _repository;
  // Get current user ID dynamically
  String get _currentUserId => CurrentUserService.getCurrentUserIdOrDefault();

  UnreadCountNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    try {
      state = const AsyncValue.loading();
      final count = await _repository.getUnreadNotificationCount(_currentUserId);
      state = AsyncValue.data(count);
    } catch (e, stack) {
      AppLogger.error('Failed to load unread count', 'UnreadCountNotifier', e);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshUnreadCount() async {
    await loadUnreadCount();
  }

  void decrementCount() {
    state.whenData((count) {
      if (count > 0) {
        state = AsyncValue.data(count - 1);
      }
    });
  }

  void resetCount() {
    state = const AsyncValue.data(0);
  }

  void incrementCount() {
    state.whenData((count) {
      state = AsyncValue.data(count + 1);
    });
  }
}

class NotificationSettingsNotifier extends StateNotifier<AsyncValue<NotificationSettings>> {
  final NotificationRepository _repository;
  // Get current user ID dynamically
  String get _currentUserId => CurrentUserService.getCurrentUserIdOrDefault();

  NotificationSettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _repository.getNotificationSettings(_currentUserId);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      AppLogger.error('Failed to load notification settings', 'NotificationSettingsNotifier', e);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    try {
      await _repository.updateNotificationSettings(_currentUserId, settings);
      state = AsyncValue.data(settings);
      AppLogger.info('Notification settings updated', 'NotificationSettingsNotifier');
    } catch (e) {
      AppLogger.error('Failed to update notification settings', 'NotificationSettingsNotifier', e);
    }
  }

  Future<void> updatePushNotifications(bool enabled) async {
    state.whenData((currentSettings) {
      final updatedSettings = currentSettings.copyWith(pushNotifications: enabled);
      updateSettings(updatedSettings);
    });
  }

  Future<void> updateMissionNotifications(bool enabled) async {
    state.whenData((currentSettings) {
      final updatedSettings = currentSettings.copyWith(missionNotifications: enabled);
      updateSettings(updatedSettings);
    });
  }

  Future<void> updatePointsNotifications(bool enabled) async {
    state.whenData((currentSettings) {
      final updatedSettings = currentSettings.copyWith(pointsNotifications: enabled);
      updateSettings(updatedSettings);
    });
  }

  Future<void> updateRankingNotifications(bool enabled) async {
    state.whenData((currentSettings) {
      final updatedSettings = currentSettings.copyWith(rankingNotifications: enabled);
      updateSettings(updatedSettings);
    });
  }

  Future<void> updateSystemNotifications(bool enabled) async {
    state.whenData((currentSettings) {
      final updatedSettings = currentSettings.copyWith(systemNotifications: enabled);
      updateSettings(updatedSettings);
    });
  }

  Future<void> updateMarketingNotifications(bool enabled) async {
    state.whenData((currentSettings) {
      final updatedSettings = currentSettings.copyWith(marketingNotifications: enabled);
      updateSettings(updatedSettings);
    });
  }
}

class FCMTokenNotifier extends StateNotifier<AsyncValue<String?>> {
  final NotificationRepository _repository;
  final FCMService _fcmService;
  // Get current user ID dynamically
  String get _currentUserId => CurrentUserService.getCurrentUserIdOrDefault();

  FCMTokenNotifier(this._repository, this._fcmService) : super(const AsyncValue.loading()) {
    initializeToken();
  }

  Future<void> initializeToken() async {
    try {
      state = const AsyncValue.loading();
      
      // Get token from FCM
      final token = await _fcmService.getToken();
      if (token != null) {
        // Save token to repository
        await _repository.saveFcmToken(_currentUserId, token);
        state = AsyncValue.data(token);
        
        AppLogger.info('FCM token initialized', 'FCMTokenNotifier');
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      AppLogger.error('Failed to initialize FCM token', 'FCMTokenNotifier', e);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshToken() async {
    await initializeToken();
  }

  Future<void> deleteToken() async {
    try {
      await _repository.deleteFcmToken(_currentUserId);
      state = const AsyncValue.data(null);
      AppLogger.info('FCM token deleted', 'FCMTokenNotifier');
    } catch (e) {
      AppLogger.error('Failed to delete FCM token', 'FCMTokenNotifier', e);
    }
  }

  Future<void> updateToken(String token) async {
    try {
      await _repository.saveFcmToken(_currentUserId, token);
      state = AsyncValue.data(token);
      AppLogger.info('FCM token updated', 'FCMTokenNotifier');
    } catch (e) {
      AppLogger.error('Failed to update FCM token', 'FCMTokenNotifier', e);
    }
  }
}

// Real-time stream providers
final notificationStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = CurrentUserService.getCurrentUserIdOrDefault();
  return repository.watchNotifications(userId);
});

final unreadCountStreamProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = CurrentUserService.getCurrentUserIdOrDefault();
  return repository.watchUnreadCount(userId);
});

final notificationSettingsStreamProvider = StreamProvider<NotificationSettings>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = CurrentUserService.getCurrentUserIdOrDefault();
  return repository.watchNotificationSettings(userId);
});