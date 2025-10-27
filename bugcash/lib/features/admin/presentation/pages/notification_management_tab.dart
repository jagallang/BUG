/// v2.185.0: 알림 관리 탭 (관리자 대시보드)
/// 관리자가 사용자들에게 알림을 발송하고 이력을 관리하는 페이지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../notification/domain/entities/notification_entity.dart';

class NotificationManagementTab extends StatefulWidget {
  const NotificationManagementTab({super.key});

  @override
  State<NotificationManagementTab> createState() => _NotificationManagementTabState();
}

class _NotificationManagementTabState extends State<NotificationManagementTab> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRecipientType = 'all'; // all, testers, providers, specific
  String? _selectedUserId;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// 알림 발송
  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('제목을 입력하세요', Colors.red);
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('내용을 입력하세요', Colors.red);
      return;
    }

    setState(() => _isSending = true);

    try {
      // 수신자 목록 조회
      List<String> recipientIds = [];

      if (_selectedRecipientType == 'all') {
        // 전체 사용자
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();
        recipientIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      } else if (_selectedRecipientType == 'testers') {
        // 테스터만
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('primaryRole', isEqualTo: 'tester')
            .get();
        recipientIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      } else if (_selectedRecipientType == 'providers') {
        // 공급자만
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('primaryRole', isEqualTo: 'provider')
            .get();
        recipientIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      } else if (_selectedRecipientType == 'specific' && _selectedUserId != null) {
        recipientIds = [_selectedUserId!];
      }

      if (recipientIds.isEmpty) {
        _showSnackBar('수신자가 없습니다', Colors.orange);
        setState(() => _isSending = false);
        return;
      }

      // 알림 생성 (각 사용자별로)
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      for (final userId in recipientIds) {
        final notificationRef = FirebaseFirestore.instance
            .collection('user_notifications')
            .doc();

        batch.set(notificationRef, {
          'recipientId': userId,
          'recipientRole': _selectedRecipientType,
          'type': 'admin_message',
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'data': {},
          'isRead': false,
          'createdAt': Timestamp.fromDate(now),
          'readAt': null,
          'sentBy': 'admin', // 실제로는 현재 관리자 userId
        });
      }

      await batch.commit();

      _showSnackBar('✅ ${recipientIds.length}명에게 알림을 발송했습니다', Colors.green);

      // 입력 필드 초기화
      _titleController.clear();
      _messageController.clear();

    } catch (e) {
      _showSnackBar('❌ 알림 발송 실패: $e', Colors.red);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Text(
            '알림 관리',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '사용자들에게 알림을 발송하고 이력을 관리합니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // 알림 발송 섹션
          _buildSendNotificationSection(),

          const SizedBox(height: 48),

          // 발송 이력 섹션
          _buildNotificationHistorySection(),
        ],
      ),
    );
  }

  /// 알림 발송 섹션
  Widget _buildSendNotificationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '알림 발송',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 수신자 선택
          const Text(
            '수신자',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _buildRecipientChip('전체', 'all'),
              _buildRecipientChip('테스터만', 'testers'),
              _buildRecipientChip('공급자만', 'providers'),
              // _buildRecipientChip('특정 사용자', 'specific'), // Phase 2
            ],
          ),
          const SizedBox(height: 24),

          // 제목 입력
          const Text(
            '제목',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '알림 제목을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),

          // 내용 입력
          const Text(
            '내용',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: '알림 내용을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 4,
            maxLength: 200,
          ),
          const SizedBox(height: 24),

          // 발송 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotification,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? '발송 중...' : '알림 발송'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 수신자 선택 칩
  Widget _buildRecipientChip(String label, String value) {
    final isSelected = _selectedRecipientType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRecipientType = value);
        }
      },
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  /// 발송 이력 섹션
  Widget _buildNotificationHistorySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    '발송 이력',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('새로고침'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 알림 목록 (StreamBuilder)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user_notifications')
                .where('sentBy', isEqualTo: 'admin')
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('오류 발생: ${snapshot.error}'),
                );
              }

              final notifications = snapshot.data?.docs ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '발송한 알림이 없습니다',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 중복 제거 (같은 title/message는 하나만 표시)
              final uniqueNotifications = <String, QueryDocumentSnapshot>{};
              for (final doc in notifications) {
                final data = doc.data() as Map<String, dynamic>;
                final key = '${data['title']}_${data['message']}';
                if (!uniqueNotifications.containsKey(key)) {
                  uniqueNotifications[key] = doc;
                }
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uniqueNotifications.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final doc = uniqueNotifications.values.elementAt(index);
                  final data = doc.data() as Map<String, dynamic>;

                  final title = data['title'] as String? ?? '제목 없음';
                  final message = data['message'] as String? ?? '';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final recipientRole = data['recipientRole'] as String? ?? 'all';

                  // 같은 title/message를 가진 알림 개수 (수신자 수)
                  final recipientCount = notifications.where((n) {
                    final nData = n.data() as Map<String, dynamic>;
                    return nData['title'] == title && nData['message'] == message;
                  }).length;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(Icons.notifications, color: Colors.blue),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$recipientCount명 수신',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              createdAt != null
                                  ? _formatDateTime(createdAt)
                                  : '시간 정보 없음',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        _getRecipientRoleText(recipientRole),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getRecipientRoleColor(recipientRole),
                      padding: EdgeInsets.zero,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

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
      return DateFormat('yy.MM.dd HH:mm').format(dateTime);
    }
  }

  String _getRecipientRoleText(String role) {
    switch (role) {
      case 'all':
        return '전체';
      case 'testers':
        return '테스터';
      case 'providers':
        return '공급자';
      default:
        return role;
    }
  }

  Color _getRecipientRoleColor(String role) {
    switch (role) {
      case 'all':
        return Colors.purple[100]!;
      case 'testers':
        return Colors.green[100]!;
      case 'providers':
        return Colors.orange[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
