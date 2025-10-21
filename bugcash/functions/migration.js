const {onDocumentWritten} = require('firebase-functions/v2/firestore');
const {onRequest} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Firebase Admin 초기화
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * 점진적 사용자 마이그레이션 Cloud Function
 * 새 사용자 생성/업데이트 시 자동으로 새 스키마 적용
 */
exports.migrateUserOnWrite = onDocumentWritten('users/{userId}', async (event) => {
    const userId = event.params.userId;
    const change = event.data;

    // 삭제된 문서는 처리하지 않음
    if (!change.after.exists) {
      return null;
    }

    const beforeData = change.before.exists ? change.before.data() : null;
    const afterData = change.after.data();

    // 이미 새 형식이면 건너뛰기
    if (afterData.roles && afterData.primaryRole) {
      console.log(`User ${userId} already migrated`);
      return null;
    }

    try {
      console.log(`Migrating user ${userId}...`);

      const oldUserType = afterData.userType || 'tester';
      const updateData = {
        roles: [oldUserType],
        primaryRole: oldUserType,
        isAdmin: oldUserType === 'admin',
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
        migratedBy: 'cloud-function'
      };

      // 역할별 프로필 추가
      if (oldUserType === 'tester') {
        updateData.testerProfile = {
          preferredCategories: afterData.preferredCategories || [],
          devices: afterData.devices || [],
          experience: afterData.experience || null,
          rating: afterData.rating || 0.0,
          completedTests: afterData.completedMissions || 0,
          testingPreferences: afterData.testingPreferences || {},
          verificationStatus: afterData.verificationStatus || 'pending'
        };
      } else if (oldUserType === 'provider') {
        updateData.providerProfile = {
          companyName: afterData.companyName || null,
          website: afterData.website || null,
          businessType: afterData.businessType || null,
          appCategories: afterData.appCategories || [],
          contactInfo: afterData.contactInfo || null,
          rating: afterData.rating || 0.0,
          publishedApps: afterData.publishedApps || 0,
          businessInfo: afterData.businessInfo || {},
          verificationStatus: afterData.verificationStatus || 'pending'
        };
      }

      // 원자성을 위해 트랜잭션 사용
      await db.runTransaction(async (transaction) => {
        const userRef = db.collection('users').doc(userId);
        transaction.update(userRef, updateData);
      });

      console.log(`User ${userId} migrated successfully`);
      return null;

    } catch (error) {
      console.error(`Migration failed for user ${userId}:`, error);
      throw error;
    }
  });

/**
 * 대량 마이그레이션 HTTP 함수
 * 관리자가 수동으로 호출하여 기존 사용자들을 일괄 마이그레이션
 */
