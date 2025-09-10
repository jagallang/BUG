import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final bool showSenderInfo;
  final bool showTimestamp;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showSenderInfo = true,
    this.showTimestamp = true,
    this.onReply,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(),
            SizedBox(width: 8.w),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showSenderInfo && !isCurrentUser)
                  _buildSenderInfo(context),
                
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: _buildMessageContent(context),
                ),
                
                if (showTimestamp)
                  _buildTimestamp(context),
              ],
            ),
          ),
          
          if (isCurrentUser) ...[
            SizedBox(width: 8.w),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16.w,
      backgroundColor: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
      backgroundImage: message.senderAvatar != null
          ? NetworkImage(message.senderAvatar!)
          : null,
      child: message.senderAvatar == null
          ? Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.blue[700] : Colors.grey[700],
              ),
            )
          : null,
    );
  }

  Widget _buildSenderInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
      child: Text(
        message.senderName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage(context);
    }

    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.system:
        return _buildSystemMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 250.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyToMessageId != null)
            _buildReplyReference(context),
          
          Text(
            message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isCurrentUser ? Colors.white : Colors.black87,
            ),
          ),
          
          if (message.editedAt != null)
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                '(편집됨)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                  fontSize: 10.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 200.w, maxHeight: 200.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: message.mediaUrl != null
            ? Image.network(
                message.mediaUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150.h,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150.h,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 24.w, color: Colors.red),
                      SizedBox(height: 4.h),
                      Text(
                        '이미지 로드 실패',
                        style: TextStyle(fontSize: 12.sp, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                height: 150.h,
                alignment: Alignment.center,
                child: Icon(Icons.image, size: 48.w, color: Colors.grey[400]),
              ),
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 250.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            size: 20.w,
            color: isCurrentUser ? Colors.white : Colors.grey[700],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isCurrentUser ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        message.content,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDeletedMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, size: 16.w, color: Colors.grey[600]),
          SizedBox(width: 4.w),
          Text(
            '삭제된 메시지입니다',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyReference(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isCurrentUser ? Colors.white.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Text(
        '답장 중...', // TODO: Show actual replied message content
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isCurrentUser ? Colors.white70 : Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final statusIcon = _getStatusIcon();

    return Padding(
      padding: EdgeInsets.only(
        top: 4.h,
        left: isCurrentUser ? 0 : 8.w,
        right: isCurrentUser ? 8.w : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeFormat.format(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11.sp,
            ),
          ),
          if (isCurrentUser && statusIcon != null) ...[
            SizedBox(width: 4.w),
            Icon(
              statusIcon,
              size: 12.w,
              color: _getStatusColor(),
            ),
          ],
        ],
      ),
    );
  }

  IconData? _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return null;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showMessageOptions(BuildContext context) {
    if (message.isDeleted) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('답장'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('복사'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy message content to clipboard
              },
            ),
            
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('수정'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}