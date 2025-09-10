import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

class GetChatRoomsUsecase {
  final ChatRepository repository;

  GetChatRoomsUsecase(this.repository);

  Future<Either<Failure, List<ChatRoom>>> call({
    required String userId,
    ChatRoomType? type,
    bool includeArchived = false,
  }) {
    return repository.getUserChatRooms(
      userId: userId,
      type: type,
      includeArchived: includeArchived,
    );
  }

  Stream<List<ChatRoom>> watchChatRooms(String userId) {
    return repository.watchUserChatRooms(userId);
  }
}