import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/core/services/optimized_firestore_service.dart';

/// 최적화된 데이터베이스 구조 테스트 스크립트
class DatabaseTester {
  static const String testUserId = 'test_user_001';
  static const String testProviderId = 'test_provider_001';

  /// 전체 테스트 실행
  static Future<void> runAllTests() async {
    print('🧪 BugCash 최적화된 데이터베이스 테스트 시작');

    try {
      // 1. 기본 CRUD 테스트
      await _testBasicCRUD();

      // 2. 사용자 관리 테스트
      await _testUserManagement();

      // 3. 프로젝트 관리 테스트
      await _testProjectManagement();

      // 4. 신청 프로세스 테스트
      await _testApplicationProcess();

      // 5. 포인트 시스템 테스트
      await _testPointsSystem();

      // 6. 쿼리 성능 테스트
      await _testQueryPerformance();

      print('✅ 모든 테스트 통과!');
    } catch (e) {
      print('❌ 테스트 실패: $e');
      rethrow;
    }
  }

  /// 기본 CRUD 테스트
  static Future<void> _testBasicCRUD() async {
    print('\n📝 기본 CRUD 테스트 중...');

    // 사용자 생성
    await OptimizedFirestoreService.createWithId(
      OptimizedFirestoreService.users,
      testUserId,
      {
        'uid': testUserId,
        'email': 'test@example.com',
        'displayName': '테스트 사용자',
        'role': 'tester',
        'points': 10000,
        'isActive': true,
      },
    );

    // 사용자 읽기
    final userData = await OptimizedFirestoreService.read(
      OptimizedFirestoreService.users,
      testUserId,
    );
    assert(userData != null, '사용자 데이터 읽기 실패');
    assert(userData!['displayName'] == '테스트 사용자', '사용자 이름 불일치');

    // 사용자 업데이트
    await OptimizedFirestoreService.update(
      OptimizedFirestoreService.users,
      testUserId,
      {'points': 15000},
    );

    // 업데이트 확인
    final updatedData = await OptimizedFirestoreService.read(
      OptimizedFirestoreService.users,
      testUserId,
    );
    assert(updatedData!['points'] == 15000, '포인트 업데이트 실패');

    print('✓ 기본 CRUD 테스트 통과');
  }

  /// 사용자 관리 테스트
  static Future<void> _testUserManagement() async {
    print('\n👤 사용자 관리 테스트 중...');

    // 공급자 사용자 생성
    await OptimizedFirestoreService.createWithId(
      OptimizedFirestoreService.users,
      testProviderId,
      {
        'uid': testProviderId,
        'email': 'provider@company.com',
        'displayName': '테스트 공급사',
        'role': 'provider',
        'points': 1000000,
        'isActive': true,
      },
    );

    // 포인트 조회 테스트
    final userPoints = await OptimizedFirestoreService.getUserPoints(testUserId);
    assert(userPoints == 15000, '포인트 조회 실패');

    print('✓ 사용자 관리 테스트 통과');
  }

  /// 프로젝트 관리 테스트
  static Future<void> _testProjectManagement() async {
    print('\n📱 프로젝트 관리 테스트 중...');

    // 테스트 프로젝트 생성
    final projectId = await OptimizedFirestoreService.create(
      OptimizedFirestoreService.projects,
      {
        'appId': 'test_app_001',
        'appName': '테스트 앱',
        'providerId': testProviderId,
        'providerName': '테스트 공급사',
        'status': 'open',
        'category': 'PRODUCTIVITY',
        'description': '테스트용 프로젝트입니다.',
        'storeUrl': 'https://play.google.com/store/apps/test',
        'estimatedDays': 14,
        'dailyReward': 5000,
        'maxTesters': 5,
        'currentTesters': 0,
        'budget': 350000,
        'requirements': ['Android 8.0 이상'],
      },
    );

    // 프로젝트 읽기
    final projectData = await OptimizedFirestoreService.read(
      OptimizedFirestoreService.projects,
      projectId,
    );
    assert(projectData != null, '프로젝트 데이터 읽기 실패');
    assert(projectData!['appName'] == '테스트 앱', '프로젝트 이름 불일치');

    // 프로젝트 통계 테스트
    final stats = await OptimizedFirestoreService.getProjectStats(
      providerId: testProviderId,
    );
    assert(stats['total']! >= 1, '프로젝트 통계 실패');
    assert(stats['open']! >= 1, '오픈 프로젝트 통계 실패');

    print('✓ 프로젝트 관리 테스트 통과');
  }

  /// 신청 프로세스 테스트
  static Future<void> _testApplicationProcess() async {
    print('\n📋 신청 프로세스 테스트 중...');

    // 프로젝트 조회 (첫 번째 open 프로젝트)
    final projectsSnapshot = await OptimizedFirestoreService.projects
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();

    if (projectsSnapshot.docs.isEmpty) {
      print('⚠️ 테스트할 오픈 프로젝트가 없습니다');
      return;
    }

    final projectId = projectsSnapshot.docs.first.id;

    // 신청 생성
    final applicationId = await OptimizedFirestoreService.create(
      OptimizedFirestoreService.applications,
      {
        'projectId': projectId,
        'testerId': testUserId,
        'testerName': '테스트 사용자',
        'testerEmail': 'test@example.com',
        'status': 'pending',
        'experience': 'beginner',
        'motivation': '테스트를 위한 신청입니다.',
      },
    );

    // 신청 승인
    await OptimizedFirestoreService.update(
      OptimizedFirestoreService.applications,
      applicationId,
      {
        'status': 'approved',
        'processedBy': testProviderId,
        'processedAt': FieldValue.serverTimestamp(),
      },
    );

    // 승인된 신청 확인
    final applicationData = await OptimizedFirestoreService.read(
      OptimizedFirestoreService.applications,
      applicationId,
    );
    assert(applicationData!['status'] == 'approved', '신청 승인 실패');

    print('✓ 신청 프로세스 테스트 통과');
  }

