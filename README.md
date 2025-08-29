# 🐛 BugCash - 버그 테스트 리워드 플랫폼

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.29.2-02569B?style=flat-square&logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.7.2-0175C2?style=flat-square&logo=dart" />
  <img src="https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=flat-square&logo=firebase" />
  <img src="https://img.shields.io/badge/Version-1.1.1-success?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" />
</p>

> **혁신적인 크라우드소싱 버그 테스트 플랫폼** - 앱 개발자와 테스터를 연결하는 Win-Win 생태계

BugCash는 앱 개발자들이 실제 사용자들에게 버그 테스트를 의뢰하고, 테스터들이 이를 통해 리워드를 획득할 수 있는 플랫폼입니다.

## ✨ 주요 기능

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

### 👤 사용자 프로필
- **티어 시스템**: BRONZE/SILVER/GOLD/PLATINUM 등급 관리
- **활동 통계**: 완료한 미션 수, 가입일, 포인트 현황
- **프로필 관리**: 개인 정보 및 설정 변경

### 앱 공급자를 위한 기능
- **📊 대시보드**: 테스트 진행 상황 실시간 모니터링
- **🐛 버그 리포트**: 상세한 버그 리포트 및 피드백 수집
- **📈 통계 분석**: 테스트 데이터 분석 및 인사이트
- **💸 리워드 관리**: 테스터 보상 체계 관리
- **⚙️ 미션 생성**: 맞춤형 테스트 미션 생성 및 관리

## 🏗️ 아키텍처

```
lib/
├── core/                    # 핵심 인프라
│   ├── config/             # 앱 설정 및 환경변수
│   ├── constants/          # 색상, 테마 상수
│   ├── error/              # 에러 처리 시스템
│   └── utils/              # 유틸리티 함수
├── features/               # 기능별 모듈화
│   ├── bug_report/         # 버그 리포트 기능
│   │   └── presentation/
│   │       └── pages/
│   │           └── bug_report_page.dart (626줄)
│   ├── home/               # 홈 화면
│   ├── mission/            # 미션 관리
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── mission_page.dart
│   │       │   └── mission_detail_page.dart (524줄)
│   │       └── widgets/
│   ├── points/             # 포인트 시스템
│   │   ├── domain/models/
│   │   └── presentation/pages/
│   │       └── point_history_page.dart (412줄)
│   ├── profile/            # 사용자 프로필
│   ├── ranking/            # 랭킹 시스템
│   ├── search/             # 검색 기능
│   └── wallet/             # 지갑/결제
├── services/               # 외부 서비스 연동
│   └── firebase_service.dart
└── shared/                 # 공유 컴포넌트
    └── providers/          # Riverpod 프로바이더
```

### 📐 설계 원칙

- **Clean Architecture**: 비즈니스 로직과 UI의 완전한 분리
- **Feature-First**: 기능 중심의 모듈화된 폴더 구조  
- **Dependency Injection**: GetIt + Injectable을 통한 의존성 관리
- **State Management**: Riverpod을 활용한 반응형 상태 관리
- **Type Safety**: Dart의 강타입 시스템 적극 활용

## 🚀 시작하기

### 📋 필요 조건

- **Flutter SDK**: 3.29.2 이상
- **Dart SDK**: 3.7.2 이상  
- **Android Studio** 또는 **VS Code**
- **Firebase 프로젝트** (Firestore, Storage, Auth)

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
   - `bug_reports` - 버그 리포트
   - `point_transactions` - 포인트 거래 내역

2. **Firebase Storage**
   - `bug_reports/` - 버그 리포트 첨부 파일
   - `user_assets/` - 사용자 업로드 파일

3. **Firebase Auth**
   - Google 로그인
   - 익명 인증 (게스트 모드)

