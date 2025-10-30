/// v2.185.1: 사용자 알림 BottomSheet
/// 테스터와 공급자가 자신의 알림을 확인하는 공통 위젯

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationBottomSheet extends StatelessWidget {
  final String userId;

  const NotificationBottomSheet({
    super.key,
    required this.userId,
  });

  /// 알림을 읽음으로 표시
  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  /// 모든 알림을 읽음으로 표시
  Future<void> _markAllAsRead(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 알림을 읽음으로 표시했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Failed to mark all as read: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    '알림',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _markAllAsRead(context),
                    child: const Text('모두 읽음'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 알림 목록
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('user_notifications')
                    .where('recipientId', isEqualTo: userId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('오류 발생: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final notifications = snapshot.data?.docs ?? [];

                  if (notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '알림이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final notificationId = doc.id;
                      final title = data['title'] as String? ?? '제목 없음';
                      final message = data['message'] as String? ?? '';
                      final isRead = data['isRead'] as bool? ?? false;
                      final createdAt =
                          (data['createdAt'] as Timestamp?)?.toDate();
                      final typeString = data['type'] as String? ?? 'custom';

                      // NotificationType 변환
                      final type = NotificationTypeExtension.fromFirestoreString(
                          typeString);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isRead ? Colors.grey[200] : Colors.blue[100],
                          child: Text(
                            type.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Row(
                          children: [
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                color: isRead ? Colors.grey : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              createdAt != null
                                  ? _formatDateTime(createdAt)
                                  : '시간 정보 없음',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        tileColor:
                            isRead ? Colors.white : Colors.blue[50]?.withValues(alpha: 0.3),
                        onTap: () async {
                          // 읽음 처리
                          if (!isRead) {
                            await _markAsRead(notificationId);
                          }

                          // TODO: 알림 타입에 따라 관련 페이지로 이동 (Phase 2)
                          // if (data['actionUrl'] != null) {
                          //   Navigator.of(context).pushNamed(data['actionUrl']);
                          // }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM.dd HH:mm').format(dateTime);
    }
  }
}
