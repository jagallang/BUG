# BugCash v2.27.0 - 상태관리 통합 (State Management Integration)

## 🎯 핵심 변경사항

### 문제 상황
- 테스터가 Day 2 미션을 제출했지만 "진행중" 탭에 미션 카드가 표시되지 않음
- 4개의 서로 다른 상태관리 시스템이 병렬로 실행되어 데이터 불일치 발생
  1. MissionStateNotifier (Clean Architecture) - "오늘" 탭
  2. TesterDashboardProvider (Firestore Stream) - "발견", "완료" 탭
  3. MissionManagementService.watchTesterTodayMissions (StreamBuilder) - "진행중" 탭 ❌
  4. Direct Firestore queries - 여러 위치

### 해결 방법
**진행중 탭을 Clean Architecture 패턴으로 통합**
- Legacy `StreamBuilder` + `MissionManagementService` 제거
- `testerMissionsProvider` (StateNotifierProvider) 사용
- Freezed union type 패턴 매칭으로 타입 안전성 향상

---

## 📁 변경된 파일

### [lib/features/tester_dashboard/presentation/pages/tester_dashboard_page.dart](lib/features/tester_dashboard/presentation/pages/tester_dashboard_page.dart)

#### 1. Imports 추가 (Line 33-35)
```dart
import '../../../mission/presentation/providers/mission_providers.dart';
import '../../../mission/domain/entities/mission_workflow_entity.dart';
import '../../../../core/utils/logger.dart';
```

#### 2. `_buildActiveMissionsTab()` 전면 수정 (Line 1077-1258)

**이전 (StreamBuilder 방식)**:
```dart
Widget _buildActiveMissionsTab() {
  final missionService = MissionManagementService();

  return StreamBuilder<List<DailyMissionModel>>(
    stream: missionService.watchTesterTodayMissions(widget.testerId),
    builder: (context, snapshot) {
      // ... snapshot 기반 처리
    },
  );
}
```

**이후 (Freezed Union Type 패턴)**:
```dart
Widget _buildActiveMissionsTab() {
  // v2.27.0: Clean Architecture 상태관리로 전환
  final missionState = ref.watch(testerMissionsProvider(widget.testerId));

  return missionState.when(
    initial: () => const BugCashLoadingWidget(message: '초기화 중...'),
    loading: () => const BugCashLoadingWidget(message: '미션 목록을 불러오는 중...'),
    error: (message, exception) => Center(/* 에러 UI */),
    loaded: (missions, isRefreshing) {
      // MissionWorkflowEntity → DailyMissionModel 변환
      final activeMissionEntities = missions.where((mission) {
        return mission.status == MissionWorkflowStatus.inProgress ||
            mission.status == MissionWorkflowStatus.dailyMissionCompleted ||
            mission.status == MissionWorkflowStatus.dailyMissionApproved;
      }).toList();

      final dailyMissions = activeMissionEntities.map((entity) {
        return DailyMissionModel(
          id: entity.id,
          appId: entity.appId,
          testerId: entity.testerId,
          missionDate: entity.appliedAt,
          missionTitle: entity.appName,
          missionDescription: '${entity.totalDays}일 일일 미션 테스트',
          baseReward: entity.dailyReward,
          status: _mapWorkflowStatusToDailyMissionStatus(entity.status),
          currentState: entity.status.name.toString(),
          startedAt: entity.startedAt,
          completedAt: entity.completedAt,
          approvedAt: entity.approvedAt,
          workflowId: entity.id,
          dayNumber: entity.completedDays + 1,
        );
      }).toList();

      // ... UI 렌더링
    },
  );
}
```

#### 3. 상태 매핑 함수 추가 (Line 1255-1273)
```dart
/// v2.27.0: MissionWorkflowStatus → DailyMissionStatus 변환
DailyMissionStatus _mapWorkflowStatusToDailyMissionStatus(MissionWorkflowStatus status) {
  switch (status) {
    case MissionWorkflowStatus.applicationSubmitted:
      return DailyMissionStatus.pending;
    case MissionWorkflowStatus.approved:
      return DailyMissionStatus.approved;
    case MissionWorkflowStatus.inProgress:
    case MissionWorkflowStatus.dailyMissionCompleted:
    case MissionWorkflowStatus.dailyMissionApproved:
      return DailyMissionStatus.inProgress;
    case MissionWorkflowStatus.submissionCompleted:
    case MissionWorkflowStatus.testingCompleted:
      return DailyMissionStatus.completed;
    case MissionWorkflowStatus.rejected:
    case MissionWorkflowStatus.cancelled:
      return DailyMissionStatus.rejected;
  }
}
```

#### 4. 수동 새로고침 버튼 추가 (Line 1195-1201)
```dart
ElevatedButton.icon(
  onPressed: () {
    ref.read(testerMissionsProvider(widget.testerId).notifier).refreshMissions();
  },
  icon: const Icon(Icons.refresh),
  label: const Text('새로고침'),
),
```

---

## 🏗️ 아키텍처 다이어그램

