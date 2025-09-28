const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

async function checkMissionData() {
  try {
    console.log('🔍 Mission Workflows 데이터 확인 시작');

    // 1. episode0611@gmail.com의 UID 확인
    const testerId = 'hthxwtMDTCapAsvGF17bn8kb3mf2';
    console.log('테스터 UID:', testerId);

    // 2. mission_workflows에서 해당 테스터 데이터 확인
    const workflowsSnapshot = await db.collection('mission_workflows')
      .where('testerId', '==', testerId)
      .get();

    console.log(`📋 테스터의 미션 신청 수: ${workflowsSnapshot.docs.length}`);

    if (workflowsSnapshot.docs.length > 0) {
      console.log('\n📝 미션 신청 상세내역:');
      workflowsSnapshot.docs.forEach((doc, index) => {
        const data = doc.data();
        console.log(`${index + 1}. 문서 ID: ${doc.id}`);
        console.log(`   미션 ID: ${data.missionId || 'N/A'}`);
        console.log(`   상태: ${data.status || 'N/A'}`);
        console.log(`   공급자 ID: ${data.providerId || 'N/A'}`);
        console.log(`   신청일: ${data.appliedAt ? data.appliedAt.toDate().toLocaleString() : 'N/A'}`);
        console.log('');
      });
    } else {
      console.log('❌ 해당 테스터의 미션 신청 기록이 없습니다');
    }

    // 3. 전체 mission_workflows 구조 확인
    const allWorkflows = await db.collection('mission_workflows').limit(5).get();
    console.log(`\n📊 전체 mission_workflows 문서 수: ${allWorkflows.size}`);

    if (allWorkflows.size > 0) {
      console.log('\n🔍 첫 번째 문서 구조:');
      const firstDoc = allWorkflows.docs[0];
      const data = firstDoc.data();
      console.log('필드들:', Object.keys(data));
      console.log('샘플 데이터:', data);
    }

  } catch (error) {
    console.error('❌ 확인 중 오류:', error);
  }
}

checkMissionData();