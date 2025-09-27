import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/type_converter.dart';
import '../../domain/entities/user_entity.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// UserEntity 생성을 위한 팩토리 메소드 (다중 역할 지원)
  UserEntity _createUserEntityFromData(String uid, Map<String, dynamic> data) {
    // 새 형식 또는 기존 형식 지원
    List<UserType> roles = [];
    UserType primaryRole = UserType.tester;
    bool isAdmin = false;

    if (data.containsKey('roles') && data['roles'] != null) {
      // 새 형식: 다중 역할
      roles = (data['roles'] as List)
          .map((role) => UserType.values.byName(role))
          .toList();
      primaryRole = UserType.values.byName(data['primaryRole'] ?? 'tester');
      isAdmin = data['isAdmin'] ?? false;
    } else if (data.containsKey('userType')) {
      // 기존 형식: 단일 역할
      final userType = data['userType'] == 'provider'
          ? UserType.provider
          : data['userType'] == 'admin'
              ? UserType.admin
              : UserType.tester;
      roles = [userType];
      primaryRole = userType;
      isAdmin = userType == UserType.admin;
    } else {
      // 기본값: 테스터
      roles = [UserType.tester];
      primaryRole = UserType.tester;
      isAdmin = false;
    }

    return UserEntity(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] as String?,
      roles: roles,
      primaryRole: primaryRole,
      isAdmin: isAdmin,
      country: data['country'] ?? '',
      timezone: data['timezone'] ?? 'UTC',
      phoneNumber: TypeConverter.safeStringConversion(data['phoneNumber']),
      createdAt: TypeConverter.safeDateTimeConversion(data['createdAt']) ?? DateTime.now(),
      updatedAt: TypeConverter.safeDateTimeConversion(data['updatedAt']) ?? DateTime.now(),
      lastLoginAt: TypeConverter.safeDateTimeConversion(data['lastLoginAt']) ?? DateTime.now(),
    );
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserEntity?> getUserData(String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 FirebaseAuthService.getUserData() - 시작: $uid');
      }

      final doc = await _firestore.collection('users').doc(uid).get();

      if (kDebugMode) {
        debugPrint('🔍 FirebaseAuthService.getUserData() - 문서 존재: ${doc.exists}');
      }

      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ FirebaseAuthService.getUserData() - 사용자 문서가 존재하지 않음: $uid');
        }
        return null;
      }

      final data = doc.data()!;
      if (kDebugMode) {
        debugPrint('🔍 FirebaseAuthService.getUserData() - 사용자 데이터: ${data['email']}, ${data['displayName']}, ${data['userType']}');
      }

      final userEntity = _createUserEntityFromData(uid, data);

      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService.getUserData() - UserEntity 생성 완료: ${userEntity.email}');
      }

      return userEntity;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService.getUserData() - 오류: $e');
      }
      AppLogger.error('Error getting user data', 'FirebaseAuthService', e);
      return null;
    }
  }

  Stream<UserEntity?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final data = snapshot.data()!;
      return _createUserEntityFromData(uid, data);
    });
  }

  Future<void> updateUserData(UserEntity user) async {
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'country': user.country,
      'timezone': user.timezone,
      'phoneNumber': user.phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔵 FirebaseAuthService.signInWithEmailAndPassword() - 시작: $email');
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('🔵 FirebaseAuthService.signInWithEmailAndPassword() - Firebase 인증 성공: ${credential.user?.uid}');
      }

      // Update last login time
      if (credential.user != null) {
        try {
          await _firestore.collection('users').doc(credential.user!.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          if (kDebugMode) {
            debugPrint('🔵 FirebaseAuthService.signInWithEmailAndPassword() - lastLoginAt 업데이트 완료');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ FirebaseAuthService.signInWithEmailAndPassword() - lastLoginAt 업데이트 실패: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('🔵 FirebaseAuthService.signInWithEmailAndPassword() - 완료');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService.signInWithEmailAndPassword() - Firebase 인증 오류: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService.signInWithEmailAndPassword() - 일반 오류: $e');
      }
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserType userType,
    required String country,
    String? phoneNumber,
  }) async {
    try {
      // Create authentication account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      if (credential.user != null) {
        try {
          if (kDebugMode) {
            debugPrint('🔵 회원가입 - Firestore 문서 생성 시작: ${credential.user!.uid}');
          }

          await _firestore.collection('users').doc(credential.user!.uid).set({
            'uid': credential.user!.uid,
            'email': email,
            'displayName': displayName,
            'role': userType == UserType.provider ? 'provider' : 'tester',
            'userType': userType == UserType.provider ? 'provider' : 'tester',
            'country': country,
            'timezone': 'UTC',
            'phoneNumber': phoneNumber,
            'photoURL': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          // Create additional collection for provider
          if (userType == UserType.provider) {
            await _firestore.collection('providers').doc(credential.user!.uid).set({
              'companyName': displayName,
              'contactEmail': email,
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else {
            // Create additional collection for tester
            await _firestore.collection('testers').doc(credential.user!.uid).set({
              'name': displayName,
              'email': email,
              'level': 'beginner',
              'totalPoints': 0,
              'completedMissions': 0,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          if (kDebugMode) {
            debugPrint('✅ 회원가입 - Firestore 문서 생성 성공');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ 회원가입 - Firestore 문서 생성 실패: $e');
          }
          // 계정은 생성되었지만 문서 생성 실패 - 계정 삭제
          await credential.user?.delete();
          throw Exception('Failed to create user profile: $e');
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Create new user document for Google sign-in
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName ?? 'User',
            'photoUrl': userCredential.user!.photoURL,
            'userType': 'tester', // Default to tester for Google sign-in
            'country': 'South Korea',
            'timezone': 'Asia/Seoul',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Update last login time
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      AppLogger.error('Error during Google sign in', 'FirebaseAuthService', e);
      return null;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete provider or tester specific data
        await _firestore.collection('providers').doc(user.uid).delete();
        await _firestore.collection('testers').doc(user.uid).delete();

        // Delete authentication account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Search users by email or display name
  Future<List<UserEntity>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      // Search by display name
      final nameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '$query\uf8ff')
          .limit(limit)
          .get();

      // Search by email
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: '$query\uf8ff')
          .limit(limit)
          .get();

      // Combine and deduplicate results
      final Map<String, UserEntity> users = {};

      for (final doc in [...nameQuery.docs, ...emailQuery.docs]) {
        if (!users.containsKey(doc.id)) {
          final data = doc.data();
          users[doc.id] = _createUserEntityFromData(doc.id, data);
        }
      }

      return users.values.toList();
    } catch (e) {
      AppLogger.error('Error searching users', 'FirebaseAuthService', e);
      return [];
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '해당 이메일로 등록된 사용자를 찾을 수 없습니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'requires-recent-login':
        return '재인증이 필요합니다. 다시 로그인해주세요.';
      default:
        return e.message ?? '인증 중 오류가 발생했습니다.';
    }
  }
}