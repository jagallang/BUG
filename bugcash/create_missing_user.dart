import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🔍 누락된 사용자 문서 생성 시작...');

  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAJ2QOJ8aZ6UJ5hJPMjMCOe5LwRhFmyJg0",
        authDomain: "bugcash-4ad60.firebaseapp.com",
        projectId: "bugcash-4ad60",
        storageBucket: "bugcash-4ad60.appspot.com",
        messagingSenderId: "1069844715615",
        appId: "1:1069844715615:web:1a8e28e5d3b4f6f8b3e8c9",
      ),
    );

    final firestore = FirebaseFirestore.instance;

    // 누락된 사용자 정보
    const userId = 'hthxwtMDTCapAsvGF17bn8kb3mf2';
    const email = 'episode0611@gmail.com';

    print('🔍 사용자 문서 확인: $userId');

    // 기존 문서 확인
    final userDoc = await firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      print('✅ 사용자 문서가 이미 존재합니다');
      print('데이터: ${userDoc.data()}');
      return;
    }

    print('❌ 사용자 문서가 없습니다. 생성하겠습니다.');

    // 새 사용자 문서 생성
    final userData = {
      'uid': userId,
      'email': email,
      'displayName': '이테스터',
      'userType': 'tester',
      'roles': ['tester'],
      'primaryRole': 'tester',
      'isAdmin': false,
      'profileImage': null,
      'points': 0,
      'level': 1,
      'experience': 0,
      'completedMissions': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    await firestore.collection('users').doc(userId).set(userData);

    print('✅ 사용자 문서가 성공적으로 생성되었습니다');
    print('데이터: $userData');

  } catch (e) {
    print('❌ 오류 발생: $e');
  }

  print('🏁 작업 완료');
  exit(0);
}