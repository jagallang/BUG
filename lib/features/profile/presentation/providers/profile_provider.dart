import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

// Repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  return ProfileRepositoryImpl(firestore: firestore, storage: storage);
});

// Profile state
class ProfileState {
  final UserProfile? profile;
  final NotificationSettings? notificationSettings;
  final List<String> availableSkills;
  final List<String> availableInterests;
  final bool isLoading;
  final bool isUpdating;
  final bool isUploadingImage;
  final String? error;
  
  const ProfileState({
    this.profile,
    this.notificationSettings,
    this.availableSkills = const [],
    this.availableInterests = const [],
    this.isLoading = false,
    this.isUpdating = false,
    this.isUploadingImage = false,
    this.error,
  });
  
  ProfileState copyWith({
    UserProfile? profile,
    NotificationSettings? notificationSettings,
    List<String>? availableSkills,
    List<String>? availableInterests,
    bool? isLoading,
    bool? isUpdating,
    bool? isUploadingImage,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      availableSkills: availableSkills ?? this.availableSkills,
      availableInterests: availableInterests ?? this.availableInterests,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      error: error ?? this.error,
    );
  }
}

// Profile state notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  
  ProfileNotifier(this._repository) : super(const ProfileState());
  
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final results = await Future.wait([
        _repository.getUserProfile(userId),
        _repository.getNotificationSettings(userId),
        _repository.getAvailableSkills(),
        _repository.getAvailableInterests(),
      ]);
      
      state = state.copyWith(
        profile: results[0] as UserProfile?,
        notificationSettings: results[1] as NotificationSettings,
        availableSkills: results[2] as List<String>,
        availableInterests: results[3] as List<String>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> updateProfile(UserProfile updatedProfile) async {
    if (state.profile == null) return;
    
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      await _repository.updateUserProfile(updatedProfile.userId, updatedProfile);
      state = state.copyWith(
        profile: updatedProfile,
        isUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> updateProfileField(String field, dynamic value) async {
    if (state.profile == null) return;
    
    try {
      await _repository.updateProfileField(state.profile!.userId, field, value);
      
      // Update local state based on field
      UserProfile updatedProfile = state.profile!;
      switch (field) {
        case 'username':
          updatedProfile = updatedProfile.copyWith(username: value);
          break;
        case 'displayName':
          updatedProfile = updatedProfile.copyWith(displayName: value);
          break;
        case 'bio':
          updatedProfile = updatedProfile.copyWith(bio: value);
          break;
        case 'location':
          updatedProfile = updatedProfile.copyWith(location: value);
          break;
        case 'website':
          updatedProfile = updatedProfile.copyWith(website: value);
          break;
        case 'githubUsername':
          updatedProfile = updatedProfile.copyWith(githubUsername: value);
          break;
        case 'linkedinProfile':
          updatedProfile = updatedProfile.copyWith(linkedinProfile: value);
          break;
        case 'skills':
          updatedProfile = updatedProfile.copyWith(skills: List<String>.from(value));
          break;
        case 'interests':
          updatedProfile = updatedProfile.copyWith(interests: List<String>.from(value));
          break;
        case 'isProfilePublic':
          updatedProfile = updatedProfile.copyWith(isProfilePublic: value);
          break;
      }
      
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> uploadProfileImage(File imageFile) async {
    if (state.profile == null) return;
    
    state = state.copyWith(isUploadingImage: true, error: null);
    
    try {
      final imageUrl = await _repository.uploadProfileImage(
        state.profile!.userId, 
        imageFile,
      );
      
      if (imageUrl != null) {
        final updatedProfile = state.profile!.copyWith(
          profileImageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
        
        state = state.copyWith(
          profile: updatedProfile,
          isUploadingImage: false,
        );
      } else {
        state = state.copyWith(
          isUploadingImage: false,
          error: '이미지 업로드에 실패했습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isUploadingImage: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> deleteProfileImage() async {
    if (state.profile == null) return;
    
    try {
      await _repository.deleteProfileImage(state.profile!.userId);
      
      final updatedProfile = state.profile!.copyWith(
        profileImageUrl: null,
        updatedAt: DateTime.now(),
      );
      
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    if (state.profile == null) return;
    
    try {
      await _repository.updateNotificationSettings(
        state.profile!.userId, 
        settings,
      );
      
      state = state.copyWith(notificationSettings: settings);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<bool> checkUsernameAvailability(String username) async {
    if (state.profile == null) return false;
    
    try {
      return await _repository.isUsernameAvailable(
        username,
        excludeUserId: state.profile!.userId,
      );
    } catch (e) {
      return false;
    }
  }
  
  Future<void> deleteAccount() async {
    if (state.profile == null) return;
    
    try {
      await _repository.deleteUserAccount(state.profile!.userId);
      state = const ProfileState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for profile state
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

// Provider for current user profile (requires user ID)
final currentUserProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getUserProfile(userId);
});

// Provider for username availability check
final usernameAvailabilityProvider = FutureProvider.family<bool, String>((ref, username) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.isUsernameAvailable(username);
});

// Provider for available skills
final availableSkillsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getAvailableSkills();
});

// Provider for available interests
final availableInterestsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getAvailableInterests();
});