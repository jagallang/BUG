import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int points;
  final String level;
  final int completedMissions;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.points = 0,
    this.level = 'bronze',
    this.completedMissions = 0,
    required this.createdAt,
    this.lastLoginAt,
  });
  
  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    points,
    level,
    completedMissions,
    createdAt,
    lastLoginAt,
  ];
}