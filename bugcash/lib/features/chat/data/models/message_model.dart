import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.chatRoomId,
    required super.senderId,
    required super.senderName,
    super.senderAvatar,
    required super.type,
    required super.content,
    super.mediaUrl,
    required super.status,
    required super.createdAt,
    super.editedAt,
    super.readAt,
    super.isDeleted,
    super.replyToMessageId,
    super.metadata,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'],
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null 
          ? (data['editedAt'] as Timestamp).toDate() 
          : null,
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate() 
          : null,
      isDeleted: data['isDeleted'] ?? false,
      replyToMessageId: data['replyToMessageId'],
      metadata: data['metadata']?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isDeleted': isDeleted,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      chatRoomId: message.chatRoomId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      type: message.type,
      content: message.content,
      mediaUrl: message.mediaUrl,
      status: message.status,
      createdAt: message.createdAt,
      editedAt: message.editedAt,
      readAt: message.readAt,
      isDeleted: message.isDeleted,
      replyToMessageId: message.replyToMessageId,
      metadata: message.metadata,
    );
  }
}