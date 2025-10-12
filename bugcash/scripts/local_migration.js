// 로컬에서 실행할 Firebase Admin 마이그레이션
const admin = require('firebase-admin');

// Service Account 키 없이 실행 (Application Default Credentials)
try {
  admin.initializeApp({
    projectId: 'bugcash'
  });
  console.log('✅ Firebase Admin 초기화 성공');
} catch (error) {
  console.log('⚠️ 초기화 오류:', error.message);
}

async function migrateAllUsers() {
  try {
    console.log('🔄 자동 마이그레이션 시작...');

    const db = admin.firestore();
    const usersSnapshot = await db.collection('users').get();

    console.log(`📊 총 ${usersSnapshot.size}명의 사용자 발견`);

    let migratedCount = 0;
    let skippedCount = 0;
    const errors = [];

    // 배치 작업으로 효율성 향상
    const batch = db.batch();

    usersSnapshot.forEach(doc => {
      try {
        const data = doc.data();
        const userId = doc.id;

        // 이미 마이그레이션된 사용자는 건너뛰기
        if (data.roles && data.primaryRole) {
          console.log(`⏭️ ${userId}: 이미 새 형식`);
          skippedCount++;
          return;
        }

        const oldUserType = data.userType || 'tester';
        const updateData = {
          roles: [oldUserType],
          primaryRole: oldUserType,
          isAdmin: oldUserType === 'admin',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // 역할별 프로필 추가
        if (oldUserType === 'tester') {
          updateData.testerProfile = {
            preferredCategories: [],
            devices: [],
            rating: 0.0,
            completedTests: data.completedMissions || 0,
            testingPreferences: {},
            verificationStatus: 'pending'
          };
        } else if (oldUserType === 'provider') {
          updateData.providerProfile = {
            companyName: null,
            website: null,
            businessType: null,
            appCategories: [],
            contactInfo: null,
            rating: 0.0,
            publishedApps: 0,
            businessInfo: {},
            verificationStatus: 'pending'
          };
        }

        batch.update(doc.ref, updateData);
        console.log(`✅ ${userId} (${data.email || 'Unknown'}): 마이그레이션 준비`);
        migratedCount++;

      } catch (error) {
        const errorMsg = `사용자 ${doc.id} 처리 실패: ${error.message}`;
        errors.push(errorMsg);
        console.error(`❌ ${errorMsg}`);
      }
    });

    // 배치 커밋
    if (migratedCount > 0) {
      await batch.commit();
      console.log('\n📦 배치 커밋 완료');
    }

    // 결과 요약
    console.log('\n📊 마이그레이션 완료!');
    console.log(`✅ 성공: ${migratedCount}명`);
    console.log(`⏭️ 건너뛰기: ${skippedCount}명`);
    console.log(`❌ 실패: ${errors.length}명`);

    if (errors.length > 0) {
      console.log('\n🚨 실패한 항목들:');
      errors.forEach(error => console.log(`  - ${error}`));
    }

    // 검증
    console.log('\n🔍 마이그레이션 결과 검증...');
    await verifyMigration(db);

  } catch (error) {
    console.error('❌ 마이그레이션 중 전체 오류:', error);
  }
}

async function verifyMigration(db) {
  try {
    const usersSnapshot = await db.collection('users').get();

    let newFormat = 0;
    let oldFormat = 0;
    const roleStats = {};

    usersSnapshot.forEach(doc => {
      const data = doc.data();

      if (data.roles && data.primaryRole) {
        newFormat++;
        const roles = data.roles || [];
        roles.forEach(role => {
          roleStats[role] = (roleStats[role] || 0) + 1;
        });
      } else {
        oldFormat++;
      }
    });

    console.log('📈 검증 결과:');
    console.log(`  새 형식: ${newFormat}명`);
    console.log(`  기존 형식: ${oldFormat}명`);
    console.log(`  총 사용자: ${usersSnapshot.size}명`);

    console.log('\n👥 역할별 통계:');
    Object.entries(roleStats).forEach(([role, count]) => {
      console.log(`  ${role}: ${count}명`);
    });

    if (oldFormat === 0) {
      console.log('\n🎉 모든 사용자가 새 형식으로 마이그레이션되었습니다!');
    } else {
      console.log(`\n⚠️ ${oldFormat}명의 사용자가 여전히 기존 형식입니다.`);
    }

  } catch (error) {
    console.error('❌ 검증 중 오류:', error);
  }
}

// 특정 사용자 확인 함수
async function checkSpecificUser(userId) {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();

    if (userDoc.exists) {
      const data = userDoc.data();
      console.log(`\n👤 사용자 ${userId} 상세 정보:`);
      console.log(`  이메일: ${data.email}`);
      console.log(`  이름: ${data.displayName}`);

      if (data.roles && data.primaryRole) {
        console.log(`  ✅ 새 형식: roles=${JSON.stringify(data.roles)}, primaryRole=${data.primaryRole}`);
        console.log(`  관리자: ${data.isAdmin ? '✅' : '❌'}`);

        if (data.testerProfile) {
          console.log(`  테스터 프로필: ✅`);
        }
        if (data.providerProfile) {
          console.log(`  공급자 프로필: ✅`);
        }
      } else {
        console.log(`  ❌ 기존 형식: userType=${data.userType}`);
      }

      console.log(`  마지막 업데이트: ${data.updatedAt?.toDate?.() || data.updatedAt}`);
    } else {
      console.log(`❌ 사용자 ${userId}를 찾을 수 없습니다`);
    }

  } catch (error) {
    console.error(`❌ 사용자 ${userId} 확인 중 오류:`, error);
  }
}

// 메인 실행
if (require.main === module) {
  console.log('🚀 BugCash 사용자 마이그레이션 도구 시작');

  migrateAllUsers()
    .then(() => {
      // 특정 사용자들 확인
      console.log('\n🔍 특정 사용자들 확인...');
      return Promise.all([
        checkSpecificUser('hthxwtMDTCapAsvGF17bn8kb3mf2'),
        checkSpecificUser('CazdCJYsxGMxEOzXGTen3AY5Kom2')
      ]);
    })
    .then(() => {
      console.log('\n✅ 마이그레이션 프로세스 완료');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ 프로그램 실행 중 오류:', error);
      process.exit(1);
    });
}

module.exports = { migrateAllUsers, checkSpecificUser };