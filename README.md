# 🎯 BugCash - 버그 테스트 리워드 플랫폼

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.29.2-02569B?style=flat-square&logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.7.2-0175C2?style=flat-square&logo=dart" />
  <img src="https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=flat-square&logo=firebase" />
  <img src="https://img.shields.io/badge/Version-1.0.01-green?style=flat-square" />
</p>

## 📱 개요

BugCash는 앱 테스터와 개발자를 연결하는 혁신적인 버그 테스트 리워드 플랫폼입니다. 테스터는 다양한 앱을 테스트하고 버그를 발견하여 포인트를 획득하고, 개발자는 실제 사용자의 피드백을 통해 앱 품질을 향상시킬 수 있습니다.

## ✨ 주요 기능

### 테스터를 위한 기능
- 📋 **미션 시스템**: 다양한 카테고리의 테스트 미션 참여
- 💰 **리워드 시스템**: 버그 발견 및 테스트 완료 시 포인트 획득
- 🏆 **랭킹 시스템**: 실력에 따른 티어 및 랭킹 제공
- 💳 **지갑 기능**: 획득한 포인트 관리 및 출금
- 👤 **프로필 관리**: 테스터 실적 및 통계 확인

### 앱 공급자를 위한 기능
- 📊 **대시보드**: 테스트 진행 상황 실시간 모니터링
- 🐛 **버그 리포트**: 상세한 버그 리포트 및 피드백 수집
- 📈 **통계 분석**: 테스트 데이터 분석 및 인사이트
- 💸 **리워드 관리**: 테스터 보상 체계 관리
- ⚙️ **미션 생성**: 맞춤형 테스트 미션 생성 및 관리

## 🚀 시작하기

### 필수 요구사항

- Flutter 3.29.2 이상
- Dart 3.7.2 이상
- Android Studio / VS Code
- Firebase 프로젝트 (선택사항)

### 설치 방법

1. 저장소 클론
```bash
git clone https://github.com/jagallang/BUG.git
cd BUG/bugcash
```

2. 의존성 설치
```bash
flutter pub get
```

3. Firebase 설정 (실제 배포 시)
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

4. 앱 실행
```bash
# 디버그 모드로 실행
flutter run

# 특정 플랫폼에서 실행
flutter run -d android  # Android
flutter run -d ios      # iOS
flutter run -d chrome   # Web
```

## 📂 프로젝트 구조

```
bugcash/
├── lib/
│   ├── main.dart                 # 앱 엔트리 포인트
│   ├── firebase_options.dart      # Firebase 설정
│   ├── services/
│   │   └── firebase_service.dart  # Firebase CRUD 서비스
│   ├── features/                  # 기능별 모듈
│   │   ├── auth/                  # 인증 기능
│   │   ├── missions/              # 미션 관리
│   │   ├── wallet/                # 지갑 기능
│   │   └── profile/               # 프로필 관리
│   ├── shared/                    # 공통 컴포넌트
│   │   ├── theme/                 # 앱 테마
│   │   └── widgets/               # 재사용 위젯
│   └── core/                      # 핵심 기능
│       └── di/                    # 의존성 주입
├── android/                       # Android 플랫폼 설정
├── ios/                          # iOS 플랫폼 설정
├── web/                          # Web 플랫폼 설정
└── pubspec.yaml                  # 패키지 의존성
```

## 🛠 기술 스택

### Frontend
- **Flutter**: 크로스플랫폼 UI 프레임워크
- **Dart**: 프로그래밍 언어
- **flutter_bloc**: 상태 관리
- **get_it**: 의존성 주입
- **flutter_screenutil**: 반응형 UI

### Backend & Services
- **Firebase**
  - Authentication: 사용자 인증
  - Firestore: NoSQL 데이터베이스
  - Storage: 파일 저장소
  - Cloud Functions: 서버리스 백엔드
- **Google Sign-In**: 소셜 로그인

## 🔧 주요 버전 정보

### v1.0.01 (2025-08-26)
#### 🐛 버그 수정
- Android 검은 화면 문제 해결
- Firebase 초기화 타임아웃 처리 추가 (5초)
- Firestore API 비활성화 시 무한 대기 문제 수정

#### ✨ 새로운 기능
- 오프라인 모드 대체 데이터 시스템 구현
- Firebase 연결 실패 시 우아한 성능 저하 처리
- Android/iOS/Web 크로스플랫폼 완벽 지원

#### 🔍 구현 완료 기능
- 🔐 Google 로그인/로그아웃
- 🏠 홈 화면 (미션 리스트)
- 📋 미션 상세 정보
- 📹 영상 제출 및 Q&A
- 💰 포인트 지갑 시스템
- 👤 사용자 프로필
- 🐛 버그 리포팅 (추가 보상)
- 🎯 미션 센터 UI
- 📱 반응형 레이아웃

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

## 🤝 기여하기

버그 리포트, 기능 제안, 풀 리퀘스트를 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 📞 연락처

- GitHub: [@jagallang](https://github.com/jagallang)
- 프로젝트 링크: [https://github.com/jagallang/BUG](https://github.com/jagallang/BUG)

## 🙏 감사의 말

- Flutter 팀의 훌륭한 프레임워크
- Firebase 팀의 강력한 백엔드 서비스
- 모든 오픈소스 기여자들

---

<p align="center">Made with ❤️ using Flutter</p>
<p align="center">
  🤖 Generated with <a href="https://claude.ai/code">Claude Code</a><br>
  Co-Authored-By: Claude <noreply@anthropic.com>
</p>