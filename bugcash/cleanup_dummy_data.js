const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupDummyData() {
  console.log('🧹 더미 데이터 정리 시작...');

  try {
    // 더미 테스터 신청 데이터 삭제
    const dummyIds = [
      'DwyC49vVgLnvBeFTACmR', // active_tester_456
      'kqgQpzJWCw0W39o79cHg'  // completed_tester_789
    ];

    for (const docId of dummyIds) {
      try {
        await db.collection('tester_applications').doc(docId).delete();
        console.log(`✅ 더미 데이터 삭제 완료: ${docId}`);
      } catch (error) {
        console.log(`❌ 더미 데이터 삭제 실패: ${docId} - ${error.message}`);
      }
    }

    console.log('🎉 더미 데이터 정리 완료!');
  } catch (error) {
    console.error('❌ 정리 과정에서 오류 발생:', error);
  }

  process.exit(0);
}

cleanupDummyData();