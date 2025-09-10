import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';

abstract class ChatRemoteDataSource {
  Future<ChatRoomModel> createChatRoom({
    required String name,
    required ChatRoomType type,
    required List<String> participantIds,
    String? missionId,
    Map<String, dynamic>? metadata,
  });
  
  Future<ChatRoomModel> getChatRoom(String chatRoomId);
  
  Future<List<ChatRoomModel>> getUserChatRooms({
    required String userId,
    ChatRoomType? type,
    bool includeArchived = false,
  });
  
  Future<ChatRoomModel> updateChatRoom({
    required String chatRoomId,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  });
  
  Future<void> archiveChatRoom(String chatRoomId);
  
  Future<void> deleteChatRoom(String chatRoomId);
  
  Future<MessageModel> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  });
  
  Future<List<MessageModel>> getMessages({
    required String chatRoomId,
    int limit = 50,
    String? lastMessageId,
  });
  
  Future<MessageModel> updateMessage({
    required String messageId,
    required String content,
  });
  
  Future<void> deleteMessage(String messageId);
  
  Future<void> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
    required String userId,
  });
  
  Stream<List<ChatRoomModel>> watchUserChatRooms(String userId);
  
  Stream<List<MessageModel>> watchChatRoomMessages(String chatRoomId);
  
  Stream<MessageModel> watchNewMessages(String chatRoomId);
  
  Future<void> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  });
  
  Stream<Map<String, bool>> watchTypingStatus(String chatRoomId);
  
  Future<void> addParticipants({
    required String chatRoomId,
    required List<String> userIds,
  });
  
  Future<void> removeParticipant({
    required String chatRoomId,
    required String userId,
  });
  
  Future<void> updateParticipantRole({
    required String chatRoomId,
    required String userId,
    required String role,
  });
  
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? chatRoomId,
    String? userId,
  });
  
  Future<void> muteChatRoom({
    required String chatRoomId,
    required String userId,
    Duration? duration,
  });
  
  Future<void> unmuteChatRoom({
    required String chatRoomId,
    required String userId,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  
  ChatRemoteDataSourceImpl({required this.firestore});
  
  @override
  Future<ChatRoomModel> createChatRoom({
    required String name,
    required ChatRoomType type,
    required List<String> participantIds,
    String? missionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      
      // Create participants map with basic info
      final participantsMap = <String, Map<String, dynamic>>{};
      for (final participantId in participantIds) {
        participantsMap[participantId] = {
          'id': participantId,
          'name': '', // Will be populated later with actual user data
          'avatarUrl': null,
          'role': participantId == participantIds.first ? 'admin' : 'member',
          'isOnline': false,
          'lastSeen': null,
          'joinedAt': Timestamp.fromDate(now),
        };
      }
      
      final chatRoomData = {
        'name': name,
        'type': type.name,
        'participantIds': participantIds,
        'participants': participantsMap,
        'avatarUrl': null,
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
        'unreadCount': 0,
        'isArchived': false,
        'isMuted': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': null,
        'missionId': missionId,
        'metadata': metadata,
      };
      
      final docRef = await firestore.collection('chat_rooms').add(chatRoomData);
      final doc = await docRef.get();
      
      return ChatRoomModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }
  
  @override
  Future<ChatRoomModel> getChatRoom(String chatRoomId) async {
    try {
      final doc = await firestore.collection('chat_rooms').doc(chatRoomId).get();
      
      if (!doc.exists) {
        throw Exception('Chat room not found');
      }
      
      return ChatRoomModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get chat room: $e');
    }
  }
  
  @override
  Future<List<ChatRoomModel>> getUserChatRooms({
    required String userId,
    ChatRoomType? type,
    bool includeArchived = false,
  }) async {
    try {
      Query query = firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: userId);
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }
      
      query = query.orderBy('lastMessageTime', descending: true);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => ChatRoomModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user chat rooms: $e');
    }
  }
  
  @override
  Future<MessageModel> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      
      // 사용자 정보 가져오기 (실제로는 Auth에서 가져와야 함)
      String senderName = 'User';
      String? senderAvatar;
      
      try {
        final userDoc = await firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          senderName = userData['displayName'] ?? userData['name'] ?? 'User';
          senderAvatar = userData['photoUrl'] ?? userData['avatar'];
        }
      } catch (e) {
        print('Failed to get sender info: $e');
      }
      
      final messageData = {
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'type': type.name,
        'content': content,
        'mediaUrl': mediaUrl,
        'status': MessageStatus.sent.name,
        'createdAt': Timestamp.fromDate(now),
        'editedAt': null,
        'readAt': null,
        'isDeleted': false,
        'replyToMessageId': replyToMessageId,
        'metadata': metadata,
      };
      
      // Firebase 배치 작업으로 메시지 생성과 채팅방 업데이트를 함께 수행
      final batch = firestore.batch();
      
      // 메시지 생성
      final messageRef = firestore.collection('messages').doc();
      batch.set(messageRef, messageData);
      
      // 채팅방 마지막 메시지 정보 업데이트
      final chatRoomRef = firestore.collection('chat_rooms').doc(chatRoomId);
      batch.update(chatRoomRef, {
        'lastMessage': content.length > 100 ? '${content.substring(0, 100)}...' : content,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
        'updatedAt': Timestamp.fromDate(now),
      });
      
      // 배치 커밋
      await batch.commit();
      
      // 생성된 메시지 반환
      final messageDoc = await messageRef.get();
      return MessageModel.fromFirestore(messageDoc);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
  
  @override
  Future<List<MessageModel>> getMessages({
    required String chatRoomId,
    int limit = 50,
    String? lastMessageId,
  }) async {
    try {
      Query query = firestore
          .collection('messages')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastMessageId != null) {
        final lastDoc = await firestore.collection('messages').doc(lastMessageId).get();
        query = query.startAfterDocument(lastDoc);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }
  
  @override
  Stream<List<ChatRoomModel>> watchUserChatRooms(String userId) {
    return firestore
        .collection('chat_rooms')
        .where('participantIds', arrayContains: userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc))
            .toList());
  }
  
  @override
  Stream<List<MessageModel>> watchChatRoomMessages(String chatRoomId) {
    return firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .where('isDeleted', isEqualTo: false) // 삭제되지 않은 메시지만
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
          print('Error watching chat room messages: $error');
        });
  }
  
  @override
  Stream<MessageModel> watchNewMessages(String chatRoomId) {
    return firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty 
            ? MessageModel.fromFirestore(snapshot.docs.first)
            : throw Exception('No messages found'));
  }
  
  // Simplified implementations for remaining methods
  @override
  Future<ChatRoomModel> updateChatRoom({
    required String chatRoomId,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    
    if (name != null) updateData['name'] = name;
    if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
    if (metadata != null) updateData['metadata'] = metadata;
    
    await firestore.collection('chat_rooms').doc(chatRoomId).update(updateData);
    return getChatRoom(chatRoomId);
  }
  
  @override
  Future<void> archiveChatRoom(String chatRoomId) async {
    await firestore.collection('chat_rooms').doc(chatRoomId).update({
      'isArchived': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  @override
  Future<void> deleteChatRoom(String chatRoomId) async {
    await firestore.collection('chat_rooms').doc(chatRoomId).delete();
  }
  
  @override
  Future<MessageModel> updateMessage({
    required String messageId,
    required String content,
  }) async {
    await firestore.collection('messages').doc(messageId).update({
      'content': content,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    });
    
    final doc = await firestore.collection('messages').doc(messageId).get();
    return MessageModel.fromFirestore(doc);
  }
  
  @override
  Future<void> deleteMessage(String messageId) async {
    await firestore.collection('messages').doc(messageId).update({
      'isDeleted': true,
      'content': '[삭제된 메시지]',
    });
  }
  
  @override
  Future<void> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
    required String userId,
  }) async {
    await firestore.collection('messages').doc(messageId).update({
      'readAt': Timestamp.fromDate(DateTime.now()),
      'status': MessageStatus.read.name,
    });
  }
  
  @override
  Future<void> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final typingRef = firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('typing')
          .doc(userId);
          
      if (isTyping) {
        await typingRef.set({
          'userId': userId,
          'isTyping': true,
          'timestamp': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }
  
  @override
  Stream<Map<String, bool>> watchTypingStatus(String chatRoomId) {
    return firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
          final typingMap = <String, bool>{};
          final now = DateTime.now();
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            
            // 30초 이상 지난 타이핑 상태는 무시
            if (now.difference(timestamp).inSeconds < 30) {
              typingMap[doc.id] = data['isTyping'] ?? false;
            }
          }
          
          return typingMap;
        })
        .handleError((error) {
          print('Error watching typing status: $error');
        });
  }
  
  @override
  Future<void> addParticipants({
    required String chatRoomId,
    required List<String> userIds,
  }) async {
    // Implementation for adding participants
  }
  
  @override
  Future<void> removeParticipant({
    required String chatRoomId,
    required String userId,
  }) async {
    // Implementation for removing participant
  }
  
  @override
  Future<void> updateParticipantRole({
    required String chatRoomId,
    required String userId,
    required String role,
  }) async {
    // Implementation for updating participant role
  }
  
  @override
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? chatRoomId,
    String? userId,
  }) async {
    // Implementation for searching messages
    return [];
  }
  
  @override
  Future<void> muteChatRoom({
    required String chatRoomId,
    required String userId,
    Duration? duration,
  }) async {
    // Implementation for muting chat room
  }
  
  @override
  Future<void> unmuteChatRoom({
    required String chatRoomId,
    required String userId,
  }) async {
    // Implementation for unmuting chat room
  }
}