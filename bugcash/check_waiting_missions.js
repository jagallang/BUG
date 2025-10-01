// Firestore 데이터 확인 스크립트
// Firebase Console에서 실행

const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function checkWaitingMissions() {
  console.log('🔍 mission_workflows 컬렉션 확인...\n');

  // 1. 모든 mission_workflows 조회
  const allWorkflows = await db.collection('mission_workflows').get();
  console.log(`📊 총 ${allWorkflows.size}개의 mission_workflows 문서\n`);

  // 2. application_submitted 상태만 조회
  const waitingWorkflows = await db.collection('mission_workflows')
    .where('currentState', '==', 'application_submitted')
    .get();

  console.log(`⏳ 대기 중인 신청: ${waitingWorkflows.size}개\n`);

  // 3. 각 문서 상세 정보
  allWorkflows.forEach(doc => {
    const data = doc.data();
    console.log(`📄 문서 ID: ${doc.id}`);
    console.log(`   ├─ appId: ${data.appId}`);
    console.log(`   ├─ currentState: ${data.currentState}`);
    console.log(`   ├─ status: ${data.status || '없음'}`);
    console.log(`   ├─ testerId: ${data.testerId}`);
    console.log(`   ├─ testerName: ${data.testerName}`);
    console.log(`   ├─ providerId: ${data.providerId}`);
    console.log(`   └─ appliedAt: ${data.appliedAt?.toDate?.()}\n`);
  });

  // 4. appId별 그룹화
  const byAppId = {};
  allWorkflows.forEach(doc => {
    const appId = doc.data().appId;
    if (!byAppId[appId]) byAppId[appId] = [];
    byAppId[appId].push({
      id: doc.id,
      currentState: doc.data().currentState,
      testerName: doc.data().testerName
    });
  });

  console.log('📊 appId별 신청 현황:');
  Object.entries(byAppId).forEach(([appId, workflows]) => {
    console.log(`\n🎯 appId: ${appId}`);
    workflows.forEach(w => {
      console.log(`   ├─ ${w.testerName}: ${w.currentState}`);
    });
  });
}

checkWaitingMissions().then(() => {
  console.log('\n✅ 확인 완료');
  process.exit(0);
}).catch(error => {
  console.error('❌ 오류:', error);
  process.exit(1);
});
