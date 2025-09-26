// Firebase Admin SDK를 사용한 관리자 계정 생성 스크립트
// 이 스크립트는 로컬에서 실행해야 합니다

const admin = require('firebase-admin');
const serviceAccount = require('./bugcash-firebase-adminsdk.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

async function createAdminAccount() {
  const adminEmail = 'admin@bugcash.com';
  const adminPassword = 'admin123456';
  const adminName = '관리자';

  try {
    // 1. Firebase Auth에 사용자 생성
    let userRecord;
    try {
      // 기존 사용자 확인
      userRecord = await auth.getUserByEmail(adminEmail);
      console.log('기존 관리자 계정 발견:', userRecord.uid);
    } catch (error) {
      // 새 사용자 생성
      userRecord = await auth.createUser({
        email: adminEmail,
        password: adminPassword,
        displayName: adminName,
        emailVerified: true
      });
      console.log('새 관리자 계정 생성:', userRecord.uid);
    }

    // 2. Firestore users 컬렉션에 관리자 정보 저장
    await db.collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: adminEmail,
      displayName: adminName,
      role: 'admin',
      photoURL: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      permissions: {
        canManageProjects: true,
        canManageUsers: true,
        canViewReports: true,
        canManagePayments: true
      }
    }, { merge: true });

    console.log('✅ 관리자 계정 생성 완료!');
    console.log('=====================================');
    console.log('이메일:', adminEmail);
    console.log('비밀번호:', adminPassword);
    console.log('역할: 관리자 (admin)');
    console.log('=====================================');
    console.log('이 정보로 로그인하실 수 있습니다.');

    process.exit(0);
  } catch (error) {
    console.error('❌ 관리자 계정 생성 실패:', error);
    process.exit(1);
  }
}

// 스크립트 실행
createAdminAccount();