# 🐛 BugCash - 버그 테스트 리워드 플랫폼

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.29.2-02569B?style=flat-square&logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.7.2-0175C2?style=flat-square&logo=dart" />
  <img src="https://img.shields.io/badge/Node.js-20.19.2-339933?style=flat-square&logo=node.js" />
  <img src="https://img.shields.io/badge/Firebase-Production%20Ready-4285F4?style=flat-square&logo=firebase" />
  <img src="https://img.shields.io/badge/Version-1.4.17-success?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" />
</p>

> **혁신적인 크라우드소싱 버그 테스트 플랫폼** - 앱 개발자와 테스터를 연결하는 Win-Win 생태계

BugCash는 앱 개발자들이 실제 사용자들에게 버그 테스트를 의뢰하고, 테스터들이 이를 통해 리워드를 획득할 수 있는 플랫폼입니다.

## ✨ 주요 기능 (v1.4.17)

### 🧹 대규모 코드 정리 및 유지보수성 개선 (v1.4.17)
- **📊 파일 수 최적화**: 166개 → 160개 파일로 6개 파일 제거하여 프로젝트 구조 간소화
- **🗑️ 미사용 기능 완전 제거**:
  - **💬 미완성 채팅 시스템**: chat/ 디렉토리 전체 제거 (26개 파일)
  - **📡 복잡한 오프라인 기능**: offline_data_cache.dart, offline_sync_service.dart
  - **🧪 테스트 파일들**: missions_tab_test.dart, apps_tab_test.dart
  - **🔧 동기화 관련 위젯**: connection_status_widget.dart, sync_management_widget.dart
- **🔄 중복 코드 통합 및 리팩토링**:
  - **🛠️ TypeConverter 유틸리티**: 안전한 타입 변환을 위한 공통 클래스 추가
  - **👤 UserEntity 생성 로직**: 3곳의 중복 코드를 팩토리 메소드로 통합
  - **🔗 FirebaseAuthService 최적화**: 중복된 타입 변환 로직 제거
- **🚫 하드코딩 완전 제거**:
  - **🆔 demo_user → 실제 인증**: currentUserIdProvider를 통한 실제 사용자 ID 사용
  - **🔐 auth_provider.dart 추가**: 중앙화된 인증 상태 관리
- **📦 의존성 최적화**:
  - **🗂️ dartz 라이브러리 제거**: 미사용 함수형 프로그래밍 라이브러리
  - **🧽 DI 모듈 정리**: 주석처리된 의존성 주입 코드 제거
  - **📋 pubspec.yaml 간소화**: 불필요한 의존성 정리
- **⚡ 성능 향상**: 7,534줄 → 212줄로 코드 대폭 감소, 빌드 속도 및 앱 성능 향상
- **🔧 유지보수성 대폭 향상**: 깔끔한 코드 구조로 향후 기능 추가 및 버그 수정 용이성 확보

### 🏢 공급자 앱 상세 관리 시스템 & 하드코딩 데이터 완전 제거 (v1.4.16)
- **📱 완전한 앱 상세 관리 페이지**: 앱 관리 탭의 "상세보기" 버튼 클릭 시 종합적인 앱 관리 인터페이스 제공
- **🔧 4가지 핵심 관리 기능**:
  - **📝 앱 정보 수정**: 이름, URL, 설명, 카테고리 실시간 수정
  - **📢 앱 공지사항 관리**: 체크박스 토글로 공지 활성화 및 내용 작성/수정
  - **💰 테스터 단가 설정**: 포인트 기반 테스팅 보상 금액 설정
  - **📋 추가 요구사항**: 테스터에게 전달할 특별 지시사항 입력
- **🎯 앱 게시 상태 관리**: "활성/비활성" 토글로 테스터에게 노출 여부 제어
- **🔗 실시간 공급자-테스터 연동**: 공급자가 설정한 모든 정보가 테스터 미션 탭에 즉시 반영
- **🚀 하드코딩 데이터 완전 제거**: 모든 가짜 미션 생성 메서드 삭제로 실제 Firestore 데이터만 사용
- **💾 Firebase 메타데이터 활용**: provider_apps 컬렉션의 metadata 필드에 모든 추가 정보 저장
- **📱 향상된 테스터 경험**: 앱 공지사항, 테스팅 보상, 요구사항이 미션 카드에 명확히 표시

### 🎨 공급자 대시보드 UI 단순화 & 테스터관리/테스트세션 기능 제거 (v1.4.15)
- **🗑️ 불필요한 기능 완전 제거**: 공급자 대시보드에서 "테스터관리" 및 "테스트세션" 탭 완전 삭제
- **🎯 앱 관리 중심 UI**: 복잡한 탭 시스템을 제거하고 "앱 관리" 기능에만 집중하는 단순화된 인터페이스
- **🏗️ TabController 구조 제거**: TabBarView에서 단일 위젯 구조로 변경하여 성능 및 유지보수성 향상
- **📝 페이지 타이틀 명확화**: "통합 관리"에서 "앱 관리"로 변경하여 기능 목적 명시
- **🧹 코드 정리**: 1,841줄의 불필요한 코드 제거 및 184줄로 최적화
- **⚡ Firestore 인덱스 최적화**: payouts 컬렉션 인덱스 추가로 앱 크래시 문제 해결
- **📱 모바일 사용성 향상**: 불필요한 탭 네비게이션 제거로 더 직관적인 사용자 경험

### 🔧 Firestore 인덱스 문제 해결 & 공급자 대시보드 데이터 로딩 수정 (v1.4.14)
- **📊 누락된 Firestore 복합 인덱스 7개 추가**: test_sessions, provider_apps, activities, earnings, missionApplications, chat_rooms
- **🎯 "제공자 ID '알려지지 않은'" 문제 완전 해결**: providerId 매칭 로직 개선 및 실시간 디버깅 시스템
- **⚡ FAILED_PRECONDITION 오류 제거**: 모든 Firestore 쿼리가 정상 작동하도록 인덱스 최적화
- **🔄 TestSession 워크플로우 완전 구현**: 테스터 미션 참여 → 공급자 승인 → 활성 테스트 전체 프로세스
- **👤 인증 서비스 타입 안전성 강화**: phoneNumber 필드 안전한 타입 변환 및 null 처리
- **🚪 로그아웃 프로세스 이중 보장**: Firebase Auth 강제 로그아웃 및 상태 초기화 개선
- **📱 테스터 대시보드 실시간 연동**: Mock 데이터 제거하고 실제 Firebase TestSession 데이터 표시
- **🐛 포괄적인 디버깅 로그**: 공급자 대시보드 데이터 로딩 전 과정 추적 가능

### 🔒 Critical Security Fixes & Code Quality Improvements (v1.4.13)
- **🚨 Firebase Storage 보안 강화**: 인증 기반 접근 제어 구현, 역할별 권한 설정, 파일 크기 및 타입 검증
- **🧹 프로덕션 코드 품질 개선**: 241개 → 86개 lint 이슈 감소 (59% 개선), print문 완전 제거
- **📊 로깅 시스템 구축**: AppLogger 도입으로 프로덕션/개발 환경별 차별화된 로깅
- **⚡ 의존성 업데이트**: Firebase 패키지 최신 보안 패치 적용
- **🔧 코드 정리**: flutter_bloc 제거 및 Riverpod 완전 이관, const 최적화
- **🎯 테스트 파일 제거**: 배포용 빌드 최적화를 위한 테스트 코드 제거

### 🔧 NEW! 인증 시스템 개선 & 사용자 데이터 통합 (v1.4.10)
- **👤 실제 사용자 프로필 연동**: 하드코딩된 '김테스터' 완전 제거 및 Firestore 실제 데이터 연동
- **🔄 동적 사용자 정보 로드**: `CurrentUserService.getUserProfile()` 기반 실시간 사용자 데이터 표시
- **🚪 햄버거 메뉴 로그아웃 수정**: Mock 인증과 Firebase 인증 모두 지원하는 통합 로그아웃 시스템
- **🔐 강화된 인증 상태 관리**: AuthProvider 경합 상태 해결 및 auth 상태 스트림 자동 처리
- **🐛 포괄적인 디버그 로깅**: 인증 플로우 전체에 대한 상세 로깅 시스템 추가
- **⚡ 안전한 null 처리**: 사용자 데이터 파싱 시 완벽한 null safety 및 fallback 처리
- **🎯 테스터 레벨 자동 변환**: 문자열 기반 레벨을 enum으로 변환하는 헬퍼 메서드 추가