exports.bulkMigrateUsers = onRequest({
    region: 'asia-northeast1',
    timeoutSeconds: 540,
    memory: '2GiB',
    cors: true
  }, async (req, res) => {
    try {
      console.log('Starting bulk migration...');

      // CORS 헤더 설정
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET, POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type');

      if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
      }

      const usersSnapshot = await db.collection('users').get();
      console.log(`Found ${usersSnapshot.size} users`);

      let migratedCount = 0;
      let skippedCount = 0;
      let errorCount = 0;
      const errors = [];

      // 배치 크기 제한 (Firestore 제한: 500)
      const batchSize = 500;
      const batches = [];
      let currentBatch = db.batch();
      let operationCount = 0;

      for (const doc of usersSnapshot.docs) {
        try {
          const data = doc.data();
          const userId = doc.id;

          // 이미 마이그레이션된 사용자는 건너뛰기
          if (data.roles && data.primaryRole) {
            skippedCount++;
            continue;
          }

          const oldUserType = data.userType || 'tester';
          const updateData = {
            roles: [oldUserType],
            primaryRole: oldUserType,
            isAdmin: oldUserType === 'admin',
            migratedAt: admin.firestore.FieldValue.serverTimestamp(),
            migratedBy: 'bulk-migration'
          };

          // 역할별 프로필 추가
          if (oldUserType === 'tester') {
            updateData.testerProfile = {
              preferredCategories: data.preferredCategories || [],
              devices: data.devices || [],
              experience: data.experience || null,
              rating: data.rating || 0.0,
              completedTests: data.completedMissions || 0,
              testingPreferences: data.testingPreferences || {},
              verificationStatus: data.verificationStatus || 'pending'
            };
          } else if (oldUserType === 'provider') {
            updateData.providerProfile = {
              companyName: data.companyName || null,
              website: data.website || null,
              businessType: data.businessType || null,
              appCategories: data.appCategories || [],
              contactInfo: data.contactInfo || null,
              rating: data.rating || 0.0,
              publishedApps: data.publishedApps || 0,
              businessInfo: data.businessInfo || {},
              verificationStatus: data.verificationStatus || 'pending'
            };
          }

          currentBatch.update(doc.ref, updateData);
          operationCount++;
          migratedCount++;

          // 배치 크기 제한 확인
          if (operationCount >= batchSize) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            operationCount = 0;
          }

        } catch (error) {
          console.error(`Error processing user ${doc.id}:`, error);
          errors.push(`${doc.id}: ${error.message}`);
          errorCount++;
        }
      }

      // 마지막 배치 추가
      if (operationCount > 0) {
        batches.push(currentBatch);
      }

      // 모든 배치 커밋
      console.log(`Committing ${batches.length} batches...`);
      for (let i = 0; i < batches.length; i++) {
        await batches[i].commit();
        console.log(`Batch ${i + 1}/${batches.length} committed`);
      }

      // 결과 반환
      const result = {
        status: 'success',
        totalUsers: usersSnapshot.size,
        migrated: migratedCount,
        skipped: skippedCount,
        errors: errorCount,
        errorDetails: errors.slice(0, 10), // 최대 10개 오류만 반환
        timestamp: new Date().toISOString()
      };

      console.log('Bulk migration completed:', result);
      res.status(200).json(result);

    } catch (error) {
      console.error('Bulk migration failed:', error);
      res.status(500).json({
        status: 'error',
        message: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

/**
 * 마이그레이션 상태 확인 함수
 */
exports.checkMigrationStatus = onRequest({
    region: 'asia-northeast1'
  }, async (req, res) => {
    try {
      // CORS 헤더 설정
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

      // OPTIONS 요청 처리
      if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
      }

      const usersSnapshot = await db.collection('users').get();

      let newFormat = 0;
      let oldFormat = 0;
      const roleStats = {};

      usersSnapshot.forEach(doc => {
        const data = doc.data();

        if (data.roles && data.primaryRole) {
          newFormat++;
          const roles = data.roles || [];
          roles.forEach(role => {
            roleStats[role] = (roleStats[role] || 0) + 1;
          });
        } else {
          oldFormat++;
        }
      });

      const result = {
        totalUsers: usersSnapshot.size,
        migrated: newFormat,
        pending: oldFormat,
        completionRate: ((newFormat / usersSnapshot.size) * 100).toFixed(1),
        roleDistribution: roleStats,
        timestamp: new Date().toISOString()
      };

      res.status(200).json(result);

    } catch (error) {
      console.error('Status check failed:', error);
      res.status(500).json({
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

/**
 * 사용자 검증 함수
 */
exports.validateMigratedUsers = onRequest({
    region: 'asia-northeast1'
  }, async (req, res) => {
    try {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

      if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
      }

      const usersSnapshot = await db.collection('users').get();
      const validationErrors = [];

      usersSnapshot.forEach(doc => {
        const data = doc.data();
        const userId = doc.id;

        // 새 형식 검증
        if (data.roles && data.primaryRole) {
          // 필수 필드 확인
          if (!Array.isArray(data.roles) || data.roles.length === 0) {
            validationErrors.push(`${userId}: Invalid roles array`);
          }

          if (!data.roles.includes(data.primaryRole)) {
            validationErrors.push(`${userId}: primaryRole not in roles array`);
          }

          // 역할별 프로필 확인
          if (data.primaryRole === 'tester' && !data.testerProfile) {
            validationErrors.push(`${userId}: Missing testerProfile`);
          }

          if (data.primaryRole === 'provider' && !data.providerProfile) {
            validationErrors.push(`${userId}: Missing providerProfile`);
          }
        }
      });

      const result = {
        totalUsers: usersSnapshot.size,
        validationErrors: validationErrors.length,
        errors: validationErrors.slice(0, 20), // 최대 20개 오류
        isValid: validationErrors.length === 0,
        timestamp: new Date().toISOString()
      };

      res.status(200).json(result);

    } catch (error) {
      console.error('Validation failed:', error);
      res.status(500).json({
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });