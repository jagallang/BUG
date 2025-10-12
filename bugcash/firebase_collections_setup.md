# 🔥 Firebase Collections Setup Guide

## 📋 app_testers 컬렉션 구조

Firebase Console에서 다음 컬렉션을 생성하세요:

### Collection: `app_testers`

#### 📄 Document 1: 샘플 테스터 신청 (Pending)
```javascript
{
  // 기본 정보
  "appId": "eUOdv8wASX7RfSGMin7c",
  "testerId": "CazdCJYsxGMxEOzXGTen3AY5Kom2",
  "providerId": "provider_demo_123",

  // 신청 상태
  "status": "pending", // pending, approved, rejected, active, completed

  // 타임스탬프
  "appliedAt": "2025-09-19T05:00:00.000Z",
  "joinedAt": null,
  "approvedAt": null,
  "completedAt": null,

  // 테스터 정보
  "testerInfo": {
    "name": "김테스터",
    "email": "tester@example.com",
    "experience": "중급",
    "motivation": "앱 품질 향상에 기여하고 싶습니다."
  },

  // 디바이스 정보
  "deviceInfo": {
    "model": "SM-S926N",
    "os": "Android 15",
    "osVersion": "API 35"
  },

  // 테스팅 진행 상황
  "testingProgress": {
    "bugsReported": 0,
    "feedbackSubmitted": 0,
    "sessionsCompleted": 0,
    "totalDays": 14,
    "currentDay": 0
  },

  // 일일 상호작용 로그
  "dailyInteractions": [
    {
      "date": "2025-09-19",
      "testerSubmitted": false,
      "providerApproved": false,
      "feedback": "",
      "screenshots": [],
      "bugReports": []
    }
  ],

  // 메타데이터
  "metadata": {
    "appName": "BugCash Demo App",
    "missionType": "daily_testing",
    "priority": "medium",
    "reward": 5000
  }
}
```

#### 📄 Document 2: 활성 테스터 (Active)
```javascript
{
  "appId": "eUOdv8wASX7RfSGMin7c",
  "testerId": "active_tester_456",
  "providerId": "provider_demo_123",

  "status": "active",

  "appliedAt": "2025-09-17T05:00:00.000Z",
  "joinedAt": "2025-09-17T09:00:00.000Z",
  "approvedAt": "2025-09-17T09:00:00.000Z",
  "completedAt": null,

  "testerInfo": {
    "name": "이활동",
    "email": "active@example.com",
    "experience": "고급",
    "motivation": "전문적인 QA 경험을 쌓고 싶습니다."
  },

  "deviceInfo": {
    "model": "iPhone 15 Pro",
    "os": "iOS 17",
    "osVersion": "17.5.1"
  },

  "testingProgress": {
    "bugsReported": 3,
    "feedbackSubmitted": 2,
    "sessionsCompleted": 2,
    "totalDays": 14,
    "currentDay": 3
  },

  "dailyInteractions": [
    {
      "date": "2025-09-17",
      "testerSubmitted": true,
      "providerApproved": true,
      "feedback": "앱이 부드럽게 작동합니다",
      "screenshots": ["screenshot1.jpg"],
      "bugReports": []
    },
    {
      "date": "2025-09-18",
      "testerSubmitted": true,
      "providerApproved": true,
      "feedback": "로그인 버그 발견",
      "screenshots": ["bug_screenshot.jpg"],
      "bugReports": ["critical_login_bug"]
    },
    {
      "date": "2025-09-19",
      "testerSubmitted": false,
      "providerApproved": false,
      "feedback": "",
      "screenshots": [],
      "bugReports": []
    }
  ],

  "metadata": {
    "appName": "BugCash Demo App",
    "missionType": "daily_testing",
    "priority": "high",
    "reward": 5000
  }
}
```

#### 📄 Document 3: 완료된 테스터 (Completed)
```javascript
{
  "appId": "eUOdv8wASX7RfSGMin7c",
  "testerId": "completed_tester_789",
  "providerId": "provider_demo_123",

  "status": "completed",

  "appliedAt": "2025-09-05T05:00:00.000Z",
  "joinedAt": "2025-09-05T10:00:00.000Z",
  "approvedAt": "2025-09-05T10:00:00.000Z",
  "completedAt": "2025-09-19T10:00:00.000Z",

  "testerInfo": {
    "name": "박완료",
    "email": "completed@example.com",
    "experience": "고급",
    "motivation": "앱 품질 향상에 기여했습니다."
  },

  "deviceInfo": {
    "model": "Galaxy S24 Ultra",
    "os": "Android 14",
    "osVersion": "API 34"
  },

  "testingProgress": {
    "bugsReported": 8,
    "feedbackSubmitted": 14,
    "sessionsCompleted": 14,
    "totalDays": 14,
    "currentDay": 14
  },

  "dailyInteractions": [
    // ... 14일간의 상호작용 로그
  ],

  "metadata": {
    "appName": "BugCash Demo App",
    "missionType": "daily_testing",
    "priority": "high",
    "reward": 70000,
    "finalRating": 4.8
  }
}
```

## 🔍 Firestore 인덱스 추가

Firebase Console > Firestore > Indexes에서 다음 인덱스를 생성하세요:

1. **컬렉션 그룹**: `app_testers`
   - **필드**: `appId` (Ascending), `status` (Ascending)
   - **용도**: 앱별 상태 필터링

2. **컬렉션 그룹**: `app_testers`
   - **필드**: `testerId` (Ascending), `appliedAt` (Descending)
   - **용도**: 테스터별 신청 이력

3. **컬렉션 그룹**: `app_testers`
   - **필드**: `providerId` (Ascending), `status` (Ascending), `appliedAt` (Descending)
   - **용도**: 공급자별 신청 관리

## 📝 Firebase Console에서 수행할 작업

1. **Firestore Database > 데이터** 로 이동
2. **컬렉션 시작** 클릭
3. 컬렉션 ID: `app_testers` 입력
4. 위의 3개 샘플 문서를 각각 추가
5. **인덱스** 탭에서 필요한 인덱스 생성

이제 테스터가 미션을 신청하면 이 컬렉션에 저장되고, 공급자가 승인/거부할 수 있으며, 일일 상호작용이 추적됩니다.