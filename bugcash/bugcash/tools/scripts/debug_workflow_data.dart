import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug script to check workflow data in Firestore
Future<void> debugWorkflowData() async {
  final firestore = FirebaseFirestore.instance;

  debugPrint('🔍 Debug Workflow Data - 시작...');

  try {
    // 1. mission_workflows 컬렉션 전체 조회
    debugPrint('\n📊 mission_workflows 컬렉션 조회...');
    final missionWorkflows = await firestore.collection('mission_workflows').get();
    debugPrint('📊 mission_workflows: ${missionWorkflows.docs.length}개 문서 발견');

    for (final doc in missionWorkflows.docs) {
      final data = doc.data();
      debugPrint('📋 Workflow ${doc.id}:');
      debugPrint('   - appId: ${data['appId']}');
      debugPrint('   - testerId: ${data['testerId']}');
      debugPrint('   - testerName: ${data['testerName']}');
      debugPrint('   - providerId: ${data['providerId']}');
      debugPrint('   - currentState: ${data['currentState']}');
      debugPrint('   - appName: ${data['appName']}');
    }

    // 2. apps 컬렉션 조회 (provider 앱들)
    debugPrint('\n📊 apps 컬렉션 조회...');
    final apps = await firestore.collection('apps').get();
    debugPrint('📊 apps: ${apps.docs.length}개 문서 발견');

    for (final doc in apps.docs) {
      final data = doc.data();
      debugPrint('📱 App ${doc.id}:');
      debugPrint('   - appName: ${data['appName']}');
      debugPrint('   - providerId: ${data['providerId']}');
      debugPrint('   - status: ${data['status']}');
    }

    // 3. missions 컬렉션 조회
    debugPrint('\n📊 missions 컬렉션 조회...');
    final missions = await firestore.collection('missions').get();
    debugPrint('📊 missions: ${missions.docs.length}개 문서 발견');

    for (final doc in missions.docs) {
      final data = doc.data();
      debugPrint('🎯 Mission ${doc.id}:');
      debugPrint('   - title: ${data['title']}');
      debugPrint('   - appId: ${data['appId']}');
      debugPrint('   - providerId: ${data['providerId']}');
      debugPrint('   - status: ${data['status']}');
    }

    // 4. 특정 앱 ID로 workflows 검색
    final targetAppId = 'IgbzmVYipzIFwQy6kdqo';
    debugPrint('\n🔍 특정 appId로 workflows 검색: $targetAppId');
    final specificWorkflows = await firestore
        .collection('mission_workflows')
        .where('appId', isEqualTo: targetAppId)
        .get();
    debugPrint('📊 해당 appId의 workflows: ${specificWorkflows.docs.length}개');

    debugPrint('\n✅ Debug 완료!');

  } catch (e) {
    debugPrint('❌ Debug 중 오류: $e');
  }
}

void main() async {
  await debugWorkflowData();
}