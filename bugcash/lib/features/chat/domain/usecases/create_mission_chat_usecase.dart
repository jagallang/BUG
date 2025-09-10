import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

class CreateMissionChatUsecase {
  final ChatRepository repository;

  CreateMissionChatUsecase(this.repository);

  Future<Either<Failure, ChatRoom>> call({
    required String missionId,
    required String missionTitle,
    required String clientId,
    required String testerId,
    Map<String, dynamic>? missionMetadata,
  }) {
    final chatRoomName = '$missionTitle - 미션 채팅';
    final participantIds = [clientId, testerId];

    return repository.createChatRoom(
      name: chatRoomName,
      type: ChatRoomType.mission,
      participantIds: participantIds,
      missionId: missionId,
      metadata: {
        'missionTitle': missionTitle,
        'autoCreated': true,
        'createdAt': DateTime.now().toIso8601String(),
        ...?missionMetadata,
      },
    );
  }
}