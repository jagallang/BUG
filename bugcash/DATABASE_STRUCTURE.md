# BUGS 플랫폼 - Firebase Firestore 데이터베이스 구조 문서

## 📋 개요

BUGS 플랫폼의 Firebase Firestore 데이터베이스 구조와 각 컬렉션의 상세 스키마를 정의합니다. PRD 요구사항에 따른 최적화된 구조로 설계되었습니다.

## 🏗️ 전체 데이터베이스 구조

```
Firebase Firestore Database Structure
├── users/                     # 사용자 정보
├── projects/                  # 프로젝트 정보 (새로운 최적화된 구조)
├── applications/              # 테스터 신청 정보
├── enrollments/               # 활성 미션 등록 정보
├── missions/                  # 일일 미션 데이터
│   └── daily_interactions/    # 일일 상호작용 서브컬렉션
├── points_transactions/       # 포인트 거래 내역
├── reports/                   # 신고 관리
├── notifications/             # 알림 시스템
├── admin_dashboard/           # 관리자 대시보드 데이터
└── [legacy collections]       # 기존 컬렉션들 (단계적 제거 예정)
    ├── missions/              # 기존 미션 구조
    ├── bug_reports/           # 버그 리포트
    ├── test_sessions/         # 테스트 세션
    ├── provider_apps/         # 공급자 앱
    └── testers/               # 테스터 정보
```

---

## 🎯 핵심 컬렉션 상세 구조

### 1. users 컬렉션
**경로**: `/users/{userId}`
**용도**: 모든 사용자(테스터, 공급자, 관리자)의 기본 정보

```typescript
interface User {
  // 기본 정보
  uid: string;                    // Firebase Auth UID
  email: string;                  // 이메일
  displayName: string;            // 표시 이름
  name?: string;                  // 실명
  role: 'tester' | 'provider' | 'admin';  // 역할

  // 프로필 정보
  photoURL?: string;              // 프로필 이미지
  phoneNumber?: string;           // 전화번호
  birthDate?: Date;               // 생년월일
  gender?: 'male' | 'female' | 'other';  // 성별

  // 테스터 전용 필드
  totalPoints?: number;           // 총 포인트
  monthlyPoints?: number;         // 월간 포인트
  completedMissions?: number;     // 완료한 미션 수
  successRate?: number;           // 성공률 (0-100)
  averageRating?: number;         // 평균 평점 (0-5)
  skills?: string[];              // 기술/전문 분야
  interests?: string[];           // 관심 분야
  level?: 'beginner' | 'intermediate' | 'advanced' | 'expert';  // 레벨
  experiencePoints?: number;      // 경험치

  // 메타데이터
  createdAt: Timestamp;           // 가입일시
  updatedAt: Timestamp;           // 최종 수정일시
  lastLoginAt?: Timestamp;        // 최종 로그인
  isActive: boolean;              // 활성 상태
  isVerified?: boolean;           // 인증 상태
}
```

### 2. projects 컬렉션 ⭐ (새로운 최적화 구조)
**경로**: `/projects/{projectId}`
**용도**: 공급자가 등록한 앱 테스트 프로젝트 정보

```typescript
interface Project {
  // 기본 정보
  id: string;                     // 문서 ID
  appName: string;                // 앱 이름
  description: string;            // 프로젝트 설명

  // 공급자 정보
  providerId: string;             // 공급자 UID
  providerName: string;           // 공급자 이름
  providerEmail?: string;         // 공급자 이메일

  // 프로젝트 상태
  status: 'pending' | 'open' | 'rejected' | 'closed';  // 프로젝트 상태

  // 테스트 설정
  maxTesters: number;             // 최대 테스터 수
  currentTesters?: number;        // 현재 참여 테스터 수
  testPeriodDays: number;         // 테스트 기간 (일)
  startDate?: Date;               // 테스트 시작일
  endDate?: Date;                 // 테스트 종료일

  // 리워드 설정
  rewards: {
    baseReward: number;           // 기본 리워드 (포인트)
    bonusReward: number;          // 보너스 리워드
    dailyReward?: number;         // 일일 리워드
    completionBonus?: number;     // 완주 보너스
  };

  // 요구사항
  requirements: {
    platforms: string[];          // 지원 플랫폼 ['android', 'ios', 'web']
    minAge: number;               // 최소 연령
    maxAge: number;               // 최대 연령
    requiredSkills?: string[];    // 필요 기술
    excludeRegions?: string[];    // 제외 지역
    minRating?: number;           // 최소 평점
    experienceLevel?: string;     // 경험 레벨
  };

  // 앱 정보
  appInfo?: {
    packageName?: string;         // 패키지명
    version?: string;             // 버전
    downloadUrl?: string;         // 다운로드 링크
    testflightUrl?: string;       // TestFlight URL (iOS)
    category?: string;            // 앱 카테고리
    screenshots?: string[];       // 스크린샷 URL들
  };

  // 테스트 타입
  testType: 'usability' | 'bug_hunting' | 'performance' | 'compatibility';
  difficulty: 'easy' | 'medium' | 'hard';  // 난이도

  // 메타데이터
  createdAt: Timestamp;           // 생성일시
  updatedAt: Timestamp;           // 수정일시
  approvedAt?: Timestamp;         // 승인일시
  approvedBy?: string;            // 승인한 관리자 ID
  rejectedAt?: Timestamp;         // 거부일시
  rejectedBy?: string;            // 거부한 관리자 ID
  rejectionReason?: string;       // 거부 사유

  // 통계
  stats?: {
    totalApplications: number;    // 총 신청 수
    approvedApplications: number; // 승인된 신청 수
    completedMissions: number;    // 완료된 미션 수
    averageRating: number;        // 평균 평점
    totalBugsFound: number;       // 발견된 버그 수
  };
}
```