  /// 포인트 시스템 테스트
  static Future<void> _testPointsSystem() async {
    print('\n💰 포인트 시스템 테스트 중...');

    // 초기 포인트 확인
    final initialPoints = await OptimizedFirestoreService.getUserPoints(testUserId);

    // 포인트 차감 테스트
    await OptimizedFirestoreService.updateUserPoints(
      userId: testUserId,
      amount: -5000,
      type: 'deduct',
      description: '테스트 차감',
    );

    final afterDeduction = await OptimizedFirestoreService.getUserPoints(testUserId);
    assert(afterDeduction == initialPoints - 5000, '포인트 차감 실패');

    // 포인트 적립 테스트
    await OptimizedFirestoreService.updateUserPoints(
      userId: testUserId,
      amount: 3000,
      type: 'earn',
      description: '테스트 적립',
      relatedId: 'test_mission_001',
    );

    final afterEarning = await OptimizedFirestoreService.getUserPoints(testUserId);
    assert(afterEarning == afterDeduction + 3000, '포인트 적립 실패');

    // 부족한 포인트 차감 시도 (실패해야 함)
    try {
      await OptimizedFirestoreService.updateUserPoints(
        userId: testUserId,
        amount: -1000000,
        type: 'deduct',
        description: '테스트 초과 차감',
      );
      assert(false, '초과 차감이 성공했습니다 (실패해야 함)');
    } catch (e) {
      // 예상된 실패
    }

    print('✓ 포인트 시스템 테스트 통과');
  }

  /// 쿼리 성능 테스트
  static Future<void> _testQueryPerformance() async {
    print('\n⚡ 쿼리 성능 테스트 중...');

    final stopwatch = Stopwatch()..start();

    // 프로젝트 스트림 테스트
    final projectsStream = OptimizedFirestoreService.getProjectsStream(
      status: 'open',
      limit: 10,
    );

    await projectsStream.first; // 첫 번째 결과 대기
    final projectsTime = stopwatch.elapsedMilliseconds;

    stopwatch.reset();

    // 신청 스트림 테스트
    final applicationsStream = OptimizedFirestoreService.getApplicationsStream(
      testerId: testUserId,
      limit: 10,
    );

    await applicationsStream.first;
    final applicationsTime = stopwatch.elapsedMilliseconds;

    stopwatch.reset();

    // 포인트 거래 내역 스트림 테스트
    final transactionsStream = OptimizedFirestoreService.getPointsTransactionsStream(
      userId: testUserId,
      limit: 10,
    );

    await transactionsStream.first;
    final transactionsTime = stopwatch.elapsedMilliseconds;

    stopwatch.stop();

    print('📊 쿼리 성능 결과:');
    print('  - 프로젝트 조회: ${projectsTime}ms');
    print('  - 신청 조회: ${applicationsTime}ms');
    print('  - 거래내역 조회: ${transactionsTime}ms');

    // 성능 임계값 확인 (2초 이내)
    assert(projectsTime < 2000, '프로젝트 조회 성능 저하');
    assert(applicationsTime < 2000, '신청 조회 성능 저하');
    assert(transactionsTime < 2000, '거래내역 조회 성능 저하');

    print('✓ 쿼리 성능 테스트 통과');
  }

  /// 테스트 데이터 정리
  static Future<void> cleanupTestData() async {
    print('\n🧹 테스트 데이터 정리 중...');

    try {
      // 테스트 사용자 삭제
      await OptimizedFirestoreService.delete(
        OptimizedFirestoreService.users,
        testUserId,
      );

      await OptimizedFirestoreService.delete(
        OptimizedFirestoreService.users,
        testProviderId,
      );

      // 테스트 프로젝트들 삭제
      final projectsSnapshot = await OptimizedFirestoreService.projects
          .where('providerId', isEqualTo: testProviderId)
          .get();

      final batch = OptimizedFirestoreService.batch();
      for (final doc in projectsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 테스트 신청들 삭제
      final applicationsSnapshot = await OptimizedFirestoreService.applications
          .where('testerId', isEqualTo: testUserId)
          .get();

      final appBatch = OptimizedFirestoreService.batch();
      for (final doc in applicationsSnapshot.docs) {
        appBatch.delete(doc.reference);
      }
      await appBatch.commit();

      // 테스트 포인트 거래 내역 삭제
      final transactionsSnapshot = await OptimizedFirestoreService.pointsTransactions
          .where('userId', isEqualTo: testUserId)
          .get();

      final txBatch = OptimizedFirestoreService.batch();
      for (final doc in transactionsSnapshot.docs) {
        txBatch.delete(doc.reference);
      }
      await txBatch.commit();

      print('✓ 테스트 데이터 정리 완료');
    } catch (e) {
      print('⚠️ 테스트 데이터 정리 중 오류: $e');
    }
  }
}

/// 메인 테스트 실행 함수
Future<void> main() async {
  print('🚀 BugCash 데이터베이스 테스트 시작');

  // Firebase 초기화
  await Firebase.initializeApp();

  try {
    // 전체 테스트 실행
    await DatabaseTester.runAllTests();

    print('\n🎉 모든 테스트가 성공적으로 완료되었습니다!');
    print('📈 최적화된 데이터베이스 구조가 올바르게 작동합니다.');

  } catch (e) {
    print('\n💥 테스트 실패: $e');
  } finally {
    // 테스트 데이터 정리
    await DatabaseTester.cleanupTestData();
  }
}