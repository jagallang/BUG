# Changelog

All notable changes to BugCash project will be documented in this file.

## [2.186.17] - 2025-10-28

### Improved
- **공급자 앱 관리 탭 상태 표시 진단 강화**: 완료된 미션이 "모집중"으로 표시되는 문제 진단을 위한 로깅 추가
  - `providerAppsProvider`: Firestore 실시간 업데이트 시 프로젝트 상태 로깅 (🔄)
  - `_buildStatusBadge`: 상태 배지 렌더링 시 Firestore status 값 로깅 (📊)
  - 로그를 통해 실시간 데이터 갱신 여부 및 UI 렌더링 시점의 상태 값 확인 가능

### Technical Details
- `app_management_page.dart`:
  - Line 30-36: providerAppsProvider에 실시간 데이터 갱신 로그 추가
    - providerId, 프로젝트 수, 각 프로젝트의 상태 출력
  - Line 1097-1101: _buildStatusBadge에 렌더링 시점 상태 로그 추가
    - Firestore에서 받은 status 값 출력
- 진단 목적:
  - Firestore에서 `closed` 상태로 업데이트되었는지 확인
  - StreamProvider가 실시간으로 데이터를 받고 있는지 확인
  - UI가 최신 데이터를 렌더링하고 있는지 확인

## [2.186.16] - 2025-10-28

### Fixed
- **공급자 Day 시작 시 테스터 알림 누락 해결**: `activateNextDayMission()` 함수에 테스터 알림 추가
  - 공급자가 일일 미션 시작 → 테스터에게 `day_started` 타입 알림 전송
  - 알림 제목: "Day N 미션이 시작되었습니다!"
  - 알림 메시지: "{appName} Day N 테스트를 시작하세요."
  - v2.186.15와 동일한 testerId 검증 및 상세 로깅 적용

### Technical Details
- `mission_workflow_service.dart` Line 705-734: `activateNextDayMission()` 개선
  - testerId 빈 값 검증 및 경고 로그
  - 알림 전송 전 수신자 정보 확인 로그 (📧, testerId, testerName, appName)
  - NotificationService.sendNotification() 호출 추가
- 미션 플로우 완성:
  1. 테스터 신청 → 공급자 알림 ✅
  2. 공급자 승인 → 테스터 알림 ✅ (v2.186.15)
  3. **공급자 Day 시작 → 테스터 알림 ✅ (v2.186.16 추가)**
  4. 테스터 완료 → 공급자 알림 ✅
  5. 공급자 승인 → 테스터 알림 ✅

## [2.186.15] - 2025-10-28

### Improved
- **테스터 알림 시스템 진단 강화**: 알림 전송 과정 추적 및 문제 진단 개선
  - 알림 전송 전/후 상세 로깅 추가 (📤 시작, ✅ 성공, ❌ 실패)
  - `recipientId` 빈 값 검증 및 경고 메시지 출력
  - `testerId` 검증 로직 추가 (미션 승인 시)
  - 에러 발생 시 스택 트레이스 포함하여 원인 추적 가능

### Technical Details
- `notification_service.dart`:
  - Line 17-83: sendNotification 로깅 강화
  - recipientId 빈 값 체크 시 상세 경고 메시지
  - Firestore 저장 성공 시 Document ID 로깅
  - 에러 발생 시 스택 트레이스 상위 3줄 포함
- `mission_workflow_service.dart`:
  - Line 212-258: processMissionApplication 테스터 알림 개선
  - testerId 검증 및 로깅 추가
  - 알림 전송 전 수신자 정보 확인 로그
- 알림 누락 문제 진단을 위한 로그 시스템 구축

## [2.186.14] - 2025-10-28

### Fixed
- **관리자 대시보드 테스트 조건 하드코딩 제거**: 공급자 앱 등록 시 입력한 실제 데이터 표시
  - 기존: 하드코딩된 fallback 값 표시 ('medium', 'play_store', '30분', '스크린샷 필수')
  - 변경: `testingGuidelines`, `minOSVersion`, `testTimeMinutes` 등 실제 입력 데이터 우선 표시
  - 데이터 없을 시: "⚠️ 테스트 조건 정보가 등록되지 않았습니다." 메시지 표시

### Technical Details
- `project_detail_page.dart` Line 231-320: `_buildTestRequirementsSection()` 개선
  - 하드코딩된 fallback 값 제거
  - 공급자 입력 데이터 (`testingGuidelines`) 최우선 표시
  - Empty state 추가
