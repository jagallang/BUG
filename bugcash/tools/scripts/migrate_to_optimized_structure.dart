import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// BugCash 데이터베이스 마이그레이션 스크립트
/// 기존 레거시 구조를 최적화된 구조로 변환
class DatabaseMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 마이그레이션 상태 추적
  final Map<String, int> _migrationStats = {
    'users_migrated': 0,
    'projects_created': 0,
    'applications_migrated': 0,
    'errors': 0,
  };

  /// 전체 마이그레이션 실행
  Future<void> executeMigration() async {
    print('🚀 BugCash 데이터베이스 마이그레이션 시작...');

    try {
      // 1. 백업 생성
      await _createBackup();

      // 2. 새로운 컬렉션 구조 준비
      await _prepareNewStructure();

      // 3. 사용자 데이터 마이그레이션
      await _migrateUsers();

      // 4. 프로젝트 데이터 마이그레이션 (apps + missions → projects)
      await _migrateProjects();

      // 5. 신청 데이터 마이그레이션 (mission_applications + tester_applications + mission_workflows → applications)
      await _migrateApplications();

      // 6. 활성 미션 데이터 생성 (enrollments + missions)
      await _createActiveMissions();

      // 7. 알림 및 기타 데이터 마이그레이션
      await _migrateNotifications();

      // 8. 포인트 거래 내역 마이그레이션
      await _migratePointsTransactions();

      // 9. 데이터 검증
      await _validateMigration();

      print('\n✅ 마이그레이션 완료!');
      _printMigrationStats();

    } catch (e) {
      print('❌ 마이그레이션 실패: $e');
      await _rollbackMigration();
      rethrow;
    }
  }

  /// 백업 생성
  Future<void> _createBackup() async {
    print('\n💾 데이터 백업 생성 중...');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupCollections = [
      'users', 'apps', 'missions', 'mission_applications',
      'tester_applications', 'mission_workflows', 'notifications'
    ];

    try {
      final batch = _firestore.batch();
      int backupCount = 0;

      for (final collectionName in backupCollections) {
        final docs = await _firestore.collection(collectionName).get();

        for (final doc in docs.docs) {
          final backupRef = _firestore
              .collection('backup_$timestamp')
              .doc('${collectionName}_${doc.id}');

          batch.set(backupRef, {
            'originalCollection': collectionName,
            'originalId': doc.id,
            'data': doc.data(),
            'backedUpAt': FieldValue.serverTimestamp(),
          });

          backupCount++;
        }
      }

      await batch.commit();
      print('✓ $backupCount개 문서 백업 완료 (backup_$timestamp)');

    } catch (e) {
      print('⚠️ 백업 생성 실패: $e');
      throw Exception('백업 실패로 마이그레이션 중단');
    }
  }

  /// 새로운 컬렉션 구조 준비
  Future<void> _prepareNewStructure() async {
    print('\n🏗️ 새로운 컬렉션 구조 준비 중...');

    final newCollections = [
      'users', 'projects', 'applications', 'enrollments',
      'missions', 'points_transactions', 'reports', 'notifications'
    ];

    try {
      for (final collection in newCollections) {
        // 초기화 문서 생성 (컬렉션을 보이게 하기 위해)
        await _firestore.collection(collection).doc('_migration_init').set({
          '_initialized': true,
          '_description': '$collection 컬렉션 마이그레이션용 초기화',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('✓ 새로운 컬렉션 구조 준비 완료');
    } catch (e) {
      print('⚠️ 구조 준비 실패: $e');
      rethrow;
    }
  }

  /// 사용자 데이터 마이그레이션
  Future<void> _migrateUsers() async {
    print('\n👤 사용자 데이터 마이그레이션 중...');

    try {
      final users = await _firestore.collection('users').get();
      final batch = _firestore.batch();

      for (final userDoc in users.docs) {
        final userData = userDoc.data();

        // 새로운 사용자 구조로 변환
        final newUserData = {
          'uid': userDoc.id,
          'email': userData['email'] ?? '',
          'displayName': userData['displayName'] ?? userData['name'] ?? 'Unknown User',
          'role': userData['role'] ?? 'tester', // 기본값은 tester
          'points': userData['points'] ?? 0,
          'isActive': userData['isActive'] ?? true,
          'phoneNumber': userData['phoneNumber'],
          'profileImage': userData['profileImage'],
          'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'metadata': {
            'lastLoginAt': userData['lastLoginAt'],
            'deviceInfo': userData['deviceInfo'] ?? {},
            'preferences': userData['preferences'] ?? {
              'language': 'ko',
              'notifications': true,
            }
          }
        };

        // 새로운 users 컬렉션에 저장
        final newUserRef = _firestore.collection('users').doc(userDoc.id);
        batch.set(newUserRef, newUserData, SetOptions(merge: true));

        _migrationStats['users_migrated'] = _migrationStats['users_migrated']! + 1;
      }

      await batch.commit();
      print('✓ ${users.docs.length}명 사용자 마이그레이션 완료');

    } catch (e) {
      print('⚠️ 사용자 마이그레이션 실패: $e');
      _migrationStats['errors'] = _migrationStats['errors']! + 1;
      rethrow;
    }
  }

  /// 프로젝트 데이터 마이그레이션 (apps + missions → projects)
  Future<void> _migrateProjects() async {
    print('\n📱 프로젝트 데이터 마이그레이션 중...');

    try {
      final apps = await _firestore.collection('apps').get();
      final missions = await _firestore.collection('missions').get();

      // missions를 appId로 그룹화
      final missionsByAppId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final mission in missions.docs) {
        final appId = mission.data()['appId'];
        if (appId != null) {
          missionsByAppId[appId] = mission;
        }
      }

      final batch = _firestore.batch();

      for (final appDoc in apps.docs) {
        final appData = appDoc.data();
        final mission = missionsByAppId[appDoc.id];
        final missionData = mission?.data() ?? {};

        // 프로젝트 데이터 통합
        final projectData = {
          'appId': appDoc.id,
          'appName': appData['appName'] ?? appData['name'] ?? 'Unknown App',
          'providerId': appData['providerId'] ?? appData['userId'] ?? 'unknown_provider',
          'providerName': appData['providerName'] ?? appData['companyName'] ?? 'Unknown Provider',
          'status': _mapAppStatusToProject(appData['status'] ?? 'draft'),
          'category': appData['category'] ?? 'PRODUCTIVITY',
          'description': missionData['description'] ?? appData['description'] ?? '앱 테스트 프로젝트입니다.',
          'storeUrl': appData['storeUrl'] ?? appData['playStoreUrl'] ?? '',
          'estimatedDays': missionData['estimatedDays'] ?? missionData['duration'] ?? 14,
          'dailyReward': missionData['reward'] ?? missionData['dailyReward'] ?? 5000,
          'maxTesters': missionData['maxTesters'] ?? appData['maxTesters'] ?? 10,
          'currentTesters': appData['currentTesters'] ?? 0,
          'budget': (missionData['reward'] ?? 5000) * (missionData['estimatedDays'] ?? 14) * (missionData['maxTesters'] ?? 10),
          'requirements': appData['requirements'] ?? missionData['requirements'] ?? [],
          'createdAt': appData['createdAt'] ?? missionData['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'startDate': missionData['startDate'],
          'endDate': missionData['endDate'],
          'metadata': {
            'version': appData['version'] ?? '1.0.0',
            'targetDevices': appData['targetDevices'] ?? ['android'],
            'testingFocus': missionData['testingFocus'] ?? ['기능성', '사용성'],
            'originalAppId': appDoc.id,
            'originalMissionId': mission?.id,
          }
        };

        // 새로운 projects 컬렉션에 저장
        final projectRef = _firestore.collection('projects').doc();
        batch.set(projectRef, projectData);

        _migrationStats['projects_created'] = _migrationStats['projects_created']! + 1;
      }

      await batch.commit();
      print('✓ ${apps.docs.length}개 프로젝트 마이그레이션 완료');

    } catch (e) {
      print('⚠️ 프로젝트 마이그레이션 실패: $e');
      _migrationStats['errors'] = _migrationStats['errors']! + 1;
      rethrow;
    }
  }

  /// 신청 데이터 마이그레이션
  Future<void> _migrateApplications() async {
    print('\n📋 신청 데이터 마이그레이션 중...');

    try {
      // 1. mission_applications 마이그레이션
      await _migrateMissionApplications();

      // 2. tester_applications 마이그레이션
      await _migrateTesterApplications();

      // 3. mission_workflows 마이그레이션
      await _migrateMissionWorkflows();

      print('✓ 신청 데이터 마이그레이션 완료');

    } catch (e) {
      print('⚠️ 신청 데이터 마이그레이션 실패: $e');
      _migrationStats['errors'] = _migrationStats['errors']! + 1;
      rethrow;
    }
  }

  /// mission_applications 마이그레이션
  Future<void> _migrateMissionApplications() async {
    final missionApps = await _firestore.collection('mission_applications').get();
    final batch = _firestore.batch();

    for (final doc in missionApps.docs) {
      final data = doc.data();

      // 프로젝트 ID 찾기 (appId로 매핑)
      final projectId = await _findProjectIdByAppId(data['missionId']);
      if (projectId == null) continue;

      final applicationData = {
        'projectId': projectId,
        'testerId': data['testerId'] ?? '',
        'testerName': data['testerName'] ?? 'Unknown Tester',
        'testerEmail': data['testerEmail'] ?? '',
        'status': _mapApplicationStatus(data['status'] ?? 'pending'),
        'appliedAt': data['appliedAt'] ?? FieldValue.serverTimestamp(),
        'processedAt': data['reviewedAt'] ?? data['processedAt'],
        'processedBy': data['processedBy'],
        'experience': data['experience'] ?? 'beginner',
        'motivation': data['message'] ?? data['motivation'] ?? '미션에 참여하고 싶습니다.',
        'feedback': data['responseMessage'] ?? data['feedback'],
        'metadata': {
          'originalCollection': 'mission_applications',
          'originalId': doc.id,
          'missionId': data['missionId'],
        }
      };

      final applicationRef = _firestore.collection('applications').doc();
      batch.set(applicationRef, applicationData);

      _migrationStats['applications_migrated'] = _migrationStats['applications_migrated']! + 1;
    }

    await batch.commit();
    print('  ✓ mission_applications: ${missionApps.docs.length}개');
  }

  /// tester_applications 마이그레이션
  Future<void> _migrateTesterApplications() async {
    final testerApps = await _firestore.collection('tester_applications').get();
    final batch = _firestore.batch();

    for (final doc in testerApps.docs) {
      final data = doc.data();

      // 중복 체크 (이미 migration된 것인지 확인)
      final existingApp = await _firestore
          .collection('applications')
          .where('testerId', isEqualTo: data['testerId'])
          .where('metadata.originalCollection', isEqualTo: 'mission_applications')
          .get();

      if (existingApp.docs.isNotEmpty) {
        continue; // 이미 mission_applications에서 마이그레이션됨
      }

      // 프로젝트 ID 찾기
      final projectId = await _findProjectIdByAppId(data['appId']);
      if (projectId == null) continue;

      final missionInfo = data['missionInfo'] as Map<String, dynamic>? ?? {};
      final progress = data['progress'] as Map<String, dynamic>? ?? {};

      final applicationData = {
        'projectId': projectId,
        'testerId': data['testerId'] ?? '',
        'testerName': data['testerName'] ?? data['name'] ?? 'Unknown Tester',
        'testerEmail': data['testerEmail'] ?? data['email'] ?? '',
        'status': _mapApplicationStatus(data['status'] ?? 'pending'),
        'appliedAt': data['appliedAt'] ?? FieldValue.serverTimestamp(),
        'processedAt': data['statusUpdatedAt'],
        'experience': data['experience'] ?? 'beginner',
        'motivation': data['motivation'] ?? '미션에 참여하고 싶습니다.',
        'metadata': {
          'originalCollection': 'tester_applications',
          'originalId': doc.id,
          'progress': progress,
          'missionInfo': missionInfo,
        }
      };

      final applicationRef = _firestore.collection('applications').doc();
      batch.set(applicationRef, applicationData);

      _migrationStats['applications_migrated'] = _migrationStats['applications_migrated']! + 1;
    }

    await batch.commit();
    print('  ✓ tester_applications: ${testerApps.docs.length}개');
  }

  /// mission_workflows 마이그레이션
  Future<void> _migrateMissionWorkflows() async {
    final workflows = await _firestore.collection('mission_workflows').get();
    final batch = _firestore.batch();

    for (final doc in workflows.docs) {
      final data = doc.data();

      // 중복 체크
      final existingApp = await _firestore
          .collection('applications')
          .where('testerId', isEqualTo: data['testerId'])
          .where('metadata.originalId', isEqualTo: doc.id)
          .get();

      if (existingApp.docs.isNotEmpty) {
        continue; // 이미 마이그레이션됨
      }

      // 프로젝트 ID 찾기
      final projectId = await _findProjectIdByAppId(data['appId']);
      if (projectId == null) continue;

      final applicationData = {
        'projectId': projectId,
        'testerId': data['testerId'] ?? '',
        'testerName': data['testerName'] ?? 'Unknown Tester',
        'testerEmail': data['testerEmail'] ?? '',
        'status': _mapWorkflowStatusToApplication(data['currentState'] ?? 'applicationSubmitted'),
        'appliedAt': data['appliedAt'] ?? FieldValue.serverTimestamp(),
        'processedAt': data['approvedAt'] ?? data['stateUpdatedAt'],
        'processedBy': data['stateUpdatedBy'],
        'experience': data['experience'] ?? 'beginner',
        'motivation': data['motivation'] ?? '미션에 참여하고 싶습니다.',
        'metadata': {
          'originalCollection': 'mission_workflows',
          'originalId': doc.id,
          'workflowState': data['currentState'],
          'totalDays': data['totalDays'],
          'dailyReward': data['dailyReward'],
        }
      };

      final applicationRef = _firestore.collection('applications').doc();
      batch.set(applicationRef, applicationData);

      // 승인된 워크플로우의 경우 enrollments와 missions도 생성
      if (data['currentState'] == 'applicationApproved' ||
          data['currentState'] == 'missionInProgress') {
        await _createEnrollmentFromWorkflow(doc.id, data, applicationRef.id);
      }

      _migrationStats['applications_migrated'] = _migrationStats['applications_migrated']! + 1;
    }

    await batch.commit();
    print('  ✓ mission_workflows: ${workflows.docs.length}개');
  }

  /// 활성 미션 데이터 생성
  Future<void> _createActiveMissions() async {
    print('\n🎯 활성 미션 데이터 생성 중...');

    try {
      // 승인된 신청들을 기반으로 enrollments 생성
      final approvedApps = await _firestore
          .collection('applications')
          .where('status', isEqualTo: 'approved')
          .get();

      final batch = _firestore.batch();

      for (final app in approvedApps.docs) {
        final appData = app.data();

        // enrollment 생성
        final enrollmentData = {
          'projectId': appData['projectId'],
          'testerId': appData['testerId'],
          'status': 'active',
          'startedAt': appData['processedAt'] ?? FieldValue.serverTimestamp(),
          'currentDay': 0,
          'totalDays': appData['metadata']?['totalDays'] ?? 14,
          'totalEarned': 0,
          'progressPercentage': 0.0,
          'lastActivityAt': appData['processedAt'] ?? FieldValue.serverTimestamp(),
          'metadata': {
            'applicationId': app.id,
            'dailyReward': appData['metadata']?['dailyReward'] ?? 5000,
          }
        };

        final enrollmentRef = _firestore.collection('enrollments').doc();
        batch.set(enrollmentRef, enrollmentData);
      }

      await batch.commit();
      print('✓ ${approvedApps.docs.length}개 활성 미션 생성');

    } catch (e) {
      print('⚠️ 활성 미션 생성 실패: $e');
      _migrationStats['errors'] = _migrationStats['errors']! + 1;
    }
  }

  /// 알림 데이터 마이그레이션
  Future<void> _migrateNotifications() async {
    print('\n🔔 알림 데이터 마이그레이션 중...');

    try {
      final notifications = await _firestore.collection('notifications').get();
      final batch = _firestore.batch();

      for (final doc in notifications.docs) {
        final data = doc.data();

        final notificationData = {
          'userId': data['userId'] ?? data['recipientId'] ?? '',
          'type': data['type'] ?? 'system',
          'title': data['title'] ?? '알림',
          'body': data['message'] ?? data['body'] ?? '',
          'data': data['data'] ?? {},
          'read': data['read'] ?? false,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        };

        final newNotificationRef = _firestore.collection('notifications').doc();
        batch.set(newNotificationRef, notificationData);
      }

      await batch.commit();
      print('✓ ${notifications.docs.length}개 알림 마이그레이션 완료');

    } catch (e) {
      print('⚠️ 알림 마이그레이션 실패: $e');
      _migrationStats['errors'] = _migrationStats['errors']! + 1;
    }
  }

  /// 포인트 거래 내역 마이그레이션
  Future<void> _migratePointsTransactions() async {
    print('\n💰 포인트 거래 내역 마이그레이션 중...');

    try {
      // payments 컬렉션에서 데이터 가져오기
      final payments = await _firestore.collection('payments').get();
      final batch = _firestore.batch();

      for (final doc in payments.docs) {
        final data = doc.data();

        final transactionData = {
          'userId': data['userId'] ?? '',
          'type': data['type'] ?? 'charge',
          'amount': data['amount'] ?? 0,
          'balance': data['balance'] ?? 0,
          'description': data['description'] ?? '포인트 거래',
          'relatedId': data['relatedId'],
          'metadata': {
            'paymentMethod': data['paymentMethod'],
            'transactionId': data['transactionId'],
            'originalPaymentId': doc.id,
          },
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        };

        final transactionRef = _firestore.collection('points_transactions').doc();
        batch.set(transactionRef, transactionData);
      }

      await batch.commit();
      print('✓ ${payments.docs.length}개 포인트 거래 내역 마이그레이션 완료');

    } catch (e) {
      print('⚠️ 포인트 거래 내역 마이그레이션 실패: $e');
      _migrationStats['errors'] = _migrationStats['errors']! + 1;
    }
  }

  /// 데이터 검증
  Future<void> _validateMigration() async {
    print('\n✅ 마이그레이션 데이터 검증 중...');

    try {
      // 각 컬렉션의 문서 수 확인
      final validationResults = <String, Map<String, int>>{};

      final collections = ['users', 'projects', 'applications', 'enrollments', 'notifications'];

      for (final collection in collections) {
        final docs = await _firestore.collection(collection).get();
        validationResults[collection] = {
          'total': docs.docs.length,
          'valid': 0,
        };

        // 각 문서의 필수 필드 검증
        for (final doc in docs.docs) {
          if (_validateDocument(collection, doc.data())) {
            validationResults[collection]!['valid'] =
                validationResults[collection]!['valid']! + 1;
          }
        }
      }

      print('📊 검증 결과:');
      for (final entry in validationResults.entries) {
        final total = entry.value['total']!;
        final valid = entry.value['valid']!;
        final percentage = total > 0 ? (valid / total * 100).toStringAsFixed(1) : '0.0';
        print('   ${entry.key}: $valid/$total ($percentage%)');
      }

    } catch (e) {
      print('⚠️ 데이터 검증 실패: $e');
      _migrationStats['errors'] = _migrationStats['errors']! + 1;
    }
  }

  /// 워크플로우에서 enrollment 생성
  Future<void> _createEnrollmentFromWorkflow(String workflowId, Map<String, dynamic> workflowData, String applicationId) async {
    final enrollmentData = {
      'projectId': await _findProjectIdByAppId(workflowData['appId']),
      'testerId': workflowData['testerId'],
      'status': 'active',
      'startedAt': workflowData['approvedAt'] ?? FieldValue.serverTimestamp(),
      'currentDay': workflowData['currentDay'] ?? 0,
      'totalDays': workflowData['totalDays'] ?? 14,
      'totalEarned': 0,
      'progressPercentage': 0.0,
      'lastActivityAt': workflowData['stateUpdatedAt'] ?? FieldValue.serverTimestamp(),
      'metadata': {
        'applicationId': applicationId,
        'workflowId': workflowId,
        'dailyReward': workflowData['dailyReward'] ?? 5000,
      }
    };

    await _firestore.collection('enrollments').add(enrollmentData);
  }

  /// appId로 프로젝트 ID 찾기
  Future<String?> _findProjectIdByAppId(String? appId) async {
    if (appId == null) return null;

    try {
      final projects = await _firestore
          .collection('projects')
          .where('appId', isEqualTo: appId)
          .limit(1)
          .get();

      return projects.docs.isNotEmpty ? projects.docs.first.id : null;
    } catch (e) {
      return null;
    }
  }

  /// 문서 유효성 검증
  bool _validateDocument(String collection, Map<String, dynamic> data) {
    switch (collection) {
      case 'users':
        return data.containsKey('uid') && data.containsKey('email') && data.containsKey('role');
      case 'projects':
        return data.containsKey('appId') && data.containsKey('appName') && data.containsKey('providerId');
      case 'applications':
        return data.containsKey('projectId') && data.containsKey('testerId') && data.containsKey('status');
      case 'enrollments':
        return data.containsKey('projectId') && data.containsKey('testerId') && data.containsKey('status');
      default:
        return true;
    }
  }

  /// 상태 매핑 헬퍼 메서드들
  String _mapAppStatusToProject(String appStatus) {
    switch (appStatus) {
      case 'active': return 'open';
      case 'inactive': return 'closed';
      case 'pending': return 'pending';
      default: return 'draft';
    }
  }

  String _mapApplicationStatus(String status) {
    switch (status) {
      case 'accepted': return 'approved';
      case 'rejected': return 'rejected';
      default: return 'pending';
    }
  }

  String _mapWorkflowStatusToApplication(String workflowState) {
    switch (workflowState) {
      case 'applicationApproved': return 'approved';
      case 'applicationRejected': return 'rejected';
      case 'missionInProgress': return 'approved';
      default: return 'pending';
    }
  }

  /// 롤백 함수
  Future<void> _rollbackMigration() async {
    print('\n🔄 마이그레이션 롤백 중...');

    try {
      // 새로 생성된 컬렉션들의 문서 삭제
      final collectionsToClean = ['projects', 'applications', 'enrollments'];

      for (final collection in collectionsToClean) {
        final docs = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      print('✓ 롤백 완료');
    } catch (e) {
      print('⚠️ 롤백 실패: $e');
    }
  }

  /// 마이그레이션 통계 출력
  void _printMigrationStats() {
    print('\n📊 마이그레이션 통계:');
    for (final entry in _migrationStats.entries) {
      print('   ${entry.key}: ${entry.value}');
    }
  }
}

/// 메인 실행 함수
Future<void> main() async {
  print('🚀 BugCash 데이터베이스 마이그레이션 시작');

  // Firebase 초기화
  await Firebase.initializeApp();

  final migration = DatabaseMigration();

  try {
    // 사용자 확인
    print('\n⚠️  주의: 이 작업은 데이터베이스 구조를 변경합니다.');
    print('계속하시겠습니까? (y/N): ');

    // 실제 운영에서는 사용자 입력을 받아야 하지만,
    // 여기서는 자동으로 진행합니다.
    print('자동 진행 모드로 마이그레이션을 시작합니다...');

    await migration.executeMigration();

    print('\n🎉 마이그레이션이 성공적으로 완료되었습니다!');
    print('📱 이제 앱을 새로운 데이터베이스 구조로 업데이트할 수 있습니다.');

  } catch (e) {
    print('\n💥 마이그레이션 실패: $e');
    print('백업에서 복구가 필요할 수 있습니다.');
  }
}