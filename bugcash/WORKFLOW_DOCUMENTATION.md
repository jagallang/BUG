# BUGS 플랫폼 - 완전한 미션 워크플로우 시스템 구현 문서

## 📋 개요

BUGS 플랫폼의 완전한 프로젝트-미션 워크플로우 시스템이 구현되었습니다. 공급자가 프로젝트를 등록하면 관리자가 승인하고, 승인된 프로젝트를 테스터가 미션 탭에서 확인할 수 있는 전체 프로세스가 완성되었습니다.

## 🏗️ 시스템 아키텍처

### 핵심 컬렉션 구조
```
Firebase Firestore Collections:
├── projects/           # 프로젝트 정보 (새로운 최적화된 구조)
├── applications/       # 테스터 신청 정보
├── enrollments/        # 활성 미션 등록 정보
├── missions/           # 일일 미션 데이터
├── users/             # 사용자 정보
└── notifications/     # 알림 시스템
```

### 워크플로우 상태 관리
```
Project Status Flow:
pending (공급자 등록) → open (관리자 승인) → closed (완료)

Mission Status Flow:
신청 (application) → 테스트 (testing) → 승인요청 (approval_request) → 승인 (approved)
```

## 🎯 구현된 주요 기능

### 1. 관리자 대시보드 (AdminDashboardPage)
**파일**: `lib/features/admin/presentation/pages/admin_dashboard_page.dart`

#### 주요 기능:
- 6개 메뉴 완전 구현: Dashboard/Projects/Users/Finance/Reports/Settings
- 실시간 프로젝트 목록 표시
- 프로젝트 승인/거부 기능
- 상태별 탭 필터링 (승인대기/승인됨/거부됨/전체)

#### 핵심 코드:
```dart
// 실시간 프로젝트 스트리밍
Widget _buildProjectsList(String status) {
  return StreamBuilder<QuerySnapshot>(
    stream: status == 'all'
        ? FirebaseFirestore.instance.collection('projects').snapshots()
        : FirebaseFirestore.instance
            .collection('projects')
            .where('status', isEqualTo: status)
            .snapshots(),
    builder: (context, snapshot) {
      // 프로젝트 목록 렌더링
    },
  );
}

// 프로젝트 승인 기능
void _approveProject(String projectId) async {
  try {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
      'status': 'open',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': 'admin',
    });
  } catch (e) {
    // 에러 처리
  }
}
```

### 2. 공급자 앱 관리 (AppManagementPage)
**파일**: `lib/features/provider_dashboard/presentation/pages/app_management_page.dart`

#### 주요 기능:
- 등록한 프로젝트 상태 실시간 확인
- PRD 기반 상태 뱃지 표시
- 프로젝트 상세 정보 관리

#### 핵심 코드:
```dart
// 상태 뱃지 렌더링
Widget _buildStatusBadge(String status) {
  Color color;
  String text;
  IconData icon;
  switch (status) {
    case 'pending':
      color = Colors.orange[600]!;
      text = '승인 대기';
      icon = Icons.schedule;
      break;
    case 'open':
      color = Colors.green[600]!;
      text = '승인됨';
      icon = Icons.check_circle;
      break;
    case 'rejected':
      color = Colors.red[600]!;
      text = '거부됨';
      icon = Icons.cancel;
      break;
    default:
      color = Colors.grey[600]!;
      text = '알 수 없음';
      icon = Icons.help;
  }

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 4.w),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
```

### 3. 테스터 대시보드 최적화 (TesterDashboardProvider)
**파일**: `lib/features/tester_dashboard/presentation/providers/tester_dashboard_provider.dart`

#### 주요 변경사항:
- 새로운 `projects` 컬렉션 사용
- 승인된 프로젝트만 표시 (`status == 'open'`)
- 실시간 데이터 동기화

#### 핵심 코드:
```dart
// 승인된 프로젝트만 조회
Future<List<MissionCard>> _getAvailableMissionsFromFirestore() async {
  final projectsSnapshot = await FirebaseFirestore.instance
      .collection('projects')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .get();

  final missions = <MissionCard>[];
  for (final doc in projectsSnapshot.docs) {
    final data = doc.data();
    missions.add(_createMissionCardFromProject(doc.id, data));
  }
  return missions;
}
```

## 🔥 Firebase 백엔드 구성

### Firestore 인덱스 구성
**파일**: `firestore.indexes.json`

#### 주요 인덱스:
```json
{
  "collectionGroup": "projects",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
},
{
  "collectionGroup": "applications",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "testerId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

### Firestore 보안 규칙
**파일**: `firestore.rules`

#### 핵심 규칙:
```javascript
// 프로젝트 관리
match /projects/{projectId} {
  // 읽기: 모든 인증된 사용자 (상태가 'open'인 경우), 본인 프로젝트, 관리자
  allow read: if isAuthenticated() &&
                 (resource.data.status == 'open' ||
                  isProjectProvider(projectId) ||
                  isAdmin());

  // 생성: 인증된 사용자 (임시로 관대하게 설정)
  allow create: if isAuthenticated() &&
                request.resource.data.providerId == request.auth.uid;

  // 수정: 본인 프로젝트만 수정 가능 (status는 관리자만)
  allow update: if (isProjectProvider(projectId) &&
                   !('status' in request.resource.data.diff(resource.data).affectedKeys())) ||
                  isAdmin();
}

