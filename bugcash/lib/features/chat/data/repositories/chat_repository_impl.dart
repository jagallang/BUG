import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ChatRoom>> createChatRoom({
    required String name,
    required ChatRoomType type,
    required List<String> participantIds,
    String? missionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await remoteDataSource.createChatRoom(
        name: name,
        type: type,
        participantIds: participantIds,
        missionId: missionId,
        metadata: metadata,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> getChatRoom(String chatRoomId) async {
    try {
      final result = await remoteDataSource.getChatRoom(chatRoomId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatRoom>>> getUserChatRooms({
    required String userId,
    ChatRoomType? type,
    bool includeArchived = false,
  }) async {
    try {
      final result = await remoteDataSource.getUserChatRooms(
        userId: userId,
        type: type,
        includeArchived: includeArchived,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> updateChatRoom({
    required String chatRoomId,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await remoteDataSource.updateChatRoom(
        chatRoomId: chatRoomId,
        name: name,
        avatarUrl: avatarUrl,
        metadata: metadata,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> archiveChatRoom(String chatRoomId) async {
    try {
      await remoteDataSource.archiveChatRoom(chatRoomId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChatRoom(String chatRoomId) async {
    try {
      await remoteDataSource.deleteChatRoom(chatRoomId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await remoteDataSource.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages({
    required String chatRoomId,
    int limit = 50,
    String? lastMessageId,
  }) async {
    try {
      final result = await remoteDataSource.getMessages(
        chatRoomId: chatRoomId,
        limit: limit,
        lastMessageId: lastMessageId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> updateMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final result = await remoteDataSource.updateMessage(
        messageId: messageId,
        content: content,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.markMessageAsRead(
        chatRoomId: chatRoomId,
        messageId: messageId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<ChatRoom>> watchUserChatRooms(String userId) {
    return remoteDataSource.watchUserChatRooms(userId);
  }

  @override
  Stream<List<Message>> watchChatRoomMessages(String chatRoomId) {
    return remoteDataSource.watchChatRoomMessages(chatRoomId);
  }

  @override
  Stream<Message> watchNewMessages(String chatRoomId) {
    return remoteDataSource.watchNewMessages(chatRoomId);
  }

  @override
  Future<Either<Failure, void>> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await remoteDataSource.setTypingStatus(
        chatRoomId: chatRoomId,
        userId: userId,
        isTyping: isTyping,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Map<String, bool>> watchTypingStatus(String chatRoomId) {
    return remoteDataSource.watchTypingStatus(chatRoomId);
  }

  @override
  Future<Either<Failure, void>> addParticipants({
    required String chatRoomId,
    required List<String> userIds,
  }) async {
    try {
      await remoteDataSource.addParticipants(
        chatRoomId: chatRoomId,
        userIds: userIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeParticipant({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.removeParticipant(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateParticipantRole({
    required String chatRoomId,
    required String userId,
    required String role,
  }) async {
    try {
      await remoteDataSource.updateParticipantRole(
        chatRoomId: chatRoomId,
        userId: userId,
        role: role,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> searchMessages({
    required String query,
    String? chatRoomId,
    String? userId,
  }) async {
    try {
      final result = await remoteDataSource.searchMessages(
        query: query,
        chatRoomId: chatRoomId,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> muteChatRoom({
    required String chatRoomId,
    required String userId,
    Duration? duration,
  }) async {
    try {
      await remoteDataSource.muteChatRoom(
        chatRoomId: chatRoomId,
        userId: userId,
        duration: duration,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unmuteChatRoom({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.unmuteChatRoom(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}