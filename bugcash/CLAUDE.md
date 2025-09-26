# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Information

### BugCash - Flutter Bug Testing Platform
- **Version**: 1.4.12
- **Type**: Flutter Cross-platform Application (Web, iOS, Android, Desktop)
- **Purpose**: Bug testing platform connecting software providers with testers through gamified missions
- **Main Branch**: main
- **Architecture**: Clean Architecture + Riverpod State Management

## 🛡️ 안전한 코드 수정 가이드라인 (CRITICAL)

### 수정 전 필수 체크사항
```markdown
⚠️ 코드 수정 전 반드시 다음을 확인할 것:

1. **위험성 평가**
   - 핵심 기능 (인증, 미션 관리, 데이터 동기화)에 영향을 주는가?
   - 다른 feature나 service에 종속성이 있는가?
   - Firebase 연결이나 상태 관리 로직을 변경하는가?

2. **영향도 분석**
   - 변경 범위가 단일 파일을 넘어서는가?
   - Provider 체인이나 Riverpod 의존성을 수정하는가?
   - API 호출이나 데이터 모델 구조를 변경하는가?

3. **허락 요청 기준**
   - 위험도가 Medium 이상인 경우
   - 영향 범위가 불명확한 경우
   - 기존 워크플로우를 변경하는 경우
```

### 위험도 분류 기준
```dart
// 🟢 LOW RISK (자유롭게 수정 가능)
- UI 스타일링 및 레이아웃 조정
- 텍스트 및 현지화 수정
- const 추가나 포맷팅
- 디버그 print → debugPrint 교체

// 🟡 MEDIUM RISK (신중히 검토)
- Widget 구조 변경
- State 관리 로직 수정
- Navigation 라우팅 변경
- Error 핸들링 수정

// 🔴 HIGH RISK (반드시 허락 필요)
- Firebase 설정 변경
- Authentication 플로우 수정
- Provider/Service 레이어 변경
- 데이터 모델 구조 수정
- 핵심 비즈니스 로직 변경
```

### 수정 내역 기록 의무
```markdown
📝 모든 수정 사항은 다음과 같이 기록할 것:

**수정 파일**: path/to/file.dart:line_number
**위험도**: LOW/MEDIUM/HIGH
**변경 내용**: 구체적인 수정 사항
**영향 범위**: 영향받는 다른 파일들
**테스트 필요**: 검증해야 할 기능들
**백업 상태**: git commit hash (수정 전)

예시:
- **수정 파일**: lib/features/auth/presentation/widgets/auth_wrapper.dart:25
- **위험도**: MEDIUM
- **변경 내용**: debugPrint 로깅 추가, 주석 코드 제거
- **영향 범위**: 인증 플로우, 사용자 라우팅
- **테스트 필요**: 3가지 역할별 로그인 테스트
- **백업 상태**: commit abc123 (수정 전 상태)
```

## Common Development Commands
- ✅ **공통사항**: 한글로 설명할 것

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run the app (development)
flutter run -d chrome  # For web development
flutter run -d ios     # For iOS simulator
flutter run -d android # For Android emulator

# Build for production
flutter build web      # Web build
flutter build apk      # Android APK
flutter build ios      # iOS build

# Development tools
flutter analyze        # Analyze code for issues (현재 454개)
flutter format .       # Format code
flutter clean          # Clean build cache
flutter test           # Run tests

# Deployment
firebase deploy        # Deploy to Firebase Hosting
```

### Git Workflow
```bash
# Development workflow
git add .
git commit -m "description 🤖 Generated with [Claude Code](https://claude.ai/code)"
git tag v1.x.xx
git push origin main --tags

# Firebase deployment
firebase deploy
```

## 🔥 Firebase 전체 설정 가이드

### Environment Variables (.env)
```bash
# Required Firebase configuration
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_auth_domain
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# Optional
FIREBASE_MEASUREMENT_ID=your_measurement_id
```

### Firebase.json 설정
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions"
  }
}
```

### Firestore 보안 규칙 관리
```bash
# Deploy rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes

# Test rules locally
firebase emulators:start --only firestore
```

## 📁 Scripts 디렉토리 관리

### Migration Scripts (Dart)
```bash
# Database structure migration
dart run scripts/migrate_to_optimized_structure.dart

# Test optimized database
dart run scripts/test_optimized_database.dart

# Setup Firestore collections
dart run scripts/setup_optimized_firestore.dart
```

