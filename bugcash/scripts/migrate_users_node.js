const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = {
  "type": "service_account",
  "project_id": "bugcash",
  "private_key_id": "your_private_key_id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",
  "client_email": "your_service_account@bugcash.iam.gserviceaccount.com",
  "client_id": "your_client_id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
};

// 대안: Application Default Credentials 사용
// admin.initializeApp({
//   credential: admin.credential.applicationDefault(),
//   projectId: 'bugcash'
// });

async function migrateUsers() {
  try {
    console.log('🔄 사용자 데이터 마이그레이션 시작...');

    const db = admin.firestore();
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();

    console.log(`📊 총 ${snapshot.size}명의 사용자 데이터 발견`);

    let migratedCount = 0;
    let skippedCount = 0;
    const errors = [];

    const batch = db.batch();

    snapshot.forEach(doc => {
      try {
        const data = doc.data();
        const userId = doc.id;

        // 이미 새 형식인지 확인
        if (data.roles && data.primaryRole) {
          console.log(`⏭️  사용자 ${userId}: 이미 새 형식`);
          skippedCount++;
          return;
        }

        // 기존 userType 기반으로 새 구조 생성
        const oldUserType = data.userType || 'tester';
        const roles = [oldUserType];
        const primaryRole = oldUserType;
        const isAdmin = oldUserType === 'admin';

        const updateData = {
          roles: roles,
          primaryRole: primaryRole,
          isAdmin: isAdmin,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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

        batch.update(doc.ref, updateData);
        console.log(`✅ 사용자 ${userId} (${oldUserType}): 마이그레이션 준비`);
        migratedCount++;

      } catch (error) {
        const errorMsg = `사용자 ${doc.id} 마이그레이션 실패: ${error}`;
        errors.push(errorMsg);
        console.error(`❌ ${errorMsg}`);
      }
    });

    // 배치 커밋
    if (migratedCount > 0) {
      await batch.commit();
      console.log('📦 배치 커밋 완료');
    }

    // 결과 출력
    console.log('\n📊 마이그레이션 완료!');
    console.log(`✅ 성공: ${migratedCount}명`);
    console.log(`⏭️  건너뛰기: ${skippedCount}명`);
    console.log(`❌ 실패: ${errors.length}명`);

    if (errors.length > 0) {
      console.log('\n🚨 실패한 항목들:');
      errors.forEach(error => console.log(`  - ${error}`));
    }

  } catch (error) {
    console.error('❌ 마이그레이션 중 오류:', error);
  }
}

// Service Account 키가 있다면 실행
if (require.main === module) {
  // admin.initializeApp({
  //   credential: admin.credential.cert(serviceAccount)
  // });

  console.log('⚠️  Service Account 키를 설정한 후 실행하세요');
  console.log('또는 gcloud auth application-default login 후 실행하세요');

  // migrateUsers().then(() => process.exit(0));
}

module.exports = { migrateUsers };