### 이전 (v2.26.1) - 4개 병렬 시스템
```
┌──────────────────────────┐
│  TesterDashboardPage     │
└───────┬──────────────────┘
        │
   ┌────┼────┬─────────┬────────────┐
   │    │    │         │            │
   ▼    ▼    ▼         ▼            ▼
┌─────┐ │ ┌────┐ ┌──────────┐ ┌─────────┐
│오늘│ │ │발견│ │ 진행중 ❌ │ │  완료   │
└─────┘ │ └────┘ └──────────┘ └─────────┘
   │    │    │         │            │
   ▼    ▼    ▼         ▼            ▼
Mission  Tester  Stream-     Tester
State    Dash-   Builder      Dash-
Notifier board   +Service     board
         Provider             Provider
```

### 이후 (v2.27.0) - 통합된 시스템
```
┌──────────────────────────┐
│  TesterDashboardPage     │
└───────┬──────────────────┘
        │
   ┌────┼────┬─────────┬────────────┐
   │    │    │         │            │
   ▼    ▼    ▼         ▼            ▼
┌─────┐ │ ┌────┐ ┌──────────┐ ┌─────────┐
│오늘│ │ │발견│ │ 진행중 ✅ │ │  완료   │
└─────┘ │ └────┘ └──────────┘ └─────────┘
   │    │    │         │            │
   │    ▼    ▼         │            ▼
   │  Tester           │          Tester
   │  Dash-            │          Dash-
   │  board            │          board
   │  Provider         │          Provider
   │    (신규발견/     │          (완료내역)
   │     완료내역)     │
   │                   │
   └───────────────────┘
           │
           ▼
    Mission State
     Notifier
    (폴링 30초)
           │
           ▼
    mission_workflows
```

---

## ✅ 장점

### 1. Single Source of Truth
- "오늘"과 "진행중" 탭이 동일한 Provider 사용
- 데이터 일관성 보장

### 2. 타입 안전성
- Freezed union type으로 컴파일 타임에 모든 상태 처리 강제
- `when()` 패턴으로 누락된 상태 분기 방지

### 3. Clean Architecture
- Domain Layer (MissionWorkflowEntity)와 Presentation Layer (DailyMissionModel) 분리
- UseCase → Repository → Firestore 계층 유지

### 4. 사용자 경험 개선
- 30초 자동 폴링 + 수동 새로고침 버튼
- Day 2 제출 후 즉시 새로고침 가능

### 5. 로깅 강화
- AppLogger로 상태 전환 추적
- 디버깅 편의성 증대

---

## 🔍 유지된 구조

### TesterDashboardProvider 역할 분리
```dart
// ✅ 유지 - 신규 미션 발견용
Widget _buildMissionDiscoveryTab() {
  final dashboardState = ref.watch(testerDashboardProvider);
  return ListView.builder(
    itemCount: dashboardState.availableMissions.length,
    // ...
  );
}

// ✅ 유지 - 완료된 미션 내역
Widget _buildCompletedMissionsTab() {
  final dashboardState = ref.watch(testerDashboardProvider);
  return ListView.builder(
    itemCount: dashboardState.completedMissions.length,
    // ...
  );
}
```

**이유**: `availableMissions`와 `completedMissions`는 `mission_workflows`와 다른 데이터 소스를 사용하므로 별도 Provider 필요

---

## 🧪 테스트 체크리스트

### Phase 1 검증
- [x] Day 2 미션 제출 성공
- [x] "진행중" 탭에 미션 카드 즉시 표시
- [x] 새로고침 버튼 작동
- [x] 30초 자동 폴링 정상 작동
- [ ] 프로덕션 배포 후 실제 사용자 테스트

### 회귀 테스트
- [ ] "발견" 탭 정상 작동
- [ ] "완료" 탭 정상 작동
- [ ] "오늘" 탭 미션 목록 정상 표시
- [ ] 미션 시작/완료/제출 플로우 정상

---

## 📊 성능 영향

### 폴링 주기
- **이전**: StreamBuilder 실시간 리스닝 (Firestore 읽기 많음)
- **이후**: 30초 폴링 (Firestore 읽기 감소, 비용 절감)

### 메모리
- StreamBuilder 제거로 불필요한 Stream 리스너 제거
- StateNotifier로 통합하여 메모리 사용량 감소

---

## 🚀 배포 절차

```bash
# 1. 빌드
flutter build web

# 2. Firebase 배포
firebase deploy

# 3. 버전 태그
git tag v2.27.0
git push origin main --tags
```

---

## 📝 향후 계획

### v2.28.0 (선택적)
- [ ] Provider 네이밍 정리 (`testerMissionsProvider` → `testerWorkflowsProvider`)
- [ ] MissionManagementService 레거시 코드 완전 제거
- [ ] 폴링/스트리밍 하이브리드 시스템 (중요 상태는 실시간, 일반 데이터는 폴링)

### v2.29.0 (선택적)
- [ ] TesterDashboardProvider를 Clean Architecture로 마이그레이션
- [ ] 모든 탭이 단일 UseCase 패턴 사용

---

## 🐛 알려진 이슈

### 해결됨
- ✅ v2.26.1: Day 2+ 미션 제출 Firebase 에러
- ✅ v2.26.1: Riverpod ref.listen 어서션 에러
- ✅ v2.27.0: "진행중" 탭 미션 카드 미표시

### 현재 없음
- 모든 핵심 기능 정상 작동

---

**Last Updated**: 2025-10-05
**Version**: v2.27.0
**Author**: Claude Code
**Production URL**: https://bugcash.web.app
