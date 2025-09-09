const express = require('express');
const admin = require('firebase-admin');
const { body, validationResult } = require('express-validator');

const router = express.Router();
const db = admin.firestore();

// 앱 등록
router.post('/', [
  body('providerId').notEmpty().withMessage('Provider ID is required'),
  body('appName').isLength({ min: 1, max: 100 }).withMessage('App name must be 1-100 characters'),
  body('description').isLength({ min: 10, max: 1000 }).withMessage('Description must be 10-1000 characters'),
  body('category').isIn(['Productivity', 'Social', 'Entertainment', 'Education', 'Health & Fitness', 'Finance', 'Shopping', 'Travel', 'Food & Drink', 'Games', 'Other']).withMessage('Invalid category'),
  body('installType').isIn(['play_store', 'apk_upload', 'testflight', 'enterprise']).withMessage('Invalid install type'),
  body('appUrl').optional().isURL().withMessage('Invalid URL format')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      providerId,
      appName,
      description,
      category,
      installType,
      appUrl,
      appVersion,
      minSdkVersion,
      targetSdkVersion,
      permissions,
      tags
    } = req.body;

    // 중복 앱 이름 확인 (같은 공급자 내에서)
    const existingApp = await db.collection('provider_apps')
      .where('providerId', '==', providerId)
      .where('appName', '==', appName)
      .where('status', '==', 'active')
      .get();

    if (!existingApp.empty) {
      return res.status(409).json({ error: 'App with this name already exists' });
    }

    // 새 앱 생성
    const appData = {
      providerId,
      appName,
      description,
      category,
      installType,
      appUrl: appUrl || '',
      appVersion: appVersion || '1.0.0',
      minSdkVersion: minSdkVersion || 21,
      targetSdkVersion: targetSdkVersion || 34,
      permissions: permissions || [],
      tags: tags || [],
      status: 'active',
      totalTesters: 0,
      activeTesters: 0,
      totalBugs: 0,
      resolvedBugs: 0,
      progressPercentage: 0,
      rating: 0,
      reviewCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        source: 'provider_dashboard',
        ipAddress: req.ip,
        userAgent: req.get('User-Agent')
      }
    };

    const docRef = await db.collection('provider_apps').add(appData);

    // 성공 응답
    res.status(201).json({
      success: true,
      appId: docRef.id,
      message: 'App registered successfully'
    });

    // 비동기로 알림 발송 (공급자에게)
    await sendAppRegistrationNotification(providerId, appName, docRef.id);

  } catch (error) {
    console.error('App registration error:', error);
    res.status(500).json({ error: 'Failed to register app' });
  }
});

// 앱 목록 조회 (공급자별)
router.get('/provider/:providerId', async (req, res) => {
  try {
    const { providerId } = req.params;
    const { status = 'active', limit = 50, offset = 0 } = req.query;

    let query = db.collection('provider_apps')
      .where('providerId', '==', providerId);

    if (status !== 'all') {
      query = query.where('status', '==', status);
    }

    const snapshot = await query
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();

    const apps = [];
    snapshot.forEach(doc => {
      apps.push({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate()
      });
    });

    res.json({
      success: true,
      apps,
      total: snapshot.size,
      hasMore: snapshot.size === parseInt(limit)
    });

  } catch (error) {
    console.error('Apps fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch apps' });
  }
});

// 앱 상세 정보 조회
router.get('/:appId', async (req, res) => {
  try {
    const { appId } = req.params;

    const doc = await db.collection('provider_apps').doc(appId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'App not found' });
    }

    const appData = doc.data();
    
    // 테스터 통계 조회
    const testersSnapshot = await db.collection('app_testers')
      .where('appId', '==', appId)
      .where('status', '==', 'active')
      .get();

    // 버그 리포트 통계 조회
    const bugsSnapshot = await db.collection('bug_reports')
      .where('appId', '==', appId)
      .get();

    const resolvedBugs = bugsSnapshot.docs.filter(doc => 
      doc.data().status === 'resolved'
    ).length;

    res.json({
      success: true,
      app: {
        id: doc.id,
        ...appData,
        createdAt: appData.createdAt?.toDate(),
        updatedAt: appData.updatedAt?.toDate(),
        activeTesters: testersSnapshot.size,
        totalBugs: bugsSnapshot.size,
        resolvedBugs
      }
    });

  } catch (error) {
    console.error('App detail fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch app details' });
  }
});