### 3. applications 컬렉션 ⭐ (새로운 구조)
**경로**: `/applications/{applicationId}`
**용도**: 테스터의 프로젝트 참여 신청 정보

```typescript
interface Application {
  // 기본 정보
  id: string;                     // 문서 ID
  projectId: string;              // 프로젝트 ID
  testerId: string;               // 테스터 UID
  testerName: string;             // 테스터 이름
  testerEmail: string;            // 테스터 이메일

  // 신청 상태
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';

  // 신청 정보
  experience: string;             // 관련 경험
  motivation: string;             // 지원 동기
  availableHours: number;         // 가능한 시간 (시간/일)
  preferredSchedule?: string;     // 선호 일정

  // 테스터 정보 스냅샷
  testerProfile: {
    level: string;                // 레벨
    rating: number;               // 평점
    completedMissions: number;    // 완료 미션 수
    skills: string[];             // 보유 기술
    devices: string[];            // 보유 기기
  };

  // 처리 정보
  processedAt?: Timestamp;        // 처리일시
  processedBy?: string;           // 처리한 관리자/공급자 ID
  feedback?: string;              // 피드백

  // 자동 매칭 점수
  matchingScore?: number;         // 0-100 점수
  autoMatchFactors?: {
    skillMatch: number;           // 기술 매칭
    experienceMatch: number;      // 경험 매칭
    ratingBonus: number;          // 평점 보너스
    availabilityMatch: number;    // 가용성 매칭
  };

  // 메타데이터
  createdAt: Timestamp;           // 신청일시
  updatedAt: Timestamp;           // 수정일시
}
```

### 4. enrollments 컬렉션 ⭐ (새로운 구조)
**경로**: `/enrollments/{enrollmentId}`
**용도**: 승인된 테스터의 활성 미션 등록 정보

```typescript
interface Enrollment {
  // 기본 정보
  id: string;                     // 문서 ID
  projectId: string;              // 프로젝트 ID
  testerId: string;               // 테스터 UID
  applicationId: string;          // 원본 신청 ID

  // 상태
  status: 'active' | 'paused' | 'completed' | 'failed' | 'cancelled';

  // 미션 진행 정보
  startDate: Date;                // 시작일
  endDate: Date;                  // 종료 예정일
  actualEndDate?: Date;           // 실제 종료일

  // 진행률
  progress: {
    totalDays: number;            // 총 일수
    completedDays: number;        // 완료한 일수
    currentDay: number;           // 현재 일차
    completionRate: number;       // 완료율 (0-100)
  };

  // 성과 지표
  performance: {
    dailySubmissions: number;     // 일일 제출 수
    qualityScore: number;         // 품질 점수 (0-100)
    bugsFound: number;            // 발견한 버그 수
    feedbackCount: number;        // 피드백 수
    averageRating: number;        // 평균 평점
  };

  // 리워드 정보
  rewards: {
    earnedPoints: number;         // 획득한 포인트
    dailyBonus: number;           // 일일 보너스
    qualityBonus: number;         // 품질 보너스
    completionBonus: number;      // 완주 보너스
    totalEarned: number;          // 총 획득 포인트
  };

  // 메타데이터
  createdAt: Timestamp;           // 등록일시
  updatedAt: Timestamp;           // 수정일시
  lastActiveAt: Timestamp;        // 마지막 활동일시
}
```

