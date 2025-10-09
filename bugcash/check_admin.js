const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkAdmin() {
  // Get current user (you'll need to replace with actual UID)
  const usersSnapshot = await db.collection('users').where('role', '==', 'admin').get();
  
  console.log('=== 관리자 계정 목록 ===');
  usersSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`ID: ${doc.id}`);
    console.log(`Email: ${data.email}`);
    console.log(`Name: ${data.displayName || data.name}`);
    console.log(`Role: ${data.role}`);
    console.log('---');
  });
  
  // Also check episode0611@gmail.com specifically
  const userByEmail = await db.collection('users').where('email', '==', 'episode0611@gmail.com').get();
  
  console.log('\n=== episode0611@gmail.com 계정 ===');
  if (userByEmail.empty) {
    console.log('❌ 사용자를 찾을 수 없습니다');
  } else {
    userByEmail.forEach(doc => {
      const data = doc.data();
      console.log(`ID: ${doc.id}`);
      console.log(`Email: ${data.email}`);
      console.log(`Role: ${data.role || '(role 없음)'}`);
    });
  }
}

checkAdmin().then(() => process.exit(0)).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
