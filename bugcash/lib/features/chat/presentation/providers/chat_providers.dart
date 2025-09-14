import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/services/mission_chat_service.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';

// Firebase Firestore provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Chat Remote Data Source Provider
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(
    firestore: ref.read(firestoreProvider),
  );
});

// Chat Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    remoteDataSource: ref.read(chatRemoteDataSourceProvider),
  );
});

// Chat Rooms State Provider
final chatRoomsProvider = StreamProvider.family<List<ChatRoom>, String>((ref, userId) {
  final repository = ref.read(chatRepositoryProvider);
  return repository.watchUserChatRooms(userId);
});

// Filtered Chat Rooms Provider
final filteredChatRoomsProvider = Provider.family<List<ChatRoom>, ChatRoomFilter>((ref, filter) {
  final chatRoomsAsync = ref.watch(chatRoomsProvider(filter.userId));
  
  return chatRoomsAsync.when(
    data: (chatRooms) {
      List<ChatRoom> filteredRooms = chatRooms;
      
      // Filter by type
      if (filter.type != null) {
        filteredRooms = filteredRooms.where((room) => room.type == filter.type).toList();
      }
      
      // Filter by search query
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        filteredRooms = filteredRooms.where((room) {
          return room.name.toLowerCase().contains(query) ||
                 (room.lastMessage?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      
      return filteredRooms;
    },
    loading: () => [],
    error: (error, stack) => [],
  );
});

// Current Chat Room Provider
final currentChatRoomProvider = StateProvider<ChatRoom?>((ref) => null);

// Chat Room Messages Provider
final chatRoomMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatRoomId) {
  final repository = ref.read(chatRepositoryProvider);
  return repository.watchChatRoomMessages(chatRoomId);
});

// Typing Status Provider
final typingStatusProvider = StreamProvider.family<Map<String, bool>, String>((ref, chatRoomId) {
  final repository = ref.read(chatRepositoryProvider);
  return repository.watchTypingStatus(chatRoomId);
});

// New Message Notification Provider
final newMessageProvider = StreamProvider.family<Message, String>((ref, chatRoomId) {
  final repository = ref.read(chatRepositoryProvider);
  return repository.watchNewMessages(chatRoomId);
});

// Mission Chat Service Provider
final missionChatServiceProvider = Provider<MissionChatService>((ref) {
  return MissionChatService(
    chatRepository: ref.read(chatRepositoryProvider),
  );
});

// Chat Actions Provider (for sending messages, creating rooms, etc.)
final chatActionsProvider = Provider<ChatActions>((ref) {
  return ChatActions(ref.read(chatRepositoryProvider));
});

// Unread Messages Count Provider
final unreadMessagesCountProvider = Provider.family<int, String>((ref, userId) {
  final chatRoomsAsync = ref.watch(chatRoomsProvider(userId));
  
  return chatRoomsAsync.when(
    data: (chatRooms) {
      return chatRooms.fold<int>(0, (sum, room) => sum + room.unreadCount);
    },
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

// Chat Room Filter Class
class ChatRoomFilter {
  final String userId;
  final ChatRoomType? type;
  final String? searchQuery;
  final bool includeArchived;

  const ChatRoomFilter({
    required this.userId,
    this.type,
    this.searchQuery,
    this.includeArchived = false,
  });

  ChatRoomFilter copyWith({
    String? userId,
    ChatRoomType? type,
    String? searchQuery,
    bool? includeArchived,
  }) {
    return ChatRoomFilter(
      userId: userId ?? this.userId,
      type: type ?? this.type,
      searchQuery: searchQuery ?? this.searchQuery,
      includeArchived: includeArchived ?? this.includeArchived,
    );
  }
}

// Chat Actions Class
class ChatActions {
  final ChatRepository _repository;

  ChatActions(this._repository);

  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _repository.sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );
    
    return result.isRight();
  }

  Future<bool> createChatRoom({
    required String name,
    required ChatRoomType type,
    required List<String> participantIds,
    String? missionId,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _repository.createChatRoom(
      name: name,
      type: type,
      participantIds: participantIds,
      missionId: missionId,
      metadata: metadata,
    );
    
    return result.isRight();
  }

  Future<bool> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
    required String userId,
  }) async {
    final result = await _repository.markMessageAsRead(
      chatRoomId: chatRoomId,
      messageId: messageId,
      userId: userId,
    );
    
    return result.isRight();
  }

  Future<bool> updateMessage({
    required String messageId,
    required String content,
  }) async {
    final result = await _repository.updateMessage(
      messageId: messageId,
      content: content,
    );
    
    return result.isRight();
  }

  Future<bool> deleteMessage(String messageId) async {
    final result = await _repository.deleteMessage(messageId);
    return result.isRight();
  }

  Future<bool> archiveChatRoom(String chatRoomId) async {
    final result = await _repository.archiveChatRoom(chatRoomId);
    return result.isRight();
  }

  Future<bool> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    final result = await _repository.setTypingStatus(
      chatRoomId: chatRoomId,
      userId: userId,
      isTyping: isTyping,
    );
    
    return result.isRight();
  }
}

