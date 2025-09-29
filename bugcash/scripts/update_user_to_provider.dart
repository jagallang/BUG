import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  try {
    print('🔧 Firebase 초기화 중...');

    // Firebase 초기화
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;

    // 업데이트할 사용자 정보
    const targetUid = 'CazdCJYsxGMxEOzXGTen3AY5Kom2';
    const targetEmail = 'episode0611@naver.com';

    print('👤 사용자 역할 업데이트 중...');
    print('   UID: $targetUid');
    print('   Email: $targetEmail');
    print('   변경: tester → provider');

    // 업데이트할 데이터
    final updateData = {
      'userType': 'provider',
      'primaryRole': 'provider',
      'roles': ['provider'], // 또는 ['tester', 'provider'] for 다중 역할
      'providerProfile': {
        'companyName': '앱공급자',
        'projects': [],
        'verificationStatus': 'verified',
        'totalProjects': 0,
        'activeProjects': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
      'migratedBy': 'role-update-script',
      'migratedAt': FieldValue.serverTimestamp(),
    };

    // Firestore 사용자 문서 업데이트
    await firestore
        .collection('users')
        .doc(targetUid)
        .update(updateData);

    print('✅ 사용자 역할 업데이트 완료!');
    print('');
    print('📋 업데이트된 정보:');
    print('   - UID: $targetUid');
    print('   - Email: $targetEmail');
    print('   - 이전 Type: tester');
    print('   - 새로운 Type: provider');
    print('   - Primary Role: provider');
    print('   - Roles: [provider]');
    print('   - Provider Profile: 생성됨');
    print('');
    print('🎉 이제 $targetEmail 계정으로 Provider Dashboard에 로그인할 수 있습니다!');

    // 변경사항 확인
    print('');
    print('🔍 변경사항 확인 중...');
    final updatedDoc = await firestore
        .collection('users')
        .doc(targetUid)
        .get();

    if (updatedDoc.exists) {
      final data = updatedDoc.data()!;
      print('   ✓ userType: ${data['userType']}');
      print('   ✓ primaryRole: ${data['primaryRole']}');
      print('   ✓ roles: ${data['roles']}');
      print('   ✓ providerProfile 존재: ${data['providerProfile'] != null}');
    }

  } catch (e) {
    print('❌ 오류 발생: $e');
    print('');
    print('📝 해결 방법:');
    print('1. Firebase 프로젝트 설정 확인');
    print('2. Firestore 보안 규칙 확인');
    print('3. 대상 사용자 문서 존재 여부 확인');
    print('4. 네트워크 연결 확인');

    exit(1);
  }
}