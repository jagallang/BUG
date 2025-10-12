// 브라우저 개발자 도구 콘솔에서 실행할 스크립트
// Firebase가 이미 초기화된 상태에서 실행

console.log('🔍 누락된 사용자 문서 생성 시작...');

async function createMissingUser() {
  try {
    // Firestore 인스턴스 가져오기
    const db = firebase.firestore();

    // 누락된 사용자 정보
    const userId = 'hthxwtMDTCapAsvGF17bn8kb3mf2';
    const email = 'episode0611@gmail.com';

    console.log('🔍 사용자 문서 확인:', userId);

    // 기존 문서 확인
    const userDoc = await db.collection('users').doc(userId).get();

    if (userDoc.exists) {
      console.log('✅ 사용자 문서가 이미 존재합니다');
      console.log('데이터:', userDoc.data());
      return;
    }

    console.log('❌ 사용자 문서가 없습니다. 생성하겠습니다.');

    // 새 사용자 문서 생성
    const userData = {
      uid: userId,
      email: email,
      displayName: '이테스터',
      userType: 'tester',
      roles: ['tester'],
      primaryRole: 'tester',
      isAdmin: false,
      profileImage: null,
      points: 0,
      level: 1,
      experience: 0,
      completedMissions: 0,
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: firebase.firestore.FieldValue.serverTimestamp(),
      isActive: true
    };

    await db.collection('users').doc(userId).set(userData);

    console.log('✅ 사용자 문서가 성공적으로 생성되었습니다');
    console.log('데이터:', userData);

  } catch (error) {
    console.error('❌ 오류 발생:', error);
  }
}

// 함수 실행
createMissingUser();