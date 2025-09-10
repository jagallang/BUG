import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_providers.dart';

class MessageInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String chatRoomId;
  final VoidCallback? onMessageSent;

  const MessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.chatRoomId,
    this.onMessageSent,
  });

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      
      // Update typing status
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.read(chatActionsProvider).setTypingStatus(
          chatRoomId: widget.chatRoomId,
          userId: currentUser.uid,
          isTyping: hasText,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = widget.controller.text.trim();
    if (content.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Clear input immediately
    widget.controller.clear();
    setState(() {
      _isTyping = false;
    });

    // Stop typing indicator
    await ref.read(chatActionsProvider).setTypingStatus(
      chatRoomId: widget.chatRoomId,
      userId: currentUser.uid,
      isTyping: false,
    );

    // Send message
    final chatActions = ref.read(chatActionsProvider);
    final success = await chatActions.sendMessage(
      chatRoomId: widget.chatRoomId,
      senderId: currentUser.uid,
      content: content,
      type: MessageType.text,
    );

    if (success) {
      widget.onMessageSent?.call();
    } else {
      // Restore text if sending failed
      widget.controller.text = content;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지 전송에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _selectImage() async {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 전송 기능 준비중입니다')),
    );
  }

  Future<void> _selectFile() async {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('파일 전송 기능 준비중입니다')),
    );
  }

  void _showAttachmentOptions() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: '사진',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _selectImage();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: '파일',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _selectFile();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: '카메라',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Open camera
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카메라 기능 준비중입니다')),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28.w,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: const Icon(Icons.add),
              iconSize: 24.w,
              color: Theme.of(context).colorScheme.primary,
            ),
            
            // Text input
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 40.h,
                  maxHeight: 120.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            SizedBox(width: 8.w),
            
            // Send button
            GestureDetector(
              onTap: _isTyping ? _sendMessage : null,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _isTyping
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _isTyping ? Colors.white : Colors.grey[600],
                  size: 20.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}