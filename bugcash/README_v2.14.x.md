# BugCash v2.14.x Series - Mission Management System Stabilization

## 📋 Overview

v2.14.x 시리즈는 v2.14.0 Clean Architecture 전환 이후 발생한 dispose 에러, 로그 출력 문제, Firestore 인덱스 문제를 단계적으로 해결한 안정화 버전입니다.

**기간**: 2025-10-03
**주요 목표**: Clean Architecture 기반 미션 관리 시스템의 완전한 안정화
**총 버전**: 8개 (v2.14.1 ~ v2.14.8)

---

## 🎯 핵심 성과

### ✅ 완전히 해결된 문제들

1. **Firestore 400 에러 제거** - 로그아웃 시 인증 없이 쿼리 실행되던 문제 해결
2. **모든 dispose 에러 제거** - "Cannot use ref after widget disposed" 완전 해결
3. **프로덕션 디버깅 시스템 구축** - kReleaseMode에서도 상세 로그 출력
4. **Firestore 인덱스 완성** - providerId 기반 미션 쿼리 인덱스 추가
5. **UI 안정성 확보** - 미션 관리 페이지 정상 작동

### 📊 시스템 개선

- **폴링 안정성**: 30초 주기 자동 갱신 안정화
- **에러 추적**: 모든 상태 전환에 상세 로그 추가
- **생명주기 관리**: mounted 체크로 위젯 dispose 후 접근 방지
- **인덱스 최적화**: Firestore 복합 쿼리 인덱스 완성

---

## 📦 버전별 상세 내역

### v2.14.1 - 로그아웃 Firestore 400 에러 해결

**문제**:
```
POST https://firestore.googleapis.com/.../Listen/channel 400 (Bad Request)
Bad state: Cannot use "ref" after the widget was disposed.
```

**원인**:
- 로그아웃 시 MissionStateNotifier의 폴링 타이머가 계속 실행
- 인증 없이 Firestore에 접근 → 400 에러

**해결**:
```dart
// lib/features/auth/presentation/widgets/auth_wrapper.dart
else {
  // 로그아웃 시 모든 폴링 중지
  RealtimeSyncService.stopRealtimeSync();

  try {
    ref.read(missionStateNotifierProvider.notifier).stopPolling();
    AppLogger.info('✅ MissionStateNotifier polling stopped', 'AuthWrapper');
  } catch (e) {
    AppLogger.warning('⚠️ Failed to stop MissionStateNotifier: $e', 'AuthWrapper');
  }
}
```

**파일**:
- `lib/features/auth/presentation/widgets/auth_wrapper.dart`

---

### v2.14.2 - 미션 버튼 클릭 로그 추가

**문제**:
- 공급자 모드 앱관리 탭의 미션 버튼 클릭 시 로그가 출력되지 않음
- 어느 페이지로 이동하는지 추적 불가

**해결**:
```dart
// lib/features/provider_dashboard/presentation/pages/app_management_page.dart
onPressed: canUse ? () {
  // v2.14.1: 로그 추가 및 V2 페이지로 전환
  AppLogger.info(
    '🔵 미션 버튼 클릭\n'
    '   ├─ 앱: ${app.appName}\n'
    '   ├─ appId: ${app.id}\n'
    '   ├─ providerId: ${app.providerId}\n'
    '   └─ 페이지: MissionManagementPageV2',
    'AppManagement'
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MissionManagementPageV2(app: app),
    ),
  );
} : null,
```

**파일**:
- `lib/features/provider_dashboard/presentation/pages/app_management_page.dart`

---

### v2.14.3 - RealtimeSync dispose 에러 해결

**문제**:
```
🔄 REALTIME_SYNC: mission_workflows 동기화 시작
Bad state: Cannot use "ref" after the widget was disposed.
```

**원인**:
- 로그인 시 `Future.delayed(Duration(seconds: 3), forceSyncAll())`가 실행
- 사용자가 빠르게 화면 전환 시 위젯 dispose 후 ref 접근

