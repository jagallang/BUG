const admin = require('firebase-admin');

// Firebase Admin SDK 초기화 (Application Default Credentials 사용)
try {
  admin.initializeApp({
    projectId: 'bugcash'
  });
  console.log('✅ Firebase Admin SDK 초기화 완료');
} catch (error) {
  console.log('⚠️ Firebase Admin SDK 초기화 시도:', error.message);
}

async function checkFirestoreData() {
  try {
    console.log('🔍 Firestore 데이터 확인 시작...');

    const db = admin.firestore();
    const usersRef = db.collection('users');

    // 모든 사용자 조회
    const snapshot = await usersRef.limit(10).get();
    console.log(`📊 총 사용자 수 (최대 10명): ${snapshot.size}명`);

    let newFormatCount = 0;
    let oldFormatCount = 0;

    snapshot.forEach(doc => {
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
          console.log(`   테스터 프로필: ✅`);
        }
        if (data.providerProfile) {
          console.log(`   공급자 프로필: ✅`);
        }
        newFormatCount++;
      } else if (data.userType) {
        console.log(`   ❌ 기존 형식: userType=${data.userType}`);
        oldFormatCount++;
      } else {
        console.log(`   ⚠️ 알 수 없는 형식`);
      }

      console.log(`   생성일: ${data.createdAt?.toDate?.() || data.createdAt}`);
      console.log(`   마지막 로그인: ${data.lastLoginAt?.toDate?.() || data.lastLoginAt}`);
    });

    console.log(`\n📈 마이그레이션 상태 요약:`);
    console.log(`   새 형식: ${newFormatCount}명`);
    console.log(`   기존 형식: ${oldFormatCount}명`);
    console.log(`   마이그레이션 완료율: ${((newFormatCount / (newFormatCount + oldFormatCount)) * 100).toFixed(1)}%`);

    if (oldFormatCount === 0) {
      console.log(`   🎉 모든 사용자가 새 형식으로 마이그레이션되었습니다!`);
    } else {
      console.log(`   ⚠️ ${oldFormatCount}명의 사용자가 여전히 기존 형식입니다.`);
    }

  } catch (error) {
    console.error('❌ 데이터 확인 중 오류:', error);

    if (error.code === 'permission-denied') {
      console.log('\n💡 해결 방법:');
      console.log('1. Firebase Console에서 Service Account 키 다운로드');
      console.log('2. GOOGLE_APPLICATION_CREDENTIALS 환경변수 설정');
      console.log('3. 또는 gcloud auth application-default login 실행');
    }
  }
}

// 특정 사용자 상세 확인
async function checkSpecificUser(userId) {
  try {
    console.log(`\n🔍 특정 사용자 상세 확인: ${userId}`);

    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();

    if (userDoc.exists) {
      const data = userDoc.data();
      console.log('📄 전체 데이터:');
      console.log(JSON.stringify(data, null, 2));
    } else {
      console.log('❌ 사용자를 찾을 수 없습니다');
    }

  } catch (error) {
    console.error('❌ 특정 사용자 확인 중 오류:', error);
  }
}

// 실행
if (require.main === module) {
  checkFirestoreData()
    .then(() => {
      // 알려진 사용자 ID로 상세 확인
      return checkSpecificUser('hthxwtMDTCapAsvGF17bn8kb3mf2');
    })
    .then(() => {
      console.log('\n✅ 데이터 확인 완료');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ 프로그램 실행 중 오류:', error);
      process.exit(1);
    });
}