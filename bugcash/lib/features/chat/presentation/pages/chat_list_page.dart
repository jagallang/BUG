import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'chat_room_page.dart';
import 'user_search_page.dart';
import '../providers/chat_providers.dart';
import '../../domain/entities/chat_room.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  ChatRoomType? _selectedFilter;

  Future<void> _loginBypass() async {
    try {
      // Create a mock user for testing
      final mockUser = UserEntity(
        uid: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'test@example.com',
        displayName: '테스트 사용자',
        photoUrl: null,
        userType: UserType.tester,
        country: 'KR',
        timezone: 'Asia/Seoul',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        lastLoginAt: DateTime.now(),
        profile: const UserProfile(
          bio: '테스트용 계정입니다',
          skills: ['Flutter', 'Testing'],
          languages: ['Korean'],
        ),
        level: 1,
        completedMissions: 0,
        points: 100,
      );

      // Set the mock user as current user
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.setMockUser(mockUser);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 사용자로 로그인했습니다: ${mockUser.displayName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 우회 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('채팅'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserSearchPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                '로그인이 필요합니다',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _loginBypass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                ),
                child: Text(
                  '테스트용 로그인 우회',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '개발자 테스트 목적으로만 사용하세요',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSearchPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 채팅 필터 탭
          _buildFilterTabs(),
          
          // 채팅방 목록
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 새 채팅 시작 기능
          _showNewChatOptions();
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildFilterChip('전체', true),
          SizedBox(width: 8.w),
          _buildFilterChip('미션', false),
          SizedBox(width: 8.w),
          _buildFilterChip('1:1', false),
          SizedBox(width: 8.w),
          _buildFilterChip('지원', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: 필터링 로직 구현
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildChatList() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return _buildEmptyState();
    
    final chatRoomsFilter = ChatRoomFilter(
      userId: currentUser.uid,
      type: _selectedFilter,
    );
    
    final chatRooms = ref.watch(filteredChatRoomsProvider(chatRoomsFilter));

    if (chatRooms.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        return _buildChatRoomTile(chatRoom);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            '채팅이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '미션 참여 시 자동으로 채팅방이 생성됩니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoom chatRoom) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24.w,
            backgroundColor: _getChatRoomTypeColor(chatRoom.type),
            backgroundImage: chatRoom.avatarUrl != null 
                ? NetworkImage(chatRoom.avatarUrl!) 
                : null,
            child: chatRoom.avatarUrl == null 
                ? _getChatRoomTypeIcon(chatRoom.type) 
                : null,
          ),
          if (_isAnyParticipantOnline(chatRoom))
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chatRoom.name,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: chatRoom.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        chatRoom.lastMessage ?? '메시지가 없습니다',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: chatRoom.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
          fontWeight: chatRoom.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chatRoom.lastMessageTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: chatRoom.unreadCount > 0 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey[500],
              fontWeight: chatRoom.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (chatRoom.unreadCount > 0)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${chatRoom.unreadCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10.sp,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoomId: chatRoom.id,
              chatRoomName: chatRoom.name,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24.w,
            backgroundColor: _getChatTypeColor(chat['type']),
            child: _getChatTypeIcon(chat['type']),
          ),
          if (chat['isOnline'])
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat['name'],
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: chat['unreadCount'] > 0 ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        chat['lastMessage'],
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: chat['unreadCount'] > 0 ? Colors.black87 : Colors.grey[600],
          fontWeight: chat['unreadCount'] > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat['time'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: chat['unreadCount'] > 0 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey[500],
              fontWeight: chat['unreadCount'] > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (chat['unreadCount'] > 0)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${chat['unreadCount']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10.sp,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        _openChatRoom(chat);
      },
    );
  }

  Color _getChatRoomTypeColor(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.mission:
        return Colors.purple[100]!;
      case ChatRoomType.direct:
        return Colors.green[100]!;
      case ChatRoomType.support:
        return Colors.orange[100]!;
      case ChatRoomType.group:
        return Colors.blue[100]!;
      case ChatRoomType.broadcast:
        return Colors.red[100]!;
    }
  }

  Widget _getChatRoomTypeIcon(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.mission:
        return Icon(Icons.assignment, color: Colors.purple[700], size: 20.w);
      case ChatRoomType.direct:
        return Icon(Icons.person, color: Colors.green[700], size: 20.w);
      case ChatRoomType.support:
        return Icon(Icons.support_agent, color: Colors.orange[700], size: 20.w);
      case ChatRoomType.group:
        return Icon(Icons.group, color: Colors.blue[700], size: 20.w);
      case ChatRoomType.broadcast:
        return Icon(Icons.campaign, color: Colors.red[700], size: 20.w);
    }
  }

  bool _isAnyParticipantOnline(ChatRoom chatRoom) {
    return chatRoom.participants.values.any((participant) => participant.isOnline);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.month}/${dateTime.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금';
    }
  }

  Color _getChatTypeColor(String type) {
    switch (type) {
      case 'mission':
        return Colors.blue[100]!;
      case 'direct':
        return Colors.green[100]!;
      case 'support':
        return Colors.orange[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Widget _getChatTypeIcon(String type) {
    switch (type) {
      case 'mission':
        return Icon(Icons.assignment, color: Colors.blue[700], size: 20.w);
      case 'direct':
        return Icon(Icons.person, color: Colors.green[700], size: 20.w);
      case 'support':
        return Icon(Icons.support_agent, color: Colors.orange[700], size: 20.w);
      default:
        return Icon(Icons.chat, color: Colors.grey[700], size: 20.w);
    }
  }

  void _openChatRoom(Map<String, dynamic> chat) {
    // For mock data, generate a mock chat room ID
    final chatRoomId = 'mock_${chat['type']}_${DateTime.now().millisecondsSinceEpoch}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          chatRoomId: chatRoomId,
          chatRoomName: chat['name'],
        ),
      ),
    );
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '새 채팅',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('고객 지원팀과 채팅'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 고객 지원 채팅 시작
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('사용자와 직접 채팅'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserSearchPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}