### 🔐 통합 인증 시스템 & 공급자 신청 시스템 (v1.4.09)
- **🎯 단일 회원가입 흐름**: 복잡한 사용자 타입 선택 제거로 간소화된 회원가입 경험
- **👤 테스터 기본 모드**: 모든 신규 사용자가 테스터로 시작하여 즉시 앱 테스트 참여 가능
- **🔒 보안 기반 공급자 신청**: 비밀번호 검증을 통한 안전한 공급자 모드 업그레이드 시스템
- **📋 직관적인 햄버거 메뉴**: 테스터 대시보드에서 "공급자 신청" 메뉴로 간편한 모드 전환
- **✨ 향상된 사용자 경험**: 단계별 안내와 확인 다이얼로그로 완성도 높은 UX
- **💬 실시간 피드백**: 신청 성공/실패에 대한 즉각적인 사용자 알림 시스템
- **🎨 개선된 UI/UX**: 정보 제공 카드와 시각적 가이드로 사용자 친화적 인터페이스

### 🚀 완전한 14일 앱 테스트 워크플로우 시스템 (v1.4.07)
- **📋 확장 가능한 미션 카드**: 탭으로 미션 상세 정보를 확인하고 "14일 테스트 신청하기" 버튼으로 즉시 신청
- **🔄 테스터 신청 및 승인 시스템**: 테스터 신청 → 공급자 승인 → 진행중 탭 자동 이동의 완전한 워크플로우
- **📱 일일 테스트 관리**: 매일 스크린샷과 메모를 제출하고 공급자가 승인하는 14일간 테스트 추적 시스템
- **🎛️ 공급자 승인 대시보드**: 테스터 신청 관리, 일일 테스트 승인/거부, 벌크 처리 기능이 포함된 완전한 관리 시스템
- **🏗️ TestSession 모델**: TestSessionStatus, DailyTestProgress를 통한 체계적인 테스트 진행 상황 추적
- **✨ 실시간 UI 업데이트**: Firebase 연동으로 신청, 승인, 일일 테스트 제출의 실시간 동기화
- **📊 진행률 시각화**: 14일간의 일일 테스트 완료 현황을 한눈에 볼 수 있는 대시보드

### 🎨 앱 아이콘 업데이트 & 커뮤니티 게시판 강화 (v1.4.06)
- **🎯 새로운 BugCash 브랜딩**: 모든 플랫폼(Android, iOS, macOS, Windows, Web)에 통일된 새 앱 아이콘 적용
- **📱 플랫폼별 최적화**: 각 플랫폼 요구사항에 맞는 아이콘 크기 및 형식 지원
- **🛠️ assets 폴더 추가**: 앱 아이콘 원본 파일을 포함한 체계적인 에셋 관리
- **🎨 커뮤니티 게시판 UI/UX 개선**: 더 직관적이고 사용하기 쉬운 게시판 인터페이스
- **📋 테스터 대시보드 기능 향상**: 사용자 경험을 개선하는 다양한 인터페이스 업데이트
- **🔧 의존성 업데이트**: 최신 Flutter 패키지들로 업그레이드하여 성능 및 안정성 향상

### 🎯 일관된 FAB 위치 개선 (v1.4.05)
- **📍 고정된 채팅 FAB 위치**: 테스터 모드에서 모든 탭에서 동일한 중간 위치로 채팅 버튼 고정
- **🔧 Custom FAB Location**: `_CustomFabLocation` 클래스로 Y 좌표 120px 고정 위치 구현
- **✨ 사용자 경험 개선**: 탭 변경 시 FAB 위치가 달라지는 혼란 완전 제거
- **🎯 정확한 위치 계산**: 하단 탭바와 기본 위치의 중간 지점으로 최적화된 접근성
- **⚡ 효율적인 코드**: TabController 리스너 제거로 불필요한 상태 업데이트 방지

### 🎨 테마 분리 & UI/UX 개선 (v1.4.04)
- **🔵 앱공급자 인디고 테마**: 전체 Provider Dashboard를 진한 파란색(Indigo) 테마로 통일
- **🟢 앱테스터 그린 테마 유지**: 기존 Tester 인터페이스의 녹색 테마 그대로 유지
- **📱 하단 탭 네비게이션**: 미션 탭을 하단으로 이동하여 모바일 접근성 향상
- **⚡ 동적 FAB 위치 조정**: 채팅 FAB가 탭 변경에 따라 자동으로 위치 조정
- **🛡️ 시스템 UI 간격 조정**: 스마트폰 네비게이션 바와의 충돌 방지를 위한 MediaQuery 패딩
- **🎯 조건부 UI 렌더링**: 탭 인덱스에 따른 동적 FloatingActionButton 위치 변경
- **✨ 실시간 상태 업데이트**: TabController 리스너로 UI 변경사항 즉시 반영

### 🔐 실제 Firebase 인증 시스템 & 더미 데이터 관리 (v1.4.08)
- **💥 실제 Firebase 이메일/비밀번호 인증 구현**: Mock 시스템을 완전 실제 Firebase Auth로 교체
- **📧 완전한 회원가입 시스템**: 이메일/비밀번호로 실제 사용자 계정 생성 및 Firestore 프로필 저장
- **🗑️ 스마트 더미 데이터 관리**: 개발용 더미 데이터 일괄 삭제 기능 및 확인 다이얼로그
- **👤 Admin 계정만 유지**: 400+ 줄의 Mock 테스터 계정 제거, 관리자 계정만 보존
- **🔧 하이브리드 인증 아키텍처**: Firebase 설정 상태에 따른 자동 Mock/Real 모드 전환
- **✨ 향상된 인증 흐름**: 실제 사용자 프로필 생성, 유형 선택, 국가/전화번호 정보 저장
- **🛠️ 코드 정리 완료**: 사용하지 않는 테스트 계정 다이얼로그, Import, 메서드 완전 제거
- **⚠️ BuildContext 경고 수정**: async gaps 관련 Flutter linting 경고 해결
- **🎯 프로덕션 준비**: Mock 의존성 제거로 실제 서비스 배포 준비 완료

### 🚀 완전한 Firebase 백엔드 통합 & 하드코딩 데이터 제거 (v1.4.03)
- **💥 모든 하드코딩 데이터 완전 제거**: 2,917줄의 Mock 데이터를 실제 Firebase 데이터로 교체
- **🏢 공급자 대시보드 완전 Firebase 연동**: 5개 탭 모두 실시간 Firebase 데이터 사용
  - **📱 앱 관리**: 실시간 앱 CRUD 및 상태 관리
  - **👥 테스터 관리**: 라이브 테스터 통계, 검색, 필터링
  - **✅ 미션 승인**: 실시간 제출 승인/거부/보완요청 시스템
  - **💰 결제 관리**: Firebase 기반 결제 추적 및 포인트 지급
  - **📊 대시보드 분석**: 실시간 Firebase 통계 및 차트
- **🔐 인증 서비스 강화**: CurrentUserService로 사용자 프로필 관리 완성
- **⚡ 실시간 스트림**: 모든 컴포넌트에서 Firestore 실시간 업데이트
- **🛠️ 에러 처리 완성**: 로딩 상태, 에러 처리, 빈 상태 UI 구현
- **🏗️ 프로덕션 준비**: MockDataSource 의존성 완전 제거로 실제 서비스 준비 완료

### 🔥 Firebase 완전 통합 & 프로덕션 배포 준비 (v1.4.01)
- **🚀 Firebase Web SDK 완전 통합**: Firebase v10.7.0 기반 실시간 연결 완료
- **🔐 프로덕션 인증 시스템**: Google Sign-In과 Firebase Auth 완전 연동
- **💾 실시간 데이터베이스**: Firestore 실시간 스트림으로 즉시 데이터 동기화
- **📁 파일 관리 시스템**: Firebase Storage 완전 통합으로 이미지/파일 업로드 지원
- **🔔 푸시 알림 준비**: FCM(Firebase Cloud Messaging) 서비스 활성화
- **⚡ 의존성 주입 시스템**: @injectable 패턴으로 확장 가능한 아키텍처
- **🌐 멀티 플랫폼 지원**: Web, Android, iOS 모든 플랫폼 Firebase 설정 완료
- **📊 실시간 모니터링**: Firebase Console 연동으로 실시간 앱 상태 추적
- **🔧 환경 설정 관리**: .env 기반 개발/프로덕션 환경 분리
- **🎯 즉시 배포 가능**: Firebase Hosting 준비 완료 상태

