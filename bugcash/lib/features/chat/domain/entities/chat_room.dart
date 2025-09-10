import 'package:equatable/equatable.dart';

enum ChatRoomType {
  direct,      // 1:1 채팅
  group,       // 그룹 채팅
  support,     // 고객 지원
  mission,     // 미션 관련 채팅
  broadcast,   // 방송 (공지)
}

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final ChatRoomType type;
  final List<String> participantIds;
  final Map<String, ParticipantInfo> participants;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? missionId; // 미션 관련 채팅인 경우
  final Map<String, dynamic>? metadata;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    required this.participants,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    required this.createdAt,
    this.updatedAt,
    this.missionId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        participantIds,
        participants,
        avatarUrl,
        lastMessage,
        lastMessageTime,
        lastMessageSenderId,
        unreadCount,
        isArchived,
        isMuted,
        createdAt,
        updatedAt,
        missionId,
        metadata,
      ];

  ChatRoom copyWith({
    String? id,
    String? name,
    ChatRoomType? type,
    List<String>? participantIds,
    Map<String, ParticipantInfo>? participants,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isArchived,
    bool? isMuted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? missionId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      missionId: missionId ?? this.missionId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ParticipantInfo extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role; // admin, member, viewer
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime joinedAt;

  const ParticipantInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.isOnline = false,
    this.lastSeen,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        role,
        isOnline,
        lastSeen,
        joinedAt,
      ];
}