### Deployment Scripts (Shell)
```bash
# Build Android
./scripts/build_android.sh

# Build iOS
./scripts/build_ios.sh

# Deploy to web
./scripts/deploy_web.sh

# Deploy all platforms
./scripts/deploy_all.sh
```

### Script Files Organization
```
scripts/
├── migrate_to_optimized_structure.dart    # DB 구조 마이그레이션
├── test_optimized_database.dart          # DB 테스트
├── setup_optimized_firestore.dart        # Firestore 초기 설정
├── analyze_current_database.dart         # DB 현황 분석
├── build_android.sh                      # Android 빌드
├── build_ios.sh                          # iOS 빌드
├── deploy_web.sh                         # Web 배포
└── deploy_all.sh                         # 전체 플랫폼 배포
```

## High-Level Architecture

### Core Technologies
- **Framework**: Flutter 3.29.2 (Dart 3.7.2)
- **State Management**: flutter_riverpod ^2.4.9
- **Backend**: Firebase (Auth, Firestore, Storage, Hosting, Functions)
- **UI**: Material Design Components + Custom Theme
- **Internationalization**: flutter_localizations
- **Responsive**: flutter_screenutil ^5.9.0

### Project Structure
```
lib/
├── main.dart                           # App entry point (ProviderScope)
├── firebase_options.dart               # Firebase configuration
├── core/                              # Shared utilities and configurations
│   ├── config/                        # App configuration
│   ├── constants/                     # App constants
│   ├── error/                         # Error handling
│   ├── services/                      # Core services
│   └── utils/                         # Helper utilities
├── features/                          # Feature modules (Clean Architecture)
│   ├── auth/                          # Authentication
│   │   ├── data/                      # Data layer
│   │   ├── domain/                    # Domain layer
│   │   └── presentation/              # Presentation layer
│   ├── tester_dashboard/              # Tester interface
│   ├── provider_dashboard/            # Provider interface
│   ├── admin/                         # Admin interface
│   └── shared/                        # Shared feature components
├── shared/                            # Shared widgets and themes
│   ├── theme/                         # App theme
│   └── providers/                     # Global providers
└── models/                            # Legacy models (정리 예정)
```

### Key Features
- **Multi-role Authentication**: Tester, Provider, Admin roles with Firebase Auth
- **Mission Management**: Create, manage, and track testing missions with real-time sync
- **Bidirectional Status Display**: Live application status between testers and providers
- **Gamification**: Points, rankings, and rewards system
- **Bug Reporting**: Comprehensive bug tracking workflow
- **Analytics Dashboard**: Mission performance and analytics
- **Multi-platform**: Web (primary), iOS, Android, Desktop support

## 🔧 BugCash 코드 품질 개선 로드맵 (454개 → 50개 이하)

### Phase 1: Scripts 파일 정리 (300+ 이슈 해결)
```bash
# 위험도: LOW - 핵심 앱 로직에 영향 없음
# 1단계: 루트 디렉토리 스크립트들을 tools/로 이동
mkdir -p tools/admin tools/scripts
mv cleanup_*.dart create_*.dart debug_*.dart tools/scripts/
mv admin_*.txt make_admin.txt users.json tools/admin/

# 2단계: print() → debugPrint() 일괄 교체 (scripts만)
find tools/ -name "*.dart" -exec sed -i 's/\bprint(/debugPrint(/g' {} \;
```

### Phase 2: lib/ 내부 코드 품질 개선 (100+ 이슈 해결)
```bash
# 위험도: LOW-MEDIUM
# const 선언 추가 (성능 최적화)
# Manual review 필요 - flutter analyze 결과 기반

# 미사용 import 제거
flutter packages pub run dependency_validator
```

### Phase 3: 아키텍처 정리 (50+ 이슈 해결)
```bash
# 위험도: MEDIUM-HIGH ⚠️ 허락 필요
# 중복 main 파일들 통합
# 미사용 주석 코드 제거
# Provider 체인 일관성 검사
```