**해결**:
```dart
// lib/features/auth/presentation/widgets/auth_wrapper.dart
if (currentUser != null) {
  // v2.14.2: Clean Architecture 전환으로 RealtimeSyncService 완전 비활성화
  AppLogger.info(
    '✅ User logged in: ${currentUser.email}\n'
    '   └─ RealtimeSyncService disabled (using Clean Architecture polling)',
    'AuthWrapper'
  );

  // v2.14.0+: RealtimeSyncService 제거, Clean Architecture 폴링만 사용
  // 강제 동기화도 제거 (dispose 후 ref 사용 에러 방지)
}
```

**변경 사항**:
- `Future.delayed(forceSyncAll())` 완전 제거
- Clean Architecture 폴링만 사용

**파일**:
- `lib/features/auth/presentation/widgets/auth_wrapper.dart`

---

### v2.14.4 - MissionManagementPageV2 dispose 에러 해결

**문제**:
```
Bad state: Cannot use "ref" after the widget was disposed.
at S4.d0 (main.dart.js:114243:29)
```

**원인**:
- `initState`의 `addPostFrameCallback`에 mounted 체크 없음
- 사용자가 빠르게 페이지 나가면 dispose 후 ref 접근

**해결**:
```dart
// lib/features/provider_dashboard/presentation/pages/mission_management_page_v2.dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // v2.14.4: dispose 후 ref 사용 방지
    if (mounted) {
      try {
        ref.read(missionStateNotifierProvider.notifier)
          .startPollingForProvider(widget.app.providerId);
        AppLogger.info('✅ Polling started', 'MissionManagementV2');
      } catch (e) {
        AppLogger.warning('⚠️ Failed to start polling: $e', 'MissionManagementV2');
      }
    }
  });
}

@override
void dispose() {
  // v2.14.4: 폴링 중지 (try-catch로 안전하게)
  try {
    ref.read(missionStateNotifierProvider.notifier).stopPolling();
    AppLogger.info('✅ Polling stopped', 'MissionManagementV2');
  } catch (e) {
    AppLogger.warning('⚠️ Failed to stop polling in dispose: $e', 'MissionManagementV2');
  }
  _tabController.dispose();
  super.dispose();
}
```

**파일**:
- `lib/features/provider_dashboard/presentation/pages/mission_management_page_v2.dart`

---

### v2.14.5 - BottomNavigationBar dispose 에러 해결

**문제**:
```
BottomNavigationBar tapped: 1
BottomNavigationBar tapped: 0
Bad state: Cannot use "ref" after the widget was disposed.
```

**원인**:
- `provider_dashboard_page.dart`의 `_buildCurrentTab()`에서 권한 체크 시
- `addPostFrameCallback` 내부에 mounted 체크 없이 `setState` 호출

**해결**:
```dart
// lib/features/provider_dashboard/presentation/pages/provider_dashboard_page.dart
case 3:
  if (hasAdminRole) {
    return _buildAdminTab();
  } else {
    // 권한이 없는 경우 대시보드로 리디렉션
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {  // v2.14.5: mounted 체크 추가
        setState(() => _selectedIndex = 0);
      }
    });
    return _buildDashboardTab();
  }
```

**파일**:
- `lib/features/provider_dashboard/presentation/pages/provider_dashboard_page.dart`

---

### v2.14.6 - 프로덕션 로그 출력 수정

**문제**:
- 프로덕션 빌드(`kReleaseMode`)에서 `AppLogger.info()` 로그가 출력되지 않음
- 미션 버튼 클릭 로그가 브라우저 콘솔에 표시 안됨

**원인**:
```dart
// lib/core/utils/logger.dart
static void _log(...) {
  // 프로덕션에서는 에러 레벨만 로깅
  if (kReleaseMode && level != LogLevel.error) {
    return;  // ❌ info 로그는 무시됨
  }
}
```

