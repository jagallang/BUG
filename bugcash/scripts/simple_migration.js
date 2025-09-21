// Simple Database Migration Script using Firebase Admin SDK
// This script migrates the legacy structure to the optimized structure

const admin = require('firebase-admin');

// Initialize Firebase Admin (will use default credentials or project config)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'bugcash'
  });
}

const db = admin.firestore();

async function analyzeDatabaseState() {
  console.log('🔍 현재 데이터베이스 상태 분석 중...');

  const collections = [
    'users', 'apps', 'missions', 'mission_applications',
    'tester_applications', 'mission_workflows', 'notifications'
  ];

  const analysis = {};
  let totalDocs = 0;

  for (const collectionName of collections) {
    try {
      const snapshot = await db.collection(collectionName).limit(1000).get();
      const count = snapshot.docs.length;
      totalDocs += count;
      analysis[collectionName] = {
        count,
        exists: count > 0,
        sampleFields: count > 0 ? Object.keys(snapshot.docs[0].data()) : []
      };

      console.log(`📁 ${collectionName}: ${count}개 문서`);
    } catch (error) {
      console.log(`⚠️ ${collectionName}: 접근 불가 (${error.message})`);
      analysis[collectionName] = { error: error.message, exists: false };
    }
  }

  console.log(`\n총 문서 수: ${totalDocs}개`);
  return { analysis, totalDocs };
}

async function createOptimizedStructure() {
  console.log('\n🏗️ 새로운 컬렉션 구조 생성 중...');

  const newCollections = [
    'users', 'projects', 'applications', 'enrollments',
    'missions', 'points_transactions', 'reports', 'notifications'
  ];

  const batch = db.batch();

  for (const collection of newCollections) {
    const docRef = db.collection(collection).doc('_init');
    batch.set(docRef, {
      _initialized: true,
      _migration_timestamp: admin.firestore.FieldValue.serverTimestamp(),
      _description: `${collection} 컬렉션 - 최적화된 구조`
    });
  }

  await batch.commit();
  console.log('✅ 새로운 컬렉션 구조 생성 완료');
}

async function migrateUsers() {
  console.log('\n👤 사용자 데이터 마이그레이션 중...');

  const usersSnapshot = await db.collection('users').get();
  const batch = db.batch();
  let migrated = 0;

  for (const doc of usersSnapshot.docs) {
    const data = doc.data();

    // 기존 사용자 데이터를 새로운 구조로 마이그레이션
    const migratedData = {
      uid: doc.id,
      email: data.email || '',
      displayName: data.displayName || data.name || 'Unknown User',
      role: data.userType || data.role || 'tester', // 기본값은 tester
      phoneNumber: data.phoneNumber || '',
      profileImageUrl: data.profileImageUrl || '',
      points: data.points || 0,
      isActive: data.isActive !== false,
      createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      // 통계 정보
      stats: {
        completedMissions: data.completedMissions || 0,
        totalEarnings: data.totalEarnings || 0,
        bugReportsSubmitted: data.bugReportsSubmitted || 0
      }
    };

    // 새로운 users 컬렉션에 저장 (덮어쓰기)
    const newUserRef = db.collection('users').doc(doc.id);
    batch.set(newUserRef, migratedData, { merge: true });
    migrated++;
  }

  if (migrated > 0) {
    await batch.commit();
  }

  console.log(`✅ 사용자 ${migrated}명 마이그레이션 완료`);
  return migrated;
}