### 5. missions 컬렉션 ⭐ (새로운 구조)
**경로**: `/missions/{missionId}`
**용도**: 일일 미션 데이터 및 제출물

```typescript
interface Mission {
  // 기본 정보
  id: string;                     // 문서 ID
  enrollmentId: string;           // 등록 ID
  projectId: string;              // 프로젝트 ID
  testerId: string;               // 테스터 UID

  // 미션 정보
  dayNumber: number;              // 미션 일차 (1-14)
  missionDate: Date;              // 미션 날짜
  title: string;                  // 미션 제목
  description?: string;           // 미션 설명

  // 상태
  status: 'assigned' | 'in_progress' | 'submitted' | 'approved' | 'rejected' | 'revision_requested';

  // 제출 데이터
  submissionData?: {
    testingDuration: number;      // 테스트 시간 (분)
    usabilityScore: number;       // 사용성 점수 (1-10)
    bugReports: BugReport[];      // 버그 리포트들
    feedback: string;             // 피드백
    screenshots: string[];        // 스크린샷 URL들
    videoUrl?: string;            // 동영상 URL
    rating: number;               // 앱 평점 (1-5)
    suggestions: string;          // 개선 제안
  };

  // 공급자 피드백
  providerFeedback?: {
    rating: number;               // 제출물 평점 (1-5)
    feedback: string;             // 피드백
    bonusPoints: number;          // 보너스 포인트
    isQualitySubmission: boolean; // 우수 제출물 여부
  };

  // 타임스탬프
  createdAt: Timestamp;           // 생성일시
  submittedAt?: Timestamp;        // 제출일시
  approvedAt?: Timestamp;         // 승인일시
  reviewedAt?: Timestamp;         // 검토일시

  // 자동 분석 데이터
  autoAnalysis?: {
    sentimentScore: number;       // 감정 분석 점수
    keywordTags: string[];        // 키워드 태그들
    similarityScore: number;      // 유사성 점수
    qualityFlags: string[];       // 품질 플래그들
  };
}

// 서브컬렉션: 일일 상호작용
interface DailyInteraction {
  // 경로: /missions/{missionId}/daily_interactions/{interactionId}
  id: string;
  timestamp: Timestamp;
  type: 'screen_tap' | 'scroll' | 'input' | 'navigation' | 'error';
  screenName: string;
  elementId?: string;
  action: string;
  metadata?: Record<string, any>;
}
```

### 6. points_transactions 컬렉션
**경로**: `/points_transactions/{transactionId}`
**용도**: 모든 포인트 거래 내역

```typescript
interface PointsTransaction {
  // 기본 정보
  id: string;                     // 문서 ID
  userId: string;                 // 사용자 UID
  type: 'earn' | 'spend' | 'bonus' | 'penalty' | 'refund';

  // 거래 정보
  amount: number;                 // 포인트 양 (+ 획득, - 사용)
  description: string;            // 거래 설명
  category: 'mission' | 'bonus' | 'purchase' | 'admin' | 'system';

  // 관련 정보
  relatedId?: string;             // 관련 문서 ID (미션, 프로젝트 등)
  relatedType?: 'mission' | 'project' | 'enrollment' | 'admin_action';

  // 잔액 정보
  balanceBefore: number;          // 거래 전 잔액
  balanceAfter: number;           // 거래 후 잔액

  // 메타데이터
  createdAt: Timestamp;           // 거래일시
  processedBy?: string;           // 처리한 관리자 ID
  adminNote?: string;             // 관리자 메모

  // 자동화 정보
  isAutomated: boolean;           // 자동 처리 여부
  automationRule?: string;        // 적용된 규칙
}
```

### 7. notifications 컬렉션
**경로**: `/notifications/{notificationId}`
**용도**: 사용자 알림 관리

```typescript
interface Notification {
  // 기본 정보
  id: string;                     // 문서 ID
  userId: string;                 // 수신자 UID
  title: string;                  // 알림 제목
  message: string;                // 알림 내용

  // 분류
  type: 'mission' | 'project' | 'system' | 'payment' | 'achievement';
  priority: 'low' | 'medium' | 'high' | 'urgent';

  // 상태
  read: boolean;                  // 읽음 여부
  dismissed: boolean;             // 무시됨 여부

  // 액션 정보
  actionType?: 'navigate' | 'approve' | 'download' | 'link';
  actionUrl?: string;             // 액션 URL
  actionData?: Record<string, any>;  // 액션 데이터

  // 관련 정보
  relatedId?: string;             // 관련 문서 ID
  relatedType?: string;           // 관련 타입

  // 메타데이터
  createdAt: Timestamp;           // 생성일시
  readAt?: Timestamp;             // 읽은 일시
  expiresAt?: Timestamp;          // 만료일시

  // 푸시 알림
  pushSent: boolean;              // 푸시 알림 발송 여부
  pushSentAt?: Timestamp;         // 푸시 발송 일시
  emailSent?: boolean;            // 이메일 발송 여부
}
```

