# BugCash 플랫폼 - 최적화된 Firestore 스키마 설계

## 현재 문제점 분석

### 기존 컬렉션들 (비효율적)
- `mission_applications` (레거시)
- `tester_applications` (중복)
- `mission_workflows` (새로운)
- `apps`, `missions` (분리됨)
- `test_sessions` (다른 구조)

### 주요 문제점
1. **데이터 중복**: 동일한 정보가 3개 컬렉션에 저장
2. **일관성 부족**: 서로 다른 필드명과 구조
3. **성능 저하**: 복잡한 조인 쿼리 필요
4. **확장성 제한**: 새로운 기능 추가 시 복잡성 증가

## 최적화된 스키마 설계 (PRD 기반)

### 1. 핵심 컬렉션 구조

#### `/users` - 통합 사용자 관리
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "role": "tester|provider|admin",
  "points": "number",
  "profileImage": "string?",
  "phoneNumber": "string?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isActive": "boolean",
  "metadata": {
    "lastLoginAt": "timestamp",
    "deviceInfo": "object",
    "preferences": "object"
  }
}
```

#### `/projects` - 통합 프로젝트 관리
```json
{
  "id": "string",
  "appId": "string",
  "appName": "string",
  "providerId": "string",
  "providerName": "string",
  "status": "draft|pending|open|closed|rejected",
  "category": "string", // Google Play 카테고리
  "description": "string",
  "storeUrl": "string",
  "estimatedDays": "number",
  "dailyReward": "number",
  "maxTesters": "number",
  "currentTesters": "number",
  "budget": "number",
  "requirements": ["string"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "startDate": "timestamp?",
  "endDate": "timestamp?",
  "adminNotes": "string?",
  "metadata": {
    "version": "string",
    "targetDevices": ["string"],
    "testingFocus": ["string"]
  }
}
```

#### `/applications` - 통합 신청 관리
```json
{
  "id": "string",
  "projectId": "string",
  "testerId": "string",
  "testerName": "string",
  "testerEmail": "string",
  "status": "pending|approved|rejected",
  "appliedAt": "timestamp",
  "processedAt": "timestamp?",
  "processedBy": "string?",
  "experience": "string",
  "motivation": "string",
  "feedback": "string?",
  "metadata": {
    "deviceInfo": "object",
    "previousExperience": "object"
  }
}
```

#### `/enrollments` - 활성 미션 관리
```json
{
  "id": "string",
  "projectId": "string",
  "testerId": "string",
  "status": "active|completed|expired|suspended",
  "startedAt": "timestamp",
  "completedAt": "timestamp?",
  "currentDay": "number",
  "totalDays": "number",
  "totalEarned": "number",
  "progressPercentage": "number",
  "lastActivityAt": "timestamp",
  "metadata": {
    "performanceScore": "number",
    "completionRate": "number"
  }
}
```

#### `/missions` - 일일 미션 관리
```json
{
  "id": "string",
  "enrollmentId": "string",
  "projectId": "string",
  "testerId": "string",
  "dayNumber": "number",
  "status": "locked|open|submitted|approved|rejected",
  "openedAt": "timestamp?",
  "submittedAt": "timestamp?",
  "approvedAt": "timestamp?",
  "reward": "number",
  "submissionData": {
    "notes": "string",
    "images": ["string"],
    "rating": "number?"
  },
  "providerFeedback": {
    "rating": "number?",
    "notes": "string?",
    "approvedBy": "string?"
  }
}
```

#### `/points_transactions` - 포인트 거래 내역
```json
{
  "id": "string",
  "userId": "string",
  "type": "charge|earn|withdraw|deduct",
  "amount": "number",
  "balance": "number",
  "description": "string",
  "relatedId": "string?", // projectId, missionId, etc.
  "metadata": {
    "paymentMethod": "string?",
    "transactionId": "string?",
    "platformFee": "number?"
  },
  "createdAt": "timestamp"
}
```

#### `/reports` - 신고 관리
```json
{
  "id": "string",
  "reporterId": "string",
  "reportedId": "string", // userId or projectId
  "type": "user|project|mission",
  "category": "spam|inappropriate|fraud|other",
  "description": "string",
  "status": "pending|investigating|resolved|dismissed",
  "evidence": ["string"], // image URLs
  "adminNotes": "string?",
  "createdAt": "timestamp",
  "resolvedAt": "timestamp?"
}
```

#### `/notifications` - 알림 관리
```json
{
  "id": "string",
  "userId": "string",
  "type": "mission|payment|system|report",
  "title": "string",
  "body": "string",
  "data": "object",
  "read": "boolean",
  "createdAt": "timestamp"
}
```

#### `/admin_dashboard/stats/{period}` - 관리자 통계 (캐시됨)
```json
{
  "period": "2024-01", // YYYY-MM
  "projects": {
    "total": "number",
    "pending": "number",
    "active": "number",
    "completed": "number"
  },
  "users": {
    "totalUsers": "number",
    "newTesters": "number",
    "newProviders": "number",
    "activeUsers": "number"
  },
  "financial": {
    "totalCharged": "number",
    "totalPaid": "number",
    "platformRevenue": "number",
    "pendingPayouts": "number"
  },
  "generatedAt": "timestamp"
}
```

### 2. 서브컬렉션 구조

#### `/projects/{projectId}/submissions` - 제출물 관리
```json
{
  "id": "string",
  "missionId": "string",
  "testerId": "string",
  "content": "string",
  "attachments": ["string"],
  "submittedAt": "timestamp"
}
```

#### `/enrollments/{enrollmentId}/daily_interactions` - 일일 상호작용
```json
{
  "date": "string", // YYYY-MM-DD
  "missionOpened": "boolean",
  "missionCompleted": "boolean",
  "testerNotes": "string?",
  "providerFeedback": "string?",
  "interactions": ["object"]
}
```

## 장점

### 1. 성능 최적화
- 단일 쿼리로 필요한 데이터 조회
- 인덱스 최적화 가능
- 실시간 업데이트 효율성

### 2. 데이터 일관성
- 중복 제거
- 표준화된 필드명
- 명확한 관계 정의

### 3. 확장성
- 새로운 기능 추가 용이
- 마이크로서비스 아키텍처 지원
- API 설계 간소화

### 4. 보안
- 컬렉션별 세분화된 권한 설정
- 민감 정보 분리
- 감사 로그 지원

## 마이그레이션 전략

### Phase 1: 새 스키마 구축
1. 새 컬렉션 생성
2. 보안 규칙 설정
3. 인덱스 생성

### Phase 2: 데이터 마이그레이션
1. 기존 데이터 변환 스크립트
2. 점진적 마이그레이션
3. 데이터 검증

### Phase 3: 코드 업데이트
1. 서비스 로직 변경
2. UI 컴포넌트 업데이트
3. 테스트 및 검증

### Phase 4: 정리
1. 레거시 컬렉션 제거
2. 최종 검증
3. 모니터링 설정