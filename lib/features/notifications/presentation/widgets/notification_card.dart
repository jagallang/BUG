import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/notification_model.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
      onDismissed: (direction) {
        if (onDelete != null) onDelete!();
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: notification.isRead 
                  ? AppColors.textHint.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w500 
                                      : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                _getNotificationTypeText(notification.type),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: _getNotificationColor(notification.type),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead && onMarkAsRead != null)
                    GestureDetector(
                      onTap: onMarkAsRead,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.mark_email_read,
                          size: 16.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                ],
              ),
              if (notification.priority == NotificationPriority.high || 
                  notification.priority == NotificationPriority.urgent)
                Container(
                  margin: EdgeInsets.only(top: 8.h, left: 36.w),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: notification.priority == NotificationPriority.urgent 
                        ? Colors.red 
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    notification.priority == NotificationPriority.urgent ? '긴급' : '중요',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
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

  String _getNotificationTypeText(NotificationType type) {
    switch (type) {
      case NotificationType.mission:
        return '미션';
      case NotificationType.points:
        return '포인트';
      case NotificationType.ranking:
        return '랭킹';
      case NotificationType.system:
        return '시스템';
      case NotificationType.marketing:
        return '홍보';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }
}