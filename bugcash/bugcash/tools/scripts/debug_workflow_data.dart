import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug script to check workflow data in Firestore
Future<void> debugWorkflowData() async {
  final firestore = FirebaseFirestore.instance;

  print('🔍 Debug Workflow Data - 시작...');

  try {
    // 1. mission_workflows 컬렉션 전체 조회
    print('\n📊 mission_workflows 컬렉션 조회...');
    final missionWorkflows = await firestore.collection('mission_workflows').get();
    print('📊 mission_workflows: ${missionWorkflows.docs.length}개 문서 발견');

    for (final doc in missionWorkflows.docs) {
      final data = doc.data();
      print('📋 Workflow ${doc.id}:');
      print('   - appId: ${data['appId']}');
      print('   - testerId: ${data['testerId']}');
      print('   - testerName: ${data['testerName']}');
      print('   - providerId: ${data['providerId']}');
      print('   - currentState: ${data['currentState']}');
      print('   - appName: ${data['appName']}');
    }

    // 2. apps 컬렉션 조회 (provider 앱들)
    print('\n📊 apps 컬렉션 조회...');
    final apps = await firestore.collection('apps').get();
    print('📊 apps: ${apps.docs.length}개 문서 발견');

    for (final doc in apps.docs) {
      final data = doc.data();
      print('📱 App ${doc.id}:');
      print('   - appName: ${data['appName']}');
      print('   - providerId: ${data['providerId']}');
      print('   - status: ${data['status']}');
    }

    // 3. missions 컬렉션 조회
    print('\n📊 missions 컬렉션 조회...');
    final missions = await firestore.collection('missions').get();
    print('📊 missions: ${missions.docs.length}개 문서 발견');

    for (final doc in missions.docs) {
      final data = doc.data();
      print('🎯 Mission ${doc.id}:');
      print('   - title: ${data['title']}');
      print('   - appId: ${data['appId']}');
      print('   - providerId: ${data['providerId']}');
      print('   - status: ${data['status']}');
    }

    // 4. 특정 앱 ID로 workflows 검색
    final targetAppId = 'IgbzmVYipzIFwQy6kdqo';
    print('\n🔍 특정 appId로 workflows 검색: $targetAppId');
    final specificWorkflows = await firestore
        .collection('mission_workflows')
        .where('appId', isEqualTo: targetAppId)
        .get();
    print('📊 해당 appId의 workflows: ${specificWorkflows.docs.length}개');

    print('\n✅ Debug 완료!');

  } catch (e) {
    print('❌ Debug 중 오류: $e');
  }
}

void main() async {
  await debugWorkflowData();
}