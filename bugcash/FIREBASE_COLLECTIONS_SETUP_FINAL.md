# 🔥 Firebase 컬렉션 즉시 생성 가이드

## 📋 Firebase Console에서 직접 생성하기

### 1단계: Firebase Console 접속
👉 **링크**: https://console.firebase.google.com/u/0/project/bugcash/firestore/databases/-default-/data

### 2단계: 컬렉션 생성

#### ✅ `tester_applications` 컬렉션 생성

1. **컬렉션 시작** 버튼 클릭
2. **컬렉션 ID**: `tester_applications` 입력
3. **첫 번째 문서 추가**:

---

## 📄 Document 1: 대기 중인 신청

**Document ID**: `auto-generated`

**필드 추가**:

```
appId (string): eUOdv8wASX7RfSGMin7c
testerId (string): CazdCJYsxGMxEOzXGTen3AY5Kom2
providerId (string): provider_demo_123
status (string): pending
statusUpdatedAt (timestamp): 2025-09-19T10:00:00.000Z
statusUpdatedBy (string):
appliedAt (timestamp): 2025-09-19T05:00:00.000Z
approvedAt (null):
startedAt (null):
completedAt (null):

testerInfo (map):
  ├── name (string): 김테스터
  ├── email (string): tester@example.com
  ├── experience (string): 중급
  ├── motivation (string): 앱 품질 향상에 기여하고 싶습니다.
  ├── deviceModel (string): SM-S926N
  ├── deviceOS (string): Android 15
  └── deviceVersion (string): API 35

missionInfo (map):
  ├── appName (string): BugCash Demo App
  ├── totalDays (number): 14
  ├── dailyReward (number): 5000
  ├── totalReward (number): 70000
  └── requirements (array): ["일일 30분 이상 앱 사용", "피드백 작성 필수", "버그 발견 시 즉시 신고"]

progress (map):
  ├── currentDay (number): 0
  ├── progressPercentage (number): 0.0
  ├── todayCompleted (boolean): false
  ├── bugsReported (number): 0
  ├── feedbackSubmitted (number): 0
  └── totalPoints (number): 0
```

---

## 📄 Document 2: 승인된 신청

**새 문서 추가** 클릭:

```
appId (string): eUOdv8wASX7RfSGMin7c
testerId (string): active_tester_456
providerId (string): provider_demo_123
status (string): approved
statusUpdatedAt (timestamp): 2025-09-17T09:00:00.000Z
statusUpdatedBy (string): provider_demo_123
appliedAt (timestamp): 2025-09-17T05:00:00.000Z
approvedAt (timestamp): 2025-09-17T09:00:00.000Z
startedAt (timestamp): 2025-09-17T09:00:00.000Z
completedAt (null):

testerInfo (map):
  ├── name (string): 이활동
  ├── email (string): active@example.com
  ├── experience (string): 고급
  ├── motivation (string): 전문적인 QA 경험을 쌓고 싶습니다.
  ├── deviceModel (string): iPhone 15 Pro
  ├── deviceOS (string): iOS 17
  └── deviceVersion (string): 17.5.1

missionInfo (map):
  ├── appName (string): BugCash Demo App
  ├── totalDays (number): 14
  ├── dailyReward (number): 5000
  ├── totalReward (number): 70000
  └── requirements (array): ["일일 30분 이상 앱 사용", "피드백 작성 필수", "버그 발견 시 즉시 신고"]

progress (map):
  ├── currentDay (number): 3
  ├── progressPercentage (number): 21.4
  ├── todayCompleted (boolean): false
  ├── bugsReported (number): 2
  ├── feedbackSubmitted (number): 3
  └── totalPoints (number): 15000
```

---

## 📄 Document 3: 완료된 신청

**새 문서 추가** 클릭:

```
appId (string): eUOdv8wASX7RfSGMin7c
testerId (string): completed_tester_789
providerId (string): provider_demo_123
status (string): completed
statusUpdatedAt (timestamp): 2025-09-19T10:00:00.000Z
statusUpdatedBy (string): provider_demo_123
appliedAt (timestamp): 2025-09-05T05:00:00.000Z
approvedAt (timestamp): 2025-09-05T10:00:00.000Z
startedAt (timestamp): 2025-09-05T10:00:00.000Z
completedAt (timestamp): 2025-09-19T10:00:00.000Z

testerInfo (map):
  ├── name (string): 박완료
  ├── email (string): completed@example.com
  ├── experience (string): 고급
  ├── motivation (string): 앱 품질 향상에 성공적으로 기여했습니다.
  ├── deviceModel (string): Galaxy S24 Ultra
  ├── deviceOS (string): Android 14
  └── deviceVersion (string): API 34

missionInfo (map):
  ├── appName (string): BugCash Demo App
  ├── totalDays (number): 14
  ├── dailyReward (number): 5000
  ├── totalReward (number): 70000
  └── requirements (array): ["일일 30분 이상 앱 사용", "피드백 작성 필수", "버그 발견 시 즉시 신고"]

progress (map):
  ├── currentDay (number): 14
  ├── progressPercentage (number): 100.0
  ├── todayCompleted (boolean): true
  ├── bugsReported (number): 8
  ├── feedbackSubmitted (number): 14
  ├── totalPoints (number): 70000
  ├── latestFeedback (string): 14일 테스트 완료, 전반적으로 만족스러운 앱입니다.
  └── averageRating (number): 4.8
```

---

## ⚡ 3단계: 상태 변경 테스트

### 테스터 승인하기:
1. Document 1 선택
2. `status` 필드를 `"pending"` → `"approved"`로 변경
3. `statusUpdatedBy`에 `"provider_demo_123"` 입력
4. `approvedAt`에 현재 시간 설정

### 진행률 업데이트:
1. Document 2 선택
2. `progress.currentDay`를 `3` → `4`로 변경
3. `progress.progressPercentage`를 `21.4` → `28.6`으로 변경

---

## 🎯 완료 확인

✅ `tester_applications` 컬렉션 생성
✅ 3개 샘플 문서 추가
✅ 실시간 상태 변경 테스트

### 최종 결과:
- **Firebase Console**: https://console.firebase.google.com/u/0/project/bugcash/firestore/databases/-default-/data/~2Ftester_applications
- **Flutter 앱**: 실시간으로 데이터 변경사항 반영 확인

---

## 🔧 필드 타입 가이드

- **string**: 텍스트 데이터
- **number**: 숫자 데이터
- **boolean**: true/false
- **timestamp**: 날짜/시간 (UTC)
- **array**: 배열 데이터
- **map**: 객체/하위 필드들
- **null**: 빈 값

### 중요한 점:
1. **map 타입**: `testerInfo`, `missionInfo`, `progress`는 반드시 **map** 타입으로 설정
2. **array 타입**: `requirements`는 **array** 타입으로 설정
3. **timestamp 타입**: 모든 날짜 필드는 **timestamp** 타입으로 설정

---

## 🚀 빠른 생성 방법

### JSON 임포트 (추천):
Firebase Console > 설정 > 프로젝트 설정 > 서비스 계정에서 JSON 파일을 사용하여 대량 임포트 가능합니다.

아래는 복사해서 사용할 수 있는 JSON 형태입니다:

```json
{
  "tester_applications": {
    "pending_001": {
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
        "requirements": ["일일 30분 이상 앱 사용", "피드백 작성 필수", "버그 발견 시 즉시 신고"]
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
  }
}
```

이제 Firebase Console에서 위의 가이드를 따라 컬렉션을 생성하시면 됩니다! 🚀