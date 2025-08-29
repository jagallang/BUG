# 🐛 BugCash - 버그 테스트 리워드 플랫폼

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.29.2-02569B?style=flat-square&logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.7.2-0175C2?style=flat-square&logo=dart" />
  <img src="https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=flat-square&logo=firebase" />
  <img src="https://img.shields.io/badge/Version-2.1.0-success?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" />
</p>

> **혁신적인 크라우드소싱 버그 테스트 플랫폼** - 앱 개발자와 테스터를 연결하는 Win-Win 생태계

BugCash는 앱 개발자들이 실제 사용자들에게 버그 테스트를 의뢰하고, 테스터들이 이를 통해 리워드를 획득할 수 있는 플랫폼입니다.

## ✨ 주요 기능 (v2.1.0)

### 🔔 실시간 알림 시스템 (NEW!)
- **FCM 푸시 알림**: Firebase Cloud Messaging을 통한 실시간 알림
- **카테고리별 알림**: 미션/포인트/랭킹/시스템/홍보별 세밀한 설정
- **로컬 알림**: 예약된 알림 및 오프라인 알림 처리
- **알림 관리**: 읽음/삭제, 필터링, 알림 히스토리 관리
- **FCM 토큰 관리**: 토큰 자동 갱신 및 서버 동기화

### 🔄 실시간 업데이트 시스템 (NEW!)
- **미션 상태 실시간 추적**: Firestore 실시간 리스너로 즉시 상태 반영
- **진행도 실시간 업데이트**: 사용자별 미션 참여 및 완료 상황 추적
- **연결 상태 모니터링**: connectivity_plus로 네트워크 상태 감지
- **자동 재연결**: 네트워크 복구 시 자동 데이터 동기화
- **오프라인 지원**: Firebase 오프라인 캐싱 활용

### 📱 오프라인 지원 시스템 (NEW!)
- **완전한 오프라인 기능**: 인터넷 없이도 모든 앱 기능 이용 가능
- **스마트 동기화**: 연결 복원 시 자동 데이터 동기화 및 충돌 해결
- **로컬 캐싱**: 효율적인 데이터 캐싱 및 만료 관리 시스템
- **동기화 큐**: 오프라인 작업 큐잉 및 재시도 메커니즘
- **연결 상태 UI**: 실시간 연결 상태 및 동기화 진행률 표시

### 🔍 고급 검색 시스템 (NEW!)
- **실시간 검색**: 미션명, 앱명, 카테고리별 즉시 검색
- **검색 히스토리**: 최근 검색어 자동 저장 및 관리
- **인기 검색어**: 실시간 인기 검색 키워드 제공
- **필터링**: 상태, 카테고리, 리워드 범위별 고급 필터
- **자동완성**: 입력 중 실시간 검색 제안

### 🏆 랭킹 시스템 (NEW!)
- **실시간 랭킹**: 포인트 기반 사용자 순위 시스템
- **티어별 랭킹**: BRONZE/SILVER/GOLD/PLATINUM 등급별 리더보드
- **카테고리별 순위**: 미션 완료수, 총 포인트, 버그 발견수별 랭킹
- **개인 통계**: 상위 퍼센트, 순위 변동, 월별 성과 추적
- **시각적 표현**: 포디움, 그래프, 뱃지 시스템

### 👤 프로필 시스템 (ENHANCED!)
- **완전한 프로필 편집**: 개인정보, 스킬, 관심사 관리
- **프로필 이미지**: 카메라/갤러리 업로드 및 Firebase Storage 연동
- **스킬 관리**: 기술 스택 선택 및 검색 기능
- **관심사 설정**: 관심 분야 선택 및 개인화
- **개인정보 보호**: 세밀한 프라이버시 설정

### 🎯 미션 시스템
- **미션 탐색**: 다양한 앱 테스트 미션 목록 및 필터링
- **상세 정보**: 미션 요구사항, 보상, 마감일, 참여 현황 표시
- **앱 설치 링크**: Google Play Store, Apple App Store, APK 직접 다운로드 지원
- **실시간 참여**: 원클릭 미션 참여 및 진행 상황 추적

### 🐛 버그 리포트
- **직관적 리포팅**: 사용자 친화적 버그 제출 폼
- **멀티미디어 첨부**: 카메라/갤러리를 통한 스크린샷 및 동영상 업로드
- **상세 분류**: 버그 심각도, 카테고리별 체계적 분류
- **재현 단계**: 버그 재현을 위한 단계별 가이드 작성

### 💰 포인트 시스템
- **자동 적립**: 버그 리포트 제출 시 즉시 포인트 획득 (500P)
- **상세 히스토리**: 포인트 획득/사용 내역의 완전한 추적
- **시각적 대시보드**: 포인트 현황 및 통계의 직관적 표시
- **다양한 적립 방식**: 미션 완료, 버그 발견, 일일 보너스 등

