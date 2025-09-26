import 'package:cloud_firestore/cloud_firestore.dart';

class DummyDataCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 더미 테스터 신청 데이터를 정리합니다.
  static Future<void> cleanupDummyTesterApplications() async {
    print('🧹 더미 테스터 데이터 정리 시작...');

    try {
      // 더미 테스터 신청 문서 ID들
      final dummyDocIds = [
        'DwyC49vVgLnvBeFTACmR', // active_tester_456 (이활동)
        'kqgQpzJWCw0W39o79cHg', // completed_tester_789 (박완료)
      ];

      // 각 더미 문서 삭제
      for (final docId in dummyDocIds) {
        try {
          final docRef = _firestore.collection('tester_applications').doc(docId);
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
      print('❌ 정리 중 오류 발생: $e');
    }
  }

  /// 특정 testerId로 더미데이터 검색 및 삭제
  static Future<void> cleanupDummyDataByTesterId() async {
    print('🧹 testerId 기반 더미 데이터 정리 시작...');

    try {
      final dummyTesterIds = [
        'active_tester_456',
        'completed_tester_789',
      ];

      for (final testerId in dummyTesterIds) {
        final query = await _firestore
            .collection('tester_applications')
            .where('testerId', isEqualTo: testerId)
            .get();

        for (final doc in query.docs) {
          await doc.reference.delete();
          print('✅ 더미 테스터 삭제 (testerId: $testerId): ${doc.id}');
        }
      }

      print('🎉 testerId 기반 더미 데이터 정리 완료!');

    } catch (e) {
      print('❌ testerId 기반 정리 중 오류 발생: $e');
    }
  }
}