### 보안 규칙 예시

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /missions/{missionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        resource.data.createdBy == request.auth.uid;
    }
    
    match /bug_reports/{reportId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🛠️ 개발 현황

### ✅ Week 1 완료 (v1.1.0) - 2025.08.29

- [x] **미션 상세 페이지** - 포괄적인 미션 정보 표시 및 참여 시스템
- [x] **버그 리포트 제출** - 완전한 제출 폼과 Firebase Storage 통합  
- [x] **포인트 시스템** - 자동 적립, 히스토리, 프로필 통합

#### 📊 Week 1 성과 지표
- **31개 파일 변경**
- **4,593줄 코드 추가**
- **1,375줄 코드 개선**
- **핵심 기능 3개 완성**

### ✅ 추가 개선 (v1.1.1) - 2025.08.29

- [x] **앱 설치 링크 기능** - 미션 상세 페이지에 테스트 앱 다운로드 섹션 추가

#### 📊 v1.1.1 개선 지표
- **3개 파일 수정**
- **255줄 코드 추가**
- **멀티 플랫폼 다운로드 링크 지원**

### 🔄 진행 예정

- [ ] **Week 2-1**: 검색 기능 구현
- [ ] **Week 2-2**: 랭킹 페이지 구현  
- [ ] **Week 2-3**: 프로필 편집 기능
- [ ] **Week 3-1**: FCM 푸시 알림 설정
- [ ] **Week 3-2**: 관리자 대시보드 구현
- [ ] **Week 3-3**: 실시간 업데이트 기능
- [ ] **Week 4-1**: 테스트 코드 작성
- [ ] **Week 4-2**: 성능 최적화
- [ ] **Week 4-3**: 프로덕션 배포 준비

## 📊 기술 스택

### Frontend
- **UI Framework**: Flutter (Material Design 3)
- **State Management**: Riverpod 2.4.9
- **Navigation**: Flutter Navigator 2.0
- **Responsive Design**: flutter_screenutil 5.9.0
- **Image Handling**: image_picker 1.2.0

### Backend & Services  
- **Database**: Firebase Firestore
- **Storage**: Firebase Storage
- **Authentication**: Firebase Auth + Google Sign-In
- **Push Notifications**: FCM (예정)
- **Analytics**: Firebase Analytics (예정)

### Development Tools
- **Dependency Injection**: GetIt + Injectable
- **Code Generation**: Build Runner
- **Linting**: Flutter Lints 3.0.0
- **Environment Variables**: flutter_dotenv
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

## 📱 스크린샷

### 미션 화면
<img src="https://raw.githubusercontent.com/jagallang/BUG/main/screenshots/mission.png" width="300" alt="미션 화면" />

- 진행 중인 미션 목록
- 미션별 리워드 및 진행률 표시
- 카테고리별 필터링

### 프로필 화면
- 테스터 티어 및 포인트
- 완료한 미션 통계
- 앱 공급자 관리 기능

## 🔧 주요 버전 정보

### v1.1.1 (2025-08-29) - 앱 설치 링크 기능 추가
#### 📱 새로운 기능
- **앱 설치 섹션**: 미션 상세 페이지에 테스트 앱 다운로드 영역 추가
- **멀티 플랫폼 지원**: Google Play Store, Apple App Store, APK 직접 다운로드
- **url_launcher 통합**: 외부 링크 실행 및 에러 핸들링

#### 🎨 UI/UX 개선
- 플랫폼별 아이콘 및 색상 구분 (Play Store, Apple, Android)
- 인터랙티브 다운로드 버튼 디자인
- 조건부 렌더링으로 사용 가능한 링크만 표시
- 직관적인 설명 텍스트 및 사용자 가이드

#### 📊 데이터 확장
- Firebase Service 데모 미션에 downloadLinks 필드 추가
- 미션별 맞춤형 다운로드 옵션 및 상세 요구사항
- fallback 미션 데이터에도 링크 정보 통합

### v1.1.0 (2025-08-29) - Week 1 완료
#### 🎯 새로운 주요 기능
- **미션 상세 페이지**: 포괄적인 미션 정보 및 참여 시스템
- **버그 리포트 제출**: Firebase Storage 통합 파일 업로드
- **포인트 시스템**: 자동 적립 및 히스토리 관리

#### 🏗️ 아키텍처 개선
- Clean Architecture 구조 적용
- Riverpod 상태 관리 통합
- Firebase Services 확장
- 통합 에러 핸들링 시스템
- 환경변수 보안 설정

#### 📱 UI/UX 향상
- Material Design 3 일관 적용
- 반응형 레이아웃 및 애니메이션
- 사용자 친화적 네비게이션
- 포인트 시각화 및 진행 상태 표시

### v1.0.01 (2025-08-26) - 초기 출시
#### 🐛 버그 수정
- Android 검은 화면 문제 해결
- Firebase 초기화 타임아웃 처리 추가 (5초)
- Firestore API 비활성화 시 무한 대기 문제 수정

#### ✨ 기본 기능
- 🔐 Google 로그인/로그아웃
- 🏠 홈 화면 (미션 리스트)
- 📋 미션 상세 정보
- 💰 포인트 지갑 시스템
- 👤 사용자 프로필
- 📱 크로스플랫폼 지원

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

```
MIT License

Copyright (c) 2025 BugCash Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software...
```

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