### 💬 완전한 실시간 채팅 시스템 (v1.4.00)
- **🏗️ Clean Architecture 기반 채팅**: Domain-Data-Presentation 레이어로 확장 가능한 채팅 시스템 구축
- **🔥 Firebase Firestore 실시간 메시징**: 실시간 메시지 전송, 읽음 상태, 온라인 상태 완벽 지원
- **5가지 채팅방 유형**: 1:1 채팅, 미션 채팅, 고객 지원, 그룹 채팅, 공지 채팅
- **👤 회원 검색 시스템**: 11명의 Mock 사용자로 실제 사용자 검색 및 1:1 채팅 시작
- **🚀 개발자 친화적 로그인 우회**: 테스트용 로그인 우회 버튼으로 즉시 채팅 기능 테스트
- **💬 고급 채팅 UI**: 메시지 버블, 타이핑 인디케이터, 온라인 상태, 시간 표시
- **📊 읽지않음 메시지 카운트**: 실시간 배지 시스템으로 새 메시지 알림
- **🔗 미션 시스템 연동**: 미션 참여 시 자동 채팅방 생성 및 관리
- **📱 통합 UI 디자인**: 테스터/공급자 대시보드에 채팅 FAB 버튼 통합
- **⚡ 모듈형 컴포넌트**: 재사용 가능한 채팅 위젯 및 서비스 구조

### 🎯 미션 신청 및 승인 시스템 (v1.3.06)
- **📋 완전한 미션 신청 워크플로우**: 테스터가 미션을 발견하고 신청부터 공급자 승인까지 전체 프로세스 구현
- **📝 상세 신청 다이얼로그**: 요구사항 확인, 앱 설치 준비 체크리스트, 개인 메시지 작성 기능
- **🏢 공급자 신청 관리 시스템**: 테스터 프로필, 경험, 평점, 전문분야 확인 후 승인/거부 결정
- **💬 양방향 메시지 교환**: 신청 시 테스터 메시지와 승인/거부 시 공급자 응답 메시지
- **📊 신청 현황 대시보드**: 대기중, 검토중, 승인됨 상태별 통계 및 관리
- **🔔 실시간 알림 시스템**: 신청 → 승인/거부 → 테스터 알림 완전한 알림 체인
- **👤 테스터 프로필 시스템**: 경험 년수, 완료 미션 수, 평점, 전문 분야 표시
- **✅ 스마트 상태 관리**: pending → reviewing → accepted/rejected 상태 자동 추적

### 🏆 완료된 미션 관리 & 포인트 정산 시스템 (v1.3.05)
- **3단계 미션 탭 시스템**: '미션 찾기', '진행 중', '완료' 탭으로 전체 미션 라이프사이클 관리
- **지능형 정산 시스템**: 3단계 정산 상태(정산 대기, 정산 처리중, 정산 완료) 자동 관리
- **색상 코딩 상태 표시**: 주황색(대기), 파란색(처리중), 녹색(완료)로 직관적 상태 파악
- **자동 사라짐 기능**: 공급자가 포인트 정산 완료 시 완료된 미션이 목록에서 자동 제거
- **상세 정산 정보**: 미션 세부 사항, 획득 포인트, 평가 점수, 완료일 등 종합 정보 제공
- **공급자 연동**: 공급자 대시보드의 결제 시스템과 실시간 연동되는 완전한 정산 워크플로우

### 📋 업그레이드된 커뮤니티 게시판 시스템 (v1.3.04)
- **새로운 카테고리 시스템**: '모집중', '모집완료', '구인', '구직', '질문', '기타' 6개 카테고리로 전면 개편
- **채용 중심 게시판**: 테스터 모집 및 구인구직 중심의 실용적 커뮤니티 환경
- **카테고리별 색상 코딩**: 녹색(모집중), 회색(모집완료), 파란색(구인), 보라색(구직), 주황색(질문), 청록색(기타)
- **스마트 태그 선택**: 게시글 작성 시 드롭다운으로 카테고리 태그 선택 가능
- **다양한 게시글 템플릿**: 모집공고, 프로젝트 완료 알림, 채용정보, 구직활동, 기술질문, 일상소통
- **실시간 필터링**: 카테고리별 즉석 필터링으로 원하는 게시글만 선별 조회

### 💳 통합 결제 관리 시스템 (v1.3.03)
- **결제 대시보드**: 예산 개요, 할당된 자금, 잔여 예산 실시간 추적
- **결제 처리 시스템**: 앱 등록비, 광고비, 테스터 포인트 지급 통합 관리
- **포인트 배분 자동화**: 결제 금액을 테스터 포인트로 자동 배분 및 추적
- **결제 히스토리**: 모든 결제 내역과 상태를 한눈에 관리 (대기→완료→처리→배분)
- **정산 리포트**: 월별/분기별 결제 및 포인트 배분 현황 보고서
- **빠른 액션**: 새 결제, 포인트 배분, 결제 히스토리, 정산 리포트 원클릭 접근

### 🇰🇷 완전한 한글 국제화 시스템 (v1.3.02)
- **Flutter 다국어 지원**: flutter_localizations 기반 완전한 i18n 인프라
- **포괄적인 한글 번역**: 180+ 핵심 UI 요소 한국어 번역 (버그 테스팅, 사용자 역할, 대시보드, 테스터 관리)
- **테스터 관리 UI 한글화**: 확장 가능한 테스터 카드, 검색/필터, 메모/태그 기능의 완전한 한글 인터페이스
- **크로스 플랫폼 일관성**: Chrome 웹, Android 모바일에서 일관된 한글 사용자 경험
- **확장 가능한 다국어**: ARB 파일 기반으로 향후 다른 언어 쉽게 추가 가능

### 🔧 테스터 관리 시스템 고도화 (v1.3.02)
- **확장 가능한 테스터 카드**: 한 줄 요약에서 클릭으로 상세정보 확장
- **고급 검색 & 필터링**: 이름, 이메일, 전문분야, 태그 통합 검색
- **메모 & 태그 시스템**: 테스터별 개별 메모 및 다중 태그 관리
- **성과 추적 대시보드**: 완료율, 품질점수, 응답시간 실시간 모니터링
- **실시간 상태 관리**: 활성/비활성 테스터 상태 추적 및 필터링

### 🚀 NEW! 완전한 백엔드 서버 시스템 (v1.3.01)
- **Node.js REST API 서버**: Express.js 기반 완전한 백엔드 인프라
- **종합 API 엔드포인트**: 인증, 미션, 앱 관리, 파일 업로드, 알림, 분석
- **AWS S3 파일 스토리지**: Sharp 이미지 처리와 함께 APK/이미지 업로드 시스템
- **Docker 컨테이너화**: docker-compose.yml로 원클릭 배포 환경
- **개발 환경 자동화**: 완전한 설정 스크립트 및 문서화
- **실시간 Mock 데이터**: Firebase 없이도 작동하는 개발 친화적 환경

### 📱 Provider 앱 관리 시스템 (v1.3.01)
- **완전한 앱 업로드 시스템**: 4가지 설치 유형 지원 (Play Store, APK, TestFlight, Enterprise)
- **앱 진행 상황 추적**: 실시간 테스터 수, 버그 리포트 현황, 해결률 통계
- **멀티플랫폼 지원**: Android APK, iOS IPA, 웹 앱, 엔터프라이즈 앱
- **시각적 관리 인터페이스**: 카드 기반 앱 목록 및 상세 통계
- **테스터 연동**: 공급자가 업로드한 앱이 자동으로 테스터 검색에 나타남

