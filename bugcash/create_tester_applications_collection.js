// Firebase Console에서 tester_applications 컬렉션 생성용 샘플 데이터
// Firestore > 데이터 > 컬렉션 추가에서 사용

// 샘플 Document 1: 대기 중인 신청
const pendingApplication = {
  // 기본 정보
  appId: "eUOdv8wASX7RfSGMin7c",
  testerId: "CazdCJYsxGMxEOzXGTen3AY5Kom2",
  providerId: "provider_demo_123",

  // 상태 관리
  status: "pending", // pending, approved, active, completed, rejected
  statusUpdatedAt: new Date("2025-09-19T10:00:00.000Z"),
  statusUpdatedBy: "",

  // 타임스탬프
  appliedAt: new Date("2025-09-19T05:00:00.000Z"),
  approvedAt: null,
  startedAt: null,
  completedAt: null,

  // 테스터 정보
  testerInfo: {
    name: "김테스터",
    email: "tester@example.com",
    experience: "중급",
    motivation: "앱 품질 향상에 기여하고 싶습니다.",
    deviceModel: "SM-S926N",
    deviceOS: "Android 15",
    deviceVersion: "API 35"
  },

  // 미션 정보
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

  // 진행 상황
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
  statusUpdatedAt: new Date("2025-09-17T09:00:00.000Z"),
  statusUpdatedBy: "provider_demo_123",

  appliedAt: new Date("2025-09-17T05:00:00.000Z"),
  approvedAt: new Date("2025-09-17T09:00:00.000Z"),
  startedAt: new Date("2025-09-17T09:00:00.000Z"),
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
  statusUpdatedAt: new Date("2025-09-19T10:00:00.000Z"),
  statusUpdatedBy: "provider_demo_123",

  appliedAt: new Date("2025-09-05T05:00:00.000Z"),
  approvedAt: new Date("2025-09-05T10:00:00.000Z"),
  startedAt: new Date("2025-09-05T10:00:00.000Z"),
  completedAt: new Date("2025-09-19T10:00:00.000Z"),

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

console.log("=== Firebase Console에서 tester_applications 컬렉션에 추가할 문서들 ===");
console.log("Document 1 (pending):", pendingApplication);
console.log("Document 2 (approved):", approvedApplication);
console.log("Document 3 (completed):", completedApplication);