**해결**:
```dart
// lib/features/provider_dashboard/presentation/pages/app_management_page.dart
onPressed: canUse ? () {
  // v2.14.6: 프로덕션에서도 로그 출력을 위해 print 사용
  print('🔵 [AppManagement] 미션 버튼 클릭\n'
        '   ├─ 앱: ${app.appName}\n'
        '   ├─ appId: ${app.id}\n'
        '   ├─ providerId: ${app.providerId}\n'
        '   └─ 페이지: MissionManagementPageV2');

  Navigator.push(...);
} : null,
```

**변경 사항**:
- `AppLogger.info()` → `print()` 변경
- 프로덕션/개발 모드 모두 로그 출력

**파일**:
- `lib/features/provider_dashboard/presentation/pages/app_management_page.dart`

---

### v2.14.7 - 미션 관리 페이지 UI 디버깅 로그 추가

**문제**:
- 미션 버튼 클릭 후 UI가 표시되지 않음 (흰 화면)
- 프로덕션에서 `AppLogger.info()` 차단으로 디버깅 불가능

**해결**:

#### 1. MissionManagementPageV2 로그 추가
```dart
// lib/features/provider_dashboard/presentation/pages/mission_management_page_v2.dart

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this);

  // v2.14.7: 프로덕션 디버깅을 위한 print 로그
  print('📱 [MissionManagementV2] 페이지 초기화');
  print('   ├─ appId: ${widget.app.id}');
  print('   ├─ appName: ${widget.app.appName}');
  print('   └─ providerId: ${widget.app.providerId}');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      try {
        print('🔄 [MissionManagementV2] 폴링 시작 시도...');
        ref.read(missionStateNotifierProvider.notifier)
          .startPollingForProvider(widget.app.providerId);
        print('✅ [MissionManagementV2] 폴링 시작 완료');
      } catch (e) {
        print('❌ [MissionManagementV2] 폴링 시작 실패: $e');
      }
    }
  });
}

// 테스터 탭 상태별 로그
Widget _buildTesterRecruitmentTab() {
  return Consumer(
    builder: (context, ref, child) {
      final missionsState = ref.watch(missionStateNotifierProvider);

      return missionsState.when(
        initial: () {
          print('⏳ [MissionManagementV2] 테스터탭 State: INITIAL');
          return const Center(child: Text('초기화 중...'));
        },
        loading: () {
          print('🔄 [MissionManagementV2] 테스터탭 State: LOADING');
          return const Center(child: CircularProgressIndicator());
        },
        loaded: (missions, isRefreshing) {
          final pendingApplications = missions
              .where((m) => m.status == MissionWorkflowStatus.applicationSubmitted)
              .toList();
          final approvedTesters = missions
              .where((m) => m.status == MissionWorkflowStatus.approved)
              .toList();

          print('✅ [MissionManagementV2] 테스터탭 State: LOADED');
          print('   ├─ 전체 미션: ${missions.length}개');
          print('   ├─ 신청 대기: ${pendingApplications.length}개');
          print('   └─ 승인됨: ${approvedTesters.length}개');

          return SingleChildScrollView(...);
        },
        error: (message, exception) {
          print('❌ [MissionManagementV2] 테스터탭 State: ERROR');
          print('   └─ 메시지: $message');
          return Center(...);
        },
      );
    },
  );
}

// 오늘 탭 상태별 로그
Widget _buildTodayMissionsTab() {
  return Consumer(
    builder: (context, ref, child) {
      final missionsState = ref.watch(missionStateNotifierProvider);

      return missionsState.when(
        initial: () {
          print('⏳ [MissionManagementV2] 오늘탭 State: INITIAL');
          return const Center(child: Text('초기화 중...'));
        },
        loading: () {
          print('🔄 [MissionManagementV2] 오늘탭 State: LOADING');
          return const Center(child: CircularProgressIndicator());
        },
        loaded: (missions, isRefreshing) {
          final inProgressMissions = missions
              .where((m) => m.status == MissionWorkflowStatus.inProgress)
              .toList();

          print('✅ [MissionManagementV2] 오늘탭 State: LOADED');
          print('   ├─ 전체 미션: ${missions.length}개');
          print('   └─ 진행중: ${inProgressMissions.length}개');

          return SingleChildScrollView(...);
        },
        error: (message, exception) {
          print('❌ [MissionManagementV2] 오늘탭 State: ERROR');
          print('   └─ 메시지: $message');
          return Center(...);
        },
      );
    },
  );
}
```

