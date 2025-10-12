// 간단한 로컬 마이그레이션 스크립트 (Firebase CLI 인증 사용)
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Firebase Admin 초기화
try {
  // 환경변수로 서비스 계정 키 경로가 설정되어 있으면 사용, 없으면 기본 경로 사용
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    '/Users/isan/Desktop/coding/BUG/bugcash/bugcash-firebase-adminsdk.json';

  const app = initializeApp({
    credential: applicationDefault(),
    projectId: 'bugcash'
  });
  console.log('✅ Firebase Admin 초기화 성공');
  console.log(`📁 서비스 계정 키: ${serviceAccountPath}`);
} catch (error) {
  console.log('⚠️ 초기화 오류:', error.message);
  console.log('💡 서비스 계정 키 파일 경로를 확인해주세요');
  process.exit(1);
}

const db = getFirestore();

async function migrateAllUsers() {
  try {
    console.log('🔄 마이그레이션 시작...');

    // 모든 사용자 조회
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
          migratedAt: FieldValue.serverTimestamp(),
          migratedBy: 'local-script'
        };

        // 역할별 프로필 추가
        if (oldUserType === 'tester') {
          updateData.testerProfile = {
            preferredCategories: data.preferredCategories || [],
            devices: data.devices || [],
            experience: data.experience || null,
            rating: data.rating || 0.0,
            completedTests: data.completedMissions || 0,
            testingPreferences: data.testingPreferences || {},
            verificationStatus: data.verificationStatus || 'pending'
          };
        } else if (oldUserType === 'provider') {
          updateData.providerProfile = {
            companyName: data.companyName || null,
            website: data.website || null,
            businessType: data.businessType || null,
            appCategories: data.appCategories || [],
            contactInfo: data.contactInfo || null,
            rating: data.rating || 0.0,
            publishedApps: data.publishedApps || 0,
            businessInfo: data.businessInfo || {},
            verificationStatus: data.verificationStatus || 'pending'
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
    await verifyMigration();

  } catch (error) {
    console.error('❌ 마이그레이션 중 전체 오류:', error);
  }
}

async function verifyMigration() {
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

// 메인 실행
if (require.main === module) {
  console.log('🚀 BugCash 사용자 마이그레이션 도구 시작');

  migrateAllUsers()
    .then(() => {
      console.log('\n✅ 마이그레이션 프로세스 완료');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ 프로그램 실행 중 오류:', error);
      process.exit(1);
    });
}

module.exports = { migrateAllUsers, verifyMigration };