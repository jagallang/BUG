import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  system,
  notification,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message extends Equatable {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? readAt;
  final bool isDeleted;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.mediaUrl,
    required this.status,
    required this.createdAt,
    this.editedAt,
    this.readAt,
    this.isDeleted = false,
    this.replyToMessageId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        chatRoomId,
        senderId,
        senderName,
        senderAvatar,
        type,
        content,
        mediaUrl,
        status,
        createdAt,
        editedAt,
        readAt,
        isDeleted,
        replyToMessageId,
        metadata,
      ];

  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? content,
    String? mediaUrl,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? readAt,
    bool? isDeleted,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }
}