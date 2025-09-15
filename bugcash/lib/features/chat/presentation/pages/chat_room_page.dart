import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/typing_indicator.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String? chatRoomName;

  const ChatRoomPage({
    super.key,
    required this.chatRoomId,
    this.chatRoomName,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Set the current chat room ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedChatRoomProvider.notifier).state = widget.chatRoomId;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    
    // Clear the current chat room ID
    ref.read(selectedChatRoomProvider.notifier).state = null;
    
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onMessageSent() {
    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomAsync = ref.watch(chatRepositoryProvider.select((repo) =>
        repo.getChatRoom(widget.chatRoomId)));
    final messagesAsync = ref.watch(chatRoomMessagesProvider(widget.chatRoomId));
    final typingStatus = ref.watch(typingStatusProvider(widget.chatRoomId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: FutureBuilder(
          future: chatRoomAsync,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isRight()) {
              final chatRoom = snapshot.data!.fold(
                (failure) => null,
                (chatRoom) => chatRoom,
              );
              
              return ChatAppBar(
                chatRoom: chatRoom,
                onBackPressed: () => Navigator.of(context).pop(),
                onCallPressed: () {
                  // TODO: Implement voice call
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('음성 통화 기능 준비중입니다')),
                  );
                },
                onVideoCallPressed: () {
                  // TODO: Implement video call
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('영상 통화 기능 준비중입니다')),
                  );
                },
                onMorePressed: () {
                  _showChatRoomOptions(chatRoom);
                },
              );
            }
            
            return ChatAppBar(
              chatRoom: null,
              title: widget.chatRoomName ?? '채팅',
              onBackPressed: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages, currentUser),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.w,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '메시지를 불러올 수 없습니다',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(chatRoomMessagesProvider(widget.chatRoomId));
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Typing Indicator
          typingStatus.when(
            data: (typing) => _buildTypingIndicator(typing, currentUser?.uid),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          
          // Message Input
          MessageInput(
            controller: _messageController,
            focusNode: _messageFocusNode,
            chatRoomId: widget.chatRoomId,
            onMessageSent: _onMessageSent,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages, currentUser) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToBottom();
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousMessage = index > 0 ? messages[index - 1] : null;
        final nextMessage = index < messages.length - 1 ? messages[index + 1] : null;
        
        final showSenderInfo = previousMessage == null || 
                               previousMessage.senderId != message.senderId ||
                               message.createdAt.difference(previousMessage.createdAt).inMinutes > 5;
        
        final showTimestamp = nextMessage == null ||
                             nextMessage.senderId != message.senderId ||
                             nextMessage.createdAt.difference(message.createdAt).inMinutes > 5;

        return MessageBubble(
          message: message,
          isCurrentUser: currentUser?.uid == message.senderId,
          showSenderInfo: showSenderInfo,
          showTimestamp: showTimestamp,
          onReply: () => _replyToMessage(message),
          onDelete: currentUser?.uid == message.senderId 
              ? () => _deleteMessage(message) 
              : null,
          onEdit: currentUser?.uid == message.senderId 
              ? () => _editMessage(message) 
              : null,
        );
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
            '아직 메시지가 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '첫 번째 메시지를 보내보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Map<String, bool> typingUsers, String? currentUserId) {
    final activeTypers = typingUsers.entries
        .where((entry) => entry.value && entry.key != currentUserId)
        .map((entry) => entry.key)
        .toList();

    if (activeTypers.isEmpty) {
      return const SizedBox.shrink();
    }

    return TypingIndicator(userIds: activeTypers);
  }

  void _replyToMessage(Message message) {
    // TODO: Implement reply functionality
    ref.read(messageInputProvider.notifier).state = 
        '${message.senderName}님에게 답장: ';
    _messageFocusNode.requestFocus();
  }

  void _editMessage(Message message) {
    // TODO: Implement edit functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메시지 수정'),
        content: TextField(
          controller: TextEditingController(text: message.content),
          decoration: const InputDecoration(
            hintText: '메시지를 입력하세요...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update message
              Navigator.of(context).pop();
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final chatActions = ref.read(chatActionsProvider);
              final success = await chatActions.deleteMessage(message.id);
              
              if (mounted) {
                Navigator.of(context).pop();
                
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('메시지 삭제에 실패했습니다')),
                  );
                }
              }
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

  void _showChatRoomOptions(ChatRoom? chatRoom) {
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
              '채팅 옵션',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            
            if (chatRoom != null) ...[
              ListTile(
                leading: Icon(chatRoom.isMuted ? Icons.notifications_off : Icons.notifications),
                title: Text(chatRoom.isMuted ? '알림 켜기' : '알림 끄기'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Toggle mute status
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('채팅방 보관'),
                onTap: () {
                  Navigator.pop(context);
                  _archiveChatRoom();
                },
              ),
              
              if (chatRoom.type == ChatRoomType.group) ...[
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('참가자 관리'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to participants page
                  },
                ),
              ],
            ],
            
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _archiveChatRoom() async {
    final chatActions = ref.read(chatActionsProvider);
    final success = await chatActions.archiveChatRoom(widget.chatRoomId);
    
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채팅방이 보관되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채팅방 보관에 실패했습니다')),
        );
      }
    }
  }
}