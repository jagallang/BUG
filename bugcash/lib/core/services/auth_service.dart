import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// v2.53.0: 지갑 자동 생성
import '../../features/wallet/domain/usecases/wallet_service.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';

/// Current user service to get authenticated user ID
class CurrentUserService {
  static String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }
  
  static String getCurrentUserIdOrDefault() {
    return getCurrentUserId() ?? 'anonymous_user';
  }
  
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }
  
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
  
  static Stream<User?> authStateChanges() {
    return FirebaseAuth.instance.authStateChanges();
  }
  
  static Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
  
  static Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
  
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final processedData = <String, dynamic>{};

        // Process each field with safe type conversion
        data.forEach((key, value) {
          if (key == 'phoneNumber') {
            // Safe phoneNumber conversion
            if (value != null) {
              if (value is String) {
                processedData[key] = value;
              } else if (value is int) {
                processedData[key] = value.toString();
              } else {
                processedData[key] = value.toString();
              }
            } else {
              processedData[key] = null;
            }
          } else {
            processedData[key] = value;
          }
        });

        return {'id': userId, ...processedData};
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // v2.53.0: 회원가입 시 지갑 자동 생성
  static Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
    // 1. 사용자 프로필 생성
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({
          'id': userId,
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    // 2. 지갑 자동 생성
    try {
      final walletRepository = WalletRepositoryImpl();
      final walletService = WalletService(walletRepository);
      await walletService.createWalletForNewUser(userId);
      print('✅ 지갑 생성 완료: userId=$userId');
    } catch (e) {
      print('⚠️ 지갑 생성 실패: $e');
      // 지갑 생성 실패해도 회원가입은 계속 진행
    }
  }
  
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
          ...userData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
  
  static Future<String> getUserType(String userId) async {
    final profile = await getUserProfile(userId);
    return profile?['userType'] ?? 'tester'; // Default to tester
  }
  
  static Future<bool> isProvider(String userId) async {
    final userType = await getUserType(userId);
    return userType == 'provider';
  }
  
  static Future<bool> isTester(String userId) async {
    final userType = await getUserType(userId);
    return userType == 'tester';
  }
}

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return CurrentUserService.getCurrentUserId();
});

/// Provider for current user ID with default fallback
final currentUserIdWithDefaultProvider = Provider<String>((ref) {
  return CurrentUserService.getCurrentUserIdOrDefault();
});

/// Stream provider for auth state changes - 자동 로그인 비활성화
final authStateProvider = StreamProvider<User?>((ref) {
  // return FirebaseAuth.instance.authStateChanges();
  return const Stream<User?>.empty(); // 빈 스트림 반환으로 자동 로그인 방지
});