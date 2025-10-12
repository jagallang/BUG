# 🔥 Firebase Console에서 tester_applications 컬렉션 생성 가이드

## 📋 1단계: 컬렉션 생성

### Firebase Console 접속 및 컬렉션 생성:

1. **Firebase Console 접속**: https://console.firebase.google.com/u/0/project/bugcash/firestore/databases/-default-/data
2. **컬렉션 시작** 버튼 클릭
3. **컬렉션 ID**: `tester_applications` 입력
4. **첫 번째 문서 추가**

---

## 📄 Document 1: 대기 중인 신청 (pending)

### Document ID: `auto-generated` (또는 `pending_application_001`)

```json
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

## 📄 Document 2: 승인된 신청 (approved)

### Document ID: `auto-generated` (또는 `approved_application_001`)

```json
{
  "appId": "eUOdv8wASX7RfSGMin7c",
  "testerId": "active_tester_456",
  "providerId": "provider_demo_123",

  "status": "approved",
  "statusUpdatedAt": "2025-09-17T09:00:00.000Z",
  "statusUpdatedBy": "provider_demo_123",

  "appliedAt": "2025-09-17T05:00:00.000Z",
  "approvedAt": "2025-09-17T09:00:00.000Z",
  "startedAt": "2025-09-17T09:00:00.000Z",
  "completedAt": null,

  "testerInfo": {
    "name": "이활동",
    "email": "active@example.com",
    "experience": "고급",
    "motivation": "전문적인 QA 경험을 쌓고 싶습니다.",
    "deviceModel": "iPhone 15 Pro",
    "deviceOS": "iOS 17",
    "deviceVersion": "17.5.1"
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
    "currentDay": 3,
    "progressPercentage": 21.4,
    "todayCompleted": false,
    "bugsReported": 2,
    "feedbackSubmitted": 3,
    "totalPoints": 15000
  }
}
```

---

## 📄 Document 3: 완료된 신청 (completed)

### Document ID: `auto-generated` (또는 `completed_application_001`)

```json
{
  "appId": "eUOdv8wASX7RfSGMin7c",
  "testerId": "completed_tester_789",
  "providerId": "provider_demo_123",

  "status": "completed",
  "statusUpdatedAt": "2025-09-19T10:00:00.000Z",
  "statusUpdatedBy": "provider_demo_123",

  "appliedAt": "2025-09-05T05:00:00.000Z",
  "approvedAt": "2025-09-05T10:00:00.000Z",
  "startedAt": "2025-09-05T10:00:00.000Z",
  "completedAt": "2025-09-19T10:00:00.000Z",

  "testerInfo": {
    "name": "박완료",
    "email": "completed@example.com",
    "experience": "고급",
    "motivation": "앱 품질 향상에 성공적으로 기여했습니다.",
    "deviceModel": "Galaxy S24 Ultra",
    "deviceOS": "Android 14",
    "deviceVersion": "API 34"
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
    "currentDay": 14,
    "progressPercentage": 100.0,
    "todayCompleted": true,
    "bugsReported": 8,
    "feedbackSubmitted": 14,
    "totalPoints": 70000,
    "latestFeedback": "14일 테스트 완료, 전반적으로 만족스러운 앱입니다.",
    "averageRating": 4.8
  }
}
```

---

## 🔧 2단계: 컬렉션 생성 방법

### Firebase Console에서 직접 생성:

1. **필드 타입 주의사항**:
   - `appliedAt`, `approvedAt` 등: **timestamp** 타입으로 설정
   - `status`, `name` 등: **string** 타입
   - `currentDay`, `totalPoints` 등: **number** 타입
   - `todayCompleted`: **boolean** 타입
   - `requirements`: **array** 타입
   - `testerInfo`, `missionInfo`: **map** 타입

2. **중첩 객체 생성**:
   - `testerInfo` 필드: **map** 타입 선택 → 하위 필드들 추가
   - `missionInfo` 필드: **map** 타입 선택 → 하위 필드들 추가
   - `progress` 필드: **map** 타입 선택 → 하위 필드들 추가

---

## 📊 3단계: 인덱스 생성

Firebase Console > Firestore > 인덱스에서 다음 인덱스 생성:

### 복합 인덱스 1
- **컬렉션 ID**: `tester_applications`
- **필드 1**: `appId` (Ascending)
- **필드 2**: `status` (Ascending)
- **필드 3**: `appliedAt` (Descending)

### 복합 인덱스 2
- **컬렉션 ID**: `tester_applications`
- **필드 1**: `testerId` (Ascending)
- **필드 2**: `appliedAt` (Descending)

### 복합 인덱스 3
- **컬렉션 ID**: `tester_applications`
- **필드 1**: `providerId` (Ascending)
- **필드 2**: `status` (Ascending)
- **필드 3**: `appliedAt` (Descending)

---

## ⚡ 4단계: 실시간 상태 테스트

### 상태 변경 테스트:

1. **테스터 승인**: Document 1에서 `status`를 `"pending"` → `"approved"`로 변경
2. **승인 시간 기록**: `approvedAt`에 현재 시간 설정, `statusUpdatedBy`에 공급자 ID 입력
3. **진행률 업데이트**: Document 2에서 `progress.currentDay`를 `3` → `4`로 변경

Flutter 앱에서 실시간으로 변경사항이 반영되는지 확인하세요!

---

## 🎯 완료 확인

✅ `tester_applications` 컬렉션 생성됨
✅ 3개의 샘플 문서 추가됨
✅ 필요한 인덱스 생성됨
✅ Flutter 앱에서 실시간 데이터 확인됨

이제 Firebase Console에서 직접 테스터 신청 상태를 관리할 수 있습니다! 🚀