### 앱 공급자를 위한 기능
- **📊 대시보드**: 테스트 진행 상황 실시간 모니터링
- **🐛 버그 리포트**: 상세한 버그 리포트 및 피드백 수집
- **📈 통계 분석**: 테스트 데이터 분석 및 인사이트
- **💸 리워드 관리**: 테스터 보상 체계 관리
- **⚙️ 미션 생성**: 맞춤형 테스트 미션 생성 및 관리

## 🏗️ 아키텍처

```
lib/
├── core/                        # 핵심 인프라
│   ├── config/                 # 앱 설정 및 환경변수
│   ├── constants/              # 색상, 테마 상수
│   ├── data/                   # 오프라인 지원 (NEW!)
│   │   └── services/
│   │       ├── offline_sync_service.dart
│   │       └── offline_data_cache.dart
│   ├── error/                  # 에러 처리 시스템
│   ├── presentation/           # 공통 UI 컴포넌트 (NEW!)
│   │   └── widgets/
│   │       ├── connection_status_widget.dart
│   │       └── sync_management_widget.dart
│   └── utils/                  # 유틸리티 함수
├── features/                   # 기능별 모듈화 (Clean Architecture)
│   ├── bug_report/            # 버그 리포트 기능
│   ├── home/                  # 홈 화면
│   ├── missions/              # 미션 관리 (NEW!)
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── realtime_mission_service.dart
│   │   ├── domain/
│   │   └── presentation/
│   │       └── providers/
│   │           ├── realtime_mission_provider.dart
│   │           └── offline_mission_provider.dart
│   ├── notifications/         # 알림 시스템 (NEW!)
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   │       └── fcm_service.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── providers/
│   │       └── widgets/
│   ├── profile/               # 사용자 프로필 (ENHANCED!)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── profile_edit_page.dart
│   │       ├── providers/
│   │       └── widgets/
│   ├── ranking/               # 랭킹 시스템 (NEW!)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── search/                # 검색 기능 (NEW!)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── settings/              # 설정 관리 (NEW!)
│   │   └── presentation/
│   │       └── pages/
│   │           └── sync_settings_page.dart
│   ├── points/                # 포인트 시스템
│   └── wallet/                # 지갑/결제
├── services/                  # 외부 서비스 연동
│   └── firebase_service.dart
└── shared/                    # 공유 컴포넌트
    └── providers/             # Riverpod 프로바이더
```

### 📐 설계 원칙

- **Clean Architecture**: 비즈니스 로직과 UI의 완전한 분리
- **Feature-First**: 기능 중심의 모듈화된 폴더 구조  
- **Dependency Injection**: GetIt + Injectable을 통한 의존성 관리
- **State Management**: Riverpod을 활용한 반응형 상태 관리
- **Real-time Architecture**: Firebase 실시간 리스너 기반 데이터 동기화

## 🚀 시작하기

### 📋 필요 조건

- **Flutter SDK**: 3.29.2 이상
- **Dart SDK**: 3.7.2 이상  
- **Android Studio** 또는 **VS Code**
- **Firebase 프로젝트** (Firestore, Storage, Auth, Messaging)

### 🔧 설치 및 실행

1. **저장소 클론**
```bash
git clone https://github.com/jagallang/BUG.git
cd BUG/bugcash
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **환경변수 설정**
```bash
cp .env.example .env
# .env 파일에 Firebase 설정 추가
```

4. **Firebase 설정**
```bash
# Firebase CLI 설치 (이미 설치되어 있으면 생략)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# 프로젝트 초기화
flutterfire configure
```

5. **앱 실행**
```bash
# 디버그 모드로 실행
flutter run

# 특정 플랫폼에서 실행
flutter run -d android  # Android
flutter run -d ios      # iOS
flutter run -d chrome   # Web