### 자동화 스크립트
```bash
#!/bin/bash
# cleanup_bugcash_quality.sh

echo "🔍 BugCash 코드 품질 개선 시작"
flutter analyze > analysis_before.txt
BEFORE_COUNT=$(grep -c "info •" analysis_before.txt)
echo "현재 이슈: ${BEFORE_COUNT}개"

echo "📂 Phase 1: Scripts 정리 (LOW RISK)"
mkdir -p tools/admin tools/scripts
mv cleanup_*.dart create_*.dart debug_*.dart tools/scripts/ 2>/dev/null || true
mv admin_*.txt make_admin.txt users.json tools/admin/ 2>/dev/null || true

echo "🔄 Phase 2: print() 교체 (LOW RISK)"
find tools/ -name "*.dart" -exec sed -i 's/\bprint(/debugPrint(/g' {} \; 2>/dev/null || true

echo "🧪 재검증"
flutter analyze > analysis_after.txt
AFTER_COUNT=$(grep -c "info •" analysis_after.txt)
IMPROVED=$((BEFORE_COUNT - AFTER_COUNT))

echo "📊 개선 결과"
echo "Before: ${BEFORE_COUNT} issues"
echo "After: ${AFTER_COUNT} issues"
echo "개선: ${IMPROVED}개 이슈 해결"
```

## 🎯 BugCash 특화 개발 패턴

### Authentication & Routing
```dart
// 3가지 역할별 라우팅 (auth_wrapper.dart)
switch (userData.userType) {
  case UserType.tester:
    return TesterDashboardPage(testerId: userData.uid);
  case UserType.provider:
    return ProviderDashboardPage(providerId: userData.uid);
  case UserType.admin:
    return const AdminDashboardPage();
}

// 안전한 인증 상태 체크
final authState = ref.watch(authProvider);
if (authState.isLoading) return LoadingWidget();
if (authState.user == null) return LoginPage();
```

### Firebase 실시간 데이터 동기화
```dart
// 미션 상태 실시간 스트림
final missionsStreamProvider = StreamProvider.family<List<Mission>, String>((ref, userId) {
  return ref.read(missionServiceProvider).getMissionsStream(userId);
});

// 안전한 스트림 구독
ref.listen(missionsStreamProvider(userId), (previous, next) {
  next.when(
    data: (missions) => handleMissionsUpdate(missions),
    loading: () => showLoadingIndicator(),
    error: (error, stackTrace) => handleError(error),
  );
});

// 메모리 누수 방지
ref.onDispose(() {
  subscription?.cancel();
});
```

### 양방향 애플리케이션 상태 관리
```dart
// 테스터 → 프로바이더 상태 동기화
class MissionApplicationStatus {
  final String id;
  final String missionId;
  final String testerId;
  final String providerId;
  final ApplicationStatus status; // pending, reviewing, accepted, rejected
  final DateTime appliedAt;
  final String? message;
  final String? providerResponse;
}

// 실시간 상태 업데이트
final applicationStatusStreamProvider = StreamProvider.family<List<MissionApplicationStatus>, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('missionApplications')
    .where('testerId', isEqualTo: userId)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) =>
      MissionApplicationStatus.fromMap(doc.data())
    ).toList());
});
```

### 반응형 디자인 패턴
```dart
// 웹/모바일 대응 반응형 헬퍼
extension ResponsiveText on num {
  double get rsp => kIsWeb ? (this * 1.1).sp : sp;
  double get rw => kIsWeb ? (this * 0.9).w : w;
  double get rh => kIsWeb ? (this * 0.9).h : h;
}

// 플랫폼별 조건부 렌더링
Widget build(BuildContext context) {
  return kIsWeb
    ? DesktopLayout(child: content)
    : MobileLayout(child: content);
}
```

## 🧪 테스트 및 검증 체크리스트

### 역할별 기능 테스트
```markdown
### Tester Dashboard
- [ ] Google 로그인 및 역할 확인
- [ ] 미션 목록 조회 및 필터링
- [ ] 미션 신청 및 상태 추적 (신청 현황 탭)
- [ ] 버그 리포트 제출
- [ ] 포인트 및 랭킹 시스템

### Provider Dashboard
- [ ] 앱 등록 및 관리
- [ ] 미션 생성 및 수정
- [ ] 테스터 신청 검토 및 승인/거절
- [ ] 버그 리포트 검토
- [ ] 분석 대시보드

### Admin Dashboard
- [ ] 사용자 관리 (테스터/프로바이더 승인)
- [ ] 시스템 모니터링
- [ ] 데이터 분석 및 리포트
```

