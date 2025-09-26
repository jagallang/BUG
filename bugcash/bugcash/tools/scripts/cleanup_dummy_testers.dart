import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Firebase 초기화
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA0hLevMSRKZpoMaF4Sb_YgvR7ED1VR6Xo",
      authDomain: "bugcash.firebaseapp.com",
      projectId: "bugcash",
      storageBucket: "bugcash.firebasestorage.app",
      messagingSenderId: "335851774651",
      appId: "1:335851774651:web:ac5c384518b6e6830abf9e",
    ),
  );

  print('🧹 더미 테스터 데이터 정리 시작...');

  final firestore = FirebaseFirestore.instance;

  try {
    // 더미 테스터 신청 문서 ID들
    final dummyDocIds = [
      'DwyC49vVgLnvBeFTACmR', // active_tester_456 (이활동)
      'kqgQpzJWCw0W39o79cHg', // completed_tester_789 (박완료)
    ];

    // 각 더미 문서 삭제
    for (final docId in dummyDocIds) {
      try {
        final docRef = firestore.collection('tester_applications').doc(docId);
        final doc = await docRef.get();

        if (doc.exists) {
          await docRef.delete();
          print('✅ 더미 테스터 삭제 완료: $docId');
        } else {
          print('ℹ️  문서가 이미 존재하지 않음: $docId');
        }
      } catch (e) {
        print('❌ 문서 삭제 실패 $docId: $e');
      }
    }

    print('🎉 더미 테스터 데이터 정리 완료!');

  } catch (e) {
    print('❌ 오류 발생: $e');
  }
}