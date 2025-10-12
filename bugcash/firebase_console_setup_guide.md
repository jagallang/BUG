# 🔥 Firebase Console 설정 가이드

## 📋 1단계: 컬렉션 생성

### Firebase Console에서 수행할 작업:

1. **Firebase Console > Firestore Database > 데이터** 로 이동
2. **컬렉션 시작** 클릭하여 다음 컬렉션들을 생성:

---

## 📄 `tester_applications` 컬렉션

### 샘플 Document 1: 대기중인 신청
```javascript
// Document ID: auto-generated (예: abc123def456)
{
  "appId": "eUOdv8wASX7RfSGMin7c",
  "testerId": "CazdCJYsxGMxEOzXGTen3AY5Kom2",
  "providerId": "provider_demo_123",

  "status": "pending",
  "statusUpdatedAt": "2025-09-19T10:00:00.000Z",
  "statusUpdatedBy": "",

  "appliedAt": "2025-09-19T05:00:00.000Z",
  "approvedAt": null,
  "startedAt": null,
  "completedAt": null,

  "testerInfo": {
    "name": "김테스터",
    "email": "tester@example.com",
    "experience": "중급",
    "motivation": "앱 품질 향상에 기여하고 싶습니다.",
    "deviceModel": "SM-S926N",
    "deviceOS": "Android 15",
    "deviceVersion": "API 35"
  },

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

---

## 📄 `daily_interactions` 컬렉션

### 샘플 Document 1: 첫날 상호작용
```javascript
// Document ID: abc123def456_2025-09-19
{
  "applicationId": "abc123def456", // tester_applications의 document ID
  "date": "2025-09-19",
  "dayNumber": 1,

  "tester": {
    "submitted": false,
    "submittedAt": null,
    "feedback": "",
    "screenshots": [],
    "bugReports": [],
    "sessionDuration": 0,
    "appRating": null
  },

  "provider": {
    "reviewed": false,
    "reviewedAt": null,
    "approved": false,
    "pointsAwarded": 0,
    "providerComment": "",
    "needsImprovement": false
  },

  "status": "pending",
  "createdAt": "2025-09-19T00:00:00.000Z",
  "updatedAt": "2025-09-19T10:00:00.000Z"
}
```

---

## 📄 `apps` 컬렉션

### 샘플 Document 1: 데모 앱
```javascript
// Document ID: eUOdv8wASX7RfSGMin7c
{
  "appId": "eUOdv8wASX7RfSGMin7c",
  "appName": "BugCash Demo App",
  "providerId": "provider_demo_123",

  "missionConfig": {
    "isActive": true,
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

---

## 🔧 2단계: 상태 변경 워크플로우

### ✅ 테스터 신청 승인하기
```
Firebase Console에서:
1. tester_applications 컬렉션 → 해당 document 선택
2. 다음 필드들을 수정:
   - status: "pending" → "approved"
   - statusUpdatedAt: 현재 시간 (예: "2025-09-19T11:00:00.000Z")
   - statusUpdatedBy: 공급자 ID (예: "provider_demo_123")
   - approvedAt: 현재 시간 설정
```

### ✅ 일일 활동 승인하기
```
Firebase Console에서:
1. daily_interactions 컬렉션 → 해당 날짜 document 선택
2. 다음 필드들을 수정:
   - provider.reviewed: true
   - provider.reviewedAt: 현재 시간
   - provider.approved: true
   - provider.pointsAwarded: 5000 (또는 원하는 포인트)
   - status: "approved"
   - updatedAt: 현재 시간
```

### ✅ 테스터 활동 제출하기 (테스터가 직접)
```
Firebase Console에서:
1. daily_interactions 컬렉션 → 해당 날짜 document 선택
2. 다음 필드들을 수정:
   - tester.submitted: true
   - tester.submittedAt: 현재 시간
   - tester.feedback: "오늘 30분간 앱을 사용했습니다. 로그인 부분에서 약간의 지연이 있었습니다."
   - tester.sessionDuration: 30
   - tester.appRating: 4
   - status: "submitted"
   - updatedAt: 현재 시간
```

---

## 📊 3단계: Firestore 인덱스 설정

Firebase Console > Firestore > 인덱스에서 다음 인덱스를 생성:

### 복합 인덱스 1
- **컬렉션 그룹**: `tester_applications`
- **필드**:
  - `appId` (Ascending)
  - `status` (Ascending)
  - `appliedAt` (Descending)

### 복합 인덱스 2
- **컬렉션 그룹**: `tester_applications`
- **필드**:
  - `testerId` (Ascending)
  - `appliedAt` (Descending)

### 복합 인덱스 3
- **컬렉션 그룹**: `tester_applications`
- **필드**:
  - `providerId` (Ascending)
  - `status` (Ascending)
  - `appliedAt` (Descending)

### 복합 인덱스 4
- **컬렉션 그룹**: `daily_interactions`
- **필드**:
  - `applicationId` (Ascending)
  - `date` (Descending)

---

## 🔄 4단계: 실시간 상태 확인

### 상호작용 상태를 실시간으로 확인하는 방법:

1. **테스터 관점**: `tester_applications`에서 자신의 `testerId`로 필터링
2. **공급자 관점**: `tester_applications`에서 자신의 `providerId`로 필터링
3. **일일 진행 상황**: `daily_interactions`에서 `applicationId`로 필터링

### Firebase Console에서 확인 가능한 정보:

- ✅ 누가 언제 신청했는지
- ✅ 공급자가 언제 승인/거부했는지
- ✅ 각 날짜별로 테스터가 활동을 제출했는지
- ✅ 공급자가 각 날짜별 활동을 검토/승인했는지
- ✅ 실시간 진행률과 포인트 현황

이제 Firebase Console에서 몇 개 필드만 변경해도 전체 앱의 상태가 실시간으로 반영됩니다! 🚀