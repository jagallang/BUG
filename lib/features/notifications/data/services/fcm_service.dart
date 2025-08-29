import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../../core/utils/logger.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final NotificationRepository _notificationRepository;

  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._internal();

  FCMService._internal()
      : _firebaseMessaging = FirebaseMessaging.instance,
        _localNotifications = FlutterLocalNotificationsPlugin(),
        _notificationRepository = _getRepository();

  static NotificationRepository _getRepository() {
    // This would normally come from DI container
    throw UnimplementedError('Repository should be injected through DI');
  }

  // Initialize FCM service
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Configure FCM
      await _configureFCM();
      
      AppLogger.info('FCM Service initialized successfully', 'FCMService');
    } catch (e) {
      AppLogger.error('Failed to initialize FCM service', 'FCMService', e);
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    AppLogger.info('Notification permission status: ${settings.authorizationStatus}', 'FCMService');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'bugcash_channel',
      'BugCash Notifications',
      description: 'Notifications from BugCash app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Configure FCM message handlers
  Future<void> _configureFCM() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    
    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    
    // Handle messages when app is terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }
  }

  // Handle foreground messages
  void _onForegroundMessage(RemoteMessage message) {
    AppLogger.info('Received foreground message: ${message.messageId}', 'FCMService');
    
    // Show local notification when app is in foreground
    _showLocalNotification(message);
    
    // Save notification to repository
    _saveNotificationFromMessage(message);
  }

  // Handle message tap when app is in background
  void _onMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('App opened from notification: ${message.messageId}', 'FCMService');
    
    // Handle navigation based on notification data
    _handleNotificationNavigation(message);
    
    // Save notification to repository if not already saved
    _saveNotificationFromMessage(message);
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Local notification tapped: ${response.payload}', 'FCMService');
    
    // Handle navigation based on payload
    if (response.payload != null) {
      _navigateToScreen(response.payload!);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'bugcash_channel',
      'BugCash Notifications',
      channelDescription: 'Notifications from BugCash app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
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
      message.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data['actionUrl'],
    );
  }

  // Save notification from Firebase message
  Future<void> _saveNotificationFromMessage(RemoteMessage message) async {
    try {
      final notification = _createNotificationFromMessage(message);
      await _notificationRepository.createNotification(notification);
    } catch (e) {
      AppLogger.error('Failed to save notification from message', 'FCMService', e);
    }
  }

  // Create NotificationModel from RemoteMessage
  NotificationModel _createNotificationFromMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: message.data['userId'] ?? 'demo_user', // TODO: Get actual user ID
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: _getNotificationTypeFromData(message.data),
      priority: _getPriorityFromData(message.data),
      data: message.data,
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      actionUrl: message.data['actionUrl'],
      createdAt: DateTime.now(),
      isLocal: false,
    );
  }

  // Get notification type from message data
  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final typeString = data['type'] as String?;
    if (typeString == null) return NotificationType.system;

    return NotificationType.values.firstWhere(
      (type) => type.name == typeString,
      orElse: () => NotificationType.system,
    );
  }

  // Get priority from message data
  NotificationPriority _getPriorityFromData(Map<String, dynamic> data) {
    final priorityString = data['priority'] as String?;
    if (priorityString == null) return NotificationPriority.normal;

    return NotificationPriority.values.firstWhere(
      (priority) => priority.name == priorityString,
      orElse: () => NotificationPriority.normal,
    );
  }

  // Handle notification navigation
  void _handleNotificationNavigation(RemoteMessage message) {
    final actionUrl = message.data['actionUrl'] as String?;
    if (actionUrl != null) {
      _navigateToScreen(actionUrl);
    }
  }

  // Navigate to specific screen based on action URL
  void _navigateToScreen(String actionUrl) {
    // This would be implemented based on your app's navigation system
    AppLogger.info('Navigating to: $actionUrl', 'FCMService');
    
    // Example implementation:
    // if (actionUrl.startsWith('/mission/')) {
    //   final missionId = actionUrl.split('/').last;
    //   Navigator.pushNamed(context, '/mission-detail', arguments: missionId);
    // }
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      AppLogger.info('FCM Token retrieved', 'FCMService');
      return token;
    } catch (e) {
      AppLogger.error('Failed to get FCM token', 'FCMService', e);
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic', 'FCMService');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', 'FCMService', e);
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic', 'FCMService');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', 'FCMService', e);
    }
  }

  // Schedule local notification
  Future<void> scheduleLocalNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
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

      await _localNotifications.zonedSchedule(
        id.hashCode,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      AppLogger.info('Local notification scheduled for: $scheduledDate', 'FCMService');
    } catch (e) {
      AppLogger.error('Failed to schedule local notification', 'FCMService', e);
    }
  }

  // Cancel local notification
  Future<void> cancelLocalNotification(String id) async {
    try {
      await _localNotifications.cancel(id.hashCode);
      AppLogger.info('Local notification cancelled: $id', 'FCMService');
    } catch (e) {
      AppLogger.error('Failed to cancel local notification', 'FCMService', e);
    }
  }

  // Cancel all local notifications
  Future<void> cancelAllLocalNotifications() async {
    try {
      await _localNotifications.cancelAll();
      AppLogger.info('All local notifications cancelled', 'FCMService');
    } catch (e) {
      AppLogger.error('Failed to cancel all local notifications', 'FCMService', e);
    }
  }

  // Listen to token refresh
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  // Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Handling background message: ${message.messageId}', 'FCMService');
  // Handle background message here if needed
}