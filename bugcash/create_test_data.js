// Firebase Admin SDK를 사용하여 테스트 데이터 생성
const admin = require('firebase-admin');

// Firebase Admin 초기화 (서비스 계정 키 필요)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'bugcash'
  });
}

const db = admin.firestore();

async function createTestProjects() {
  const projectsRef = db.collection('projects');

  // 테스트 프로젝트 1 - pending 상태
  await projectsRef.add({
    appName: '테스트 쇼핑몰 앱',
    description: '쇼핑몰 앱의 결제 기능과 사용자 인터페이스를 테스트해주세요.',
    providerId: 'test-provider-1',
    providerName: '테스트 공급자 1',
    status: 'pending',
    maxTesters: 10,
    testPeriodDays: 14,
    rewards: {
      baseReward: 50000,
      bonusReward: 10000
    },
    requirements: {
      platforms: ['android', 'ios'],
      minAge: 18,
      maxAge: 60
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // 테스트 프로젝트 2 - pending 상태
  await projectsRef.add({
    appName: '게임 앱 테스트',
    description: '새로운 게임 앱의 게임플레이와 버그를 찾아주세요.',
    providerId: 'test-provider-2',
    providerName: '테스트 공급자 2',
    status: 'pending',
    maxTesters: 15,
    testPeriodDays: 21,
    rewards: {
      baseReward: 75000,
      bonusReward: 15000
    },
    requirements: {
      platforms: ['android', 'ios'],
      minAge: 16,
      maxAge: 50
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // 테스트 프로젝트 3 - open 상태 (이미 승인됨)
  await projectsRef.add({
    appName: '건강 관리 앱',
    description: '건강 데이터 추적 기능과 UI/UX 테스트',
    providerId: 'test-provider-3',
    providerName: '테스트 공급자 3',
    status: 'open',
    maxTesters: 8,
    testPeriodDays: 14,
    rewards: {
      baseReward: 40000,
      bonusReward: 8000
    },
    requirements: {
      platforms: ['android'],
      minAge: 20,
      maxAge: 65
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    approvedBy: 'admin'
  });

  console.log('테스트 프로젝트 데이터가 성공적으로 생성되었습니다!');
}

createTestProjects().catch(console.error);