// 신청 관리
match /applications/{applicationId} {
  // 읽기: 신청자 본인, 해당 프로젝트 공급자, 관리자
  allow read: if isAuthenticated() &&
                 (request.auth.uid == resource.data.testerId ||
                  isProjectProvider(resource.data.projectId) ||
                  isAdmin());

  // 생성: 테스터만 가능 (본인 신청만)
  allow create: if isTester() &&
                request.resource.data.testerId == request.auth.uid;
}
```

## 📱 사용자 인터페이스

### 관리자 대시보드 UI
- **네비게이션**: 6개 메뉴 사이드바
- **프로젝트 관리**: 상태별 탭 (승인대기/승인됨/거부됨/전체)
- **액션 버튼**: 승인/거부/상세보기
- **실시간 업데이트**: StreamBuilder 기반

### 공급자 대시보드 UI
- **상태 뱃지**: 색상별 상태 표시 (주황/초록/빨강)
- **프로젝트 카드**: 상세 정보와 상태 표시
- **실시간 모니터링**: 등록한 프로젝트 상태 추적

### 테스터 대시보드 UI
- **미션 카드**: 승인된 프로젝트만 표시
- **필터링**: 플랫폼, 난이도, 리워드별 정렬
- **신청 기능**: 관심 프로젝트 신청

## 🔄 완전한 워크플로우

### 1. 프로젝트 등록 단계
```
공급자 → 프로젝트 등록 → Firestore 'projects' 컬렉션
Status: 'pending'
```

### 2. 관리자 검토 단계
```
관리자 → 대시보드 확인 → 승인/거부 결정
Status: 'pending' → 'open' or 'rejected'
```

### 3. 테스터 참여 단계
```
테스터 → 미션 탭 확인 → 승인된 프로젝트 신청
Status: 'open' projects 만 표시
```

### 4. 미션 수행 단계
```
테스터 → 미션 수행 → 일일 리포트 제출
Daily missions with status tracking
```

## 🛠️ 기술 스택

### Frontend
- **Flutter Web**: 크로스 플랫폼 웹 애플리케이션
- **Flutter Riverpod**: 상태 관리
- **Flutter ScreenUtil**: 반응형 UI

### Backend
- **Firebase Firestore**: NoSQL 데이터베이스
- **Firebase Auth**: 사용자 인증
- **Firebase Functions**: 서버리스 로직 (예정)

### 개발 도구
- **Firebase CLI**: 배포 및 관리
- **Flutter DevTools**: 디버깅
- **VS Code**: 개발 환경

## 📊 데이터 구조

### Projects 컬렉션
```typescript
interface Project {
  id: string;
  appName: string;
  description: string;
  providerId: string;
  providerName: string;
  status: 'pending' | 'open' | 'rejected' | 'closed';
  maxTesters: number;
  testPeriodDays: number;
  rewards: {
    baseReward: number;
    bonusReward: number;
  };
  requirements: {
    platforms: string[];
    minAge: number;
    maxAge: number;
  };
  createdAt: Timestamp;
  updatedAt: Timestamp;
  approvedAt?: Timestamp;
  approvedBy?: string;
}
```

### Applications 컬렉션
```typescript
interface Application {
  id: string;
  projectId: string;
  testerId: string;
  testerName: string;
  testerEmail: string;
  status: 'pending' | 'approved' | 'rejected';
  experience: string;
  motivation: string;
  createdAt: Timestamp;
  processedAt?: Timestamp;
  processedBy?: string;
  feedback?: string;
}
```

## 🚀 배포 및 운영

### Firebase 배포 명령어
```bash
# Firestore 규칙과 인덱스 배포
firebase deploy --only firestore

# 전체 프로젝트 배포
firebase deploy
```

### Flutter 빌드 및 실행
```bash
# 개발 서버 실행
flutter run -d chrome

# 프로덕션 빌드
flutter build web

# 분석 및 테스트
flutter analyze
flutter test
```

## 🔍 모니터링 및 디버깅

### Firebase 콘솔
- **Firestore**: https://console.firebase.google.com/project/bugcash/firestore
- **Authentication**: 사용자 관리
- **Functions**: 서버리스 로직 모니터링

### Flutter DevTools
- **성능 모니터링**: 위젯 트리 분석
- **네트워크 요청**: Firebase 호출 추적
- **상태 관리**: Riverpod 상태 확인

## ✅ 테스트 시나리오

### 1. 관리자 승인 워크플로우 테스트
1. 공급자로 로그인 → 프로젝트 등록
2. 관리자로 로그인 → 대시보드에서 승인
3. 테스터로 로그인 → 미션 탭에서 확인

### 2. 실시간 업데이트 테스트
1. 여러 브라우저 탭에서 동시 접속
2. 한 탭에서 상태 변경
3. 다른 탭에서 실시간 반영 확인

### 3. 권한 관리 테스트
1. 역할별 접근 권한 확인
2. Firestore 규칙 검증
3. 데이터 보안 테스트

## 📈 향후 개선 계획

### 1. 성능 최적화
- [ ] 페이지네이션 구현
- [ ] 이미지 최적화
- [ ] 캐싱 전략 적용

### 2. 기능 확장
- [ ] 실시간 알림 시스템
- [ ] 고급 필터링 옵션
- [ ] 통계 및 분석 대시보드

### 3. 사용자 경험 개선
- [ ] 로딩 상태 개선
- [ ] 에러 처리 강화
- [ ] 접근성 향상

---

## 📞 문의 및 지원

기술적 문제나 기능 개선 제안이 있으시면 개발팀에 문의해주세요.

**완성된 기능**: ✅ 관리자 대시보드 백엔드 연동 완료
**현재 상태**: 🚀 프로덕션 준비 완료
**다음 단계**: 📊 사용자 피드백 수집 및 성능 모니터링