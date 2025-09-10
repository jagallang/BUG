import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUsecase {
  final ChatRepository repository;

  SendMessageUsecase(this.repository);

  Future<Either<Failure, Message>> call({
    required String chatRoomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return repository.sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );
  }
}