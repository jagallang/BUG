import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  
  AuthRepository(
    this._firebaseAuth,
    this._firestore,
    this._googleSignIn,
  );
  
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  User? get currentUser => _firebaseAuth.currentUser;
  
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) return null;
      
      final user = userCredential.user!;
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL,
          userType: UserType.tester,
          country: 'KR',
          timezone: 'Asia/Seoul',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await userDoc.set(newUser.toFirestore());
        return newUser;
      } else {
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        
        final updatedDoc = await userDoc.get();
        return UserModel.fromFirestore(updatedDoc);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }
  
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}