import 'package:cloud_firestore/cloud_firestore.dart';

/// 테스트 데이터 정리 스크립트
Future<void> cleanupTestData() async {
  final firestore = FirebaseFirestore.instance;

  print('🔄 테스트 데이터 정리 시작...');

  try {
    // 1. mission_applications 컬렉션 정리
    final missionApplications = await firestore.collection('mission_applications').get();
    print('📊 mission_applications: ${missionApplications.docs.length}개 문서 발견');

    for (final doc in missionApplications.docs) {
      await doc.reference.delete();
      print('🗑️ mission_applications 문서 삭제: ${doc.id}');
    }

    // 2. mission_workflows 컬렉션 정리
    final missionWorkflows = await firestore.collection('mission_workflows').get();
    print('📊 mission_workflows: ${missionWorkflows.docs.length}개 문서 발견');

    for (final doc in missionWorkflows.docs) {
      await doc.reference.delete();
      print('🗑️ mission_workflows 문서 삭제: ${doc.id}');
    }

    // 3. tester_applications 컬렉션 정리
    final testerApplications = await firestore.collection('tester_applications').get();
    print('📊 tester_applications: ${testerApplications.docs.length}개 문서 발견');

    for (final doc in testerApplications.docs) {
      await doc.reference.delete();
      print('🗑️ tester_applications 문서 삭제: ${doc.id}');
    }

    print('✅ 테스트 데이터 정리 완료!');

  } catch (e) {
    print('❌ 테스트 데이터 정리 중 오류: $e');
  }
}

void main() async {
  await cleanupTestData();
}