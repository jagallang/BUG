import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🔄 Firestore users 컬렉션 조회 중...');

    // Users 컬렉션 조회
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    print('✅ 총 ${usersSnapshot.docs.length}명의 사용자 발견');
    print('');

    // 사용자 통계
    Map<String, int> userTypes = {};
    Map<String, int> signupDates = {};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final userType = data['userType'] ?? 'unknown';
      final createdAt = data['createdAt'] as Timestamp?;

      // 사용자 유형 통계
      userTypes[userType] = (userTypes[userType] ?? 0) + 1;

      // 가입 날짜 통계 (월별)
      if (createdAt != null) {
        final date = createdAt.toDate();
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        signupDates[monthKey] = (signupDates[monthKey] ?? 0) + 1;
      }

      // 사용자 정보 출력
      print('👤 ${doc.id}');
      print('   이메일: ${data['email'] ?? 'N/A'}');
      print('   이름: ${data['displayName'] ?? 'N/A'}');
      print('   유형: ${data['userType'] ?? 'N/A'}');
      print('   생성: ${createdAt?.toDate().toString().split(' ')[0] ?? 'N/A'}');
      print('   마지막 로그인: ${(data['lastLoginAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'N/A'}');
      print('');
    }

    print('📊 사용자 유형별 통계:');
    userTypes.forEach((type, count) {
      print('   $type: ${count}명');
    });

    print('');
    print('📅 월별 가입자 통계:');
    signupDates.forEach((month, count) {
      print('   $month: ${count}명');
    });

  } catch (e) {
    print('❌ 오류: $e');
  }
}