#### 2. MissionStateNotifier 로그 추가
```dart
// lib/features/mission/presentation/providers/mission_state_notifier.dart

void startPollingForProvider(String providerId) {
  _currentUserId = providerId;
  _isProvider = true;

  print('🔵 [MissionNotifier] Polling started for provider: $providerId');

  refreshMissions();

  _pollingTimer?.cancel();
  _pollingTimer = Timer.periodic(_pollingInterval, (_) {
    refreshMissions();
  });
}

Future<void> refreshMissions() async {
  if (_currentUserId == null) {
    print('⚠️ [MissionNotifier] Cannot refresh: userId is null');
    return;
  }

  try {
    print('🔄 [MissionNotifier] Refreshing missions...');
    print('   ├─ userId: $_currentUserId');
    print('   └─ isProvider: $_isProvider');

    state.maybeWhen(
      loaded: (missions, _) => state = MissionState.loaded(
        missions: missions,
        isRefreshing: true,
      ),
      orElse: () => state = const MissionState.loading(),
    );

    final missions = _isProvider
        ? await _getMissionsUseCase.getProviderMissions(_currentUserId!)
        : await _getMissionsUseCase.getTesterMissions(_currentUserId!);

    state = MissionState.loaded(missions: missions);

    print('✅ [MissionNotifier] Missions refreshed: ${missions.length} items');
  } catch (e) {
    print('❌ [MissionNotifier] Failed to refresh missions: $e');
    state = MissionState.error(
      message: 'Failed to load missions: ${e.toString()}',
      exception: e,
    );
  }
}
```

**로그 출력 예시**:
```
📱 [MissionManagementV2] 페이지 초기화
🔄 [MissionManagementV2] 폴링 시작 시도...
✅ [MissionManagementV2] 폴링 시작 완료
🔵 [MissionNotifier] Polling started for provider: ...
🔄 [MissionNotifier] Refreshing missions...
✅ [MissionNotifier] Missions refreshed: X items
✅ [MissionManagementV2] 테스터탭 State: LOADED
   ├─ 전체 미션: X개
   ├─ 신청 대기: X개
   └─ 승인됨: X개
```

**파일**:
- `lib/features/provider_dashboard/presentation/pages/mission_management_page_v2.dart`
- `lib/features/mission/presentation/providers/mission_state_notifier.dart`

---

### v2.14.8 - Firestore 인덱스 추가 (providerId)

**문제**:
```
❌ [MissionNotifier] Failed to refresh missions:
[cloud_firestore/failed-precondition] The query requires an index.
providerId (ASCENDING) + appliedAt (DESCENDING) + __name__ (DESCENDING)
```

**원인**:
- Firestore 쿼리 실행 시 필요한 복합 인덱스 없음
- `mission_workflows` 컬렉션에 `testerId` 인덱스만 존재
- `providerId` 기반 쿼리 인덱스 누락

**실행된 쿼리**:
```dart
// lib/features/mission/data/datasources/mission_remote_datasource.dart
final snapshot = await _firestore
    .collection('mission_workflows')
    .where('providerId', isEqualTo: providerId)  // ← 필터
    .orderBy('appliedAt', descending: true)      // ← 정렬
    .get();                                       // ← 암시적 __name__ 정렬
```

