import 'dart:io';
import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getUserProfile(String userId);
  
  Future<void> updateUserProfile(String userId, UserProfile profile);
  
  Future<void> updateProfileField(String userId, String field, dynamic value);
  
  Future<String?> uploadProfileImage(String userId, File imageFile);
  
  Future<void> deleteProfileImage(String userId);
  
  Future<NotificationSettings> getNotificationSettings(String userId);
  
  Future<void> updateNotificationSettings(String userId, NotificationSettings settings);
  
  Future<void> deleteUserAccount(String userId);
  
  Future<List<String>> getAvailableSkills();
  
  Future<List<String>> getAvailableInterests();
  
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId});
}