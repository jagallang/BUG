import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.userType,
    super.phoneNumber,
    required super.country,
    required super.timezone,
    required super.createdAt,
    required super.updatedAt,
    super.isActive = true,
    super.lastLoginAt,
    super.profile,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoURL'],
      userType: UserType.values.byName(data['userType'] ?? 'tester'),
      phoneNumber: data['phoneNumber'],
      country: data['country'] ?? '',
      timezone: data['timezone'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      lastLoginAt: data['lastLoginAt'] != null 
          ? (data['lastLoginAt'] as Timestamp).toDate() 
          : null,
      profile: data['profile'] != null
          ? UserProfile.fromMap(data['profile'])
          : null,
    );
  }
  
  @override
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoUrl,
      'userType': userType.name,
      'phoneNumber': phoneNumber,
      'country': country,
      'timezone': timezone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'lastLoginAt': lastLoginAt != null 
          ? Timestamp.fromDate(lastLoginAt!) 
          : null,
      'profile': profile?.toMap(),
    };
  }
  
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      userType: entity.userType,
      phoneNumber: entity.phoneNumber,
      country: entity.country,
      timezone: entity.timezone,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      lastLoginAt: entity.lastLoginAt,
      profile: entity.profile,
    );
  }
}