- 관리자 대시보드 → 프로젝트 탭 → 상세보기에서 정확한 데이터 표시

## [2.186.13] - 2025-10-28

### Fixed
- **프로젝트 상태 유지 보장**: 포인트 지급 후에도 프로젝트 상태가 'closed'로 유지
  - `payFinalRewardOnly()` 함수에 status 보존 로직 추가
  - 최종일 승인 시와 포인트 지급 시 이중으로 'closed' 상태 보장
  - 앱관리 페이지에서 "완료" 배지가 계속 유지됨

### Technical Details
- `mission_workflow_service.dart` Line 1014-1048: status 보존 로직 추가
  - 포인트 지급 후 `projects.status` = 'closed' 명시적 업데이트
  - 에러 발생 시에도 포인트 지급은 성공 유지 (non-blocking)
  - 상세 로깅 추가 (🔒, ✅, ❌ 이모지로 상태 추적)
- 기존 기능 영향 없음 (추가 업데이트만)

## [2.186.12] - 2025-10-28

### Improved
- **UX 및 접근성 개선**: 코드 리뷰 피드백 반영
  - 검색 힌트 텍스트: "검색..." → "앱 검색" (명확성 향상)
  - TextField에 Semantics 레이블 추가: "앱 이름, 설명, 카테고리 검색"
  - floatingActionButton 불필요한 삼항연산자 제거 (코드 간결화)

### Technical Details
- `app_management_page.dart` Line 765, 758, 888: UX 및 접근성 개선
- 스크린 리더 지원 강화
- 다른 코드 영향 없음 (app_management_page.dart 내부만 변경)

## [2.186.11] - 2025-10-27

### Fixed
- **앱관리 페이지 오버플로우 완전 해결**: 좁은 화면 스마트폰에서도 완벽하게 작동
  - 검색 TextField: 150.w → 135.w
  - 간격: 8.w → 6.w (2곳)
  - 앱 등록 버튼: 90.w → 80.w
  - 총 약 29w 절약으로 오버플로우 0픽셀 달성

### Technical Details
- `app_management_page.dart` Line 750, 799, 850, 854: 최종 크기 조정
- 최종 구성: 검색(135.w) + 간격(6.w) + 필터(~95w) + 간격(6.w) + 버튼(80.w) = 약 322w
- 여유 공간: 약 62w (384w 기준)

## [2.186.10] - 2025-10-27

### Fixed
- **'앱 관리' 텍스트 제거**: 약 80-100w 공간 확보
  - Row 구조 단순화 (mainAxisAlignment: spaceBetween 제거)
  - 검색필드 140.w → 150.w로 증가 (사용성 개선)
  - 버튼 85.w → 90.w로 증가
  - 간격 6.w → 8.w 복원
  - 오버플로우 80픽셀 → 25픽셀로 감소

### Technical Details
- `app_management_page.dart` Line 743-753: '앱 관리' Text 위젯 제거

## [2.186.9] - 2025-10-27

### Fixed
- **검색필드 대폭 축소**: 오버플로우 153픽셀 → 80픽셀로 개선
  - 검색 TextField: 180.w → 140.w
  - 필터 padding: 12.w → 8.w
  - 버튼: 100.w → 85.w
  - 간격: 8.w → 6.w (2곳)
  - 힌트 텍스트: "앱 이름, 설명, 카테고리 검색..." → "검색..."

### Technical Details
- `app_management_page.dart` Line 762, 777, 815, 865: 크기 축소

## [2.186.8] - 2025-10-27

### Fixed
- **v2.186.7 긴급 롤백**: Expanded/Flexible 방식이 unbounded constraint 에러 유발
  - 고정 너비 방식으로 복원
  - 검색: 220.w → 180.w
  - 버튼: 120.w → 100.w
  - 간격: 12.w → 8.w

### Technical Details
- v2.186.7의 반응형 레이아웃은 부모 Row의 unbounded width로 인해 RenderFlex 에러 발생
- 고정 너비 + 축소 방식이 더 안정적임을 확인

## [2.186.7] - 2025-10-27 (ROLLBACK)

### Attempted (Failed)
- **반응형 레이아웃 시도**: Expanded/Flexible 사용
- 문제: 부모 Row가 unbounded constraint를 가져 RenderFlex 에러 발생
- 결과: 앱관리 탭 전체가 흰 화면으로 렌더링 실패
- 해결: v2.186.8에서 고정 너비 방식으로 롤백

