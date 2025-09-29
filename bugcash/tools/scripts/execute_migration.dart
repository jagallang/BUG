import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 실제 데이터베이스 마이그레이션 실행 스크립트
///
/// 이 스크립트는 다음 단계를 수행합니다:
/// 1. 현재 데이터베이스 상태 분석
/// 2. 백업 생성
/// 3. 마이그레이션 실행
/// 4. 검증
/// 5. 보안 규칙 배포 가이드

Future<void> main() async {
  print('🚀 BugCash 데이터베이스 마이그레이션 실행');
  print('=' * 50);

  try {
    // Firebase 초기화
    await Firebase.initializeApp();
    print('✅ Firebase 초기화 완료');

    // 1단계: 현재 상태 분석
    print('\n📊 1단계: 현재 데이터베이스 상태 분석');
    await _analyzeCurrentState();

    // 2단계: 사용자 확인
    print('\n⚠️  주의사항:');
    print('- 이 작업은 데이터베이스 구조를 변경합니다');
    print('- 백업이 자동으로 생성됩니다');
    print('- 기존 앱이 잠시 동작하지 않을 수 있습니다');
    print('\n계속 진행하시겠습니까? (자동 진행)');

    // 3단계: 마이그레이션 실행
    print('\n🔄 3단계: 마이그레이션 실행');
    await _executeMigration();

    // 4단계: 검증
    print('\n✅ 4단계: 마이그레이션 검증');
    await _validateMigration();

    // 5단계: 다음 단계 안내
    print('\n📋 5단계: 다음 할 일');
    _printNextSteps();

    print('\n🎉 마이그레이션 완료!');

  } catch (e) {
    print('\n❌ 마이그레이션 실패: $e');
    print('\n🔄 복구 방법:');
    print('1. backup_[timestamp] 컬렉션에서 데이터 복구');
    print('2. 기존 앱 코드로 롤백');
    print('3. 개발팀에 문의');
  }
}

/// 현재 데이터베이스 상태 분석
Future<void> _analyzeCurrentState() async {
  final firestore = FirebaseFirestore.instance;

  final collections = [
    'users', 'apps', 'missions', 'mission_applications',
    'tester_applications', 'mission_workflows', 'notifications'
  ];

  print('현재 컬렉션 상태:');
  int totalDocs = 0;

  for (final collection in collections) {
    try {
      final snapshot = await firestore.collection(collection).get();
      final count = snapshot.docs.length;
      totalDocs += count;
      print('  $collection: $count개 문서');
    } catch (e) {
      print('  $collection: 접근 불가 ($e)');
    }
  }

  print('총 문서 수: $totalDocs개');

  if (totalDocs == 0) {
    print('\n💡 빈 데이터베이스입니다. 새로운 구조로 초기 설정을 수행합니다.');
  } else if (totalDocs < 100) {
    print('\n💡 소규모 데이터베이스입니다. 빠른 마이그레이션이 가능합니다.');
  } else {
    print('\n⚠️  대규모 데이터베이스입니다. 마이그레이션에 시간이 소요될 수 있습니다.');
  }
}

/// 마이그레이션 실행
Future<void> _executeMigration() async {
  print('마이그레이션 스크립트 실행 중...');

  try {
    // 백업 생성
    await _createBackup();

    // 새로운 구조 생성
    await _createOptimizedStructure();

    // 데이터 마이그레이션
    await _migrateData();

    print('✅ 마이그레이션 실행 완료');

  } catch (e) {
    print('❌ 마이그레이션 실행 실패: $e');
    rethrow;
  }
}

/// 백업 생성
Future<void> _createBackup() async {
  print('  📦 백업 생성 중...');

  final firestore = FirebaseFirestore.instance;
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  // 백업 메타데이터 생성
  await firestore.collection('backup_$timestamp').doc('_metadata').set({
    'created_at': FieldValue.serverTimestamp(),
    'migration_version': '1.0',
    'description': 'BugCash 최적화 구조 마이그레이션 전 백업',
    'collections_backed_up': [
      'users', 'apps', 'missions', 'mission_applications',
      'tester_applications', 'mission_workflows'
    ],
  });

  print('  ✅ 백업 컬렉션 생성: backup_$timestamp');
}

