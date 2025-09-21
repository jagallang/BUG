# BugCash 플랫폼 - 최적화된 데이터베이스 설정 가이드

## 개요

이 문서는 BugCash 플랫폼의 최적화된 Firestore 데이터베이스 구조 설정 방법을 안내합니다.

## 🚀 빠른 시작

### 1. Firebase 프로젝트 설정

```bash
# Firebase CLI 설치 (아직 설치하지 않은 경우)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 초기화
firebase init firestore
```

### 2. 보안 규칙 배포

```bash
# 보안 규칙 파일 복사
cp firestore_security_rules.rules firestore.rules

# 보안 규칙 배포
firebase deploy --only firestore:rules
```

### 3. 인덱스 설정

```bash
# 인덱스 파일 복사
cp firestore_indexes.json firestore.indexes.json

# 인덱스 배포
firebase deploy --only firestore:indexes
```

### 4. 초기 데이터 설정

```bash
# Flutter 앱에서 스크립트 실행
flutter run scripts/setup_optimized_firestore.dart
```

## 📋 상세 설정 절차

### Phase 1: 기존 데이터 백업

**⚠️ 중요: 실제 데이터가 있는 경우 반드시 백업하세요!**

```bash
# 기존 데이터 백업 (선택사항)
gcloud firestore export gs://[YOUR_BACKUP_BUCKET]/backup-$(date +%Y%m%d)
```

### Phase 2: 새로운 구조 배포

#### 2.1 보안 규칙 설정

`firestore.rules` 파일에 다음을 추가:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 복사된 보안 규칙 내용
  }
}
```

#### 2.2 복합 인덱스 생성

Firebase Console에서 또는 CLI로 다음 인덱스들을 생성:

```json
{
  "indexes": [
    // projects 컬렉션
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    // applications 컬렉션
    {
      "collectionGroup": "applications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "projectId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "appliedAt", "order": "DESCENDING" }
      ]
    }
    // ... 추가 인덱스들
  ]
}
```

### Phase 3: 데이터 마이그레이션

#### 3.1 기존 데이터 변환

레거시 컬렉션에서 새로운 구조로 데이터 마이그레이션:

```dart
// 마이그레이션 스크립트 예시
Future<void> migrateLegacyData() async {
  // mission_applications → applications
  final legacyApps = await FirebaseFirestore.instance
      .collection('mission_applications')
      .get();

  for (final doc in legacyApps.docs) {
    final data = doc.data();
    await OptimizedFirestoreService.create(
      OptimizedFirestoreService.applications,
      {
        'projectId': data['missionId'],
        'testerId': data['testerId'],
        'testerName': data['testerName'],
        'testerEmail': data['testerEmail'],
        'status': data['status'],
        'appliedAt': data['appliedAt'],
        // ... 추가 필드 매핑
      },
    );
  }
}
```

#### 3.2 데이터 검증

```dart
// 마이그레이션 후 데이터 검증
Future<void> validateMigration() async {
  final stats = await OptimizedFirestoreService.getProjectStats();
  print('마이그레이션 완료 - 총 프로젝트: ${stats['total']}');

  // 추가 검증 로직
}
```

### Phase 4: 코드 업데이트

#### 4.1 서비스 클래스 교체

기존 `FirestoreService` 대신 `OptimizedFirestoreService` 사용:

```dart
// Before
final userData = await FirestoreService.read(
  FirestoreService.users,
  userId
);

// After
final userData = await OptimizedFirestoreService.read(
  OptimizedFirestoreService.users,
  userId
);
```

#### 4.2 쿼리 로직 업데이트

새로운 스트림 메서드 활용:

```dart
// 프로젝트 목록 조회
final projectsStream = OptimizedFirestoreService.getProjectsStream(
  status: 'open',
  category: 'PRODUCTIVITY',
  limit: 20,
);

// 사용자 신청 내역 조회
final applicationsStream = OptimizedFirestoreService.getApplicationsStream(
  testerId: currentUser.uid,
  status: 'pending',
);
```

## 🔧 설정 확인

### 1. 컬렉션 구조 확인

Firebase Console에서 다음 컬렉션들이 생성되었는지 확인:

- ✅ `users` - 통합 사용자 관리
- ✅ `projects` - 통합 프로젝트 관리
- ✅ `applications` - 신청 관리
- ✅ `enrollments` - 활성 미션 관리
- ✅ `missions` - 일일 미션 관리
- ✅ `points_transactions` - 포인트 거래 내역
- ✅ `reports` - 신고 관리
- ✅ `notifications` - 알림 관리
- ✅ `admin_dashboard` - 관리자 통계

### 2. 보안 규칙 테스트

Firebase Console의 Rules Playground에서 테스트:

```javascript
// 테스터가 자신의 신청만 볼 수 있는지 확인
match /applications/test_app_001 {
  allow read: if request.auth.uid == "tester_001";
}
```

### 3. 인덱스 상태 확인

Firebase Console > Firestore > 인덱스에서:
- 모든 인덱스가 "사용 가능" 상태인지 확인
- 빌드 중인 인덱스가 완료될 때까지 대기

### 4. 성능 테스트

```dart
// 테스트 스크립트 실행
flutter run scripts/test_optimized_database.dart
```

## 📊 모니터링 및 최적화

### 1. 쿼리 성능 모니터링

Firebase Console > Performance에서:
- 평균 응답 시간 < 2초 유지
- 읽기/쓰기 작업 수 모니터링
- 인덱스 사용률 확인

### 2. 비용 최적화

- 불필요한 실시간 리스너 제거
- 페이지네이션으로 대량 데이터 처리
- 캐싱 적극 활용 (admin_dashboard/stats)

### 3. 정기 유지보수

```dart
// 월별 통계 업데이트 (Cloud Functions)
exports.updateMonthlyStats = functions.pubsub
  .schedule('0 1 1 * *') // 매월 1일 01:00
  .onRun(async (context) => {
    // 통계 집계 및 캐싱
  });
```

## 🚨 문제 해결

### 일반적인 문제들

#### 1. 권한 오류
```
Error: Missing or insufficient permissions
```
**해결**: Firebase Console에서 보안 규칙 확인 및 수정

#### 2. 인덱스 부족
```
Error: The query requires an index
```
**해결**: Firebase Console에서 제안된 인덱스 생성

#### 3. 마이그레이션 오류
```
Error: Document already exists
```
**해결**: 중복 확인 로직 추가 또는 upsert 패턴 사용

### 복구 절차

1. **데이터 손실 시**: 백업에서 복원
2. **성능 저하 시**: 인덱스 및 쿼리 최적화
3. **권한 문제 시**: 보안 규칙 재배포

## 📞 지원

문제가 발생하면:
1. 이 가이드의 문제 해결 섹션 확인
2. Firebase Console의 로그 확인
3. 개발팀에 문의

---

**최종 업데이트**: 2024년 12월
**문서 버전**: v1.0