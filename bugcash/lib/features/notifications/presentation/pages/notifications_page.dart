import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter.dart';
import '../../domain/models/notification_model.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationListProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🔔 알림'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: Icon(
              _selectedFilter != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
              size: 20.sp,
            ),
            tooltip: '필터',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20.sp,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('모두 읽음 처리'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete_read',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('읽은 알림 삭제'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('알림 설정'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('전체'),
                  SizedBox(width: 4.w),
                  notificationsAsync.when(
                    data: (notifications) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${notifications.length}',
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('읽지 않음'),
                  SizedBox(width: 4.w),
                  unreadCountAsync.when(
                    data: (count) => count > 0
                        ? Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(notificationsAsync, false),
          _buildNotificationsList(notificationsAsync, true),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(AsyncValue<List<NotificationModel>> notificationsAsync, bool unreadOnly) {
    return notificationsAsync.when(
      data: (notifications) {
        var filteredNotifications = notifications;
        
        // Filter by read status
        if (unreadOnly) {
          filteredNotifications = notifications.where((n) => !n.isRead).toList();
        }
        
        // Filter by type
        if (_selectedFilter != null) {
          filteredNotifications = filteredNotifications.where((n) => n.type == _selectedFilter).toList();
        }

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState(unreadOnly);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(notificationListProvider.notifier).refreshNotifications();
            ref.read(unreadNotificationCountProvider.notifier).refreshUnreadCount();
          },
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: filteredNotifications.length,
            separatorBuilder: (context, index) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onMarkAsRead: () => _markAsRead(notification),
                onDelete: () => _deleteNotification(notification),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16.h),
            Text(
              '알림을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () => ref.refresh(notificationListProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool unreadOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unreadOnly ? Icons.mark_email_read : Icons.notifications_off,
            size: 64.sp,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16.h),
          Text(
            unreadOnly ? '읽지 않은 알림이 없습니다' : '알림이 없습니다',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            unreadOnly
                ? '모든 알림을 확인하셨습니다!'
                : '새로운 알림이 오면 여기에 표시됩니다',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationFilter(
        selectedType: _selectedFilter,
        onFilterChanged: (type) {
          setState(() {
            _selectedFilter = type;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _showMarkAllReadDialog();
        break;
      case 'delete_read':
        _showDeleteReadDialog();
        break;
      case 'settings':
        _navigateToSettings();
        break;
    }
  }

  void _showMarkAllReadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모두 읽음 처리'),
        content: const Text('모든 알림을 읽음 처리하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationListProvider.notifier).markAllAsRead();
              ref.read(unreadNotificationCountProvider.notifier).resetCount();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 알림을 읽음 처리했습니다')),
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDeleteReadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('읽은 알림 삭제'),
        content: const Text('읽은 알림을 모두 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationListProvider.notifier).deleteReadNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('읽은 알림을 삭제했습니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/notification-settings');
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Handle navigation based on notification type and data
    if (notification.actionUrl != null) {
      _navigateToAction(notification.actionUrl!);
    } else {
      _showNotificationDetail(notification);
    }
  }

  void _markAsRead(NotificationModel notification) {
    if (!notification.isRead) {
      ref.read(notificationListProvider.notifier).markAsRead(notification.id);
      ref.read(unreadNotificationCountProvider.notifier).decrementCount();
    }
  }

  void _deleteNotification(NotificationModel notification) {
    ref.read(notificationListProvider.notifier).deleteNotification(notification.id);
    if (!notification.isRead) {
      ref.read(unreadNotificationCountProvider.notifier).decrementCount();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('알림이 삭제되었습니다'),
        action: SnackBarAction(
          label: '취소',
          onPressed: () {
            // Implement undo functionality if needed
            ref.read(notificationListProvider.notifier).addNotification(notification);
          },
        ),
      ),
    );
  }

  void _navigateToAction(String actionUrl) {
    // Implement navigation logic based on action URL
    // Example:
    // if (actionUrl.startsWith('/mission/')) {
    //   final missionId = actionUrl.split('/').last;
    //   Navigator.pushNamed(context, '/mission-detail', arguments: missionId);
    // }
  }

  void _showNotificationDetail(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MM/dd HH:mm').format(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('닫기'),
                        ),
                      ),
                      if (notification.actionUrl != null) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToAction(notification.actionUrl!);
                            },
                            child: const Text('확인'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.mission:
        return AppColors.primary;
      case NotificationType.points:
        return AppColors.goldText;
      case NotificationType.ranking:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.info;
      case NotificationType.marketing:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.mission:
        return Icons.assignment;
      case NotificationType.points:
        return Icons.monetization_on;
      case NotificationType.ranking:
        return Icons.emoji_events;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.marketing:
        return Icons.campaign;
    }
  }
}