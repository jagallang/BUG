import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserEntity?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return UserEntity(
        uid: uid,
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? '',
        photoUrl: data['photoUrl'],
        userType: data['userType'] == 'provider'
            ? UserType.provider
            : UserType.tester,
        country: data['country'] ?? '',
        timezone: data['timezone'] ?? 'UTC',
        phoneNumber: data['phoneNumber'],
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error getting user data: $e');
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
      return UserEntity(
        uid: uid,
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? '',
        photoUrl: data['photoUrl'],
        userType: data['userType'] == 'provider'
            ? UserType.provider
            : UserType.tester,
        country: data['country'] ?? '',
        timezone: data['timezone'] ?? 'UTC',
        phoneNumber: data['phoneNumber'],
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'userType': userType == UserType.provider ? 'provider' : 'tester',
          'country': country,
          'timezone': 'UTC',
          'phoneNumber': phoneNumber,
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
      print('Error during Google sign in: $e');
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
          .where('displayName', isLessThan: query + '\uf8ff')
          .limit(limit)
          .get();

      // Search by email
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + '\uf8ff')
          .limit(limit)
          .get();

      // Combine and deduplicate results
      final Map<String, UserEntity> users = {};

      for (final doc in [...nameQuery.docs, ...emailQuery.docs]) {
        if (!users.containsKey(doc.id)) {
          final data = doc.data();
          users[doc.id] = UserEntity(
            uid: doc.id,
            email: data['email'] ?? '',
            displayName: data['displayName'] ?? '',
            photoUrl: data['photoUrl'],
            userType: data['userType'] == 'provider'
                ? UserType.provider
                : UserType.tester,
            country: data['country'] ?? '',
            timezone: data['timezone'] ?? 'UTC',
            phoneNumber: data['phoneNumber'],
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }
      }

      return users.values.toList();
    } catch (e) {
      print('Error searching users: $e');
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