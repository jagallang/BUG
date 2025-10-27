/**
 * v2.186.2: 완료된 미션의 프로젝트 상태를 'closed'로 업데이트하는 마이그레이션 스크립트
 *
 * 문제: v2.170.0 이전에 완료된 프로젝트들이 projects.status = 'open'으로 남아있음
 * 해결: mission_workflows.currentState = 'projectCompleted'인 워크플로우의 프로젝트를 'closed'로 업데이트
 */

const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
// gcloud auth application-default login 실행 후 사용
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'bugcash'
  });
}

async function closeCompletedMissions() {
  try {
    console.log('🔄 완료된 미션 프로젝트 상태 업데이트 시작...\n');

    const db = admin.firestore();

    // 1. mission_workflows에서 완료된 워크플로우 조회
    const workflowsRef = db.collection('mission_workflows');
    const completedWorkflows = await workflowsRef
      .where('currentState', '==', 'projectCompleted')
      .get();

    console.log(`📊 완료된 워크플로우: ${completedWorkflows.size}개 발견\n`);

    if (completedWorkflows.empty) {
      console.log('✅ 완료된 워크플로우가 없습니다.');
      return;
    }

    // 2. 각 워크플로우의 appId를 추출하고 중복 제거
    const appIds = new Set();
    const workflowsByAppId = new Map();

    completedWorkflows.forEach(doc => {
      const data = doc.data();
      const appId = data.appId;

      if (appId) {
        appIds.add(appId);

        if (!workflowsByAppId.has(appId)) {
          workflowsByAppId.set(appId, []);
        }
        workflowsByAppId.get(appId).push({
          workflowId: doc.id,
          appName: data.appName,
          testerId: data.testerId,
          completedAt: data.completedAt?.toDate() || new Date(),
        });
      }
    });

    console.log(`📱 업데이트 대상 프로젝트: ${appIds.size}개\n`);

    // 3. 각 프로젝트의 현재 상태 확인 및 업데이트
    let updatedCount = 0;
    let alreadyClosedCount = 0;
    let notFoundCount = 0;
    const errors = [];

    for (const appId of appIds) {
      try {
        const projectRef = db.collection('projects').doc(appId);
        const projectDoc = await projectRef.get();

        if (!projectDoc.exists) {
          console.log(`⚠️  프로젝트 ${appId}: 문서를 찾을 수 없음`);
          notFoundCount++;
          continue;
        }

        const projectData = projectDoc.data();
        const currentStatus = projectData.status || 'unknown';
        const appName = projectData.appName || 'Unknown App';
        const workflows = workflowsByAppId.get(appId);

        console.log(`\n📋 ${appName} (${appId})`);
        console.log(`   현재 상태: ${currentStatus}`);
        console.log(`   완료된 워크플로우: ${workflows.length}개`);

        workflows.forEach((wf, index) => {
          console.log(`   ${index + 1}. 워크플로우 ${wf.workflowId}`);
          console.log(`      - 테스터: ${wf.testerId}`);
          console.log(`      - 완료 시간: ${wf.completedAt.toLocaleString('ko-KR')}`);
        });

        if (currentStatus === 'closed') {
          console.log(`   ✅ 이미 closed 상태 (업데이트 불필요)`);
          alreadyClosedCount++;
        } else {
          // 프로젝트 상태를 'closed'로 업데이트
          await projectRef.update({
            status: 'closed',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`   🔄 ${currentStatus} → closed 업데이트 완료!`);
          updatedCount++;
        }

      } catch (error) {
        const errorMsg = `프로젝트 ${appId} 업데이트 실패: ${error.message}`;
        errors.push(errorMsg);
        console.error(`   ❌ ${errorMsg}`);
      }
    }

    // 4. 결과 출력
    console.log('\n' + '='.repeat(60));
    console.log('📊 마이그레이션 완료!');
    console.log('='.repeat(60));
    console.log(`✅ 업데이트 완료: ${updatedCount}개`);
    console.log(`⏭️  이미 closed: ${alreadyClosedCount}개`);
    console.log(`⚠️  찾을 수 없음: ${notFoundCount}개`);
    console.log(`❌ 실패: ${errors.length}개`);
    console.log('='.repeat(60));

    if (errors.length > 0) {
      console.log('\n🚨 실패한 항목들:');
      errors.forEach(error => console.log(`  - ${error}`));
    }

    console.log('\n✨ 스크립트 실행 완료!\n');

  } catch (error) {
    console.error('❌ 마이그레이션 중 오류:', error);
    throw error;
  }
}

// 스크립트 실행
if (require.main === module) {
  closeCompletedMissions()
    .then(() => {
      console.log('🎉 프로세스 종료');
      process.exit(0);
    })
    .catch(error => {
      console.error('💥 치명적 오류:', error);
      process.exit(1);
    });
}

module.exports = { closeCompletedMissions };