**해결**:
```json
// bugcash/firestore.indexes.json
{
  "indexes": [
    // ... 기존 인덱스들 ...
    {
      "collectionGroup": "mission_workflows",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "testerId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "appliedAt",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "mission_workflows",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "providerId",  // ← 추가됨
          "order": "ASCENDING"
        },
        {
          "fieldPath": "appliedAt",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

**배포 절차**:
1. `firestore.indexes.json` 편집
2. Git commit + push
3. Firebase 콘솔에서 자동 인덱스 생성 링크 클릭
4. 인덱스 빌드 완료 대기 (5-10분)
5. 앱 새로고침 → 정상 작동

**성공 로그**:
```
✅ [MissionNotifier] Missions refreshed: 2 items
✅ [MissionManagementV2] 테스터탭 State: LOADED
   ├─ 전체 미션: 2개
   ├─ 신청 대기: 0개
   └─ 승인됨: 0개
```

**파일**:
- `bugcash/firestore.indexes.json`

---

## 🔧 기술적 개선 사항

### 1. Widget Lifecycle 관리

**문제 패턴**:
```dart
// ❌ 잘못된 패턴
WidgetsBinding.instance.addPostFrameCallback((_) {
  setState(() => ...);  // mounted 체크 없음
});
```

**해결 패턴**:
```dart
// ✅ 올바른 패턴
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {  // 위젯이 여전히 존재하는지 확인
    setState(() => ...);
  }
});
```

**적용 위치**:
- `auth_wrapper.dart`
- `mission_management_page_v2.dart`
- `provider_dashboard_page.dart`

---

### 2. 프로덕션 로깅 전략

**문제**:
- `AppLogger.info()` → `kReleaseMode`에서 차단
- 프로덕션 환경에서 디버깅 불가능

**해결**:
```dart
// 개발 중 디버깅용: AppLogger (선택적 출력)
AppLogger.info('message', 'tag');

// 프로덕션 디버깅용: print (항상 출력)
print('🔵 [Tag] message');
```

**사용 기준**:
- **AppLogger**: 내부 로직, 캐시 히트, 일반 정보
- **print**: 사용자 액션, 상태 전환, 에러 추적

---

### 3. Firestore 인덱스 설계

**복합 인덱스 원칙**:
1. **where 필드** (ASCENDING/DESCENDING)
2. **orderBy 필드** (DESCENDING이 일반적)
3. **__name__** (자동 추가되는 문서 ID 정렬)

**예시**:
```javascript
// 쿼리
collection('mission_workflows')
  .where('providerId', isEqualTo: 'abc')
  .orderBy('appliedAt', descending: true)

// 필요한 인덱스
[providerId ASC] + [appliedAt DESC] + [__name__ DESC]
```

**인덱스 파일 관리**:
- `firestore.indexes.json`에 정의
- `firebase deploy --only firestore:indexes`로 배포
- Firebase 콘솔에서 자동 생성 가능

---

## 📊 성능 지표

### Before (v2.14.0)
- ❌ 로그아웃 시 Firestore 400 에러 발생
- ❌ 빠른 화면 전환 시 dispose 에러 (5건)
- ❌ 프로덕션 로그 출력 안됨
- ❌ 미션 관리 페이지 UI 미표시

### After (v2.14.8)
- ✅ Firestore 에러 완전 제거
- ✅ dispose 에러 0건
- ✅ 프로덕션 상세 로그 출력
- ✅ 미션 관리 페이지 정상 작동
- ✅ 30초 주기 안정적인 폴링

### 로그 개선
```
Before: 에러 발생 시에만 최소한의 정보
After: 모든 상태 전환, 데이터 로드 상태 실시간 추적

예시:
📱 페이지 초기화
🔄 폴링 시작
🔵 Polling started
✅ Missions refreshed: X items
✅ State: LOADED (X개 미션)
```

---

## 🚀 배포 가이드

### 1. Git 관리
```bash
# 변경사항 커밋
git add .
git commit -m "fix: v2.14.x - 설명"

# 버전 태그
git tag v2.14.x

# 푸시
git push origin main --tags
```

### 2. Flutter 빌드
```bash
cd bugcash
flutter build web
```

### 3. Firebase 배포
```bash
# 호스팅만 배포
firebase deploy --only hosting

