import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

void main() async {
  debugPrint('🔍 누락된 사용자 문서 생성 시작...');

  try {
    // 환경변수 로드
    await dotenv.load(fileName: ".env");
    debugPrint('✅ 환경변수 로드 완료');

    // Firebase 초기화 (환경변수 사용)
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'your_api_key_here',
        authDomain: "${dotenv.env['FIREBASE_PROJECT_ID'] ?? 'bugcash-4ad60'}.firebaseapp.com",
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'bugcash-4ad60',
        storageBucket: "${dotenv.env['FIREBASE_PROJECT_ID'] ?? 'bugcash-4ad60'}.appspot.com",
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '335851774651',
        appId: "1:${dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '335851774651'}:web:1a8e28e5d3b4f6f8b3e8c9",
      ),
    );
    debugPrint('✅ Firebase 초기화 완료');

    final firestore = FirebaseFirestore.instance;

    // 누락된 사용자 정보
    const userId = 'hthxwtMDTCapAsvGF17bn8kb3mf2';
    const email = 'episode0611@gmail.com';

    debugPrint('🔍 사용자 문서 확인: $userId');

    // 기존 문서 확인
    final userDoc = await firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      debugPrint('✅ 사용자 문서가 이미 존재합니다');
      debugPrint('데이터: ${userDoc.data()}');
      return;
    }

    debugPrint('❌ 사용자 문서가 없습니다. 생성하겠습니다.');

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

    debugPrint('✅ 사용자 문서가 성공적으로 생성되었습니다');
    debugPrint('데이터: $userData');

  } catch (e) {
    debugPrint('❌ 오류 발생: $e');
  }

  debugPrint('🏁 작업 완료');
  exit(0);
}