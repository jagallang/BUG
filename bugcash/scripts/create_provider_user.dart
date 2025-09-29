import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Firebase 설정 정보 (실제 프로젝트에 맞게 수정)
const firebaseConfig = {
  'apiKey': 'your-api-key',
  'authDomain': 'your-auth-domain',
  'projectId': 'your-project-id',
  'storageBucket': 'your-storage-bucket',
  'messagingSenderId': 'your-messaging-sender-id',
  'appId': 'your-app-id',
};

Future<void> main() async {
  try {
    print('🔧 Firebase 초기화 중...');

    // Firebase 초기화
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;

    // 공급자 사용자 정보
    const providerUid = 'CazdCJYsxGMxEOzXGTen3AY5Kom2';
    const providerEmail = 'episode0611@naver.com';

    print('👤 공급자 사용자 문서 생성 중...');
    print('   UID: $providerUid');
    print('   Email: $providerEmail');

    // 사용자 문서 데이터
    final userData = {
      'uid': providerUid,
      'email': providerEmail,
      'userType': 'provider',
      'displayName': '앱공급자',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'profileImageUrl': null,
      'phoneNumber': null,
    };

    // Firestore에 사용자 문서 생성
    await firestore
        .collection('users')
        .doc(providerUid)
        .set(userData);

    print('✅ 공급자 사용자 문서 생성 완료!');
    print('');
    print('📋 생성된 사용자 정보:');
    print('   - UID: $providerUid');
    print('   - Email: $providerEmail');
    print('   - Type: provider');
    print('   - Display Name: 앱공급자');
    print('   - Status: active');
    print('');
    print('🎉 이제 $providerEmail 계정으로 공급자 대시보드에 로그인할 수 있습니다!');

  } catch (e) {
    print('❌ 오류 발생: $e');
    print('');
    print('📝 해결 방법:');
    print('1. Firebase 프로젝트 설정 확인');
    print('2. Firestore 보안 규칙 확인');
    print('3. 네트워크 연결 확인');

    exit(1);
  }
}