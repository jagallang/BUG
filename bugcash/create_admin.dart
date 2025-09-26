import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await createAdminAccount();
}

Future<void> createAdminAccount() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // 관리자 계정 정보
  const adminEmail = 'admin@bugcash.com';
  const adminPassword = 'Admin123456!';
  const adminName = '시스템 관리자';

  try {
    // 1. Firebase Auth에 계정 생성
    UserCredential userCredential;
    try {
      // 먼저 로그인 시도 (기존 계정 확인)
      userCredential = await auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('기존 관리자 계정으로 로그인: ${userCredential.user?.uid}');
    } catch (e) {
      // 계정이 없으면 새로 생성
      userCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('새 관리자 계정 생성: ${userCredential.user?.uid}');

      // 사용자 프로필 업데이트
      await userCredential.user?.updateDisplayName(adminName);
    }

    if (userCredential.user != null) {
      // 2. Firestore users 컬렉션에 관리자 정보 저장
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': adminEmail,
        'displayName': adminName,
        'role': 'admin',
        'photoURL': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'permissions': {
          'canManageProjects': true,
          'canManageUsers': true,
          'canViewReports': true,
          'canManagePayments': true,
        },
      }, SetOptions(merge: true));

      print('✅ 관리자 계정 설정 완료!');
      print('=====================================');
      print('📧 이메일: $adminEmail');
      print('🔑 비밀번호: $adminPassword');
      print('👤 이름: $adminName');
      print('🛡️ 역할: 관리자 (admin)');
      print('=====================================');
      print('위 정보로 로그인하실 수 있습니다.');

      // 로그아웃
      await auth.signOut();
      print('로그아웃 완료. 로그인 페이지에서 위 정보로 로그인하세요.');
    }
  } catch (e) {
    print('❌ 오류 발생: $e');
  }
}