// 앱 정보 업데이트
router.patch('/:appId', [
  body('appName').optional().isLength({ min: 1, max: 100 }),
  body('description').optional().isLength({ min: 10, max: 1000 }),
  body('category').optional().isIn(['Productivity', 'Social', 'Entertainment', 'Education', 'Health & Fitness', 'Finance', 'Shopping', 'Travel', 'Food & Drink', 'Games', 'Other']),
  body('appUrl').optional().isURL(),
  body('status').optional().isIn(['active', 'paused', 'completed', 'cancelled'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { appId } = req.params;
    const { providerId, ...updateData } = req.body;

    // 권한 확인
    const doc = await db.collection('provider_apps').doc(appId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'App not found' });
    }

    if (doc.data().providerId !== providerId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // 업데이트
    await doc.ref.update({
      ...updateData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true, message: 'App updated successfully' });

  } catch (error) {
    console.error('App update error:', error);
    res.status(500).json({ error: 'Failed to update app' });
  }
});

// 앱 삭제 (soft delete)
router.delete('/:appId', async (req, res) => {
  try {
    const { appId } = req.params;
    const { providerId } = req.body;

    const doc = await db.collection('provider_apps').doc(appId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'App not found' });
    }

    if (doc.data().providerId !== providerId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    await doc.ref.update({
      status: 'deleted',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true, message: 'App deleted successfully' });

  } catch (error) {
    console.error('App deletion error:', error);
    res.status(500).json({ error: 'Failed to delete app' });
  }
});

// 테스터가 앱에 참여
router.post('/:appId/join', async (req, res) => {
  try {
    const { appId } = req.params;
    const { testerId, deviceInfo } = req.body;

    if (!testerId) {
      return res.status(400).json({ error: 'Tester ID is required' });
    }

    // 앱 존재 확인
    const appDoc = await db.collection('provider_apps').doc(appId).get();
    if (!appDoc.exists) {
      return res.status(404).json({ error: 'App not found' });
    }

    // 이미 참여 중인지 확인
    const existingParticipation = await db.collection('app_testers')
      .where('appId', '==', appId)
      .where('testerId', '==', testerId)
      .where('status', '==', 'active')
      .get();

    if (!existingParticipation.empty) {
      return res.status(409).json({ error: 'Already participating in this app testing' });
    }

    // 참여 정보 저장
    const participationData = {
      appId,
      testerId,
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active',
      deviceInfo: deviceInfo || {},
      testingProgress: {
        bugsReported: 0,
        feedbackSubmitted: 0,
        sessionsCompleted: 0
      }
    };

    await db.collection('app_testers').add(participationData);

    // 앱의 테스터 수 업데이트
    await appDoc.ref.update({
      activeTesters: admin.firestore.FieldValue.increment(1),
      totalTesters: admin.firestore.FieldValue.increment(1)
    });

    res.json({ success: true, message: 'Successfully joined app testing' });

  } catch (error) {
    console.error('App join error:', error);
    res.status(500).json({ error: 'Failed to join app testing' });
  }
});

// 공급자 앱 검색 (테스터용)
router.get('/search', async (req, res) => {
  try {
    const { query = '', category, limit = 20 } = req.query;

    let dbQuery = db.collection('provider_apps')
      .where('status', '==', 'active');

    if (category && category !== 'all') {
      dbQuery = dbQuery.where('category', '==', category);
    }

    const snapshot = await dbQuery
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit))
      .get();

    let apps = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      apps.push({
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate(),
        updatedAt: data.updatedAt?.toDate()
      });
    });

    // 클라이언트 사이드 텍스트 검색
    if (query) {
      const searchTerm = query.toLowerCase();
      apps = apps.filter(app => 
        app.appName.toLowerCase().includes(searchTerm) ||
        app.description.toLowerCase().includes(searchTerm) ||
        app.category.toLowerCase().includes(searchTerm) ||
        (app.tags && app.tags.some(tag => tag.toLowerCase().includes(searchTerm)))
      );
    }

    res.json({
      success: true,
      apps,
      total: apps.length
    });

  } catch (error) {
    console.error('App search error:', error);
    res.status(500).json({ error: 'Failed to search apps' });
  }
});

// 알림 발송 함수
async function sendAppRegistrationNotification(providerId, appName, appId) {
  try {
    const notificationData = {
      recipientId: providerId,
      type: 'app_registered',
      title: '앱 등록 완료',
      message: `${appName} 앱이 성공적으로 등록되었습니다.`,
      data: {
        appId,
        appName
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    };

    await db.collection('notifications').add(notificationData);
  } catch (error) {
    console.error('Failed to send notification:', error);
  }
}

module.exports = router;