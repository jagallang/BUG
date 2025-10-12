const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = require('./bugcash/firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'bugcash-4ad60'
});

const db = admin.firestore();

async function createMissingUser() {
  const userId = 'hthxwtMDTCapAsvGF17bn8kb3mf2';
  const email = 'episode0611@gmail.com';

  try {
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
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true
    };

    await db.collection('users').doc(userId).set(userData);

    console.log('✅ 사용자 문서가 성공적으로 생성되었습니다');
    console.log('데이터:', userData);

  } catch (error) {
    console.error('❌ 오류 발생:', error);
  } finally {
    admin.app().delete();
  }
}

createMissingUser();