// Chat UI State Providers
final chatListFilterProvider = StateProvider<ChatRoomType?>((ref) => null);

final chatSearchQueryProvider = StateProvider<String>((ref) => '');

final selectedChatRoomProvider = StateProvider<String?>((ref) => null);

final messageInputProvider = StateProvider<String>((ref) => '');

final isTypingProvider = StateProvider<bool>((ref) => false);

// Combined Chat State Provider
final chatStateProvider = Provider<ChatState>((ref) {
  final authState = ref.watch(authProvider);
  final currentUser = authState.user;
  final filter = ref.watch(chatListFilterProvider);
  final searchQuery = ref.watch(chatSearchQueryProvider);
  final selectedChatRoom = ref.watch(selectedChatRoomProvider);
  
  if (currentUser == null) {
    return const ChatState.unauthenticated();
  }
  
  final chatRoomsFilter = ChatRoomFilter(
    userId: currentUser.uid,
    type: filter,
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
  );
  
  final chatRooms = ref.watch(filteredChatRoomsProvider(chatRoomsFilter));
  final unreadCount = ref.watch(unreadMessagesCountProvider(currentUser.uid));
  
  return ChatState.loaded(
    chatRooms: chatRooms,
    selectedChatRoomId: selectedChatRoom,
    unreadCount: unreadCount,
    currentFilter: filter,
    searchQuery: searchQuery,
  );
});

// Chat State Class
class ChatState {
  final List<ChatRoom> chatRooms;
  final String? selectedChatRoomId;
  final int unreadCount;
  final ChatRoomType? currentFilter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.chatRooms,
    this.selectedChatRoomId,
    required this.unreadCount,
    this.currentFilter,
    required this.searchQuery,
    this.isLoading = false,
    this.error,
  });

  const ChatState.loading()
      : chatRooms = const [],
        selectedChatRoomId = null,
        unreadCount = 0,
        currentFilter = null,
        searchQuery = '',
        isLoading = true,
        error = null;

  const ChatState.error(String errorMessage)
      : chatRooms = const [],
        selectedChatRoomId = null,
        unreadCount = 0,
        currentFilter = null,
        searchQuery = '',
        isLoading = false,
        error = errorMessage;

  const ChatState.unauthenticated()
      : chatRooms = const [],
        selectedChatRoomId = null,
        unreadCount = 0,
        currentFilter = null,
        searchQuery = '',
        isLoading = false,
        error = null;

  const ChatState.loaded({
    required this.chatRooms,
    this.selectedChatRoomId,
    required this.unreadCount,
    this.currentFilter,
    required this.searchQuery,
  })  : isLoading = false,
        error = null;
}

// User Search Provider
final userSearchProvider = FutureProvider.family<List<UserEntity>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return [];
  }
  
  // HybridAuthService는 사용자 검색 기능을 제공하지 않음
  throw UnimplementedError('사용자 검색 기능은 현재 지원되지 않습니다.');
});

// Current user provider from auth
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});