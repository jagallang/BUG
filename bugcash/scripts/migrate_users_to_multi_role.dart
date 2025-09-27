import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🔄 기존 사용자 데이터를 다중 역할 시스템으로 마이그레이션 시작...');

    final firestore = FirebaseFirestore.instance;
    final usersCollection = firestore.collection('users');

    // 기존 사용자 데이터 조회
    final usersSnapshot = await usersCollection.get();

    if (usersSnapshot.docs.isEmpty) {
      print('❌ 마이그레이션할 사용자 데이터가 없습니다.');
      return;
    }

    print('📊 총 ${usersSnapshot.docs.length}명의 사용자 데이터 마이그레이션 필요');

    int migratedCount = 0;
    int skippedCount = 0;
    List<String> errors = [];

    // 배치 작업 준비
    WriteBatch batch = firestore.batch();
    int batchSize = 0;
    const maxBatchSize = 500;

    for (var doc in usersSnapshot.docs) {
      try {
        final data = doc.data();
        final userId = doc.id;

        // 이미 새 형식인지 확인
        if (data.containsKey('roles') && data.containsKey('primaryRole')) {
          print('⏭️  사용자 $userId: 이미 새 형식으로 되어있음');
          skippedCount++;
          continue;
        }

        // 기존 userType 기반으로 새 구조 생성
        final oldUserType = data['userType'] ?? 'tester';
        final List<String> roles = [oldUserType];
        final String primaryRole = oldUserType;
        final bool isAdmin = oldUserType == 'admin';

        // 업데이트할 데이터 준비
        Map<String, dynamic> updateData = {
          'roles': roles,
          'primaryRole': primaryRole,
          'isAdmin': isAdmin,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 역할별 기본 프로필 추가
        if (oldUserType == 'tester') {
          updateData['testerProfile'] = {
            'preferredCategories': [],
            'devices': [],
            'experience': null,
            'rating': 0.0,
            'completedTests': data['completedMissions'] ?? 0,
            'testingPreferences': {},
            'verificationStatus': 'pending',
          };
        } else if (oldUserType == 'provider') {
          updateData['providerProfile'] = {
            'companyName': null,
            'website': null,
            'businessType': null,
            'appCategories': [],
            'contactInfo': null,
            'rating': 0.0,
            'publishedApps': 0,
            'businessInfo': {},
            'verificationStatus': 'pending',
          };
        }

        // 배치에 추가
        batch.update(doc.reference, updateData);
        batchSize++;

        print('✅ 사용자 $userId ($oldUserType): 마이그레이션 준비 완료');

        // 배치 크기 제한 확인
        if (batchSize >= maxBatchSize) {
          await batch.commit();
          print('📦 배치 ${(migratedCount / maxBatchSize).floor() + 1} 커밋 완료');
          batch = firestore.batch();
          batchSize = 0;
        }

        migratedCount++;

      } catch (e) {
        final error = '사용자 ${doc.id} 마이그레이션 실패: $e';
        errors.add(error);
        print('❌ $error');
      }
    }

    // 남은 배치 커밋
    if (batchSize > 0) {
      await batch.commit();
      print('📦 마지막 배치 커밋 완료');
    }

    // 마이그레이션 결과 출력
    print('\n📊 마이그레이션 완료!');
    print('✅ 성공: ${migratedCount}명');
    print('⏭️  건너뛰기: ${skippedCount}명');
    print('❌ 실패: ${errors.length}명');

    if (errors.isNotEmpty) {
      print('\n🚨 실패한 항목들:');
      for (var error in errors) {
        print('  - $error');
      }
    }

    // 마이그레이션 후 검증
    print('\n🔍 마이그레이션 결과 검증 중...');
    await verifyMigration(firestore);

  } catch (e) {
    print('❌ 마이그레이션 중 오류 발생: $e');
  }
}

Future<void> verifyMigration(FirebaseFirestore firestore) async {
  try {
    final usersSnapshot = await firestore.collection('users').get();

    int newFormatCount = 0;
    int oldFormatCount = 0;
    Map<String, int> roleStats = {};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();

      if (data.containsKey('roles') && data.containsKey('primaryRole')) {
        newFormatCount++;

        // 역할 통계 수집
        final roles = List<String>.from(data['roles'] ?? []);
        for (var role in roles) {
          roleStats[role] = (roleStats[role] ?? 0) + 1;
        }
      } else {
        oldFormatCount++;
      }
    }

    print('📈 검증 결과:');
    print('  새 형식: ${newFormatCount}명');
    print('  기존 형식: ${oldFormatCount}명');
    print('  총 사용자: ${usersSnapshot.docs.length}명');

    print('\n👥 역할별 통계:');
    roleStats.forEach((role, count) {
      print('  $role: ${count}명');
    });

    if (oldFormatCount == 0) {
      print('\n🎉 모든 사용자가 새 형식으로 마이그레이션되었습니다!');
    } else {
      print('\n⚠️  ${oldFormatCount}명의 사용자가 여전히 기존 형식입니다.');
    }

  } catch (e) {
    print('❌ 검증 중 오류: $e');
  }
}