### 🔧 버그 수정 및 코드 품질 개선 (v1.3.01)
- **Hero 태그 충돌 해결**: FloatingActionButton 고유 heroTag 적용
- **Flutter Analyzer 오류 수정**: 129개→0개 오류로 완전한 코드 품질 확보
- **UserEntity 강화**: level, points, completedMissions 필드 추가
- **타입 안전성 개선**: null-aware 연산자 최적화 및 타입 오류 해결

### 📅 일일 미션 진행률 추적 시스템 (v1.2.0)
- **날짜별 진행 표시**: "몇월몇칠 1일차 미션" 형식으로 오늘 해야 할 미션을 명확히 표시
- **달력형 진행 현황**: 7열 그리드 달력으로 일일 진행 상황을 한눈에 확인
- **체크박스 스타일 완료 표시**: 간결한 ✓, ●, ✕ 아이콘으로 완료/진행/놓침 상태 표시
- **실시간 진행률 업데이트**: 완료된 일수 기반으로 전체 진행률 자동 계산
- **오늘 미션 하이라이트**: 오늘 해야 할 미션을 주황색으로 강조 표시

### 🔔 실시간 알림 시스템
- **FCM 푸시 알림**: Firebase Cloud Messaging을 통한 실시간 알림
- **카테고리별 알림**: 미션/포인트/랭킹/시스템/홍보별 세밀한 설정
- **로컬 알림**: 예약된 알림 및 오프라인 알림 처리
- **알림 관리**: 읽음/삭제, 필터링, 알림 히스토리 관리

### 📱 오프라인 지원 시스템
- **완전한 오프라인 기능**: 인터넷 없이도 모든 앱 기능 이용 가능
- **스마트 동기화**: 연결 복원 시 자동 데이터 동기화 및 충돌 해결
- **로컬 캐싱**: 효율적인 데이터 캐싱 및 만료 관리 시스템

### 🔍 고급 검색 시스템
- **실시간 검색**: 미션명, 앱명, 카테고리별 즉시 검색
- **검색 히스토리**: 최근 검색어 자동 저장 및 관리
- **인기 검색어**: 실시간 인기 검색 키워드 제공
- **Provider 앱 통합**: 공급자 앱이 테스터 검색 결과에 자동 포함

### 🏆 랭킹 시스템
- **실시간 랭킹**: 포인트 기반 사용자 순위 시스템
- **티어별 랭킹**: BRONZE/SILVER/GOLD/PLATINUM 등급별 리더보드
- **개인 통계**: 상위 퍼센트, 순위 변동, 월별 성과 추적

## 🌐 백엔드 서버 아키텍처 (v1.3.01)

### 📡 API 엔드포인트
```
🏥 /health                          - 서버 상태 확인
🔐 /api/auth/*                      - 사용자 인증 및 프로필 관리
📱 /api/apps/*                      - Provider 앱 등록 및 관리
🎯 /api/missions/*                  - 미션 생성 및 참여
📤 /api/upload/*                    - 파일 업로드 (APK, 이미지)
🔔 /api/notifications/*             - 실시간 알림 시스템
📊 /api/analytics/*                 - 플랫폼/공급자/테스터 분석
```

### 🐳 Docker 배포 스택
```yaml
🚀 Node.js API Server (Port: 3001)
🗄️ Redis Cache (Port: 6379)
🐘 PostgreSQL Database (Port: 5432)
🌐 Nginx Load Balancer (Port: 80/443)
📊 Prometheus Monitoring (Port: 9090)
📈 Grafana Dashboards (Port: 3001)
```

### 🛠️ 기술 스택
- **Runtime**: Node.js 20.19.2
- **Framework**: Express.js 4.18.2
- **Database**: PostgreSQL 15 + Redis 7
- **Storage**: AWS S3 + Sharp 이미지 처리
- **Authentication**: Firebase Admin SDK
- **Validation**: express-validator 7.2.1
- **DevOps**: Docker + docker-compose
- **Monitoring**: Prometheus + Grafana

## 🏗️ 프로젝트 구조

```
BugCash/
├── bugcash/                        # Flutter 앱
│   ├── lib/
│   │   ├── core/                   # 핵심 인프라
│   │   ├── features/               # 기능별 모듈
│   │   │   ├── chat/               # 실시간 채팅 시스템 (NEW!)
│   │   │   │   ├── data/          # 데이터 레이어
│   │   │   │   ├── domain/        # 도메인 레이어
│   │   │   │   └── presentation/  # 프레젠테이션 레이어
│   │   │   ├── provider_dashboard/ # 공급자 대시보드
│   │   │   │   └── pages/
│   │   │   │       └── app_management_page.dart
│   │   │   ├── search/             # 검색 시스템 (ENHANCED!)
│   │   │   ├── notifications/      # 알림 시스템
│   │   │   └── ranking/            # 랭킹 시스템
│   │   └── shared/                 # 공유 컴포넌트
└── server/                         # Node.js 백엔드 (NEW!)
    ├── src/
    │   ├── routes/                 # API 라우트
    │   │   ├── auth.js            # 인증 관리
    │   │   ├── apps.js            # 앱 관리
    │   │   ├── missions.js        # 미션 시스템
    │   │   ├── upload.js          # 파일 업로드
    │   │   ├── notifications.js   # 알림 시스템
    │   │   └── analytics.js       # 분석 데이터
    │   └── index.js               # 메인 서버 파일
    ├── docker-compose.yml         # Docker 스택 구성
    ├── Dockerfile                 # 컨테이너 이미지
    ├── package.json               # 의존성 관리
    └── README.md                  # 서버 문서화
```

## 🚀 시작하기

### 📋 필요 조건
- **Flutter SDK**: 3.29.2 이상
- **Dart SDK**: 3.7.2 이상  
- **Node.js**: 18+ (서버용)
- **Docker**: 최신 버전 (서버 배포용)

### 🔧 Flutter 앱 설치 및 실행

1. **저장소 클론**
```bash
git clone https://github.com/jagallang/BUG.git
cd BUG/bugcash
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **앱 실행**
```bash
flutter run -d chrome  # 웹에서 실행
flutter run -d android # Android에서 실행
```

### 🌐 백엔드 서버 설치 및 실행

1. **서버 디렉토리로 이동**
```bash
cd BUG/server
```

2. **의존성 설치**
```bash
npm install
```

3. **개발 서버 실행**
```bash
npm run dev
# 서버가 http://localhost:3001 에서 실행됩니다
```

4. **Docker로 전체 스택 실행**
```bash
docker-compose up -d
# 전체 백엔드 스택이 실행됩니다 (Redis, PostgreSQL, Nginx 포함)
```

### 🧪 API 테스트
```bash
# 서버 상태 확인
curl http://localhost:3001/health

# 미션 목록 조회
curl http://localhost:3001/api/missions

