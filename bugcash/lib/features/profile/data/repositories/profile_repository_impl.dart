import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  ProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore, _storage = storage;
  
  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return _createDemoProfile(userId);
      }
      
      final data = doc.data()!;
      data['userId'] = doc.id;
      return UserProfile.fromJson(data);
    } catch (e) {
      return _createDemoProfile(userId);
    }
  }
  
  @override
  Future<void> updateUserProfile(String userId, UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(userId).set(
        updatedProfile.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      // Silently fail for demo purposes
    }
  }
  
  @override
  Future<void> updateProfileField(String userId, String field, dynamic value) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for demo purposes
    }
  }
  
  @override
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update profile with new image URL
      await updateProfileField(userId, 'profileImageUrl', downloadUrl);
      
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      await ref.delete();
      
      // Remove image URL from profile
      await updateProfileField(userId, 'profileImageUrl', null);
    } catch (e) {
      // Silently fail for demo purposes
    }
  }
  
  @override
  Future<NotificationSettings> getNotificationSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();
      
      if (!doc.exists) {
        return const NotificationSettings();
      }
      
      return NotificationSettings.fromJson(doc.data()!);
    } catch (e) {
      return const NotificationSettings();
    }
  }
  
  @override
  Future<void> updateNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set(settings.toJson());
    } catch (e) {
      // Silently fail for demo purposes
    }
  }
  
  @override
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete profile image
      try {
        await deleteProfileImage(userId);
      } catch (e) {
        // Ignore if image doesn't exist
      }
      
      // Delete user's sub-collections
      final batch = _firestore.batch();
      
      // Delete settings
      final settingsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('settings');
      final settingsSnapshot = await settingsRef.get();
      for (final doc in settingsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      // Silently fail for demo purposes
    }
  }
  
  @override
  Future<List<String>> getAvailableSkills() async {
    return [
      'Flutter/Dart',
      'React Native',
      'iOS Development',
      'Android Development',
      'Web Development',
      'Backend Development',
      'Database Design',
      'API Testing',
      'Security Testing',
      'Performance Testing',
      'UI/UX Design',
      'Manual Testing',
      'Automation Testing',
      'Bug Hunting',
      'Penetration Testing',
      'DevOps',
      'Cloud Services',
      'Machine Learning',
      'Blockchain',
      'Game Development',
    ];
  }
  
  @override
  Future<List<String>> getAvailableInterests() async {
    return [
      'Mobile Apps',
      'Web Applications',
      'Games',
      'E-commerce',
      'Social Media',
      'Finance/Fintech',
      'Healthcare',
      'Education',
      'IoT Devices',
      'AI/ML Applications',
      'Blockchain Apps',
      'AR/VR',
      'Security',
      'Performance',
      'Accessibility',
      'Usability',
      'API Integration',
      'Cloud Platforms',
      'DevTools',
      'Open Source',
    ];
  }
  
  @override
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('username', isEqualTo: username);
      
      final snapshot = await query.get();
      
      if (excludeUserId != null) {
        return snapshot.docs.isEmpty || 
               (snapshot.docs.length == 1 && snapshot.docs.first.id == excludeUserId);
      }
      
      return snapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
  
  UserProfile _createDemoProfile(String userId) {
    return UserProfile(
      userId: userId,
      username: 'user_${userId.substring(0, 6)}',
      email: 'user@bugcash.com',
      displayName: 'Demo User',
      bio: '버그 헌팅을 좋아하는 테스터입니다.',
      location: '서울, 대한민국',
      skills: ['Flutter/Dart', 'Mobile Testing', 'Bug Hunting'],
      interests: ['Mobile Apps', 'Security', 'UI/UX'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      isEmailVerified: true,
      stats: UserStats(
        totalPoints: 2450,
        completedMissions: 15,
        activeMissions: 3,
        bugReportsSubmitted: 28,
        rank: 127,
        currentBadge: 'bug_hunter',
        categoryStats: {
          'Mobile Apps': 1200,
          'Web Applications': 850,
          'Security': 400,
        },
        achievements: [
          'first_bug_report',
          'mission_complete_5',
          'points_1000',
        ],
        successRate: 0.85,
        joinDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
    );
  }
}