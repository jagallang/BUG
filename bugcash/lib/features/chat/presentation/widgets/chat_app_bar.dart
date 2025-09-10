import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/chat_room.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatRoom? chatRoom;
  final String? title;
  final VoidCallback onBackPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onVideoCallPressed;
  final VoidCallback? onMorePressed;

  const ChatAppBar({
    super.key,
    this.chatRoom,
    this.title,
    required this.onBackPressed,
    this.onCallPressed,
    this.onVideoCallPressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        onPressed: onBackPressed,
        icon: const Icon(Icons.arrow_back),
      ),
      title: _buildTitle(context),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (chatRoom == null) {
      return Text(
        title ?? '채팅',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Row(
      children: [
        _buildChatRoomAvatar(),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                chatRoom!.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              _buildSubtitle(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatRoomAvatar() {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getChatTypeColor(),
      ),
      child: chatRoom!.avatarUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Image.network(
                chatRoom!.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _getChatTypeIcon();
                },
              ),
            )
          : _getChatTypeIcon(),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    if (chatRoom == null) return const SizedBox.shrink();

    String subtitle = '';
    Color subtitleColor = Colors.grey[600]!;

    switch (chatRoom!.type) {
      case ChatRoomType.direct:
        // Show online status for direct chats
        final isOnline = _getOnlineStatus();
        subtitle = isOnline ? '온라인' : '오프라인';
        subtitleColor = isOnline ? Colors.green : Colors.grey[600]!;
        break;
      case ChatRoomType.group:
        subtitle = '참여자 ${chatRoom!.participantIds.length}명';
        break;
      case ChatRoomType.mission:
        subtitle = '미션 채팅';
        break;
      case ChatRoomType.support:
        subtitle = '고객 지원';
        break;
      case ChatRoomType.broadcast:
        subtitle = '공지사항';
        break;
    }

    return Text(
      subtitle,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: subtitleColor,
        fontSize: 11.sp,
      ),
    );
  }

  List<Widget> _buildActions() {
    final actions = <Widget>[];

    // Voice call button (only for direct chats)
    if (chatRoom?.type == ChatRoomType.direct && onCallPressed != null) {
      actions.add(
        IconButton(
          onPressed: onCallPressed,
          icon: const Icon(Icons.call),
        ),
      );
    }

    // Video call button (only for direct chats)
    if (chatRoom?.type == ChatRoomType.direct && onVideoCallPressed != null) {
      actions.add(
        IconButton(
          onPressed: onVideoCallPressed,
          icon: const Icon(Icons.videocam),
        ),
      );
    }

    // More options button
    if (onMorePressed != null) {
      actions.add(
        IconButton(
          onPressed: onMorePressed,
          icon: const Icon(Icons.more_vert),
        ),
      );
    }

    return actions;
  }

  Color _getChatTypeColor() {
    if (chatRoom == null) return Colors.grey[100]!;

    switch (chatRoom!.type) {
      case ChatRoomType.direct:
        return Colors.green[100]!;
      case ChatRoomType.group:
        return Colors.blue[100]!;
      case ChatRoomType.mission:
        return Colors.purple[100]!;
      case ChatRoomType.support:
        return Colors.orange[100]!;
      case ChatRoomType.broadcast:
        return Colors.red[100]!;
    }
  }

  Widget _getChatTypeIcon() {
    if (chatRoom == null) {
      return Icon(Icons.chat, size: 18.w, color: Colors.grey[600]);
    }

    IconData iconData;
    Color iconColor;

    switch (chatRoom!.type) {
      case ChatRoomType.direct:
        iconData = Icons.person;
        iconColor = Colors.green[700]!;
        break;
      case ChatRoomType.group:
        iconData = Icons.group;
        iconColor = Colors.blue[700]!;
        break;
      case ChatRoomType.mission:
        iconData = Icons.assignment;
        iconColor = Colors.purple[700]!;
        break;
      case ChatRoomType.support:
        iconData = Icons.support_agent;
        iconColor = Colors.orange[700]!;
        break;
      case ChatRoomType.broadcast:
        iconData = Icons.campaign;
        iconColor = Colors.red[700]!;
        break;
    }

    return Icon(iconData, size: 18.w, color: iconColor);
  }

  bool _getOnlineStatus() {
    if (chatRoom == null || chatRoom!.type != ChatRoomType.direct) {
      return false;
    }

    // For direct chats, check if any participant is online
    return chatRoom!.participants.values.any((participant) => participant.isOnline);
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}