# 앱 목록 조회
curl http://localhost:3001/api/apps/provider/mock-provider-123
```

## 🧪 테스트 계정

앱은 **Mock 인증 시스템**으로 구동되며, Firebase 설정 없이 즉시 테스트가 가능합니다.

### Provider (앱 공급자) 계정
| 계정 타입 | 이메일 | 비밀번호 | 설명 |
|-----------|--------|----------|------|
| 🏢 관리자 | admin@techcorp.com | admin123 | TechCorp Ltd. 관리자 |
| 👨‍💼 공급자 | provider@gamedev.com | provider123 | GameDev Studio 개발팀 |
| 🏭 기업 | company@fintech.com | company123 | FinTech Solutions |
| 💻 개발자 | developer@startup.com | dev123 | Startup Inc. 개발자 |
| 🔍 QA | qa@enterprise.com | qa456 | Enterprise Solutions QA |

### Tester (테스터) 계정  
| 계정 타입 | 이메일 | 비밀번호 | 설명 |
|-----------|--------|----------|------|
| 👤 김테스터 | tester1@gmail.com | tester123 | 일반 앱 테스터 |
| 🎨 이사용자 | tester2@gmail.com | test456 | UI/UX 전문 테스터 |
| 🔒 박검증자 | tester3@gmail.com | tester789 | 보안 전문 테스터 |
| 🏆 최버그헌터 | tester4@gmail.com | test999 | 버그 헌팅 전문가 |
| 📱 정모바일테스터 | tester5@gmail.com | tester555 | 모바일 앱 전문 |
| 🌐 강웹테스터 | tester6@naver.com | naver123 | 웹 애플리케이션 전문 |

### 🔧 채팅 시스템 테스트 (v1.4.00)
- **로그인 우회 기능**: 채팅 페이지에서 "테스트용 로그인 우회" 버튼 클릭
- **회원 검색**: 검색 아이콘으로 위 계정들을 이름이나 이메일로 검색
- **1:1 채팅 시작**: 검색 결과에서 채팅 버튼 클릭하여 즉시 채팅 시작

## 🔧 주요 버전 정보

### 🏢 v1.4.16 (2025-09-17) - 공급자 앱 상세 관리 시스템 & 하드코딩 데이터 완전 제거

#### ✨ 핵심 신규 기능
- **📱 새로운 앱 상세 관리 페이지**: `app_detail_page.dart` 생성으로 공급자의 종합적인 앱 관리 인터페이스 제공
- **🔧 4개 섹션 완전 관리 시스템**:
  - **📝 앱 기본 정보 관리**: 이름, URL, 설명, 카테고리 실시간 수정
  - **🎯 앱 게시 상태 토글**: "활성/비활성" 스위치로 테스터 노출 여부 제어
  - **📢 앱 공지사항 시스템**: 체크박스 토글 + 공지 내용 작성으로 테스터 알림 관리
  - **💰 단가 설정 + 요구사항**: 포인트 기반 보상 설정 및 특별 지시사항 입력
- **🔗 실시간 공급자-테스터 연동**: 모든 설정이 즉시 테스터 미션 탭에 반영되는 완전한 워크플로우
- **🚀 하드코딩 데이터 완전 제거**: `_generateAvailableMissions`, `_generateActiveMissions`, `_generateCompletedMissions` 등 모든 가짜 데이터 생성 메서드 삭제
- **💾 Firebase 메타데이터 확장**: `metadata` 필드에 `hasAnnouncement`, `announcement`, `price`, `requirements`, `isActive` 저장

#### 🛠️ 기술적 구현 세부사항
- **새로운 파일**: `app_detail_page.dart` (477줄) - 완전한 앱 관리 인터페이스
- **네비게이션 개선**: `app_management_page.dart`의 "상세보기" 버튼에 `Navigator.push` 및 결과 처리 로직
- **데이터 모델 확장**: `MissionCard` 클래스에 `isProviderApp`, `originalAppData` 필드 추가
- **UI 컴포넌트 분화**: `ProviderAppMissionCard` 사용으로 일반 미션과 공급자 앱 구분 표시
- **헬퍼 메서드 추가**: `_hasAnnouncement`, `_getAnnouncement`, `_hasPrice`, `_getPrice`, `_hasRequirements`, `_getRequirements`
- **상태 관리**: Riverpod `ref.refresh()` 활용으로 앱 목록 실시간 업데이트
- **Firebase 쿼리 최적화**: `isActive` 필드 기반 활성 앱만 테스터에게 노출

#### 🔍 해결된 주요 문제
- **하드코딩 의존성**: 테스터 미션 탭의 모든 가짜 데이터를 실제 공급자 데이터로 교체
- **공급자-테스터 단절**: 공급자 설정이 테스터에게 반영되지 않던 문제 완전 해결
- **앱 관리 한계**: 기본적인 앱 정보만 수정 가능했던 것을 포괄적 관리 시스템으로 확장
- **사용자 경험**: 테스터가 공급자의 공지사항, 보상, 요구사항을 명확히 확인 가능

### 🎨 v1.4.15 (2025-09-17) - 공급자 대시보드 UI 단순화 및 Firestore 인덱스 최적화

#### ✨ 핵심 개선 사항
- **🗑️ 테스터관리/테스트세션 탭 완전 제거**: 공급자 대시보드에서 불필요한 기능 2개 완전 삭제
- **🎯 앱 관리 중심 UI 재설계**: 복잡한 3-탭 시스템을 단일 앱 관리 페이지로 단순화
- **🏗️ 아키텍처 최적화**: TabController, TabBar, TabBarView 구조 완전 제거로 성능 향상
- **📝 명확한 페이지 타이틀**: "통합 관리" → "앱 관리"로 변경하여 기능 명시
- **⚡ Firestore 인덱스 추가**: payouts 컬렉션 인덱스 배포로 앱 크래시 문제 해결

#### 🛠️ 기술적 구현 세부사항
- **파일 삭제**: `tester_management_tab.dart`, `test_session_application_tab.dart` 완전 제거
- **UI 구조 변경**: `TabBarView` → `Expanded(child: _buildAppsTab(apps))` 단일 위젯화
- **상태 관리 최적화**: `TickerProviderStateMixin` 및 `TabController` 제거
- **Import 정리**: 삭제된 탭 파일들의 import 문 제거
- **Firestore 인덱스**: `firestore.indexes.json`에 payouts 컬렉션 복합 인덱스 추가
- **Firebase 배포**: `firebase deploy --only firestore:indexes`로 누락 인덱스 배포

#### 🔍 해결된 주요 문제
- **복잡한 UI 구조**: 불필요한 3-탭 네비게이션으로 인한 사용자 혼란 해결
- **코드 복잡성**: 1,841줄의 불필요한 코드 제거로 유지보수성 대폭 향상
- **앱 크래시**: Firestore payouts 쿼리 인덱스 누락으로 인한 FAILED_PRECONDITION 오류 해결
- **성능 이슈**: TabController 및 관련 상태 관리 오버헤드 제거

### 🔧 v1.4.14 (2025-09-16) - Firestore 인덱스 문제 해결 & 공급자 대시보드 데이터 로딩 수정

#### ✨ 핵심 문제 해결
- **📊 Firestore 복합 인덱스 누락 문제**: `FAILED_PRECONDITION` 오류의 근본 원인 발견 및 해결
- **🎯 "제공자 ID '알려지지 않은'" 이슈 완전 해결**: providerId 매칭 실패로 인한 데이터 로딩 실패 수정
- **⚡ 7개 핵심 인덱스 추가**: test_sessions(providerId+createdAt, testerId+createdAt), provider_apps, activities, earnings, missionApplications, chat_rooms
- **🔄 완전한 TestSession 워크플로우**: 미션 참여 → 공급자 승인 대기 → 활성 테스트 프로세스 구현

#### 🛠️ 기술적 구현 세부사항
- **Firebase 인덱스 배포**: `firestore.indexes.json`에 누락된 복합 인덱스 7개 추가 및 배포
- **디버깅 시스템 구축**: TestSessionService, TestSessionApplicationTab에 포괄적 로깅 시스템
- **임시 수정 로직**: currentUserId를 사용한 providerId 매칭 대안 로직 구현
- **타입 안전성 강화**: phoneNumber 필드의 int→string 타입 변환 안전장치
- **로그아웃 프로세스 개선**: Firebase Auth 이중 로그아웃 및 상태 초기화 보장
- **실시간 데이터 연동**: 테스터 대시보드에서 Mock 데이터 제거하고 실제 Firebase 데이터 연동

#### 🔍 해결된 주요 문제
- **데이터 로딩 실패**: 공급자 대시보드에서 "제공자 ID 알려지지 않은" 오류로 TestSession 데이터 로딩 불가
- **Firestore 쿼리 실패**: 복합 인덱스 누락으로 인한 모든 providerId 기반 쿼리 실패
- **워크플로우 단절**: 테스터가 미션 신청해도 공급자 화면에 표시되지 않는 문제
- **Mock 데이터 의존성**: 테스터 대시보드의 하드코딩된 데이터를 실제 Firebase 데이터로 교체

### 🔧 v1.4.10 (2025-09-14) - 인증 시스템 개선 & 사용자 데이터 통합

#### ✨ 핵심 개선 사항
- **👤 하드코딩 데이터 완전 제거**: `tester_dashboard_provider.dart`에서 하드코딩된 '김테스터' 완전 제거
- **🔄 실제 백엔드 데이터 연동**: `CurrentUserService.getUserProfile()` 기반 Firestore 실시간 사용자 데이터 로드
- **🚪 로그아웃 기능 완전 수정**: Mock 사용자와 Firebase 사용자 모두 지원하는 통합 로그아웃 시스템
- **🔐 인증 상태 관리 개선**: AuthProvider에서 경합 상태(race condition) 해결
- **🐛 포괄적인 디버그 시스템**: 인증 플로우 전체에 대한 상세 로깅 시스템

#### 🛠️ 기술적 구현 세부사항
- **사용자 프로필 로드 개선**: `_loadTesterProfile` 메서드를 Firebase 연동으로 완전 교체
- **HybridAuthService 로그아웃 개선**: Mock 사용자 감지 및 포괄적 로깅 시스템
- **AuthProvider 상태 관리**: 수동 상태 설정 제거로 auth 스트림 자동 처리
- **안전한 데이터 파싱**: null safety와 fallback 값을 통한 안정적 데이터 처리
- **테스터 레벨 변환**: `_getTesterLevelFromString` 헬퍼 메서드로 문자열-enum 변환

#### 🔍 해결된 주요 문제
- **하드코딩 이슈**: 다른 사용자로 로그인 후에도 '김테스터'가 표시되던 문제 해결
- **로그아웃 실패**: 햄버거 메뉴 로그아웃이 작동하지 않던 문제 완전 해결
- **상태 동기화**: 인증 상태와 UI 상태 간 불일치 문제 해결
- **Mock 인증 처리**: Mock 사용자 로그아웃 시 적절한 처리 로직 추가

### 🔐 v1.4.09 (2025-09-14) - 통합 인증 시스템 & 공급자 신청 시스템

#### ✨ 혁신적인 사용자 경험 개선
- **🎯 단일화된 회원가입**: 복잡한 사용자 타입 선택(테스터/공급자) 완전 제거로 간소화된 가입 프로세스
- **👤 테스터 우선 전략**: 모든 신규 사용자가 테스터 모드로 시작하여 즉시 앱 테스트 참여 가능
- **📋 시각적 가이드 시스템**: 가입 안내 카드로 테스터 혜택과 공급자 업그레이드 경로 명확히 안내
- **🔒 보안 기반 모드 전환**: 비밀번호 재확인을 통한 안전한 공급자 모드 업그레이드 시스템
- **🍔 직관적 햄버거 메뉴**: "공급자 기능" → "공급자 신청"으로 의도 명확화 및 접근성 향상
- **💬 완전한 피드백 루프**: 성공/실패에 대한 실시간 스낵바 알림 및 사용자 상태 안내

#### 🛠️ 기술적 구현 세부사항
- **UI 컴포넌트 개선**: signup_page.dart에서 _UserTypeCard 클래스 제거 및 정보 제공 카드 추가
- **인증 흐름 간소화**: 모든 신규 사용자를 `UserType.tester`로 기본 설정
- **다이얼로그 시스템**: `_showProviderApplicationDialog` 메서드로 완전한 공급자 신청 워크플로우
- **비밀번호 검증**: `_verifyPasswordAndSwitchToProvider` 메서드로 보안 기반 모드 전환
- **네비게이션 최적화**: MaterialPageRoute를 통한 부드러운 대시보드 전환
- **상태 관리**: 실시간 UI 업데이트 및 오류 처리 시스템 완성
- **코드 품질**: 불필요한 import 제거 및 사용되지 않는 클래스 정리

### 🚀 v1.4.07 (2025-09-14) - 완전한 14일 앱 테스트 워크플로우 시스템

#### ✨ 혁신적인 새 기능
- **📋 ExpandableMissionCard 시스템**: 미션 카드 탭 시 상세 정보 표시 및 애니메이션 전환
- **🎯 완전한 테스터 신청 워크플로우**: "14일 테스트 신청하기" → 공급자 승인 → 진행중 탭 이동 전체 프로세스
- **📱 ActiveTestSessionCard**: 14일간의 일일 테스트 진행 상황을 시각적으로 추적하는 카드 시스템
- **🎛️ DailyTestApprovalWidget**: 공급자가 테스터의 일일 테스트를 승인/거부할 수 있는 완전한 관리 시스템
- **🔄 실시간 상태 동기화**: TestSessionService를 통한 Firebase 실시간 데이터 동기화
- **💬 사용자 친화적 다이얼로그**: 성공 확인, 오류 처리, 로딩 상태를 포함한 완전한 UX

#### 🛠️ 기술적 구현 세부사항
- **새로운 데이터 모델**: TestSession, DailyTestProgress, TestSessionStatus, DailyTestStatus enum
- **서비스 레이어**: TestSessionService로 테스트 세션 생성, 일일 테스트 제출, 승인 처리
- **UI 컴포넌트**: ExpandableMissionCard, ActiveTestSessionCard, DailyTestApprovalWidget 위젯
- **애니메이션 시스템**: AnimationController 기반 smooth expand/collapse 전환
- **Mock 데이터 지원**: 실제 Firebase 없이도 완전한 워크플로우 테스트 가능
- **타입 안전 enum 처리**: MissionType, MissionDifficulty enum에 대한 완전한 한글 텍스트 변환
- **상태 관리 개선**: Riverpod 기반 실시간 상태 업데이트 및 오류 처리

### 🎯 v1.4.05 (2025-09-11) - 일관된 FAB 위치 개선

#### ✨ 사용자 경험 개선
- **📍 고정된 채팅 FAB 위치**: 테스터 모드에서 모든 탭('미션찾기', '진행중', '완료')에서 동일한 중간 위치로 채팅 버튼 완전 고정
- **🔧 Custom FloatingActionButtonLocation**: `_CustomFabLocation` 클래스 구현으로 Y 좌표 120px 고정 위치 제공
- **✨ 일관성 있는 UX**: 탭 변경 시 FAB 위치가 달라지는 사용자 혼란 완전 제거
- **🎯 최적화된 위치**: 하단 탭바 위 적절한 거리에 위치하여 엄지 접근성 향상
- **⚡ 효율적인 상태 관리**: 불필요한 TabController 리스너 제거로 성능 개선

#### 🛠️ 기술적 구현 세부사항
- **커스텀 FAB 위치 클래스**: `class _CustomFabLocation extends FloatingActionButtonLocation`
- **고정 좌표 계산**: `final double y = scaffoldGeometry.scaffoldSize.height - height - 120.0`
- **단일 위치 적용**: `floatingActionButtonLocation: _CustomFabLocation()` 모든 탭에 적용
- **상태 최적화**: TabController addListener() 제거로 불필요한 setState() 호출 방지
- **코드 정리**: 탭별 조건부 로직 제거로 더 깔끔한 코드베이스

### 🎨 v1.4.04 (2025-09-11) - 테마 분리 & UI/UX 개선

#### ✨ 혁신적인 디자인 개선
- **🎨 완전한 색상 테마 분리**: 앱테스터(녹색)와 앱공급자(인디고) 역할별 색상 체계 분리
- **🔵 인디고 테마 Provider Dashboard**: AppBar, 버튼, 상태 표시, 네비게이션 모두 indigo[700-900] 통일
- **🟢 그린 테마 Tester Interface**: 기존 green 테마 완전 유지로 역할별 시각적 구분 강화
- **📱 모바일 친화적 하단 탭**: 미션 탭바를 상단에서 하단으로 이동하여 엄지 접근성 향상
- **🛡️ 시스템 UI 충돌 해결**: MediaQuery 패딩으로 Android 네비게이션 바와의 겹침 방지
- **⚡ 동적 FAB 위치**: 탭 변경 시 채팅 FloatingActionButton이 자동으로 위치 조정
- **✨ 실시간 UI 업데이트**: TabController 리스너로 탭 변경에 따른 즉시 UI 반영

#### 🛠️ 기술적 구현 세부사항
- **7개 파일 동시 수정**: Provider Dashboard 전체 컴포넌트 색상 체계 통일
- **조건부 FAB 렌더링**: `_tabController.index == 1 ? FloatingActionButtonLocation.endTop : FloatingActionButtonLocation.endFloat`
- **MediaQuery 반응형 설계**: `height: 60.h + MediaQuery.of(context).padding.bottom`로 기기별 최적화
- **Colors.indigo 완전 적용**: indigo[50], indigo[100], indigo[700], indigo[900] 단계적 색상 적용
- **TabController 상태 관리**: addListener()로 탭 변경 시 setState() 호출하여 FAB 위치 동적 업데이트
- **앱바 테마 통일**: backgroundColor: Colors.indigo[900], foregroundColor: Colors.white 일관성
- **버튼 스타일 표준화**: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700]) 전체 적용

### 💬 v1.4.00 (2025-09-10) - 완전한 실시간 채팅 시스템

#### ✨ 혁신적인 새 기능
- **🏗️ Clean Architecture 기반 채팅 시스템**: Domain-Data-Presentation 레이어로 완전히 분리된 확장 가능한 채팅 아키텍처
- **🔥 Firebase Firestore 실시간 메시징**: 실시간 메시지 전송, 읽음 상태, 타이핑 인디케이터, 온라인 상태 완벽 지원
- **5가지 채팅방 유형**: 1:1 직접 채팅, 미션 채팅, 고객 지원 채팅, 그룹 채팅, 공지 채팅방
- **👤 완전한 회원 검색 시스템**: 11명의 Mock 사용자 계정으로 실제 검색 환경 시뮬레이션
- **🚀 개발자 친화적 테스트 환경**: 로그인 우회 버튼으로 Firebase 설정 없이 즉시 채팅 기능 테스트
- **💬 고급 채팅 UI 컴포넌트**: 메시지 버블, 시간 표시, 읽음 상태, 타이핑 인디케이터 완전 구현
- **📊 실시간 알림 시스템**: 읽지않음 메시지 카운트 배지와 실시간 업데이트
- **🔗 미션 시스템 완전 연동**: 미션 참여 시 자동 채팅방 생성 및 관리 워크플로우
- **📱 완전한 UI 통합**: 테스터/공급자 대시보드에 채팅 FAB 버튼과 배지 시스템 추가

#### 🛠️ 기술적 구현
- **새로운 도메인 모델**: Message, ChatRoom, ChatRoomType, MessageStatus, MessageType enum
- **Repository Pattern**: ChatRepository로 데이터 추상화 및 Firebase 연동
- **Riverpod 상태 관리**: 채팅 상태, 메시지, 사용자 검색을 위한 완전한 Provider 시스템
- **UI 컴포넌트**: MessageBubble, MessageInput, TypingIndicator, ChatAppBar 재사용 가능 위젯
- **Mock 데이터 시스템**: 11명의 다양한 테스터/공급자 계정으로 완전한 테스트 환경
- **로그인 우회 시스템**: setMockUser 메서드로 개발 및 테스트 편의성 극대화
- **실시간 동기화**: Firebase Auth State와 채팅 시스템 완전 연동

### 🏗️ v1.3.07 (2025-01-10) - Clean Architecture & 확장 가능한 구조

#### ✨ 아키텍처 개선
- **🏛️ Clean Architecture 전면 적용**: Domain, Data, Presentation 레이어 명확히 분리
- **💉 의존성 주입 개선**: GetIt과 Injectable을 활용한 DI 컨테이너 구성
- **📁 모듈화 구조**: 기능별 독립적인 모듈로 재구성

#### 🆕 신규 기능 준비
- **💳 결제 시스템 아키텍처**: Payment 도메인 설계 (카카오페이, 네이버페이, 토스페이 지원 예정)
- **💬 실시간 채팅 아키텍처**: Chat 도메인 설계 (1:1, 그룹, 미션 채팅 지원)
- **🔄 Repository Pattern**: 데이터 추상화 레이어 구현

#### 🐛 버그 수정
- **✅ MissionType enum 중복 제거**: functional, performance 등 중복 타입 정리
- **✅ MissionDifficulty 클래스명 충돌 해결**: MissionDifficultyAnalysis로 변경
- **✅ Switch 문 누락 case 추가**: 모든 enum 타입에 대한 완전한 처리
- **✅ 사용하지 않는 import 및 코드 제거**: 코드베이스 정리

#### 📚 문서화
- **📖 ARCHITECTURE.md 생성**: 전체 아키텍처 가이드라인 문서
- **📝 코드 주석 개선**: 주요 클래스 및 메서드 문서화
- **🗺️ 확장 로드맵 추가**: 향후 기능 개발 계획

### 🚀 v1.3.06 (2025-09-09) - 미션 신청 및 승인 시스템

#### ✨ 혁신적인 새 기능
- **🎯 완전한 미션 신청 워크플로우**: 테스터 미션 발견 → 테스트 → 신청 → 공급자 승인/거부 → 테스트 시작 전체 프로세스
- **📋 상세 신청 다이얼로그**: 공급자 요구사항 확인, 앱 설치 준비 체크리스트, 개인 어필 메시지 작성
- **🏢 공급자 신청 관리**: 테스터 프로필(경험/평점/전문분야) 확인 후 승인/거부 결정 시스템
- **💬 양방향 커뮤니케이션**: 테스터 신청 메시지 ↔ 공급자 응답 메시지 완전한 소통 체계
- **📊 신청 현황 통계**: 대기중/검토중/승인됨 상태별 실시간 관리 대시보드
- **🔔 통합 알림 시스템**: 신청-승인-거부 전 단계 실시간 알림 (MissionNotification 모델)
- **👤 테스터 프로필**: 경험 년수, 완료 미션 수, 평점, 전문 분야 종합 정보 시스템
- **⚡ 스마트 상태 관리**: MissionApplicationStatus enum 기반 체계적 상태 추적

#### 🛠️ 기술적 구현
- **새로운 데이터 모델**: MissionApplication, MissionApplicationStatus, MissionNotification, NotificationType
- **미션 신청 다이얼로그**: MissionApplicationDialog 위젯으로 사용자 친화적 신청 인터페이스
- **공급자 관리 위젯**: MissionApplicationsWidget으로 신청 승인/거부 완전 관리
- **실시간 상태 업데이트**: 신청-검토-승인/거부 상태의 실시간 UI 반영
- **Mock 데이터 통합**: Firebase 없이도 완전한 워크플로우 테스트 가능

### 🚀 v1.3.05 (2025-09-09) - 완료된 미션 관리 & 포인트 정산 시스템

#### ✨ 혁신적인 새 기능
- **🏆 3단계 미션 탭 시스템**: 기존 2탭(미션 찾기, 진행 중)에서 '완료' 탭 추가로 전체 미션 라이프사이클 관리
- **🔄 지능형 정산 시스템**: 정산 대기 → 정산 처리중 → 정산 완료 3단계 자동 상태 관리
- **🎨 시각적 상태 표시**: 주황색(대기), 파란색(처리중), 녹색(완료) 색상 코딩으로 직관적 상태 파악
- **📊 완료 미션 대시보드**: 포인트, 평점, 완료일, 정산 상태 등 종합 정보를 카드 형태로 표시
- **⚡ 자동 정산 연동**: 공급자의 포인트 정산 완료 시 완료된 미션이 자동으로 목록에서 제거

#### 🛠️ 사용자 경험 개선
- **상세 정산 정보 다이얼로그**: '정산 대기' 버튼 클릭 시 미션 세부 사항 및 정산 진행 상황 안내
- **빈 상태 UI**: 완료된 미션이 없을 때 사용자 친화적인 안내 메시지 및 액션 가이드
- **실시간 상태 업데이트**: 공급자 대시보드의 결제 시스템과 실시간 연동되는 정산 상태 변경
- **한글 완전 지원**: 모든 정산 관련 텍스트와 UI가 한국어로 완벽 현지화

### 🚀 v1.3.04 (2025-09-09) - 업그레이드된 커뮤니티 게시판 시스템

#### ✨ 혁신적인 새 기능
- **📋 새로운 카테고리 시스템**: 기존 '버그발견', '팁공유', '미션추천', '질문'을 실용적인 6개 카테고리로 전면 개편
- **👥 채용 중심 게시판**: '모집중', '모집완료', '구인', '구직' 카테고리로 테스터 채용 생태계 강화
- **🎨 카테고리별 색상 코딩**: 직관적인 색상으로 게시글 구분 (녹색-모집중, 회색-모집완료, 파란색-구인, 보라색-구직, 주황색-질문, 청록색-기타)
- **🏷️ 스마트 태그 선택**: 게시글 작성 시 드롭다운으로 카테고리 태그 선택 가능
- **📝 다양한 게시글 템플릿**: 모집공고, 프로젝트 완료 알림, 채용정보, 구직활동, 기술질문, 일상소통 등 실제 사용 사례 반영

#### 🛠️ 커뮤니티 개선사항
- **실시간 필터링**: 카테고리별 즉석 필터링으로 원하는 게시글만 선별 조회
- **향상된 UX**: 카테고리 태그와 색상 코딩으로 한눈에 파악 가능한 직관적 인터페이스
- **확장성**: 향후 새로운 카테고리 추가 용이한 유연한 구조
- **한글 완전 지원**: 모든 카테고리와 UI가 한국어로 완벽 현지화

### 🚀 v1.3.03 (2025-09-09) - 통합 결제 관리 시스템

#### ✨ 혁신적인 새 기능
- **💳 통합 결제 관리 시스템**: 분석 탭을 완전한 결제 관리 시스템으로 교체
- **📊 결제 대시보드**: 예산 개요, 할당 자금, 잔여 예산 실시간 모니터링
- **🔄 포인트 배분 자동화**: 결제 금액을 테스터 포인트로 자동 변환 및 배분
- **📈 결제 히스토리**: 모든 결제 내역과 상태 추적 (대기→완료→처리→배분)
- **⚡ 빠른 액션**: 새 결제, 포인트 배분, 결제 히스토리, 정산 리포트 원클릭 접근

#### 🛠️ 시스템 개선
- **결제 탭으로 전환**: 하단 네비게이션의 분석 탭을 결제 탭으로 완전 교체
- **Interactive UI**: 실시간 결제 처리 다이얼로그 및 상태 업데이트
- **Mock 결제 시스템**: 실제 결제 워크플로우를 시뮬레이션하는 완전한 시스템
- **한글 인터페이스**: 모든 결제 관련 UI가 한국어로 완전히 현지화

### 🚀 v1.3.01 (2025-09-09) - Provider 앱 관리 & Node.js 백엔드 서버

#### ✨ 혁신적인 새 기능
- **🌐 완전한 Node.js 백엔드**: Express.js 기반 REST API 서버 구축
- **📱 Provider 앱 관리 시스템**: 앱 업로드, 관리, 진행 상황 추적
- **🔧 버그 수정**: Hero 태그 충돌 및 Flutter analyzer 오류 완전 해결
- **🔗 검색 통합**: Provider 앱이 테스터 검색 결과에 자동 포함

#### 🛠️ 백엔드 서버 기능
- **6개 주요 API 라우트**: auth, apps, missions, upload, notifications, analytics
- **AWS S3 통합**: APK 파일 및 이미지 업로드 with Sharp 처리
- **Docker 완전 지원**: docker-compose로 원클릭 배포
- **Mock 데이터 지원**: Firebase 없이 개발 가능한 환경
- **포트 3001**: Rails와 충돌하지 않는 안전한 포트 설정

#### 📱 Provider Dashboard 강화
- **앱 관리 페이지**: 업로드한 앱 목록 및 상세 통계 표시
- **4가지 설치 타입**: Play Store, APK 업로드, TestFlight, Enterprise
- **실시간 진행 추적**: 테스터 수, 버그 리포트, 해결률 모니터링
- **시각적 UI**: 카드 기반 인터페이스로 직관적 관리

#### 🐛 코드 품질 개선
- **Hero 태그 수정**: 3개 FloatingActionButton에 고유 heroTag 적용
- **Flutter 오류 해결**: 129개 오류를 모두 수정하여 깔끔한 코드베이스
- **UserEntity 확장**: level(int), points, completedMissions 필드 추가
- **타입 안전성**: null-aware 연산자 및 타입 캐스팅 최적화

### 🚀 v1.2.03 (2025-08-31) - 앱 등록 시스템 & Provider Dashboard 완전 통합
- **📱 4단계 앱 등록 시스템**: 기본정보 → 상세정보 → 미디어파일 → 검토제출 완전 구현
- **☁️ Firebase Storage 통합**: 앱 아이콘, 스크린샷, 바이너리 파일 안전한 클라우드 저장
- **🎯 다중 플랫폼 지원**: Android(APK), iOS(IPA), Web(ZIP), Desktop(EXE) 통합 지원

### 🚀 v1.2.0 (2025-08-31) - 일일 미션 진행률 추적 시스템
- **일일 미션 진행률 추적**: "몇월몇칠 1일차 미션" 형식으로 날짜별 진행 상황 표시
- **달력형 UI**: 7열 그리드 달력으로 일일 진행 현황을 직관적으로 시각화
- **접이식 앱바**: 닉네임 클릭 시에만 확장되는 미니멀한 상단 앱바 인터페이스

## 📊 기술 스택

### Frontend
- **UI Framework**: Flutter 3.29.2 (Material Design 3)
- **State Management**: Riverpod 2.4.9
- **Navigation**: Flutter Navigator 2.0
- **Responsive Design**: flutter_screenutil 5.9.0

### Backend (NEW!)
- **Runtime**: Node.js 20.19.2
- **Framework**: Express.js 4.18.2
- **Database**: PostgreSQL 15 + Redis 7
- **Storage**: AWS S3 + Sharp image processing
- **Validation**: express-validator 7.2.1
- **Container**: Docker + docker-compose

### Services  
- **Database**: Firebase Firestore (실시간 리스너)
- **Storage**: Firebase Storage + AWS S3
- **Authentication**: Firebase Auth + Mock System
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Connectivity**: connectivity_plus 6.1.0

## 🔒 보안 개선사항 (v1.4.13)

### Firebase Storage Rules 강화
```javascript
// Before (Critical Security Issue)
match /{allPaths=**} {
  allow read, write: if true;  // 누구나 접근 가능 ⚠️
}

