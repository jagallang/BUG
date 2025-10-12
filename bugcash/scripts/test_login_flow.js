// Firebase Web SDK를 통한 로그인 플로우 테스트 스크립트
// 브라우저 콘솔에서 실행 가능

console.log('🧪 BugCash 로그인 플로우 테스트 시작');

// 1. 현재 사용자 상태 확인
function checkCurrentUser() {
  console.log('👤 현재 사용자 상태:');
  console.log('  Firebase Auth User:', firebase.auth().currentUser);
  console.log('  User Email:', firebase.auth().currentUser?.email || 'None');
  console.log('  UID:', firebase.auth().currentUser?.uid || 'None');
}

// 2. Firestore에서 사용자 데이터 확인
async function checkUserData(uid) {
  try {
    console.log('📊 Firestore 사용자 데이터 확인:', uid);
    const doc = await firebase.firestore().collection('users').doc(uid).get();

    if (doc.exists) {
      const data = doc.data();
      console.log('  사용자 데이터:', data);
      console.log('  새 형식 여부:', data.roles && data.primaryRole ? '✅' : '❌');
      console.log('  역할:', data.roles || [data.userType]);
      console.log('  기본 역할:', data.primaryRole || data.userType);
      console.log('  관리자:', data.isAdmin ? '✅' : '❌');

      if (data.testerProfile) {
        console.log('  테스터 프로필:', '✅');
      }
      if (data.providerProfile) {
        console.log('  공급자 프로필:', '✅');
      }
    } else {
      console.log('  ❌ 사용자 문서가 존재하지 않습니다');
    }
  } catch (error) {
    console.error('  ❌ 사용자 데이터 조회 실패:', error);
  }
}

// 3. 마이그레이션 상태 확인
async function checkMigrationStatus() {
  try {
    console.log('🔄 마이그레이션 상태 확인');
    const usersSnapshot = await firebase.firestore().collection('users').limit(10).get();

    let newFormat = 0;
    let oldFormat = 0;

    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.roles && data.primaryRole) {
        newFormat++;
      } else {
        oldFormat++;
      }
    });

    console.log('  새 형식 사용자:', newFormat, '명');
    console.log('  기존 형식 사용자:', oldFormat, '명');
    console.log('  마이그레이션 상태:', oldFormat === 0 ? '✅ 완료' : '⚠️ 미완료');
  } catch (error) {
    console.error('  ❌ 마이그레이션 상태 확인 실패:', error);
  }
}

// 4. 전체 테스트 실행
async function runFullTest() {
  console.log('🚀 전체 테스트 시작');

  // 현재 사용자 확인
  checkCurrentUser();

  // 마이그레이션 상태 확인
  await checkMigrationStatus();

  // 로그인된 사용자가 있으면 데이터 확인
  const currentUser = firebase.auth().currentUser;
  if (currentUser) {
    await checkUserData(currentUser.uid);
  } else {
    console.log('👤 로그인된 사용자가 없습니다');
  }

  console.log('✅ 테스트 완료');
}

// 즉시 실행
runFullTest();