// 브라우저 콘솔에서 실행할 마이그레이션 결과 확인 코드
console.log('🔍 마이그레이션 결과 확인 시작...');

async function verifyMigrationResult() {
  try {
    const db = firebase.firestore();

    // 특정 사용자 확인 (이민 사용자)
    console.log('\n👤 특정 사용자 확인: hthxwtMDTCapAsvGF17bn8kb3mf2');
    const userDoc = await db.collection('users').doc('hthxwtMDTCapAsvGF17bn8kb3mf2').get();

    if (userDoc.exists) {
      const data = userDoc.data();
      console.log('📄 사용자 데이터:');
      console.log(`   이메일: ${data.email}`);
      console.log(`   이름: ${data.displayName}`);

      // 마이그레이션 상태 확인
      if (data.roles && data.primaryRole) {
        console.log('✅ 마이그레이션 완료!');
        console.log(`   기존: userType = ${data.userType}`);
        console.log(`   새로운: roles = ${JSON.stringify(data.roles)}`);
        console.log(`   새로운: primaryRole = ${data.primaryRole}`);
        console.log(`   새로운: isAdmin = ${data.isAdmin}`);

        if (data.testerProfile) {
          console.log('   테스터 프로필: ✅');
          console.log(`     - 완료된 테스트: ${data.testerProfile.completedTests}`);
          console.log(`     - 평점: ${data.testerProfile.rating}`);
          console.log(`     - 검증 상태: ${data.testerProfile.verificationStatus}`);
        }

        if (data.providerProfile) {
          console.log('   공급자 프로필: ✅');
          console.log(`     - 발행 앱: ${data.providerProfile.publishedApps}`);
          console.log(`     - 평점: ${data.providerProfile.rating}`);
        }
      } else {
        console.log('❌ 마이그레이션 미완료');
        console.log(`   현재: userType = ${data.userType}`);
        console.log('   누락된 필드: roles, primaryRole, isAdmin');
      }

      console.log(`   마지막 업데이트: ${data.updatedAt?.toDate?.() || data.updatedAt}`);
    } else {
      console.log('❌ 사용자를 찾을 수 없습니다');
    }

    // 전체 사용자 마이그레이션 상태 확인
    console.log('\n📊 전체 마이그레이션 상태 확인...');
    const allUsers = await db.collection('users').limit(10).get();

    let newFormat = 0;
    let oldFormat = 0;

    allUsers.forEach(doc => {
      const data = doc.data();
      if (data.roles && data.primaryRole) {
        newFormat++;
      } else {
        oldFormat++;
      }
    });

    console.log(`   새 형식: ${newFormat}명`);
    console.log(`   기존 형식: ${oldFormat}명`);
    console.log(`   총 사용자: ${allUsers.size}명`);

    if (oldFormat === 0) {
      console.log('🎉 모든 사용자 마이그레이션 완료!');
    } else {
      console.log(`⚠️ ${oldFormat}명의 사용자가 아직 마이그레이션되지 않았습니다`);
    }

  } catch (error) {
    console.error('❌ 확인 중 오류:', error);
  }
}

// 즉시 실행
verifyMigrationResult();

// 글로벌 함수로 등록
window.verifyMigrationResult = verifyMigrationResult;