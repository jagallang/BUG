import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.roles,
    required super.primaryRole,
    super.isAdmin = false,
    super.phoneNumber,
    required super.country,
    required super.timezone,
    required super.createdAt,
    required super.updatedAt,
    super.isActive = true,
    super.lastLoginAt,
    super.profile,
    super.testerProfile,
    super.providerProfile,
    super.level = 1,
    super.completedMissions = 0,
    super.points = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromUserEntity(UserEntity.fromFirestore(doc.id, doc.data() as Map<String, dynamic>));
  }

  // UserEntity에서 UserModel로 변환
  factory UserModel.fromUserEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      roles: entity.roles,
      primaryRole: entity.primaryRole,
      isAdmin: entity.isAdmin,
      phoneNumber: entity.phoneNumber,
      country: entity.country,
      timezone: entity.timezone,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      lastLoginAt: entity.lastLoginAt,
      profile: entity.profile,
      testerProfile: entity.testerProfile,
      providerProfile: entity.providerProfile,
      level: entity.level,
      completedMissions: entity.completedMissions,
      points: entity.points,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return super.toFirestore(); // UserEntity의 toFirestore 사용
  }
}