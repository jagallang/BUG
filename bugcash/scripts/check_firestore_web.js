// 브라우저 개발자 콘솔에서 실행할 JavaScript 코드
// Flutter 웹 앱에서 Firebase Firestore 데이터 확인

console.log('🔍 BugCash Firestore 데이터 실시간 확인 시작');

// Firebase 인스턴스 확인
try {
  if (typeof firebase !== 'undefined') {
    console.log('✅ Firebase SDK 사용 가능');

    // 현재 사용자 확인
    const currentUser = firebase.auth().currentUser;
    console.log('👤 현재 로그인 사용자:', currentUser?.email || '없음');

    // Firestore 데이터 확인
    checkFirestoreData();

  } else {
    console.log('❌ Firebase SDK를 찾을 수 없습니다');
    console.log('💡 Flutter 웹 앱이 로드된 후 다시 시도하세요');
  }
} catch (error) {
  console.error('❌ Firebase 확인 중 오류:', error);
}

async function checkFirestoreData() {
  try {
    console.log('\n📊 users 컬렉션 데이터 확인...');

    const db = firebase.firestore();
    const usersSnapshot = await db.collection('users').limit(10).get();

    console.log(`총 사용자 수 (최대 10명): ${usersSnapshot.size}명`);

    let newFormatCount = 0;
    let oldFormatCount = 0;

    usersSnapshot.forEach(doc => {
      const data = doc.data();
      const userId = doc.id;

      console.log(`\n👤 사용자: ${userId}`);
      console.log(`   이메일: ${data.email}`);
      console.log(`   이름: ${data.displayName}`);

      // 마이그레이션 상태 확인
      if (data.roles && data.primaryRole) {
        console.log(`   ✅ 새 형식: roles=${JSON.stringify(data.roles)}, primaryRole=${data.primaryRole}`);
        console.log(`   관리자: ${data.isAdmin ? '✅' : '❌'}`);

        if (data.testerProfile) {
          console.log(`   테스터 프로필: ✅ (완료된 테스트: ${data.testerProfile.completedTests || 0})`);
        }
        if (data.providerProfile) {
          console.log(`   공급자 프로필: ✅ (발행 앱: ${data.providerProfile.publishedApps || 0})`);
        }
        newFormatCount++;
      } else if (data.userType) {
        console.log(`   ❌ 기존 형식: userType=${data.userType}`);
        oldFormatCount++;
      }

      // 타임스탬프 확인
      console.log(`   생성일: ${data.createdAt?.toDate?.() || data.createdAt}`);
      console.log(`   마지막 로그인: ${data.lastLoginAt?.toDate?.() || data.lastLoginAt}`);
    });

    console.log(`\n📈 마이그레이션 상태 요약:`);
    console.log(`   새 형식: ${newFormatCount}명`);
    console.log(`   기존 형식: ${oldFormatCount}명`);

    if (newFormatCount + oldFormatCount > 0) {
      const completionRate = ((newFormatCount / (newFormatCount + oldFormatCount)) * 100).toFixed(1);
      console.log(`   마이그레이션 완료율: ${completionRate}%`);
    }

    if (oldFormatCount === 0) {
      console.log(`   🎉 모든 사용자가 새 형식으로 마이그레이션되었습니다!`);
    } else {
      console.log(`   ⚠️ ${oldFormatCount}명의 사용자가 여전히 기존 형식입니다.`);
      console.log(`   💡 관리자 대시보드에서 마이그레이션 버튼을 클릭하세요.`);
    }

  } catch (error) {
    console.error('❌ Firestore 데이터 확인 중 오류:', error);
  }
}

// 특정 사용자 상세 확인 함수
async function checkSpecificUser(userId) {
  try {
    console.log(`\n🔍 특정 사용자 상세 확인: ${userId}`);

    const db = firebase.firestore();
    const userDoc = await db.collection('users').doc(userId).get();

    if (userDoc.exists) {
      const data = userDoc.data();
      console.log('📄 전체 데이터:');
      console.log(JSON.stringify(data, null, 2));

      // 마이그레이션 필요 여부 확인
      if (!data.roles || !data.primaryRole) {
        console.log('⚠️ 이 사용자는 마이그레이션이 필요합니다!');
      } else {
        console.log('✅ 이 사용자는 이미 새 형식입니다.');
      }
    } else {
      console.log('❌ 사용자를 찾을 수 없습니다');
    }

  } catch (error) {
    console.error('❌ 특정 사용자 확인 중 오류:', error);
  }
}

// 사용법 안내
console.log('\n📖 사용법:');
console.log('1. 전체 사용자 확인: checkFirestoreData()');
console.log('2. 특정 사용자 확인: checkSpecificUser("userId")');
console.log('3. 알려진 사용자 확인: checkSpecificUser("hthxwtMDTCapAsvGF17bn8kb3mf2")');

// 글로벌 함수로 등록
window.checkFirestoreData = checkFirestoreData;
window.checkSpecificUser = checkSpecificUser;