### Firebase 연결 테스트
```bash
# 1. Authentication 테스트
# Google Sign-In 플로우 검증

# 2. Firestore 실시간 동기화 테스트
# 미션 상태 변경 → 실시간 반영 확인

# 3. Storage 업로드 테스트
# 버그 스크린샷 업로드 기능

# 4. Functions 호출 테스트 (해당하는 경우)
# 자동화된 워크플로우 검증
```

### 성능 및 안정성 테스트
```dart
// 메모리 누수 체크
void checkMemoryLeaks() {
  // Provider 구독 해제 확인
  // Stream 구독 정리 확인
  // Image cache 관리 확인
}

// 네트워크 오류 시뮬레이션
void testOfflineScenarios() {
  // 오프라인 상태에서의 앱 동작
  // 재연결 시 데이터 동기화
  // 로컬 캐시 활용
}
```

## Development Guidelines for BugCash

### DO (권장사항)
- ✅ **안전 우선**: 수정 전 위험도 평가 및 기록
- ✅ **Riverpod 패턴**: ref.watch(), ref.read() 일관된 사용
- ✅ **Clean Architecture**: feature별 레이어 분리 유지
- ✅ **Firebase 실시간**: Stream 기반 실시간 데이터 동기화
- ✅ **역할별 분기**: UserType enum 기반 라우팅
- ✅ **에러 핸들링**: AppError, Failures 클래스 활용
- ✅ **메모리 관리**: ref.onDispose()로 구독 해제
- ✅ **환경 분리**: .env 파일 활용한 설정 관리

### DON'T (주의사항)
- ❌ **무단 수정**: HIGH RISK 변경 시 반드시 허락 요청
- ❌ **기록 누락**: 모든 수정사항 문서화 의무
- ❌ **Mock 시스템 사용**: 순수 Firebase만 사용
- ❌ **print() 사용**: debugPrint() 또는 AppLogger 사용
- ❌ **하드코딩**: 환경변수나 constants 사용
- ❌ **직접 Firestore 접근**: Service 레이어를 통한 접근
- ❌ **상태 관리 혼재**: Riverpod만 사용

## Known Issues & Current Status

### Critical Issues (즉시 해결 필요)
- **454개 코드 품질 이슈**: 대부분 scripts 파일의 print() 사용
- **Firebase hosting 설정 누락**: firebase.json에 hosting 섹션 없음
- **Scripts 파일 위치**: lib/ 밖으로 이동 필요

### Fixed Issues in v1.4.12
- ✅ **Mock System 완전 제거**: Firebase 100% 전환 완료
- ✅ **Bidirectional Application Status**: 테스터-프로바이더 양방향 상태 동기화
- ✅ **Real-time Sync**: Firestore Stream 기반 실시간 업데이트
- ✅ **Authentication Flow**: 순수 Firebase Auth 통합

### Upcoming Improvements
- **코드 품질**: 454개 → 50개 이하로 개선
- **성능 최적화**: const 생성자 추가, 메모리 관리 개선
- **테스트 커버리지**: 핵심 기능 자동화 테스트 추가

## Deployment Process

### Firebase Deployment
```bash
# 환경 설정 확인
cp .env.example .env  # 환경변수 설정
flutter pub get

# 빌드 및 배포
flutter build web --release
firebase deploy --only hosting

# 전체 배포 (functions, firestore 포함)
firebase deploy

# 버전 태깅
git tag v1.4.xx
git push origin main --tags
```

### Production Checklist
- [ ] Firebase 프로덕션 환경 설정 확인
- [ ] 환경변수 (.env) 보안 설정 완료
- [ ] Firestore 보안 규칙 production 배포
- [ ] Storage 규칙 및 CORS 설정
- [ ] 성능 모니터링 (Firebase Performance) 활성화
- [ ] 에러 트래킹 (Crashlytics) 설정
- [ ] 빌드 크기 최적화 확인

---

**Last Updated**: 2025-09-27
**App Version**: 1.4.12 (Bidirectional Application Status System)
**Flutter Version**: 3.29.2
**Current Issues**: 454개 (목표: 50개 이하)
**Next Priority**: Scripts 정리 및 Firebase hosting 설정