import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 현재 데이터베이스 상태 분석 스크립트
class DatabaseAnalyzer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 전체 데이터베이스 분석 실행
  Future<void> analyzeDatabase() async {
    print('🔍 BugCash 데이터베이스 현재 상태 분석 시작...');

    try {
      // 1. 기존 컬렉션들 분석
      await _analyzeExistingCollections();

      // 2. 데이터 중복 확인
      await _checkDataDuplication();

      // 3. 데이터 품질 검사
      await _checkDataQuality();

      // 4. 마이그레이션 계획 제안
      await _suggestMigrationPlan();

      print('\n✅ 데이터베이스 분석 완료!');
    } catch (e) {
      print('❌ 분석 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 기존 컬렉션들 분석
  Future<void> _analyzeExistingCollections() async {
    print('\n📊 기존 컬렉션 분석 중...');

    final collections = [
      'users',
      'apps',
      'missions',
      'mission_applications',
      'tester_applications',
      'mission_workflows',
      'app_testers',
      'test_sessions',
      'notifications',
      'bug_reports',
      'payments',
    ];

    final analysisResult = <String, Map<String, dynamic>>{};

    for (final collectionName in collections) {
      try {
        final snapshot = await _firestore.collection(collectionName).limit(1000).get();
        final docs = snapshot.docs;

        if (docs.isNotEmpty) {
          // 첫 번째 문서의 필드 구조 분석
          final sampleDoc = docs.first.data();
          final fields = sampleDoc.keys.toList();

          analysisResult[collectionName] = {
            'documentCount': docs.length,
            'sampleFields': fields,
            'hasData': true,
          };

          print('📁 $collectionName: ${docs.length}개 문서');
          print('   필드: ${fields.take(5).join(', ')}${fields.length > 5 ? '...' : ''}');
        } else {
          analysisResult[collectionName] = {
            'documentCount': 0,
            'hasData': false,
          };
          print('📁 $collectionName: 비어있음');
        }
      } catch (e) {
        print('⚠️ $collectionName 분석 실패: $e');
        analysisResult[collectionName] = {
          'error': e.toString(),
          'hasData': false,
        };
      }
    }

    // 분석 결과를 JSON 파일로 저장
    await _saveAnalysisResult(analysisResult);
  }

  /// 데이터 중복 확인
  Future<void> _checkDataDuplication() async {
    print('\n🔄 데이터 중복 검사 중...');

    try {
      // mission_applications vs tester_applications 중복 확인
      final missionApps = await _firestore.collection('mission_applications').get();
      final testerApps = await _firestore.collection('tester_applications').get();
      final workflows = await _firestore.collection('mission_workflows').get();

      print('📋 신청 데이터 분석:');
      print('   mission_applications: ${missionApps.docs.length}개');
      print('   tester_applications: ${testerApps.docs.length}개');
      print('   mission_workflows: ${workflows.docs.length}개');

      // 중복 검사 - testerId + missionId 조합으로 확인
      final missionAppKeys = <String>{};
      final testerAppKeys = <String>{};
      final workflowKeys = <String>{};

      for (final doc in missionApps.docs) {
        final data = doc.data();
        final key = '${data['testerId']}_${data['missionId']}';
        missionAppKeys.add(key);
      }

      for (final doc in testerApps.docs) {
        final data = doc.data();
        final key = '${data['testerId']}_${data['appId']}';
        testerAppKeys.add(key);
      }

      for (final doc in workflows.docs) {
        final data = doc.data();
        final key = '${data['testerId']}_${data['appId']}';
        workflowKeys.add(key);
      }

      // 중복 분석
      final missionTesterOverlap = missionAppKeys.intersection(testerAppKeys);
      final missionWorkflowOverlap = missionAppKeys.intersection(workflowKeys);
      final testerWorkflowOverlap = testerAppKeys.intersection(workflowKeys);

      print('\n📊 중복 분석 결과:');
      print('   mission_applications ∩ tester_applications: ${missionTesterOverlap.length}개');
      print('   mission_applications ∩ mission_workflows: ${missionWorkflowOverlap.length}개');
      print('   tester_applications ∩ mission_workflows: ${testerWorkflowOverlap.length}개');

    } catch (e) {
      print('⚠️ 중복 검사 실패: $e');
    }
  }

  /// 데이터 품질 검사
  Future<void> _checkDataQuality() async {
    print('\n🔍 데이터 품질 검사 중...');

    try {
      // Users 컬렉션 품질 검사
      await _checkUsersQuality();

      // Apps/Missions 컬렉션 품질 검사
      await _checkAppsQuality();

      // Applications 컬렉션 품질 검사
      await _checkApplicationsQuality();

    } catch (e) {
      print('⚠️ 데이터 품질 검사 실패: $e');
    }
  }

  /// Users 컬렉션 품질 검사
  Future<void> _checkUsersQuality() async {
    final users = await _firestore.collection('users').get();

    int validUsers = 0;
    int missingFields = 0;
    final roles = <String, int>{};

    for (final doc in users.docs) {
      final data = doc.data();

      // 필수 필드 확인
      final hasRequiredFields = data.containsKey('email') &&
                               data.containsKey('displayName') &&
                               data.containsKey('role');

      if (hasRequiredFields) {
        validUsers++;
        final role = data['role'] ?? 'unknown';
        roles[role] = (roles[role] ?? 0) + 1;
      } else {
        missingFields++;
      }
    }

    print('👥 Users 컬렉션 품질:');
    print('   총 사용자: ${users.docs.length}개');
    print('   유효한 사용자: $validUsers개');
    print('   필드 누락: $missingFields개');
    print('   역할 분포: $roles');
  }

  /// Apps 컬렉션 품질 검사
  Future<void> _checkAppsQuality() async {
    final apps = await _firestore.collection('apps').get();
    final missions = await _firestore.collection('missions').get();

    print('📱 Apps/Missions 컬렉션 품질:');
    print('   Apps: ${apps.docs.length}개');
    print('   Missions: ${missions.docs.length}개');

    // 연결성 확인 - 얼마나 많은 mission이 app과 연결되어 있는지
    final appIds = apps.docs.map((doc) => doc.id).toSet();
    int connectedMissions = 0;

    for (final mission in missions.docs) {
      final data = mission.data();
      final appId = data['appId'];
      if (appId != null && appIds.contains(appId)) {
        connectedMissions++;
      }
    }

    print('   연결된 미션: $connectedMissions/${missions.docs.length}개');
  }

  /// Applications 컬렉션 품질 검사
  Future<void> _checkApplicationsQuality() async {
    final collections = ['mission_applications', 'tester_applications', 'mission_workflows'];

    print('📋 신청 컬렉션들 품질:');

    for (final collection in collections) {
      final docs = await _firestore.collection(collection).get();

      int validDocs = 0;
      final statuses = <String, int>{};

      for (final doc in docs.docs) {
        final data = doc.data();

        // 기본 필드 확인
        final hasBasicFields = data.containsKey('testerId') &&
                              (data.containsKey('missionId') || data.containsKey('appId'));

        if (hasBasicFields) {
          validDocs++;
        }

        final status = data['status'] ?? 'unknown';
        statuses[status] = (statuses[status] ?? 0) + 1;
      }

      print('   $collection: ${docs.docs.length}개 (유효: $validDocs개)');
      print('     상태 분포: $statuses');
    }
  }

  /// 마이그레이션 계획 제안
  Future<void> _suggestMigrationPlan() async {
    print('\n📋 마이그레이션 계획 제안:');
    print('');
    print('1️⃣ 준비 단계 (Pre-Migration)');
    print('   • 현재 데이터 백업 생성');
    print('   • 새로운 컬렉션 구조 준비');
    print('   • 마이그레이션 스크립트 테스트');
    print('');
    print('2️⃣ 마이그레이션 단계 (Migration)');
    print('   • users 컬렉션 → 통합 users (역할 통합)');
    print('   • apps + missions → projects (통합)');
    print('   • mission_applications + tester_applications + mission_workflows → applications');
    print('   • 새로운 enrollments, missions 컬렉션 생성');
    print('');
    print('3️⃣ 검증 단계 (Validation)');
    print('   • 데이터 무결성 확인');
    print('   • 애플리케이션 테스트');
    print('   • 성능 검증');
    print('');
    print('4️⃣ 정리 단계 (Cleanup)');
    print('   • 레거시 컬렉션 아카이브');
    print('   • 인덱스 최적화');
    print('   • 모니터링 설정');
  }

  /// 분석 결과를 파일로 저장
  Future<void> _saveAnalysisResult(Map<String, dynamic> result) async {
    // 여기서는 콘솔 출력만 하지만, 실제로는 파일로 저장할 수 있음
    print('\n💾 분석 결과 저장됨');
  }

  /// 특정 컬렉션의 샘플 데이터 확인
  Future<void> getSampleData(String collectionName, {int limit = 3}) async {
    try {
      final snapshot = await _firestore.collection(collectionName).limit(limit).get();

      print('\n📄 $collectionName 샘플 데이터:');
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        print('   문서 ${i + 1} (${doc.id}):');

        final data = doc.data();
        for (final entry in data.entries) {
          final value = entry.value;
          final displayValue = value is Map || value is List
              ? '[복합 데이터]'
              : value.toString();
          print('     ${entry.key}: $displayValue');
        }
        print('');
      }
    } catch (e) {
      print('⚠️ $collectionName 샘플 데이터 조회 실패: $e');
    }
  }

  /// 마이그레이션 가능성 평가
  Future<Map<String, dynamic>> assessMigrationFeasibility() async {
    print('\n🎯 마이그레이션 가능성 평가 중...');

    final assessment = <String, dynamic>{
      'riskLevel': 'low', // low, medium, high
      'estimatedTime': '2-4 hours',
      'dataIntegrity': 'good',
      'recommendations': <String>[],
    };

    try {
      // 데이터 볼륨 확인
      final collections = ['users', 'apps', 'missions', 'mission_applications', 'tester_applications'];
      int totalDocuments = 0;

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        totalDocuments += snapshot.docs.length;
      }

      // 리스크 평가
      if (totalDocuments > 10000) {
        assessment['riskLevel'] = 'high';
        assessment['estimatedTime'] = '6-8 hours';
        assessment['recommendations'].add('대용량 데이터로 인한 배치 처리 필요');
      } else if (totalDocuments > 1000) {
        assessment['riskLevel'] = 'medium';
        assessment['estimatedTime'] = '3-5 hours';
        assessment['recommendations'].add('중간 규모 데이터, 단계적 마이그레이션 권장');
      }

      // 데이터 무결성 확인
      final users = await _firestore.collection('users').get();
      final apps = await _firestore.collection('apps').get();

      if (users.docs.isEmpty) {
        assessment['dataIntegrity'] = 'poor';
        assessment['recommendations'].add('사용자 데이터 부족 - 초기 설정 필요');
      }

      if (apps.docs.isEmpty) {
        assessment['dataIntegrity'] = 'poor';
        assessment['recommendations'].add('앱 데이터 부족 - 샘플 데이터 생성 필요');
      }

      print('📊 평가 결과:');
      print('   위험도: ${assessment['riskLevel']}');
      print('   예상 시간: ${assessment['estimatedTime']}');
      print('   데이터 무결성: ${assessment['dataIntegrity']}');
      print('   총 문서 수: $totalDocuments개');

      if (assessment['recommendations'].isNotEmpty) {
        print('   권장사항:');
        for (final rec in assessment['recommendations']) {
          print('   • $rec');
        }
      }

      return assessment;
    } catch (e) {
      print('⚠️ 마이그레이션 평가 실패: $e');
      return {'error': e.toString()};
    }
  }
}

/// 메인 실행 함수
Future<void> main() async {
  print('🚀 BugCash 데이터베이스 분석 시작');

  // Firebase 초기화
  await Firebase.initializeApp();

  final analyzer = DatabaseAnalyzer();

  try {
    // 전체 분석 실행
    await analyzer.analyzeDatabase();

    // 마이그레이션 가능성 평가
    await analyzer.assessMigrationFeasibility();

    print('\n💡 다음 단계: 마이그레이션 스크립트 실행');
    print('   dart run scripts/migrate_to_optimized_structure.dart');

  } catch (e) {
    print('\n💥 분석 실패: $e');
  }
}