# 릴리즈 빌드
flutter build apk --release
```

## 🔥 Firebase 설정

### 필요한 Firebase 서비스

1. **Firestore Database**
   - `missions` - 미션 정보
   - `users` - 사용자 데이터  
   - `user_missions` - 사용자별 미션 참여 현황
   - `bug_reports` - 버그 리포트
   - `point_transactions` - 포인트 거래 내역
   - `notifications` - 알림 데이터
   - `rankings` - 랭킹 정보

2. **Firebase Storage**
   - `bug_reports/` - 버그 리포트 첨부 파일
   - `user_assets/` - 사용자 업로드 파일
   - `profile_images/` - 프로필 이미지

3. **Firebase Auth**
   - Google 로그인
   - 익명 인증 (게스트 모드)

4. **Firebase Cloud Messaging**
   - 푸시 알림 서비스
   - FCM 토큰 관리

## 🛠️ 개발 현황

### ✅ Week 3 완료 (v2.1.0) - 2025.08.29

#### 🎯 Week 3-1: FCM 알림 시스템
- [x] **Firebase Messaging 통합** - FCM 완전 설정 및 토큰 관리
- [x] **실시간 푸시 알림** - 포그라운드/백그라운드 알림 처리
- [x] **카테고리별 알림 설정** - 미션/포인트/랭킹/시스템/홍보별 세밀한 제어
- [x] **로컬 알림 시스템** - flutter_local_notifications 통합
- [x] **알림 관리 UI** - 알림 목록, 필터링, 설정 페이지

#### 🔄 Week 3-2: 실시간 업데이트 시스템  
- [x] **Firestore 실시간 리스너** - 미션 상태 즉시 반영
- [x] **연결 상태 모니터링** - connectivity_plus 네트워크 감지
- [x] **미션 진행도 추적** - 사용자별 실시간 진행 상황
- [x] **자동 재연결 시스템** - 네트워크 복구 시 데이터 동기화
- [x] **오프라인 동기화 시스템** - 완전한 오프라인 지원 및 스마트 동기화
- [x] **로컬 데이터 캐싱** - 효율적인 캐시 관리 및 만료 처리
- [x] **연결 상태 UI** - 실시간 연결 상태 및 동기화 진행률 표시

### ✅ Week 2 완료 (v2.0.0) - 2025.08.29

#### 🔍 Week 2-1: 검색 시스템
- [x] **실시간 미션 검색** - 미션명, 앱명, 카테고리 검색
- [x] **검색 히스토리** - shared_preferences 기반 최근 검색어
- [x] **인기 검색어** - 실시간 트렌딩 키워드
- [x] **고급 필터링** - 상태, 리워드, 카테고리별 필터
- [x] **검색 UI/UX** - 직관적인 검색 인터페이스

#### 🏆 Week 2-2: 랭킹 시스템
- [x] **실시간 랭킹** - 포인트 기반 사용자 순위
- [x] **티어별 리더보드** - 등급별 랭킹 시스템
- [x] **랭킹 통계** - 개인 성과 및 순위 변동 추적
- [x] **시각적 랭킹** - 포디움, 차트, 뱃지 시스템
- [x] **카테고리별 랭킹** - 다양한 기준의 순위 표시

#### 👤 Week 2-3: 프로필 편집 시스템
- [x] **완전한 프로필 편집** - 개인정보, 설정 관리
- [x] **프로필 이미지 업로드** - Firebase Storage 연동
- [x] **스킬 관리** - 기술 스택 선택 및 검색
- [x] **관심사 설정** - 개인화된 관심 분야
- [x] **개인정보 보호** - 프라이버시 설정

### ✅ Week 1 완료 (v1.1.0) - 2025.08.29

- [x] **미션 상세 페이지** - 포괄적인 미션 정보 표시 및 참여 시스템
- [x] **버그 리포트 제출** - 완전한 제출 폼과 Firebase Storage 통합  
- [x] **포인트 시스템** - 자동 적립, 히스토리, 프로필 통합
- [x] **앱 설치 링크 기능** - 미션 상세 페이지에 테스트 앱 다운로드 섹션

#### 📊 성과 지표
- **46개 파일 변경** (v2.1.0)
- **11,678줄 코드 추가** (v2.1.0)
- **핵심 기능 15개 완성**

### 🔄 진행 예정

- [ ] **Week 3-3**: 사용자 인증 시스템 (Firebase Auth)
- [ ] **Week 3-4**: 앱 성능 최적화 및 캐싱 시스템
- [ ] **Week 4-1**: 테스트 코드 작성
- [ ] **Week 4-2**: 성능 최적화
- [ ] **Week 4-3**: 프로덕션 배포 준비

## 📊 기술 스택

### Frontend
- **UI Framework**: Flutter (Material Design 3)
- **State Management**: Riverpod 2.4.9
- **Navigation**: Flutter Navigator 2.0
- **Responsive Design**: flutter_screenutil 5.9.0
- **Image Handling**: image_picker 1.0.4

### Backend & Services  
- **Database**: Firebase Firestore (실시간 리스너)
- **Storage**: Firebase Storage
- **Authentication**: Firebase Auth + Google Sign-In
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Real-time Updates**: Firestore Streams
- **Connectivity**: connectivity_plus 6.1.0

### Development Tools
- **Dependency Injection**: GetIt + Injectable
- **Code Generation**: Build Runner
- **Linting**: Flutter Lints 3.0.0
- **Environment Variables**: flutter_dotenv
- **Notifications**: flutter_local_notifications 17.2.3
- **Unique IDs**: UUID 4.2.1

## 🧪 테스트

```bash
# 단위 테스트 실행
flutter test

