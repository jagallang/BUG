import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room.dart';

class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.name,
    required super.type,
    required super.participantIds,
    required super.participants,
    super.avatarUrl,
    super.lastMessage,
    super.lastMessageTime,
    super.lastMessageSenderId,
    super.unreadCount,
    super.isArchived,
    super.isMuted,
    required super.createdAt,
    super.updatedAt,
    super.missionId,
    super.metadata,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert participants map
    final participantsData = data['participants'] as Map<String, dynamic>? ?? {};
    final participants = participantsData.map((key, value) {
      final participantData = value as Map<String, dynamic>;
      return MapEntry(
        key,
        ParticipantInfoModel.fromMap(participantData),
      );
    });

    return ChatRoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: ChatRoomType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChatRoomType.direct,
      ),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participants: participants,
      avatarUrl: data['avatarUrl'],
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: data['unreadCount'] ?? 0,
      isArchived: data['isArchived'] ?? false,
      isMuted: data['isMuted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      missionId: data['missionId'],
      metadata: data['metadata']?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toFirestore() {
    // Convert participants to map format for Firestore
    final participantsMap = participants.map((key, value) {
      if (value is ParticipantInfoModel) {
        return MapEntry(key, value.toMap());
      } else {
        return MapEntry(key, ParticipantInfoModel.fromEntity(value).toMap());
      }
    });

    return {
      'name': name,
      'type': type.name,
      'participantIds': participantIds,
      'participants': participantsMap,
      'avatarUrl': avatarUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'missionId': missionId,
      'metadata': metadata,
    };
  }

  factory ChatRoomModel.fromEntity(ChatRoom chatRoom) {
    return ChatRoomModel(
      id: chatRoom.id,
      name: chatRoom.name,
      type: chatRoom.type,
      participantIds: chatRoom.participantIds,
      participants: chatRoom.participants,
      avatarUrl: chatRoom.avatarUrl,
      lastMessage: chatRoom.lastMessage,
      lastMessageTime: chatRoom.lastMessageTime,
      lastMessageSenderId: chatRoom.lastMessageSenderId,
      unreadCount: chatRoom.unreadCount,
      isArchived: chatRoom.isArchived,
      isMuted: chatRoom.isMuted,
      createdAt: chatRoom.createdAt,
      updatedAt: chatRoom.updatedAt,
      missionId: chatRoom.missionId,
      metadata: chatRoom.metadata,
    );
  }
}

class ParticipantInfoModel extends ParticipantInfo {
  const ParticipantInfoModel({
    required super.id,
    required super.name,
    super.avatarUrl,
    required super.role,
    super.isOnline,
    super.lastSeen,
    required super.joinedAt,
  });

  factory ParticipantInfoModel.fromMap(Map<String, dynamic> data) {
    return ParticipantInfoModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'],
      role: data['role'] ?? 'member',
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory ParticipantInfoModel.fromEntity(ParticipantInfo participant) {
    return ParticipantInfoModel(
      id: participant.id,
      name: participant.name,
      avatarUrl: participant.avatarUrl,
      role: participant.role,
      isOnline: participant.isOnline,
      lastSeen: participant.lastSeen,
      joinedAt: participant.joinedAt,
    );
  }
}