const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = {
  // 환경변수에서 서비스 계정 키를 가져오거나, 서비스 계정 JSON 파일 경로 설정
  // 실제 환경에서는 환경변수나 안전한 방법으로 관리해야 함
};

// Firebase Admin 초기화 (이미 초기화되어 있지 않은 경우에만)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'bugcash'
  });
}

const db = admin.firestore();

// tester_applications 컬렉션 생성 및 샘플 데이터 추가
async function createTesterApplicationsCollection() {
  console.log('🔥 tester_applications 컬렉션 생성 시작...');

  try {
    // 샘플 Document 1: 대기 중인 신청
    const pendingApplication = {
      appId: "eUOdv8wASX7RfSGMin7c",
      testerId: "CazdCJYsxGMxEOzXGTen3AY5Kom2",
      providerId: "provider_demo_123",

      status: "pending",
      statusUpdatedAt: admin.firestore.Timestamp.now(),
      statusUpdatedBy: "",

      appliedAt: admin.firestore.Timestamp.now(),
      approvedAt: null,
      startedAt: null,
      completedAt: null,

      testerInfo: {
        name: "김테스터",
        email: "tester@example.com",
        experience: "중급",
        motivation: "앱 품질 향상에 기여하고 싶습니다.",
        deviceModel: "SM-S926N",
        deviceOS: "Android 15",
        deviceVersion: "API 35"
      },

      missionInfo: {
        appName: "BugCash Demo App",
        totalDays: 14,
        dailyReward: 5000,
        totalReward: 70000,
        requirements: [
          "일일 30분 이상 앱 사용",
          "피드백 작성 필수",
          "버그 발견 시 즉시 신고"
        ]
      },

      progress: {
        currentDay: 0,
        progressPercentage: 0.0,
        todayCompleted: false,
        bugsReported: 0,
        feedbackSubmitted: 0,
        totalPoints: 0
      }
    };

    // 샘플 Document 2: 승인된 신청
    const approvedApplication = {
      appId: "eUOdv8wASX7RfSGMin7c",
      testerId: "active_tester_456",
      providerId: "provider_demo_123",

      status: "approved",
      statusUpdatedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-17T09:00:00.000Z")),
      statusUpdatedBy: "provider_demo_123",

      appliedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-17T05:00:00.000Z")),
      approvedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-17T09:00:00.000Z")),
      startedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-17T09:00:00.000Z")),
      completedAt: null,

      testerInfo: {
        name: "이활동",
        email: "active@example.com",
        experience: "고급",
        motivation: "전문적인 QA 경험을 쌓고 싶습니다.",
        deviceModel: "iPhone 15 Pro",
        deviceOS: "iOS 17",
        deviceVersion: "17.5.1"
      },

      missionInfo: {
        appName: "BugCash Demo App",
        totalDays: 14,
        dailyReward: 5000,
        totalReward: 70000,
        requirements: [
          "일일 30분 이상 앱 사용",
          "피드백 작성 필수",
          "버그 발견 시 즉시 신고"
        ]
      },

      progress: {
        currentDay: 3,
        progressPercentage: 21.4,
        todayCompleted: false,
        bugsReported: 2,
        feedbackSubmitted: 3,
        totalPoints: 15000
      }
    };

    // 샘플 Document 3: 완료된 신청
    const completedApplication = {
      appId: "eUOdv8wASX7RfSGMin7c",
      testerId: "completed_tester_789",
      providerId: "provider_demo_123",

      status: "completed",
      statusUpdatedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-19T10:00:00.000Z")),
      statusUpdatedBy: "provider_demo_123",

      appliedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-05T05:00:00.000Z")),
      approvedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-05T10:00:00.000Z")),
      startedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-05T10:00:00.000Z")),
      completedAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-19T10:00:00.000Z")),

      testerInfo: {
        name: "박완료",
        email: "completed@example.com",
        experience: "고급",
        motivation: "앱 품질 향상에 성공적으로 기여했습니다.",
        deviceModel: "Galaxy S24 Ultra",
        deviceOS: "Android 14",
        deviceVersion: "API 34"
      },

      missionInfo: {
        appName: "BugCash Demo App",
        totalDays: 14,
        dailyReward: 5000,
        totalReward: 70000,
        requirements: [
          "일일 30분 이상 앱 사용",
          "피드백 작성 필수",
          "버그 발견 시 즉시 신고"
        ]
      },

      progress: {
        currentDay: 14,
        progressPercentage: 100.0,
        todayCompleted: true,
        bugsReported: 8,
        feedbackSubmitted: 14,
        totalPoints: 70000,
        latestFeedback: "14일 테스트 완료, 전반적으로 만족스러운 앱입니다.",
        averageRating: 4.8
      }
    };

    // 컬렉션에 문서 추가
    console.log('📄 Document 1 (pending) 추가 중...');
    await db.collection('tester_applications').add(pendingApplication);
    console.log('✅ Document 1 추가 완료');

    console.log('📄 Document 2 (approved) 추가 중...');
    await db.collection('tester_applications').add(approvedApplication);
    console.log('✅ Document 2 추가 완료');

    console.log('📄 Document 3 (completed) 추가 중...');
    await db.collection('tester_applications').add(completedApplication);
    console.log('✅ Document 3 추가 완료');

    console.log('🎉 tester_applications 컬렉션 생성 완료!');

  } catch (error) {
    console.error('❌ 컬렉션 생성 중 오류 발생:', error);
  }
}

