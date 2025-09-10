import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_room.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  // Chat Room Management
  Future<Either<Failure, ChatRoom>> createChatRoom({
    required String name,
    required ChatRoomType type,
    required List<String> participantIds,
    String? missionId,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, ChatRoom>> getChatRoom(String chatRoomId);
  
  Future<Either<Failure, List<ChatRoom>>> getUserChatRooms({
    required String userId,
    ChatRoomType? type,
    bool includeArchived = false,
  });

  Future<Either<Failure, ChatRoom>> updateChatRoom({
    required String chatRoomId,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, void>> archiveChatRoom(String chatRoomId);
  
  Future<Either<Failure, void>> deleteChatRoom(String chatRoomId);

  // Message Management
  Future<Either<Failure, Message>> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, List<Message>>> getMessages({
    required String chatRoomId,
    int limit = 50,
    String? lastMessageId,
  });

  Future<Either<Failure, Message>> updateMessage({
    required String messageId,
    required String content,
  });

  Future<Either<Failure, void>> deleteMessage(String messageId);

  Future<Either<Failure, void>> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
    required String userId,
  });

  // Real-time Streams
  Stream<List<ChatRoom>> watchUserChatRooms(String userId);
  
  Stream<List<Message>> watchChatRoomMessages(String chatRoomId);
  
  Stream<Message> watchNewMessages(String chatRoomId);

  // Typing Indicators
  Future<Either<Failure, void>> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  });

  Stream<Map<String, bool>> watchTypingStatus(String chatRoomId);

  // Participant Management
  Future<Either<Failure, void>> addParticipants({
    required String chatRoomId,
    required List<String> userIds,
  });

  Future<Either<Failure, void>> removeParticipant({
    required String chatRoomId,
    required String userId,
  });

  Future<Either<Failure, void>> updateParticipantRole({
    required String chatRoomId,
    required String userId,
    required String role,
  });

  // Search
  Future<Either<Failure, List<Message>>> searchMessages({
    required String query,
    String? chatRoomId,
    String? userId,
  });

  // Notifications
  Future<Either<Failure, void>> muteChatRoom({
    required String chatRoomId,
    required String userId,
    Duration? duration,
  });

  Future<Either<Failure, void>> unmuteChatRoom({
    required String chatRoomId,
    required String userId,
  });
}