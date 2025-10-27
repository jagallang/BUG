/**
 * v2.173.0: 프로젝트 상태 동기화 스크립트
 *
 * 목적:
 * - mission_workflows에서 'project_completed' 상태인 프로젝트 찾기
 * - 해당 projects 문서의 status를 'closed'로 업데이트
 * - v2.170.0 이전에 완료된 프로젝트들의 상태 불일치 해결
 *
 * 사용법:
 * node sync_project_status.js
 */

const admin = require('firebase-admin');

// Firebase Admin 초기화 (Application Default Credentials 사용)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'bugcash'
  });
}

const db = admin.firestore();

async function syncProjectStatus() {
  console.log('🔄 프로젝트 상태 동기화 시작...\n');

  try {
    // 1. mission_workflows에서 'project_completed' 상태인 문서 찾기
    const completedWorkflowsSnapshot = await db.collection('mission_workflows')
      .where('status', '==', 'project_completed')
      .get();

    console.log(`✅ 완료된 워크플로우 ${completedWorkflowsSnapshot.size}개 발견\n`);

    if (completedWorkflowsSnapshot.empty) {
      console.log('ℹ️  업데이트할 프로젝트가 없습니다.');
      return;
    }

    // 2. 각 워크플로우에서 appId 추출 및 projects 업데이트
    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    const appIds = new Set();
    completedWorkflowsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.appId) {
        appIds.add(data.appId);
      }
    });

    console.log(`📋 고유한 프로젝트 ID ${appIds.size}개 발견\n`);

    for (const appId of appIds) {
      try {
        // projects 문서 가져오기
        const projectDoc = await db.collection('projects').doc(appId).get();

        if (!projectDoc.exists) {
          console.log(`⚠️  [${appId}] 프로젝트 문서가 존재하지 않습니다`);
          errorCount++;
          continue;
        }

        const projectData = projectDoc.data();
        const currentStatus = projectData.status;

        if (currentStatus === 'closed') {
          console.log(`✓ [${appId}] "${projectData.appName}" - 이미 'closed' 상태 (스킵)`);
          skippedCount++;
          continue;
        }

        // status를 'closed'로 업데이트
        await db.collection('projects').doc(appId).update({
          status: 'closed',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✅ [${appId}] "${projectData.appName}" - '${currentStatus}' → 'closed' 업데이트 완료`);
        updatedCount++;

      } catch (error) {
        console.error(`❌ [${appId}] 업데이트 실패:`, error.message);
        errorCount++;
      }
    }

    // 3. 결과 요약
    console.log('\n' + '='.repeat(60));
    console.log('📊 동기화 결과 요약:');
    console.log('='.repeat(60));
    console.log(`✅ 업데이트 완료: ${updatedCount}개`);
    console.log(`✓ 이미 완료됨 (스킵): ${skippedCount}개`);
    console.log(`❌ 에러 발생: ${errorCount}개`);
    console.log(`📋 전체 처리: ${appIds.size}개`);
    console.log('='.repeat(60) + '\n');

  } catch (error) {
    console.error('❌ 동기화 중 오류 발생:', error);
    throw error;
  }
}

syncProjectStatus()
  .then(() => {
    console.log('✅ 프로젝트 상태 동기화 완료');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ 실행 실패:', err);
    process.exit(1);
  });
