import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/create_mission_chat_usecase.dart';

class MissionChatService {
  final ChatRepository _chatRepository;
  late final CreateMissionChatUsecase _createMissionChatUsecase;

  MissionChatService({required ChatRepository chatRepository}) 
      : _chatRepository = chatRepository {
    _createMissionChatUsecase = CreateMissionChatUsecase(_chatRepository);
  }

  /// 미션이 승인되었을 때 자동으로 채팅방 생성
  Future<Either<Failure, ChatRoom>> createMissionChatRoom({
    required String missionId,
    required String missionTitle,
    required String clientId,
    required String testerId,
    Map<String, dynamic>? missionMetadata,
  }) async {
    try {
      // 이미 해당 미션의 채팅방이 있는지 확인
      final existingChatRooms = await _chatRepository.getUserChatRooms(
        userId: clientId,
        type: ChatRoomType.mission,
      );
      
      final existingRoom = existingChatRooms.fold<ChatRoom?>(
        (failure) => null,
        (chatRooms) => chatRooms.cast<ChatRoom?>().firstWhere(
          (room) => room?.missionId == missionId,
          orElse: () => null,
        ),
      );
      
      if (existingRoom != null) {
        return Right(existingRoom);
      }

      // 새 채팅방 생성
      final result = await _createMissionChatUsecase(
        missionId: missionId,
        missionTitle: missionTitle,
        clientId: clientId,
        testerId: testerId,
        missionMetadata: missionMetadata,
      );

      // 성공 시 환영 메시지 전송
      if (result.isRight()) {
        final chatRoom = result.getOrElse(() => throw Exception('ChatRoom is null'));
        await _sendWelcomeMessage(chatRoom, missionTitle);
      }

      return result;
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create mission chat room: $e'));
    }
  }

  /// 미션 진행 상태가 변경될 때 시스템 메시지 전송
  Future<Either<Failure, Message>> sendMissionStatusMessage({
    required String missionId,
    required String statusMessage,
    required String senderId,
  }) async {
    try {
      // 미션 채팅방 찾기
      final chatRooms = await _chatRepository.getUserChatRooms(
        userId: senderId,
        type: ChatRoomType.mission,
      );

      final chatRoom = chatRooms.fold<ChatRoom?>(
        (failure) => null,
        (rooms) => rooms.cast<ChatRoom?>().firstWhere(
          (room) => room?.missionId == missionId,
          orElse: () => null,
        ),
      );

      if (chatRoom == null) {
        return const Left(ValidationFailure(message: 'Mission chat room not found'));
      }

      // 시스템 메시지 전송
      return await _chatRepository.sendMessage(
        chatRoomId: chatRoom.id,
        senderId: 'system',
        content: statusMessage,
        type: MessageType.system,
        metadata: {
          'missionId': missionId,
          'messageType': 'status_update',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to send mission status message: $e'));
    }
  }

  /// 미션 완료 시 완료 메시지 전송
  Future<Either<Failure, Message>> sendMissionCompletionMessage({
    required String missionId,
    required String testerId,
    required bool isSuccessful,
    String? completionNote,
  }) async {
    final message = isSuccessful
        ? '🎉 미션이 성공적으로 완료되었습니다!'
        : '❌ 미션이 실패로 처리되었습니다.';

    final fullMessage = completionNote != null
        ? '$message\n\n완료 메모: $completionNote'
        : message;

    return await sendMissionStatusMessage(
      missionId: missionId,
      statusMessage: fullMessage,
      senderId: testerId,
    );
  }

  /// 미션 채팅방에서 파일/이미지 업로드 처리
  Future<Either<Failure, Message>> sendMissionFile({
    required String missionId,
    required String senderId,
    required String fileName,
    required String fileUrl,
    required MessageType messageType,
    String? description,
  }) async {
    try {
      // 미션 채팅방 찾기
      final chatRooms = await _chatRepository.getUserChatRooms(
        userId: senderId,
        type: ChatRoomType.mission,
      );

      final chatRoom = chatRooms.fold<ChatRoom?>(
        (failure) => null,
        (rooms) => rooms.cast<ChatRoom?>().firstWhere(
          (room) => room?.missionId == missionId,
          orElse: () => null,
        ),
      );

      if (chatRoom == null) {
        return const Left(ValidationFailure(message: 'Mission chat room not found'));
      }

      final content = description ?? fileName;

      return await _chatRepository.sendMessage(
        chatRoomId: chatRoom.id,
        senderId: senderId,
        content: content,
        type: messageType,
        mediaUrl: fileUrl,
        metadata: {
          'missionId': missionId,
          'fileName': fileName,
          'fileUrl': fileUrl,
          'messageType': 'file_share',
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to send mission file: $e'));
    }
  }

  /// 미션 채팅방 목록 가져오기
  Future<Either<Failure, List<ChatRoom>>> getMissionChatRooms(String userId) {
    return _chatRepository.getUserChatRooms(
      userId: userId,
      type: ChatRoomType.mission,
    );
  }

  /// 특정 미션의 채팅방 찾기
  Future<Either<Failure, ChatRoom?>> findMissionChatRoom({
    required String missionId,
    required String userId,
  }) async {
    try {
      final chatRoomsResult = await getMissionChatRooms(userId);
      
      return chatRoomsResult.fold(
        (failure) => Left(failure),
        (chatRooms) {
          final missionRoom = chatRooms.cast<ChatRoom?>().firstWhere(
            (room) => room?.missionId == missionId,
            orElse: () => null,
          );
          return Right(missionRoom);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to find mission chat room: $e'));
    }
  }

  /// 환영 메시지 전송 (private method)
  Future<void> _sendWelcomeMessage(ChatRoom chatRoom, String missionTitle) async {
    final welcomeMessage = '''
🚀 "$missionTitle" 미션 채팅방에 오신 것을 환영합니다!

이 채팅방에서는:
• 미션 진행 상황을 실시간으로 공유할 수 있습니다
• 테스트 결과와 스크린샷을 업로드할 수 있습니다
• 클라이언트와 테스터가 직접 소통할 수 있습니다

좋은 테스팅 되세요! 💪
''';

    await _chatRepository.sendMessage(
      chatRoomId: chatRoom.id,
      senderId: 'system',
      content: welcomeMessage,
      type: MessageType.system,
      metadata: {
        'messageType': 'welcome',
        'missionId': chatRoom.missionId,
      },
    );
  }
}