// daily_interactions 컬렉션 생성 및 샘플 데이터 추가
async function createDailyInteractionsCollection() {
  console.log('📅 daily_interactions 컬렉션 생성 시작...');

  try {
    const today = new Date().toISOString().substring(0, 10);
    const yesterday = new Date(Date.now() - 86400000).toISOString().substring(0, 10);

    // 샘플 일일 상호작용 1: 오늘 (대기중)
    const todayInteraction = {
      applicationId: "application_001",
      date: today,
      dayNumber: 3,

      tester: {
        submitted: false,
        submittedAt: null,
        feedback: "",
        screenshots: [],
        bugReports: [],
        sessionDuration: 0,
        appRating: null
      },

      provider: {
        reviewed: false,
        reviewedAt: null,
        approved: false,
        pointsAwarded: 0,
        providerComment: "",
        needsImprovement: false
      },

      status: "pending",
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    };

    // 샘플 일일 상호작용 2: 어제 (완료됨)
    const yesterdayInteraction = {
      applicationId: "application_001",
      date: yesterday,
      dayNumber: 2,

      tester: {
        submitted: true,
        submittedAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000 + 3600000)),
        feedback: "앱이 전반적으로 잘 작동합니다. 로그인 속도가 빨라졌네요.",
        screenshots: ["screenshot_001.jpg"],
        bugReports: [],
        sessionDuration: 35,
        appRating: 4
      },

      provider: {
        reviewed: true,
        reviewedAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000 + 7200000)),
        approved: true,
        pointsAwarded: 5000,
        providerComment: "좋은 피드백 감사합니다.",
        needsImprovement: false
      },

      status: "approved",
      createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000)),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000 + 7200000))
    };

    // 컬렉션에 문서 추가
    console.log('📄 오늘 상호작용 추가 중...');
    await db.collection('daily_interactions').doc(`application_001_${today}`).set(todayInteraction);
    console.log('✅ 오늘 상호작용 추가 완료');

    console.log('📄 어제 상호작용 추가 중...');
    await db.collection('daily_interactions').doc(`application_001_${yesterday}`).set(yesterdayInteraction);
    console.log('✅ 어제 상호작용 추가 완료');

    console.log('🎉 daily_interactions 컬렉션 생성 완료!');

  } catch (error) {
    console.error('❌ daily_interactions 컬렉션 생성 중 오류 발생:', error);
  }
}

// apps 컬렉션 생성 및 샘플 데이터 추가
async function createAppsCollection() {
  console.log('📱 apps 컬렉션 생성 시작...');

  try {
    const appData = {
      appId: "eUOdv8wASX7RfSGMin7c",
      appName: "BugCash Demo App",
      providerId: "provider_demo_123",

      missionConfig: {
        isActive: true,
        maxTesters: 10,
        currentTesters: 3,
        testingPeriod: 14,
        dailyReward: 5000,
        requirements: [
          "일일 30분 이상 앱 사용",
          "피드백 작성 필수",
          "버그 발견 시 즉시 신고"
        ]
      },

      stats: {
        totalApplications: 15,
        pendingApplications: 2,
        activeTesters: 3,
        completedTesters: 10,
        totalBugsFound: 25,
        averageRating: 4.2
      },

      createdAt: admin.firestore.Timestamp.fromDate(new Date("2025-09-15T00:00:00.000Z")),
      updatedAt: admin.firestore.Timestamp.now()
    };

    console.log('📄 앱 정보 추가 중...');
    await db.collection('apps').doc('eUOdv8wASX7RfSGMin7c').set(appData);
    console.log('✅ 앱 정보 추가 완료');

    console.log('🎉 apps 컬렉션 생성 완료!');

  } catch (error) {
    console.error('❌ apps 컬렉션 생성 중 오류 발생:', error);
  }
}

// 메인 실행 함수
async function main() {
  console.log('🚀 Firebase 컬렉션 생성 시작...');
  console.log('프로젝트 ID: bugcash');
  console.log('');

  try {
    await createTesterApplicationsCollection();
    console.log('');

    await createDailyInteractionsCollection();
    console.log('');

    await createAppsCollection();
    console.log('');

    console.log('🎉 모든 컬렉션 생성 완료!');
    console.log('');
    console.log('생성된 컬렉션:');
    console.log('- tester_applications (3개 문서)');
    console.log('- daily_interactions (2개 문서)');
    console.log('- apps (1개 문서)');
    console.log('');
    console.log('Firebase Console에서 확인하세요: https://console.firebase.google.com/u/0/project/bugcash/firestore');

  } catch (error) {
    console.error('❌ 전체 프로세스 중 오류 발생:', error);
  } finally {
    process.exit(0);
  }
}

// 스크립트 실행
if (require.main === module) {
  main();
}

module.exports = {
  createTesterApplicationsCollection,
  createDailyInteractionsCollection,
  createAppsCollection
};