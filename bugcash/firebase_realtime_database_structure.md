# 🔥 Firebase 실시간 데이터베이스 구조 설계

## 📋 직접 상태 관리가 가능한 컬렉션 구조

### 1. **테스터 신청 관리** (`tester_applications`)

```javascript
// Collection: tester_applications
// Document ID: auto-generated

{
  // 기본 정보
  "appId": "eUOdv8wASX7RfSGMin7c",
  "testerId": "CazdCJYsxGMxEOzXGTen3AY5Kom2",
  "providerId": "provider_demo_123",

  // 상태 관리 (Firebase Console에서 직접 수정 가능)
  "status": "pending", // pending → approved → active → completed / rejected
  "statusUpdatedAt": "2025-09-19T10:00:00.000Z",
  "statusUpdatedBy": "provider_demo_123", // 누가 상태를 변경했는지

  // 타임스탬프
  "appliedAt": "2025-09-19T05:00:00.000Z",
  "approvedAt": null, // status가 approved로 변경될 때 자동 설정
  "startedAt": null,  // status가 active로 변경될 때 자동 설정
  "completedAt": null, // status가 completed로 변경될 때 자동 설정

  // 테스터 기본 정보
  "testerInfo": {
    "name": "김테스터",
    "email": "tester@example.com",
    "experience": "중급",
    "motivation": "앱 품질 향상에 기여하고 싶습니다.",
    "deviceModel": "SM-S926N",
    "deviceOS": "Android 15",
    "deviceVersion": "API 35"
  },

  // 미션 정보
  "missionInfo": {
    "appName": "BugCash Demo App",
    "totalDays": 14,
    "dailyReward": 5000,
    "totalReward": 70000,
    "requirements": [
      "일일 30분 이상 앱 사용",
      "피드백 작성 필수",
      "버그 발견 시 즉시 신고"
    ]
  },

  // 실시간 진행 상황
  "progress": {
    "currentDay": 0,
    "progressPercentage": 0.0,
    "todayCompleted": false,
    "bugsReported": 0,
    "feedbackSubmitted": 0,
    "totalPoints": 0
  }
}
```

### 2. **일일 상호작용 관리** (`daily_interactions`)

```javascript
// Collection: daily_interactions
// Document ID: {applicationId}_{date} (예: abc123_2025-09-19)

{
  "applicationId": "abc123", // tester_applications의 document ID
  "date": "2025-09-19",
  "dayNumber": 1, // 미션의 몇 번째 날인지

  // 테스터 액션 (Firebase Console에서 직접 수정 가능)
  "tester": {
    "submitted": false, // true로 변경하면 테스터가 오늘 활동을 완료한 것으로 처리
    "submittedAt": null,
    "feedback": "",
    "screenshots": [],
    "bugReports": [],
    "sessionDuration": 0, // 분 단위
    "appRating": null // 1-5점
  },

  // 공급자 액션 (Firebase Console에서 직접 수정 가능)
  "provider": {
    "reviewed": false, // true로 변경하면 공급자가 검토 완료
    "reviewedAt": null,
    "approved": false, // true로 변경하면 오늘 활동 승인
    "pointsAwarded": 0,
    "providerComment": "",
    "needsImprovement": false
  },

  // 자동 계산 필드
  "status": "pending", // pending → submitted → reviewed → approved
  "createdAt": "2025-09-19T00:00:00.000Z",
  "updatedAt": "2025-09-19T10:00:00.000Z"
}
```

### 3. **앱 정보 관리** (`apps`)

```javascript
// Collection: apps
// Document ID: appId

{
  "appId": "eUOdv8wASX7RfSGMin7c",
  "appName": "BugCash Demo App",
  "providerId": "provider_demo_123",

  // 미션 설정 (Firebase Console에서 직접 수정 가능)
  "missionConfig": {
    "isActive": true, // false로 변경하면 신규 신청 중단
    "maxTesters": 10,
    "currentTesters": 3,
    "testingPeriod": 14,
    "dailyReward": 5000,
    "requirements": [
      "일일 30분 이상 앱 사용",
      "피드백 작성 필수",
      "버그 발견 시 즉시 신고"
    ]
  },

  // 통계 정보 (자동 계산)
  "stats": {
    "totalApplications": 15,
    "pendingApplications": 2,
    "activeTesters": 3,
    "completedTesters": 10,
    "totalBugsFound": 25,
    "averageRating": 4.2
  },

  "createdAt": "2025-09-15T00:00:00.000Z",
  "updatedAt": "2025-09-19T10:00:00.000Z"
}
```

### 4. **실시간 알림 관리** (`notifications`)

```javascript
// Collection: notifications
// Document ID: auto-generated

{
  "recipientId": "CazdCJYsxGMxEOzXGTen3AY5Kom2", // 수신자 ID
  "recipientType": "tester", // tester 또는 provider

  // 알림 내용
  "type": "application_approved", // 알림 타입
  "title": "미션 신청이 승인되었습니다",
  "message": "BugCash Demo App 테스트 미션이 승인되어 테스트를 시작할 수 있습니다.",

  // 상태 관리 (Firebase Console에서 직접 수정 가능)
  "read": false, // true로 변경하면 읽음 처리
  "readAt": null,

  // 관련 데이터
  "relatedData": {
    "applicationId": "abc123",
    "appId": "eUOdv8wASX7RfSGMin7c"
  },

  "createdAt": "2025-09-19T10:00:00.000Z"
}
```

## 🔧 Firebase Console에서 직접 상태 변경하는 방법

### 1. **테스터 신청 승인하기**
```
1. tester_applications 컬렉션 → 해당 document 선택
2. status 필드를 "pending" → "approved"로 변경
3. statusUpdatedAt을 현재 시간으로 설정
4. statusUpdatedBy에 공급자 ID 입력
5. approvedAt에 현재 시간 설정
```

### 2. **일일 활동 승인하기**
```
1. daily_interactions 컬렉션 → 해당 날짜 document 선택
2. provider.reviewed를 true로 변경
3. provider.approved를 true로 변경
4. provider.pointsAwarded에 포인트 입력
5. status를 "approved"로 변경
```

### 3. **미션 중단하기**
```
1. apps 컬렉션 → 해당 앱 document 선택
2. missionConfig.isActive를 false로 변경
```

## 📊 자동 계산 필드들

이 구조의 장점은 Firebase Console에서 핵심 상태만 변경하면, 앱에서 자동으로 계산되는 필드들이 있다는 것입니다:

- `progress.currentDay`: daily_interactions에서 approved된 날짜 수를 계산
- `progress.progressPercentage`: currentDay / totalDays * 100
- `progress.todayCompleted`: 오늘 날짜의 daily_interaction에서 tester.submitted 확인
- `apps.stats.*`: 관련 documents를 집계하여 자동 계산

이제 Firebase Console에서 간단히 몇 개 필드만 변경해도 전체 앱의 상태가 실시간으로 반영됩니다!