async function migrateProjects() {
  console.log('\n📱 프로젝트 데이터 마이그레이션 중...');

  // apps 컬렉션에서 프로젝트 생성
  const appsSnapshot = await db.collection('apps').get();
  const missionsSnapshot = await db.collection('missions').get();

  const batch = db.batch();
  let migrated = 0;

  // Apps를 Projects로 마이그레이션
  for (const doc of appsSnapshot.docs) {
    const data = doc.data();

    const projectData = {
      type: 'app',
      appId: doc.id,
      appName: data.appName || data.title || 'Unknown App',
      description: data.description || '',
      providerId: data.providerId || 'unknown_provider',
      category: data.category || 'general',
      platform: data.platform || 'android',
      minOSVersion: data.minOSVersion || '',
      appStoreUrl: data.appStoreUrl || '',
      testingGuidelines: data.testingGuidelines || '',
      status: data.status || 'draft',
      maxTesters: data.maxTesters || 10,
      testPeriodDays: 14,
      rewardPoints: data.rewardPoints || 5000,
      createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const projectRef = db.collection('projects').doc(doc.id);
    batch.set(projectRef, projectData);
    migrated++;
  }

  // Missions도 Projects로 마이그레이션 (타입 구분)
  for (const doc of missionsSnapshot.docs) {
    const data = doc.data();

    const projectData = {
      type: 'mission',
      appId: data.appId || doc.id,
      appName: data.title || data.missionTitle || 'Unknown Mission',
      description: data.description || '',
      providerId: data.providerId || 'unknown_provider',
      category: data.category || 'general',
      platform: data.platform || 'android',
      status: data.status || 'draft',
      maxTesters: data.maxTesters || 10,
      testPeriodDays: 14,
      rewardPoints: data.rewardPoints || 5000,
      createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const projectRef = db.collection('projects').doc(doc.id);
    batch.set(projectRef, projectData);
    migrated++;
  }

  if (migrated > 0) {
    await batch.commit();
  }

  console.log(`✅ 프로젝트 ${migrated}개 마이그레이션 완료`);
  return migrated;
}

async function migrateApplications() {
  console.log('\n📋 신청 데이터 마이그레이션 중...');

  // 여러 컬렉션의 신청 데이터를 통합
  const collections = [
    { name: 'mission_applications', type: 'mission' },
    { name: 'tester_applications', type: 'app' },
    { name: 'mission_workflows', type: 'workflow' }
  ];

  const batch = db.batch();
  let migrated = 0;

  for (const collection of collections) {
    try {
      const snapshot = await db.collection(collection.name).get();

      for (const doc of snapshot.docs) {
        const data = doc.data();

        const applicationData = {
          type: collection.type,
          projectId: data.missionId || data.appId || data.projectId,
          testerId: data.testerId || 'unknown_tester',
          providerId: data.providerId || 'unknown_provider',
          status: data.status || 'pending',
          appliedAt: data.createdAt || data.appliedAt || admin.firestore.FieldValue.serverTimestamp(),
          processedAt: data.processedAt || null,
          processedBy: data.processedBy || '',
          feedback: data.feedback || '',
          // 원본 데이터 보존
          originalCollection: collection.name,
          originalData: data,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        const applicationRef = db.collection('applications').doc();
        batch.set(applicationRef, applicationData);
        migrated++;
      }
    } catch (error) {
      console.log(`⚠️ ${collection.name} 마이그레이션 실패: ${error.message}`);
    }
  }

  if (migrated > 0) {
    await batch.commit();
  }

  console.log(`✅ 신청 ${migrated}개 마이그레이션 완료`);
  return migrated;
}

async function createBackup() {
  console.log('\n💾 백업 생성 중...');

  const timestamp = Date.now();
  const backupRef = db.collection(`backup_${timestamp}`).doc('_metadata');

  await backupRef.set({
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    migration_version: '1.0',
    description: 'BugCash 최적화 구조 마이그레이션 전 백업',
    collections_backed_up: [
      'users', 'apps', 'missions', 'mission_applications',
      'tester_applications', 'mission_workflows'
    ]
  });

  console.log(`✅ 백업 생성 완료: backup_${timestamp}`);
  return `backup_${timestamp}`;
}

async function validateMigration() {
  console.log('\n✅ 마이그레이션 검증 중...');

  const newCollections = ['users', 'projects', 'applications'];
  const results = {};

  for (const collection of newCollections) {
    try {
      const snapshot = await db.collection(collection).get();
      const count = snapshot.docs.length;
      results[collection] = { count, valid: count > 0 };

      if (count > 0) {
        console.log(`✅ ${collection}: ${count}개 문서`);
      } else {
        console.log(`⚠️ ${collection}: 비어있음`);
      }
    } catch (error) {
      console.log(`❌ ${collection}: 검증 실패 (${error.message})`);
      results[collection] = { error: error.message, valid: false };
    }
  }

  return results;
}

async function main() {
  console.log('🚀 BugCash 데이터베이스 마이그레이션 시작');
  console.log('=' * 50);

  try {
    // 1. 현재 상태 분석
    const { analysis, totalDocs } = await analyzeDatabaseState();

    if (totalDocs === 0) {
      console.log('\n💡 빈 데이터베이스입니다. 초기 구조만 생성합니다.');
      await createOptimizedStructure();
      console.log('\n✅ 초기 구조 생성 완료!');
      return;
    }

    // 2. 백업 생성
    const backupName = await createBackup();

    // 3. 새로운 구조 생성
    await createOptimizedStructure();

    // 4. 데이터 마이그레이션
    const usersMigrated = await migrateUsers();
    const projectsMigrated = await migrateProjects();
    const applicationsMigrated = await migrateApplications();

    // 5. 검증
    const validationResults = await validateMigration();

    // 6. 결과 출력
    console.log('\n🎉 마이그레이션 완료!');
    console.log('=' * 50);
    console.log(`📊 마이그레이션 통계:`);
    console.log(`   사용자: ${usersMigrated}명`);
    console.log(`   프로젝트: ${projectsMigrated}개`);
    console.log(`   신청: ${applicationsMigrated}개`);
    console.log(`   백업: ${backupName}`);

    console.log('\n📋 다음 단계:');
    console.log('1. Firebase Console에서 새로운 컬렉션 확인');
    console.log('2. 앱 코드에서 새로운 구조 사용 시작');
    console.log('3. 기능 테스트 수행');
    console.log('4. 레거시 컬렉션 정리 (충분한 테스트 후)');

  } catch (error) {
    console.error('\n❌ 마이그레이션 실패:', error);
    console.log('\n🔄 복구 방법:');
    console.log('1. Firebase Console에서 백업 확인');
    console.log('2. 새로 생성된 컬렉션 정리');
    console.log('3. 기존 구조로 롤백');
  }
}

// 스크립트 실행
if (require.main === module) {
  main().then(() => {
    console.log('\n✨ 스크립트 실행 완료');
    process.exit(0);
  }).catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = {
  analyzeDatabaseState,
  createOptimizedStructure,
  migrateUsers,
  migrateProjects,
  migrateApplications,
  validateMigration
};