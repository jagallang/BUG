// 브라우저 콘솔에서 강제 마이그레이션 실행
console.log('🔄 강제 마이그레이션 시작...');

async function forceMigration() {
  try {
    const db = firebase.firestore();

    // 1. 모든 users 조회
    console.log('📊 사용자 조회 중...');
    const usersSnapshot = await db.collection('users').get();
    console.log(`총 ${usersSnapshot.size}명의 사용자 발견`);

    let migratedCount = 0;
    let skippedCount = 0;
    const errors = [];

    // 2. 각 사용자 마이그레이션
    for (const doc of usersSnapshot.docs) {
      try {
        const data = doc.data();
        const userId = doc.id;

        // 이미 새 형식인지 확인
        if (data.roles && data.primaryRole) {
          console.log(`⏭️ ${userId}: 이미 새 형식`);
          skippedCount++;
          continue;
        }

        console.log(`🔄 ${userId} (${data.email}): 마이그레이션 중...`);

        // 기존 userType 기반으로 새 구조 생성
        const oldUserType = data.userType || 'tester';
        const roles = [oldUserType];
        const primaryRole = oldUserType;
        const isAdmin = oldUserType === 'admin';

        // 업데이트할 데이터 준비
        const updateData = {
          roles: roles,
          primaryRole: primaryRole,
          isAdmin: isAdmin,
          updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
        };

        // 역할별 기본 프로필 추가
        if (oldUserType === 'tester') {
          updateData.testerProfile = {
            preferredCategories: [],
            devices: [],
            experience: null,
            rating: 0.0,
            completedTests: data.completedMissions || 0,
            testingPreferences: {},
            verificationStatus: 'pending',
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
            verificationStatus: 'pending',
          };
        }

        // Firestore 업데이트 실행
        await db.collection('users').doc(userId).update(updateData);

        console.log(`✅ ${userId}: 마이그레이션 완료`);
        migratedCount++;

      } catch (e) {
        const error = `❌ ${doc.id}: ${e.message}`;
        errors.push(error);
        console.error(error);
      }
    }

    // 3. 결과 출력
    console.log('\n📊 마이그레이션 완료!');
    console.log(`✅ 성공: ${migratedCount}명`);
    console.log(`⏭️ 건너뛰기: ${skippedCount}명`);
    console.log(`❌ 실패: ${errors.length}명`);

    if (errors.length > 0) {
      console.log('\n🚨 실패한 항목들:');
      errors.forEach(error => console.log(`  ${error}`));
    }

    // 4. 검증
    console.log('\n🔍 결과 검증 중...');
    await verifyMigrationResults();

  } catch (error) {
    console.error('❌ 마이그레이션 중 전체 오류:', error);
  }
}

async function verifyMigrationResults() {
  try {
    const db = firebase.firestore();
    const usersSnapshot = await db.collection('users').get();

    let newFormat = 0;
    let oldFormat = 0;

    usersSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.roles && data.primaryRole) {
        newFormat++;
      } else {
        oldFormat++;
      }
    });

    console.log(`📈 검증 결과:`);
    console.log(`  새 형식: ${newFormat}명`);
    console.log(`  기존 형식: ${oldFormat}명`);
    console.log(`  총 사용자: ${usersSnapshot.size}명`);

    if (oldFormat === 0) {
      console.log('🎉 모든 사용자가 새 형식으로 마이그레이션되었습니다!');
    } else {
      console.log(`⚠️ ${oldFormat}명의 사용자가 여전히 기존 형식입니다.`);
    }

    // 특정 사용자들 상세 확인
    console.log('\n👤 특정 사용자들 확인:');
    const testUsers = ['hthxwtMDTCapAsvGF17bn8kb3mf2', 'CazdCJYsxGMxEOzXGTen3AY5Kom2'];

    for (const userId of testUsers) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const data = userDoc.data();
        console.log(`  ${userId} (${data.email}):`);
        if (data.roles && data.primaryRole) {
          console.log(`    ✅ 새 형식: roles=${JSON.stringify(data.roles)}, primaryRole=${data.primaryRole}`);
        } else {
          console.log(`    ❌ 기존 형식: userType=${data.userType}`);
        }
      }
    }

  } catch (error) {
    console.error('❌ 검증 중 오류:', error);
  }
}

// 즉시 실행
forceMigration();

// 글로벌 함수로 등록
window.forceMigration = forceMigration;
window.verifyMigrationResults = verifyMigrationResults;