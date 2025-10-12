// Firebase Console에서 실행할 수 있는 샘플 데이터 생성 스크립트
// Firestore > 데이터 > 컬렉션 추가에서 사용

// 샘플 Document 1: 신청 대기 중
const pendingApplication = {
  appId: "eUOdv8wASX7RfSGMin7c",
  testerId: "CazdCJYsxGMxEOzXGTen3AY5Kom2",
  providerId: "provider_demo_123",

  status: "pending",

  appliedAt: new Date("2025-09-19T05:00:00.000Z"),
  joinedAt: null,
  approvedAt: null,
  completedAt: null,

  testerInfo: {
    name: "김테스터",
    email: "tester@example.com",
    experience: "중급",
    motivation: "앱 품질 향상에 기여하고 싶습니다."
  },

  deviceInfo: {
    model: "SM-S926N",
    os: "Android 15",
    osVersion: "API 35"
  },

  testingProgress: {
    bugsReported: 0,
    feedbackSubmitted: 0,
    sessionsCompleted: 0,
    totalDays: 14,
    currentDay: 0
  },

  dailyInteractions: [
    {
      date: "2025-09-19",
      testerSubmitted: false,
      providerApproved: false,
      feedback: "",
      screenshots: [],
      bugReports: []
    }
  ],

  metadata: {
    appName: "BugCash Demo App",
    missionType: "daily_testing",
    priority: "medium",
    reward: 5000
  }
};

// 샘플 Document 2: 활성 테스터
const activeApplication = {
  appId: "eUOdv8wASX7RfSGMin7c",
  testerId: "active_tester_456",
  providerId: "provider_demo_123",

  status: "active",

  appliedAt: new Date("2025-09-17T05:00:00.000Z"),
  joinedAt: new Date("2025-09-17T09:00:00.000Z"),
  approvedAt: new Date("2025-09-17T09:00:00.000Z"),
  completedAt: null,

  testerInfo: {
    name: "이활동",
    email: "active@example.com",
    experience: "고급",
    motivation: "전문적인 QA 경험을 쌓고 싶습니다."
  },

  deviceInfo: {
    model: "iPhone 15 Pro",
    os: "iOS 17",
    osVersion: "17.5.1"
  },

  testingProgress: {
    bugsReported: 3,
    feedbackSubmitted: 2,
    sessionsCompleted: 2,
    totalDays: 14,
    currentDay: 3
  },

  dailyInteractions: [
    {
      date: "2025-09-17",
      testerSubmitted: true,
      providerApproved: true,
      feedback: "앱이 부드럽게 작동합니다",
      screenshots: ["screenshot1.jpg"],
      bugReports: []
    },
    {
      date: "2025-09-18",
      testerSubmitted: true,
      providerApproved: true,
      feedback: "로그인 버그 발견",
      screenshots: ["bug_screenshot.jpg"],
      bugReports: ["critical_login_bug"]
    },
    {
      date: "2025-09-19",
      testerSubmitted: false,
      providerApproved: false,
      feedback: "",
      screenshots: [],
      bugReports: []
    }
  ],

  metadata: {
    appName: "BugCash Demo App",
    missionType: "daily_testing",
    priority: "high",
    reward: 5000
  }
};

// 샘플 Document 3: 완료된 테스터
const completedApplication = {
  appId: "eUOdv8wASX7RfSGMin7c",
  testerId: "completed_tester_789",
  providerId: "provider_demo_123",

  status: "completed",

  appliedAt: new Date("2025-09-05T05:00:00.000Z"),
  joinedAt: new Date("2025-09-05T10:00:00.000Z"),
  approvedAt: new Date("2025-09-05T10:00:00.000Z"),
  completedAt: new Date("2025-09-19T10:00:00.000Z"),

  testerInfo: {
    name: "박완료",
    email: "completed@example.com",
    experience: "고급",
    motivation: "앱 품질 향상에 기여했습니다."
  },

  deviceInfo: {
    model: "Galaxy S24 Ultra",
    os: "Android 14",
    osVersion: "API 34"
  },

  testingProgress: {
    bugsReported: 8,
    feedbackSubmitted: 14,
    sessionsCompleted: 14,
    totalDays: 14,
    currentDay: 14
  },

  dailyInteractions: [
    // 14일간의 완료된 상호작용
    {
      date: "2025-09-19",
      testerSubmitted: true,
      providerApproved: true,
      feedback: "14일 테스트 완료, 전반적으로 만족스러운 앱입니다.",
      screenshots: ["final_screenshot.jpg"],
      bugReports: []
    }
  ],

  metadata: {
    appName: "BugCash Demo App",
    missionType: "daily_testing",
    priority: "high",
    reward: 70000,
    finalRating: 4.8
  }
};

console.log("=== Firebase Console에서 app_testers 컬렉션에 추가할 문서들 ===");
console.log("Document 1 (pending):", pendingApplication);
console.log("Document 2 (active):", activeApplication);
console.log("Document 3 (completed):", completedApplication);