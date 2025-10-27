/**
 * Orphan mission_workflows 정리 스크립트
 *
 * 문제: projects 문서가 삭제되었지만 mission_workflows는 남아있어서
 *       미션 관리 탭에서 조회 시 PROJECT_NOT_FOUND 오류 발생
 *
 * 해결: mission_workflows의 appId가 가리키는 projects 문서가 없으면 삭제
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

async function cleanupOrphanWorkflows() {
  try {
    console.log('🔄 Orphan mission_workflows 정리 시작...\n');

    const db = admin.firestore();

    // 1. 모든 mission_workflows 조회
    const workflowsRef = db.collection('mission_workflows');
    const workflowsSnapshot = await workflowsRef.get();

    console.log(`📊 총 mission_workflows: ${workflowsSnapshot.size}개\n`);

    if (workflowsSnapshot.empty) {
      console.log('✅ mission_workflows가 없습니다.');
      return;
    }

    // 2. 각 workflow의 appId를 추출하고 projects 문서 존재 여부 확인
    const orphanWorkflows = [];
    const validWorkflows = [];
    const checkedAppIds = new Map(); // appId별 존재 여부 캐시

    for (const doc of workflowsSnapshot.docs) {
      const data = doc.data();
      const appId = data.appId;
      const workflowId = doc.id;

      if (!appId) {
        console.log(`⚠️  [${workflowId}] appId가 없음 (건너뛰기)`);
        continue;
      }

      // 캐시 확인
      if (!checkedAppIds.has(appId)) {
        // projects 문서 존재 여부 확인
        const projectDoc = await db.collection('projects').doc(appId).get();
        checkedAppIds.set(appId, projectDoc.exists);
      }

      const projectExists = checkedAppIds.get(appId);

      if (!projectExists) {
        orphanWorkflows.push({
          workflowId,
          appId,
          appName: data.appName || 'Unknown',
          testerId: data.testerId,
          currentState: data.currentState,
          createdAt: data.createdAt?.toDate() || new Date(),
        });
      } else {
        validWorkflows.push(workflowId);
      }
    }

    console.log(`\n📊 검사 결과:`);
    console.log(`   ✅ 정상: ${validWorkflows.length}개`);
    console.log(`   ❌ Orphan: ${orphanWorkflows.length}개`);

    if (orphanWorkflows.length === 0) {
      console.log('\n✅ Orphan workflows가 없습니다!');
      return;
    }

    // 3. Orphan workflows 상세 출력
    console.log(`\n🚨 Orphan workflows 목록:\n`);
    orphanWorkflows.forEach((wf, index) => {
      console.log(`${index + 1}. [${wf.workflowId}]`);
      console.log(`   ├─ 앱 이름: ${wf.appName}`);
      console.log(`   ├─ appId: ${wf.appId} (projects 문서 없음)`);
      console.log(`   ├─ 테스터: ${wf.testerId}`);
      console.log(`   ├─ 상태: ${wf.currentState}`);
      console.log(`   └─ 생성일: ${wf.createdAt.toLocaleString('ko-KR')}`);
    });

    // 4. 삭제 확인
    console.log(`\n⚠️  위 ${orphanWorkflows.length}개의 orphan workflows를 삭제하시겠습니까?`);
    console.log(`   (스크립트를 종료하려면 Ctrl+C)`);
    console.log(`   (삭제하려면 10초 대기...)\n`);

    await new Promise(resolve => setTimeout(resolve, 10000));

    // 5. 삭제 실행
    console.log(`\n🗑️  삭제 시작...\n`);

    let deletedCount = 0;
    const errors = [];

    for (const wf of orphanWorkflows) {
      try {
        await db.collection('mission_workflows').doc(wf.workflowId).delete();
        console.log(`✅ [${wf.workflowId}] 삭제 완료 (${wf.appName})`);
        deletedCount++;
      } catch (error) {
        const errorMsg = `[${wf.workflowId}] 삭제 실패: ${error.message}`;
        errors.push(errorMsg);
        console.error(`❌ ${errorMsg}`);
      }
    }

    // 6. 결과 출력
    console.log('\n' + '='.repeat(60));
    console.log('📊 정리 완료!');
    console.log('='.repeat(60));
    console.log(`✅ 삭제 완료: ${deletedCount}개`);
    console.log(`❌ 실패: ${errors.length}개`);
    console.log('='.repeat(60));

    if (errors.length > 0) {
      console.log('\n🚨 실패한 항목들:');
      errors.forEach(error => console.log(`  - ${error}`));
    }

    console.log('\n✨ 스크립트 실행 완료!\n');

  } catch (error) {
    console.error('❌ 정리 중 오류:', error);
    throw error;
  }
}

// 스크립트 실행
if (require.main === module) {
  cleanupOrphanWorkflows()
    .then(() => {
      console.log('🎉 프로세스 종료');
      process.exit(0);
    })
    .catch(error => {
      console.error('💥 치명적 오류:', error);
      process.exit(1);
    });
}

module.exports = { cleanupOrphanWorkflows };