# 위젯 테스트 실행  
flutter test test/widget_test.dart

# 통합 테스트 실행
flutter drive --target=test_driver/app.dart

# 코드 커버리지 생성
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 코드 분석
flutter analyze
```

## 🔧 주요 버전 정보

### 🚀 v2.1.0 (2025-08-29) - 완전한 오프라인 지원

#### ✨ 새로운 혁신 기능
- **완전한 오프라인 지원**: 인터넷 연결 없이도 모든 앱 기능 이용
- **스마트 동기화 시스템**: 연결 복원 시 자동 데이터 동기화 및 충돌 해결
- **실시간 연결 상태 모니터링**: 네트워크 품질 및 연결 상태 시각적 표시
- **효율적인 로컬 캐싱**: 데이터 캐시 크기 관리 및 자동 만료 처리

#### 🔧 고급 기술 구현
- **OfflineSyncService**: 동기화 큐 관리 및 자동 재시도 메커니즘
- **OfflineDataCache**: 스마트 캐싱 시스템으로 빠른 로딩 보장
- **ConnectionStatusWidget**: 실시간 연결 품질 및 상태 표시
- **SyncManagementWidget**: 포괄적인 동기화 관리 인터페이스

#### 🎯 사용자 경험 혁신
- **무중단 서비스**: 네트워크 상태와 관계없이 원활한 앱 사용
- **투명한 동기화**: 동기화 진행률 및 상태를 실시간으로 확인
- **배터리 효율**: 백그라운드 동기화 최적화로 배터리 수명 보호
- **데이터 절약**: Wi-Fi 전용 동기화 옵션으로 데이터 사용량 절약

### 🚀 v2.0.0 (2025-08-29) - 고급 기능 출시

#### ✨ 주요 신기능
- **FCM 실시간 푸시 알림 시스템**: Firebase Cloud Messaging 완전 통합
- **미션 상태 실시간 업데이트**: Firestore 실시간 리스너 기반 즉시 반영
- **고급 검색 시스템**: 실시간 검색, 히스토리, 인기 검색어
- **랭킹 시스템**: 포인트 기반 실시간 리더보드 및 티어 관리
- **완전한 프로필 편집**: 이미지 업로드, 스킬/관심사 관리

#### 🔧 기술적 개선
- **Clean Architecture**: 완전한 feature-first 모듈화 구조
- **실시간 데이터 동기화**: Firestore 실시간 리스너 전면 도입
- **연결 상태 모니터링**: connectivity_plus를 통한 네트워크 감지
- **상태 관리 고도화**: Riverpod 기반 복합 상태 관리
- **패키지 확장**: 4개 신규 패키지 추가

#### 📦 새로운 의존성
- `firebase_messaging: ^15.1.3` - FCM 푸시 알림
- `flutter_local_notifications: ^17.2.3` - 로컬 알림
- `timezone: ^0.9.4` - 시간대 처리
- `connectivity_plus: ^6.1.0` - 네트워크 상태 감지

#### 🎨 UI/UX 혁신
- **알림 센터**: 카테고리별 알림 관리 및 필터링
- **실시간 랭킹 보드**: 포디움 및 차트 시각화
- **고급 검색 인터페이스**: 자동완성 및 히스토리
- **프로필 개인화**: 스킬 태그 및 관심사 선택 UI

### v1.1.1 (2025-08-29) - 앱 설치 링크 기능 추가
#### 📱 새로운 기능
- **앱 설치 섹션**: 미션 상세 페이지에 테스트 앱 다운로드 영역 추가
- **멀티 플랫폼 지원**: Google Play Store, Apple App Store, APK 직접 다운로드
- **url_launcher 통합**: 외부 링크 실행 및 에러 핸들링

### v1.1.0 (2025-08-29) - Week 1 완료
#### 🎯 새로운 주요 기능
- **미션 상세 페이지**: 포괄적인 미션 정보 및 참여 시스템
- **버그 리포트 제출**: Firebase Storage 통합 파일 업로드
- **포인트 시스템**: 자동 적립 및 히스토리 관리

## 📱 스크린샷

### 알림 시스템
- 실시간 푸시 알림 
- 카테고리별 알림 설정
- 알림 히스토리 관리

### 랭킹 시스템
- 실시간 리더보드
- 티어별 포디움
- 개인 랭킹 통계

### 검색 기능
- 실시간 미션 검색
- 검색 히스토리
- 고급 필터링

### 프로필 편집
- 이미지 업로드
- 스킬 선택
- 관심사 관리

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
- Riverpod 커뮤니티의 상태 관리 솔루션
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
Made with ❤️ using Flutter & Firebase
</p>

<p align="center">
🤖 Generated with <a href="https://claude.ai/code">Claude Code</a><br>
Co-Authored-By: Claude <noreply@anthropic.com>
</p>