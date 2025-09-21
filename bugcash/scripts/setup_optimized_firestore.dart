import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// BugCash 플랫폼 최적화된 Firestore 컬렉션 설정 스크립트
/// PRD 요구사항에 따른 데이터베이스 구조 초기화
class OptimizedFirestoreSetup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 전체 데이터베이스 초기화
  Future<void> setupDatabase() async {
    print('🚀 BugCash 최적화된 Firestore 데이터베이스 설정 시작...');

    try {
      // 1. 핵심 컬렉션 생성
      await _createCoreCollections();

      // 2. 샘플 데이터 생성 (개발/테스트용)
      await _createSampleData();

      // 3. 관리자 통계 컬렉션 초기화
      await _initializeAdminStats();

      print('✅ 데이터베이스 설정 완료!');
    } catch (e) {
      print('❌ 데이터베이스 설정 실패: $e');
      rethrow;
    }
  }

  /// 핵심 컬렉션 구조 생성
  Future<void> _createCoreCollections() async {
    print('📁 핵심 컬렉션 생성 중...');

    // Users 컬렉션 - 관리자 계정 생성
    await _createAdminUser();

    // Projects 컬렉션 - 샘플 프로젝트
    await _createSampleProject();

    // Applications 컬렉션 - 빈 컬렉션 초기화
    await _initializeCollection('applications');

    // Enrollments 컬렉션 - 빈 컬렉션 초기화
    await _initializeCollection('enrollments');

    // Missions 컬렉션 - 빈 컬렉션 초기화
    await _initializeCollection('missions');

    // Points Transactions 컬렉션 - 빈 컬렉션 초기화
    await _initializeCollection('points_transactions');

    // Reports 컬렉션 - 빈 컬렉션 초기화
    await _initializeCollection('reports');

    // Notifications 컬렉션 - 빈 컬렉션 초기화
    await _initializeCollection('notifications');
  }

  /// 관리자 사용자 생성
  Future<void> _createAdminUser() async {
    const adminId = 'admin_bugcash_2024';

    final adminData = {
      'uid': adminId,
      'email': 'admin@bugcash.com',
      'displayName': 'BugCash 관리자',
      'role': 'admin',
      'points': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'lastLoginAt': FieldValue.serverTimestamp(),
        'deviceInfo': {},
        'preferences': {
          'language': 'ko',
          'notifications': true,
        }
      }
    };

    await _firestore.collection('users').doc(adminId).set(adminData);
    print('👤 관리자 계정 생성: $adminId');
  }

  /// 샘플 프로젝트 생성
  Future<void> _createSampleProject() async {
    final projectData = {
      'appId': 'sample_app_001',
      'appName': '샘플 테스트 앱',
      'providerId': 'sample_provider_001',
      'providerName': '샘플 개발사',
      'status': 'draft',
      'category': 'PRODUCTIVITY',
      'description': '새로운 생산성 앱의 기능 테스트를 진행합니다.',
      'storeUrl': 'https://play.google.com/store/apps/sample',
      'estimatedDays': 14,
      'dailyReward': 5000,
      'maxTesters': 10,
      'currentTesters': 0,
      'budget': 700000, // 14일 × 10명 × 5000P
      'requirements': ['Android 8.0 이상', '일일 30분 이상 사용'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'version': '1.0.0',
        'targetDevices': ['android', 'tablet'],
        'testingFocus': ['기능성', '사용성', '버그리포트']
      }
    };

    final docRef = await _firestore.collection('projects').add(projectData);
    print('📱 샘플 프로젝트 생성: ${docRef.id}');
  }

  /// 빈 컬렉션 초기화 (Firestore에서 컬렉션을 보이게 하기 위해)
  Future<void> _initializeCollection(String collectionName) async {
    final initDoc = {
      '_initialized': true,
      '_description': '$collectionName 컬렉션 초기화 문서',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection(collectionName).doc('_init').set(initDoc);
    print('📂 컬렉션 초기화: $collectionName');
  }

  /// 샘플 데이터 생성 (개발/테스트용)
  Future<void> _createSampleData() async {
    print('🎯 샘플 데이터 생성 중...');

    // 샘플 테스터 사용자들
    await _createSampleTesters();

    // 샘플 공급자 사용자들
    await _createSampleProviders();

    // 샘플 포인트 거래
    await _createSamplePointsTransactions();
  }

  /// 샘플 테스터 생성
  Future<void> _createSampleTesters() async {
    final sampleTesters = [
      {
        'uid': 'tester_001',
        'email': 'tester1@example.com',
        'displayName': '김테스터',
        'role': 'tester',
        'points': 25000,
        'isActive': true,
      },
      {
        'uid': 'tester_002',
        'email': 'tester2@example.com',
        'displayName': '이버그',
        'role': 'tester',
        'points': 18000,
        'isActive': true,
      },
      {
        'uid': 'tester_003',
        'email': 'tester3@example.com',
        'displayName': '박앱테스트',
        'role': 'tester',
        'points': 32000,
        'isActive': true,
      },
    ];

    for (final tester in sampleTesters) {
      final userData = {
        ...tester,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'lastLoginAt': FieldValue.serverTimestamp(),
          'deviceInfo': {
            'model': 'Samsung Galaxy S21',
            'os': 'Android 12',
          },
          'preferences': {
            'language': 'ko',
            'notifications': true,
          }
        }
      };

      await _firestore.collection('users').doc(tester['uid'] as String).set(userData);
      print('👤 테스터 생성: ${tester['displayName']}');
    }
  }

  /// 샘플 공급자 생성
  Future<void> _createSampleProviders() async {
    final sampleProviders = [
      {
        'uid': 'provider_001',
        'email': 'provider1@company.com',
        'displayName': 'TechCorp',
        'role': 'provider',
        'points': 1000000,
        'isActive': true,
      },
      {
        'uid': 'provider_002',
        'email': 'provider2@startup.com',
        'displayName': 'AppStartup',
        'role': 'provider',
        'points': 500000,
        'isActive': true,
      },
    ];

    for (final provider in sampleProviders) {
      final userData = {
        ...provider,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'lastLoginAt': FieldValue.serverTimestamp(),
          'deviceInfo': {},
          'preferences': {
            'language': 'ko',
            'notifications': true,
          }
        }
      };

      await _firestore.collection('users').doc(provider['uid'] as String).set(userData);
      print('🏢 공급자 생성: ${provider['displayName']}');
    }
  }

  /// 샘플 포인트 거래 내역 생성
  Future<void> _createSamplePointsTransactions() async {
    final sampleTransactions = [
      {
        'userId': 'provider_001',
        'type': 'charge',
        'amount': 1000000,
        'balance': 1000000,
        'description': '포인트 충전 (초기 설정)',
        'metadata': {
          'paymentMethod': 'credit_card',
          'transactionId': 'tx_001',
        }
      },
      {
        'userId': 'tester_001',
        'type': 'earn',
        'amount': 5000,
        'balance': 25000,
        'description': '일일 미션 완료 보상',
        'relatedId': 'mission_001',
        'metadata': {}
      },
    ];

    for (final transaction in sampleTransactions) {
      final transactionData = {
        ...transaction,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('points_transactions').add(transactionData);
      print('💰 포인트 거래 생성: ${transaction['description']}');
    }
  }

  /// 관리자 통계 초기화
  Future<void> _initializeAdminStats() async {
    print('📊 관리자 통계 초기화 중...');

    final currentMonth = DateTime.now().toString().substring(0, 7); // YYYY-MM

    final statsData = {
      'period': currentMonth,
      'projects': {
        'total': 1,
        'pending': 0,
        'active': 0,
        'completed': 0,
        'draft': 1,
      },
      'users': {
        'totalUsers': 6, // 관리자 1 + 테스터 3 + 공급자 2
        'newTesters': 3,
        'newProviders': 2,
        'activeUsers': 6,
      },
      'financial': {
        'totalCharged': 1000000,
        'totalPaid': 5000,
        'platformRevenue': 1000, // 수수료 예상
        'pendingPayouts': 0,
      },
      'generatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('admin_dashboard')
        .doc('stats')
        .collection('monthly')
        .doc(currentMonth)
        .set(statsData);

    print('📈 관리자 통계 초기화: $currentMonth');
  }

  /// 컬렉션 존재 확인
  Future<bool> _collectionExists(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 데이터베이스 상태 확인
  Future<void> checkDatabaseStatus() async {
    print('🔍 데이터베이스 상태 확인 중...');

    final collections = [
      'users',
      'projects',
      'applications',
      'enrollments',
      'missions',
      'points_transactions',
      'reports',
      'notifications'
    ];

    for (final collection in collections) {
      final exists = await _collectionExists(collection);
      final status = exists ? '✅' : '❌';

      if (exists) {
        final snapshot = await _firestore.collection(collection).get();
        print('$status $collection: ${snapshot.docs.length}개 문서');
      } else {
        print('$status $collection: 컬렉션 없음');
      }
    }
  }

  /// 기존 레거시 데이터 정리 (주의: 실제 데이터 삭제)
  Future<void> cleanupLegacyCollections() async {
    print('🧹 레거시 컬렉션 정리 중... (주의: 데이터 삭제)');

    final legacyCollections = [
      'mission_applications',
      'tester_applications',
      'test_sessions',
      'app_testers',
    ];

    for (final collection in legacyCollections) {
      try {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        print('🗑️ $collection 삭제: ${snapshot.docs.length}개 문서');
      } catch (e) {
        print('⚠️ $collection 삭제 실패: $e');
      }
    }
  }
}

/// 스크립트 실행 메인 함수
Future<void> main() async {
  print('🚀 BugCash Firestore 최적화 스크립트 시작');

  // Firebase 초기화
  await Firebase.initializeApp();

  final setup = OptimizedFirestoreSetup();

  try {
    // 현재 상태 확인
    await setup.checkDatabaseStatus();

    print('\n📋 다음 작업을 수행할 수 있습니다:');
    print('1. setup() - 새로운 최적화된 구조 생성');
    print('2. checkStatus() - 현재 데이터베이스 상태 확인');
    print('3. cleanup() - 레거시 컬렉션 정리 (주의!)');

    // 전체 설정 실행
    await setup.setupDatabase();

    print('\n✅ 모든 작업 완료!');

  } catch (e) {
    print('❌ 스크립트 실행 실패: $e');
  }
}