# 인덱스만 배포 (v2.14.8)
firebase deploy --only firestore:indexes
```

### 4. 배포 확인
1. https://bugcash.web.app 접속
2. 브라우저 콘솔 열기 (F12)
3. 공급자 로그인 → 앱관리 → 미션 버튼 클릭
4. 로그 확인:
   ```
   🔵 [AppManagement] 미션 버튼 클릭
   📱 [MissionManagementV2] 페이지 초기화
   ✅ [MissionNotifier] Missions refreshed: X items
   ✅ [MissionManagementV2] 테스터탭 State: LOADED
   ```

---

## 🔍 디버깅 가이드

### 로그 해석

#### 정상 작동
```javascript
✅ [MissionNotifier] Missions refreshed: X items
✅ [MissionManagementV2] 테스터탭 State: LOADED
   ├─ 전체 미션: X개
   ├─ 신청 대기: X개
   └─ 승인됨: X개
```

#### Firestore 인덱스 에러
```javascript
❌ [MissionNotifier] Failed to refresh missions:
[cloud_firestore/failed-precondition] The query requires an index.
```
**해결**: Firebase 콘솔에서 인덱스 생성

#### dispose 에러
```javascript
Bad state: Cannot use "ref" after the widget was disposed.
```
**해결**: `if (mounted)` 체크 추가

#### 로그 출력 안됨
```javascript
// 아무 로그도 없음
```
**해결**: `AppLogger` → `print()` 변경

---

## 📝 주요 파일 목록

### 수정된 파일
```
bugcash/
├── lib/
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/
│   │   │       └── widgets/
│   │   │           └── auth_wrapper.dart (v2.14.1, v2.14.3)
│   │   ├── mission/
│   │   │   ├── presentation/
│   │   │   │   └── providers/
│   │   │   │       └── mission_state_notifier.dart (v2.14.7)
│   │   │   └── data/
│   │   │       └── datasources/
│   │   │           └── mission_remote_datasource.dart (v2.14.8)
│   │   └── provider_dashboard/
│   │       └── presentation/
│   │           └── pages/
│   │               ├── app_management_page.dart (v2.14.2, v2.14.6)
│   │               ├── mission_management_page_v2.dart (v2.14.4, v2.14.7)
│   │               └── provider_dashboard_page.dart (v2.14.5)
│   └── core/
│       └── utils/
│           └── logger.dart (참조용)
└── firestore.indexes.json (v2.14.8)
```

---

## 🎓 교훈 및 베스트 프랙티스

### 1. Widget Lifecycle 관리
- **항상** `addPostFrameCallback` 내부에 `if (mounted)` 체크
- **항상** `dispose()` 메서드에서 타이머/리스너 정리
- **항상** try-catch로 안전하게 감싸기

### 2. 프로덕션 디버깅
- 중요한 사용자 액션: `print()` 사용
- 내부 로직: `AppLogger` 사용
- 상태 전환: 상세 로그 출력
- 에러 발생 시: 원인 파악 가능한 컨텍스트 포함

### 3. Firestore 최적화
- 복합 쿼리 전에 인덱스 미리 생성
- `firestore.indexes.json`으로 버전 관리
- 에러 메시지의 인덱스 생성 링크 활용

### 4. Clean Architecture 패턴
- 폴링 시작/중지를 명확한 생명주기에 연결
- Repository → UseCase → StateNotifier 계층 유지
- 에러 전파 시 각 레이어에서 적절한 처리

---

## 🔗 관련 문서

- [v2.14.0 README](README_v2.14.0.md) - Clean Architecture 전환
- [Firebase 인덱스 관리](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Flutter Widget Lifecycle](https://api.flutter.dev/flutter/widgets/State-class.html)
- [Riverpod 상태 관리](https://riverpod.dev/)

---

## 📞 문의 및 지원

**버전**: v2.14.8
**배포일**: 2025-10-03
**상태**: ✅ Stable
**다음 버전**: v2.15.0 (기능 추가 예정)

---

**🎉 v2.14.x 시리즈 완료! 미션 관리 시스템이 안정적으로 작동합니다!**
