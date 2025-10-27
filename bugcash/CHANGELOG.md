# Changelog

All notable changes to BugCash project will be documented in this file.

## [2.186.7] - 2025-10-27

### Fixed
- **앱관리 페이지 상단 오버플로우 수정**: 안드로이드 앱에서 검색창, 필터, 버튼이 겹치는 문제 해결
  - 고정 너비(width: 220.w, 120.w)를 Expanded/Flexible로 변경
  - Flex 비율: 검색(3), 필터(2), 버튼(2) → 반응형 레이아웃
  - 간격 축소: 12.w → 8.w
  - 드롭다운에 `isExpanded: true`, `mainAxisSize: MainAxisSize.min` 추가

### Technical Details
- `app_management_page.dart` Line 754-894: Row 레이아웃 반응형 전환
- ScreenUtil(.w) 기반 고정 너비 제거
- 모든 화면 크기에서 오버플로우 없이 작동

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

- **v2.186.7**: 앱관리 페이지 상단 오버플로우 수정 (반응형 레이아웃)
- **v2.186.6**: 관리자 프로젝트 승인 권한 수정 (status 업데이트 가능)
- **v2.186.5**: 공급자 앱 삭제 UI 제한 제거
- **v2.186.4**: 공급자 앱 삭제 Firestore rules 권한 확대
- **v2.186.3**: Orphan workflows 방지 및 정리 스크립트 추가

## Notes

- 모든 변경사항은 하위 호환성 유지
- Firestore Security Rules는 최소 권한 원칙 준수
- 관리자 대시보드는 별도 권한으로 관리