### 8. reports 컬렉션
**경로**: `/reports/{reportId}`
**용도**: 신고 및 문제 제기 관리

```typescript
interface Report {
  // 기본 정보
  id: string;                     // 문서 ID
  reporterId: string;             // 신고자 UID
  reportedId: string;             // 피신고자 UID

  // 신고 내용
  type: 'user' | 'content' | 'bug' | 'spam' | 'inappropriate';
  category: string;               // 세부 카테고리
  title: string;                  // 신고 제목
  description: string;            // 신고 내용

  // 증거 자료
  evidence: {
    screenshots: string[];        // 스크린샷들
    attachments: string[];        // 첨부파일들
    urls: string[];               // 관련 URL들
  };

  // 처리 상태
  status: 'pending' | 'investigating' | 'resolved' | 'dismissed' | 'escalated';

  // 처리 정보
  assignedTo?: string;            // 담당자 ID
  resolution?: string;            // 해결 내용
  action?: 'none' | 'warning' | 'suspension' | 'ban' | 'content_removal';

  // 메타데이터
  createdAt: Timestamp;           // 신고일시
  updatedAt: Timestamp;           // 수정일시
  resolvedAt?: Timestamp;         // 해결일시
  resolvedBy?: string;            // 해결한 관리자 ID

  // 우선순위
  priority: number;               // 우선순위 (1-10)
  severity: 'low' | 'medium' | 'high' | 'critical';
}
```

---

## 🔄 데이터 흐름 및 관계

### 프로젝트 생명주기
```
1. projects (pending) ← 공급자가 생성
2. projects (open) ← 관리자가 승인
3. applications ← 테스터들이 신청
4. enrollments ← 승인된 테스터들의 활성 미션
5. missions ← 일일 미션 생성 및 제출
6. points_transactions ← 리워드 지급
```

### 데이터 관계도
```
users (1) ──── (N) projects [providerId]
users (1) ──── (N) applications [testerId]
projects (1) ──── (N) applications [projectId]
applications (1) ──── (1) enrollments [applicationId]
enrollments (1) ──── (N) missions [enrollmentId]
users (1) ──── (N) points_transactions [userId]
users (1) ──── (N) notifications [userId]
```

---

## 📊 인덱스 구성

### 핵심 복합 인덱스
```json
// projects 컬렉션
{
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}

// applications 컬렉션
{
  "fields": [
    {"fieldPath": "testerId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}

// enrollments 컬렉션
{
  "fields": [
    {"fieldPath": "testerId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "startDate", "order": "DESCENDING"}
  ]
}

// missions 컬렉션
{
  "fields": [
    {"fieldPath": "testerId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "missionDate", "order": "DESCENDING"}
  ]
}
```

---

## 🔒 보안 규칙 요약

### 주요 접근 제어
- **users**: 본인 정보만 읽기/쓰기, 관리자는 모든 사용자 접근
- **projects**: 공개 프로젝트는 모든 사용자 읽기, 본인 프로젝트만 수정
- **applications**: 본인 신청만 읽기/쓰기, 프로젝트 소유자와 관리자 접근
- **enrollments**: Cloud Functions만 생성/수정, 참여자만 읽기
- **missions**: 본인 미션만 읽기/제출, 공급자는 피드백만 수정

---

## 📈 성능 최적화

### 쿼리 최적화 전략
1. **페이지네이션**: limit() 및 startAfter() 사용
2. **필드 선택**: select()로 필요한 필드만 조회
3. **캐싱**: 자주 조회되는 데이터 로컬 캐싱
4. **배치 작업**: batch() 사용으로 다중 문서 처리

### 비용 최적화
1. **인덱스 최소화**: 필요한 인덱스만 유지
2. **읽기 최적화**: 불필요한 실시간 리스너 최소화
3. **쓰기 최적화**: 트랜잭션과 배치 작업 활용

---

이 문서는 BUGS 플랫폼의 완전한 데이터베이스 구조를 정의하며, 향후 기능 확장과 성능 최적화의 기준점 역할을 합니다.