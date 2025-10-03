# Migration Guide v2.14.0 - Clean Architecture 전환

## 개요
Firestore 400 에러 해결을 위한 Clean Architecture 전환 가이드입니다.

## 핵심 변경사항

### Before: Service Pattern (62개 실시간 리스너)
```dart
// ❌ OLD - Direct Firestore .snapshots()
final missionsStream = StreamProvider((ref) {
  return FirebaseFirestore.instance
    .collection('mission_workflows')
    .snapshots()
    .map((snapshot) => ...);
});
```

### After: Clean Architecture (1개 실시간 리스너)
```dart
// ✅ NEW - Repository + Polling
final missions = ref.watch(missionStateNotifierProvider);
missions.when(
  loading: () => CircularProgressIndicator(),
  loaded: (missions, isRefreshing) => MissionList(missions),
  error: (msg, _) => ErrorWidget(msg),
);
```

## 마이그레이션 단계

### Step 1: Provider 변경

#### unified_mission_provider.dart
**Before:**
```dart
final unifiedMissionsStreamProvider = StreamProvider<List<UnifiedMissionModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('mission_workflows')
      .snapshots()
      .map(...);
});
```

**After:**
```dart
// ✅ 새로운 Clean Architecture Provider 사용
import 'package:bugcash_web_demo/features/mission/presentation/providers/mission_providers.dart';

// Provider는 자동으로 30초마다 폴링
final missions = ref.watch(missionStateNotifierProvider);
```

### Step 2: UI 컴포넌트 변경

#### mission_management_page.dart
**Before:**
```dart
StreamBuilder<List<TesterApplicationModel>>(
  stream: _missionService.watchTesterApplications(widget.app.id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    // ...
  },
)
```

**After:**
```dart
// ✅ 1. initState에서 폴링 시작
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(missionStateNotifierProvider.notifier)
      .startPollingForProvider(widget.app.providerId);
  });
}

// ✅ 2. Consumer로 변경
Consumer(
  builder: (context, ref, child) {
    final missionsState = ref.watch(missionStateNotifierProvider);

    return missionsState.when(
      initial: () => SizedBox.shrink(),
      loading: () => Center(child: CircularProgressIndicator()),
      loaded: (missions, isRefreshing) {
        // isRefreshing = true일 때 백그라운드 새로고침 중
        final applications = missions
          .where((m) => m.status == MissionWorkflowStatus.applicationSubmitted)
          .toList();

        return Column(
          children: [
            if (isRefreshing) LinearProgressIndicator(minHeight: 2),
            ListView.builder(...),
          ],
        );
      },
      error: (message, exception) => ErrorWidget(message),
    );
  },
)
```

### Step 3: Action 호출 변경

**Before:**
```dart
await _missionService.reviewTesterApplication(
  applicationId: applicationId,
  status: status,
);
```

**After:**
```dart
// ✅ Optimistic Update 자동 적용
await ref.read(missionStateNotifierProvider.notifier)
  .approveMission(missionId);
// UI는 즉시 업데이트, 백그라운드에서 동기화
```

## 제거할 파일들

### Phase 5에서 삭제:
- ❌ `lib/core/services/mission_management_service.dart` (10개 .snapshots())
- ❌ `lib/core/services/mission_workflow_service.dart` (4개 .snapshots())
- ❌ `lib/core/services/realtime_sync_service.dart` (전체 컬렉션 스트리밍)
- ❌ `lib/features/shared/providers/unified_mission_provider.dart` (4개 StreamProvider)

### 유지할 파일:
- ✅ `lib/core/services/storage_service.dart` (인프라 서비스)
- ✅ `lib/core/services/projects_service.dart` (필요시 리팩토링)

## 새로운 아키텍처 사용법

### 1. Provider에서 데이터 읽기
```dart
final missionsState = ref.watch(missionStateNotifierProvider);
```

### 2. 수동 새로고침
```dart
ref.read(missionStateNotifierProvider.notifier).refreshMissions();
```

### 3. 폴링 시작/중지
```dart
// Provider용
ref.read(missionStateNotifierProvider.notifier)
  .startPollingForProvider(providerId);

// Tester용
ref.read(missionStateNotifierProvider.notifier)
  .startPollingForTester(testerId);

// 중지 (페이지 dispose 시)
@override
void dispose() {
  ref.read(missionStateNotifierProvider.notifier).stopPolling();
  super.dispose();
}
```

### 4. 미션 작업
```dart
// 승인
await ref.read(missionStateNotifierProvider.notifier)
  .approveMission(missionId);

// 거부
await ref.read(missionStateNotifierProvider.notifier)
  .rejectMission(missionId, '사유');

// 생성 (별도 UseCase 사용)
await ref.read(createMissionUseCaseProvider)
  .execute(CreateMissionParams(...));
```

## 성능 최적화

### 캐싱
- Repository 레이어에서 5분 캐싱
- 같은 데이터 재요청 시 캐시 사용
- 변경 작업 후 캐시 무효화

### 폴링 주기
- 기본: 30초 (변경 가능)
- 백그라운드 새로고침 표시 (isRefreshing 플래그)

### Optimistic Update
- UI 즉시 업데이트
- 백그라운드 동기화
- 실패 시 자동 롤백

## 테스트 체크리스트
- [ ] Provider 미션 목록 조회
- [ ] Tester 미션 목록 조회
- [ ] 미션 승인/거부
- [ ] 30초 자동 새로고침 확인
- [ ] 수동 새로고침 동작
- [ ] Firestore 400 에러 없음 확인
- [ ] 페이지 전환 시 메모리 누수 없음

## Firestore 사용량 비교

### Before (v2.13.x)
- 실시간 리스너: 62개
- 초당 읽기: ~620 reads/sec (10개 문서 × 62 리스너)
- 월 예상 비용: ~$186 (무료 한도 초과)

### After (v2.14.0)
- 실시간 리스너: 1개 (활성 미션만)
- 30초마다 읽기: ~2 reads/30sec (캐시 사용)
- 월 예상 비용: ~$0.60 (무료 한도 내)

## 문제 해결

### Q: 데이터가 30초마다만 업데이트되는데 즉시 보고 싶어요
A: `refreshMissions()` 수동 호출하거나, Pull-to-Refresh 구현

### Q: 특정 미션만 실시간으로 보고 싶어요
A: `watchActiveMission(testerId)` 사용 (진행 중 미션만)

### Q: 마이그레이션 중 둘 다 동작하게 하려면?
A: 새 Provider를 `missionStateNotifierProviderV2`로 네이밍하고 점진적 전환