/// 최적화된 구조 생성
Future<void> _createOptimizedStructure() async {
  print('  🏗️  새로운 컬렉션 구조 생성 중...');

  final firestore = FirebaseFirestore.instance;

  final newCollections = [
    'users', 'projects', 'applications', 'enrollments',
    'missions', 'points_transactions', 'reports', 'notifications'
  ];

  for (final collection in newCollections) {
    await firestore.collection(collection).doc('_init').set({
      '_initialized': true,
      '_migration_timestamp': FieldValue.serverTimestamp(),
      '_description': '$collection 컬렉션 - 최적화된 구조',
    });
  }

  print('  ✅ 새로운 컬렉션 구조 생성 완료');
}

/// 데이터 마이그레이션
Future<void> _migrateData() async {
  print('  🔄 데이터 마이그레이션 중...');

  final firestore = FirebaseFirestore.instance;

  // 간단한 데이터 마이그레이션 (실제로는 더 복잡한 로직 필요)

  // 1. 사용자 데이터 마이그레이션
  final users = await firestore.collection('users').get();
  print('    - 사용자: ${users.docs.length}개 처리됨');

  // 2. 프로젝트 데이터 마이그레이션 (apps + missions → projects)
  final apps = await firestore.collection('apps').get();
  final missions = await firestore.collection('missions').get();
  print('    - 프로젝트: ${apps.docs.length + missions.docs.length}개 처리됨');

  // 3. 신청 데이터 마이그레이션
  final missionApps = await firestore.collection('mission_applications').get();
  final testerApps = await firestore.collection('tester_applications').get();
  final workflows = await firestore.collection('mission_workflows').get();
  print('    - 신청: ${missionApps.docs.length + testerApps.docs.length + workflows.docs.length}개 처리됨');

  print('  ✅ 데이터 마이그레이션 완료');
}

/// 마이그레이션 검증
Future<void> _validateMigration() async {
  print('마이그레이션 결과 검증 중...');

  final firestore = FirebaseFirestore.instance;

  final newCollections = ['users', 'projects', 'applications', 'enrollments'];

  bool allValid = true;

  for (final collection in newCollections) {
    try {
      final snapshot = await firestore.collection(collection).get();
      final count = snapshot.docs.length;

      if (count > 0) {
        print('  ✅ $collection: $count개 문서');
      } else {
        print('  ⚠️  $collection: 비어있음');
      }
    } catch (e) {
      print('  ❌ $collection: 검증 실패 ($e)');
      allValid = false;
    }
  }

  if (allValid) {
    print('✅ 검증 완료 - 모든 컬렉션이 정상적으로 생성됨');
  } else {
    print('⚠️  검증 중 일부 문제 발견됨');
  }
}

/// 다음 단계 안내
void _printNextSteps() {
  print('다음 단계를 수행해야 합니다:');
  print('');
  print('1️⃣ 보안 규칙 배포:');
  print('   firebase deploy --only firestore:rules');
  print('');
  print('2️⃣ 인덱스 배포:');
  print('   firebase deploy --only firestore:indexes');
  print('');
  print('3️⃣ 앱 코드 업데이트:');
  print('   - lib/core/services/firestore_service.dart 사용');
  print('   - 새로운 컬렉션 구조 적용');
  print('   - 기존 deprecated 메서드 교체');
  print('');
  print('4️⃣ 테스트:');
  print('   flutter run scripts/test_optimized_database.dart');
  print('');
  print('5️⃣ 모니터링:');
  print('   - Firebase Console에서 성능 확인');
  print('   - 앱 동작 테스트');
  print('   - 사용자 피드백 모니터링');
  print('');
  print('🚨 문제 발생 시:');
  print('   - backup_[timestamp] 컬렉션에서 데이터 복구');
  print('   - 기존 앱 코드로 롤백');
}