## [2.186.6] - 2025-10-27

### Fixed
- **관리자 승인 권한 추가**: 관리자가 프로젝트 승인 시 status 업데이트가 실패하던 문제 해결
  - firestore.rules에 관리자의 projects status 업데이트 권한 추가
  - 관리자가 승인하면 프로젝트가 즉시 '모집 중(open)' 상태로 변경됨
  - Cloud Functions 없이도 fallback 로직이 정상 작동

### Technical Details
- `firestore.rules` Line 151-154: `allow update` 규칙에 `|| isAdmin()` 추가
- 공급자는 status 변경 불가 (기존과 동일)
- 관리자는 status 포함 모든 필드 수정 가능

## [2.186.5] - 2025-10-27

### Fixed
- **공급자 앱 삭제 UI 제한 제거**: 모든 상태에서 공급자가 자신의 앱을 삭제할 수 있도록 수정
  - `app_management_page.dart`: draft 상태 체크 로직 제거
  - "진행 중인 프로젝트는 관리자에게 문의하세요" 오류 메시지 제거
  - 워크플로우 쿼리: `where('appId')` 사용 (v2.186.3과 일관성)

### Technical Details
- `app_management_page.dart` Line 2313-2329: status 체크 제거
- v2.186.4의 Firestore rules와 일치하도록 UI 로직 수정

## [2.186.4] - 2025-10-27

### Changed
- **공급자 앱 삭제 권한 확대**: Firestore rules에서 모든 상태의 프로젝트 삭제 허용
  - 이전: draft 상태만 삭제 가능
  - 이후: 모든 상태(draft, open, closed)에서 자신의 프로젝트 삭제 가능

### Technical Details
- `firestore.rules` Line 156: `resource.data.status == 'draft'` 조건 제거
- 공급자는 `isProjectProvider(projectId)` 검증으로 본인 프로젝트만 삭제 가능

## [2.186.3] - 2025-10-27

### Added
- **Orphan workflows 방지**: 프로젝트 삭제 시 관련 mission_workflows 자동 삭제
  - `admin_dashboard_page.dart`: `_deleteProject()` 함수 수정
  - 삭제된 워크플로우 개수를 사용자에게 알림
  - orphan workflows 문제 예방

### Added (Scripts)
- `scripts/cleanup_orphan_workflows.js`: 기존 orphan workflows 정리 스크립트
  - mission_workflows의 appId가 가리키는 projects 문서 존재 여부 확인
  - 10초 안전 지연 후 삭제
  - 상세한 로깅 및 오류 처리

### Fixed
- **Firestore Rules 롤백**: v2.186.2에서 발생한 wallet/provider_apps 권한 오류 수정
  - v2.186.1 상태로 롤백
  - wallet 로직 보존 (사용자 요청사항 준수)

### Technical Details
- `admin_dashboard_page.dart` Line 756-797: mission_workflows 쿼리 및 삭제 로직 추가
- `firestore.rules`: v2.186.1 상태 유지 (안전한 상태)

---

## Version History Summary

- **v2.186.13**: 프로젝트 상태 유지 보장 (포인트 지급 후에도 'closed' 유지)
- **v2.186.12**: UX 및 접근성 개선 (코드 리뷰 피드백 반영)
- **v2.186.11**: 앱관리 페이지 오버플로우 완전 해결 (좁은 화면 대응)
- **v2.186.10**: '앱 관리' 텍스트 제거로 공간 확보
- **v2.186.9**: 검색필드 대폭 축소 (153px → 80px)
- **v2.186.8**: v2.186.7 긴급 롤백 (고정 너비 방식 복원)
- **v2.186.7**: 반응형 레이아웃 시도 실패 (RenderFlex 에러)
- **v2.186.6**: 관리자 프로젝트 승인 권한 수정 (status 업데이트 가능)
- **v2.186.5**: 공급자 앱 삭제 UI 제한 제거
- **v2.186.4**: 공급자 앱 삭제 Firestore rules 권한 확대
- **v2.186.3**: Orphan workflows 방지 및 정리 스크립트 추가

## Notes

- 모든 변경사항은 하위 호환성 유지
- Firestore Security Rules는 최소 권한 원칙 준수
- 관리자 대시보드는 별도 권한으로 관리
