const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = {
  "projectId": "bugcash"
};

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'bugcash'
});

const db = admin.firestore();

async function exportFirestoreUsers() {
  try {
    console.log('🔄 Firestore users 컬렉션 데이터 내보내기...');

    const usersSnapshot = await db.collection('users').get();
    const users = [];

    usersSnapshot.forEach(doc => {
      users.push({
        id: doc.id,
        data: doc.data()
      });
    });

    fs.writeFileSync('firestore_users.json', JSON.stringify(users, null, 2));

    console.log(`✅ ${users.length}명의 사용자 데이터 내보내기 완료: firestore_users.json`);

    // 사용자 통계
    const userTypes = {};
    users.forEach(user => {
      const userType = user.data.userType || 'unknown';
      userTypes[userType] = (userTypes[userType] || 0) + 1;
    });

    console.log('\n📊 사용자 유형별 통계:');
    Object.entries(userTypes).forEach(([type, count]) => {
      console.log(`  ${type}: ${count}명`);
    });

  } catch (error) {
    console.error('❌ 오류:', error);
  }
}

exportFirestoreUsers();