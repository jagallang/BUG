const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setAdminRole() {
  const email = 'episode0611@gmail.com';
  
  // Find user by email
  const usersSnapshot = await db.collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();
  
  if (usersSnapshot.empty) {
    console.log(`❌ ${email} 사용자를 찾을 수 없습니다`);
    return;
  }
  
  const userDoc = usersSnapshot.docs[0];
  const userId = userDoc.id;
  const userData = userDoc.data();
  
  console.log(`✅ 사용자 찾음: ${userId}`);
  console.log(`현재 role: ${userData.role || '(없음)'}`);
  
  // Set admin role
  await db.collection('users').doc(userId).update({
    role: 'admin',
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  console.log(`✅ ${email}를 관리자로 설정했습니다`);
  
  // Verify
  const updatedDoc = await db.collection('users').doc(userId).get();
  console.log(`확인된 role: ${updatedDoc.data().role}`);
}

setAdminRole()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