// After (Secure)
match /users/{userId}/profile/{allPaths=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId
               && request.resource.size < 5 * 1024 * 1024;
}
```

### 코드 품질 지표
- **Lint Issues**: 241 → 86 (64% 감소)
- **Print Statements**: 완전 제거 (0개)
- **Test Coverage**: 프로덕션 배포용 최적화
- **Dependencies**: 모든 보안 패치 적용

## 📝 기여하기

1. **Fork** 버튼을 클릭하여 저장소를 포크하세요
2. **Feature Branch** 생성: `git checkout -b feature/amazing-feature`
3. **변경사항 커밋**: `git commit -m 'feat: Add amazing feature'`
4. **브랜치에 푸시**: `git push origin feature/amazing-feature`
5. **Pull Request** 생성

### 코딩 컨벤션
- **Dart Style Guide** 준수
- **Clean Code** 원칙 적용
- **주석은 한국어**로 작성
- **Commit Message**는 [Conventional Commits](https://conventionalcommits.org/) 형식

## 📄 라이선스

이 프로젝트는 [MIT License](LICENSE)로 배포됩니다.

## 🤝 팀

- **Lead Developer**: [@jagallang](https://github.com/jagallang)
- **AI Assistant**: Claude (Anthropic) - 코드 아키텍처 및 구현 지원

## 📞 연락처

- **GitHub Issues**: [이슈 제기](https://github.com/jagallang/BUG/issues)
- **GitHub**: [@jagallang](https://github.com/jagallang)
- **프로젝트 링크**: [https://github.com/jagallang/BUG](https://github.com/jagallang/BUG)

## 🙏 감사의 말

- Flutter 팀의 훌륭한 프레임워크
- Firebase 팀의 강력한 백엔드 서비스
- Node.js 및 Express.js 커뮤니티
- Docker 및 컨테이너화 도구들
- 모든 오픈소스 기여자들

---

<p align="center">
<strong>BugCash와 함께 더 나은 앱 생태계를 만들어가세요!</strong> 🚀
</p>

<p align="center">
<a href="https://github.com/jagallang/BUG/stargazers">⭐ Star</a> · 
<a href="https://github.com/jagallang/BUG/issues">🐛 Report Bug</a> · 
<a href="https://github.com/jagallang/BUG/issues">💡 Request Feature</a>
</p>

<p align="center">
Made with ❤️ using Flutter, Node.js & Firebase
</p>

<p align="center">
🤖 Generated with <a href="https://claude.ai/code">Claude Code</a><br>
Co-Authored-By: Claude <noreply@anthropic.com>
</p>