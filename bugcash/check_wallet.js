const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'bugcash'
  });
}

const db = admin.firestore();

async function checkWallet() {
  try {
    // 모든 wallets 문서 조회
    const walletsSnapshot = await db.collection('wallets').get();
    
    console.log('=== 모든 지갑 정보 ===');
    console.log(`총 ${walletsSnapshot.size}개의 지갑 발견\n`);
    
    for (const doc of walletsSnapshot.docs) {
      const data = doc.data();
      console.log(`📝 지갑 ID: ${doc.id}`);
      console.log(`   잔액: ${data.balance || 0} 포인트`);
      console.log(`   생성일: ${data.createdAt?.toDate() || '없음'}`);
      console.log(`   총 충전: ${data.totalCharged || 0}`);
      console.log(`   총 사용: ${data.totalSpent || 0}`);
      console.log(`   총 적립: ${data.totalEarned || 0}`);
      console.log('');
    }
    
    // 공급자 역할을 가진 사용자 찾기
    const usersSnapshot = await db.collection('users')
      .where('roles', 'array-contains', 'provider')
      .get();
    
    console.log('=== 공급자 사용자 ===');
    console.log(`총 ${usersSnapshot.size}명의 공급자 발견\n`);
    
    for (const doc of usersSnapshot.docs) {
      const data = doc.data();
      console.log(`👤 사용자 ID: ${doc.id}`);
      console.log(`   이메일: ${data.email || '없음'}`);
      console.log(`   이름: ${data.displayName || '없음'}`);
      console.log(`   역할: ${data.roles?.join(', ') || '없음'}`);
      
      // 해당 사용자의 지갑 확인
      const walletDoc = await db.collection('wallets').doc(doc.id).get();
      if (walletDoc.exists) {
        const walletData = walletDoc.data();
        console.log(`   💰 지갑 잔액: ${walletData.balance || 0} 포인트`);
      } else {
        console.log(`   ⚠️ 지갑 문서 없음`);
      }
      console.log('');
    }
    
  } catch (error) {
    console.error('❌ 에러 발생:', error);
  }
}

checkWallet().then(() => {
  console.log('✅ 조회 완료');
  process.exit(0);
}).catch(error => {
  console.error('❌ 실행 실패:', error);
  process.exit(1);
});
