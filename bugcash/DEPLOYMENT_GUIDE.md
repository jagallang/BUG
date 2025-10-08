# 🚀 BugCash 배포 가이드

## 📋 목차
1. [Firebase 설정](#firebase-설정)
2. [웹 배포](#웹-배포)
3. [Android 앱 배포](#android-앱-배포)
4. [iOS 앱 배포](#ios-앱-배포)
5. [자동화 스크립트](#자동화-스크립트)

---

## 🔥 Firebase 설정

### 1단계: Firebase Console 설정
1. [Firebase Console](https://console.firebase.google.com/project/bugcash) 접속
2. **프로젝트 설정** → **일반** → **내 앱** 섹션

### 2단계: 웹 앱 추가
1. **웹 앱 추가** (`</>` 아이콘) 클릭
2. **앱 닉네임**: `BugCash Web`
3. **Firebase Hosting 설정** ✅ 체크
4. **앱 등록** 클릭
5. 생성된 설정 코드를 복사하여 `lib/firebase_options.dart`의 `web` 섹션 업데이트

### 3단계: Android 앱 추가
1. **Android 앱 추가** (🤖 아이콘) 클릭
2. **Android 패키지명**: `com.bugcash.app`
3. **앱 닉네임**: `BugCash Android`
4. **앱 등록** 클릭
5. `google-services.json` 다운로드하여 `android/app/` 폴더에 저장

### 4단계: iOS 앱 추가 (선택사항)
1. **iOS 앱 추가** (🍎 아이콘) 클릭
2. **iOS 번들 ID**: `com.bugcash.app`
3. **앱 닉네임**: `BugCash iOS`
4. **앱 등록** 클릭
5. `GoogleService-Info.plist` 다운로드하여 `ios/Runner/` 폴더에 저장

### 5단계: Firebase 서비스 활성화
1. **Authentication** → **시작하기** → **로그인 방법**
   - **이메일/비밀번호** 활성화 ✅
   - **Google** 활성화 (선택사항) ✅

2. **Firestore Database** → **데이터베이스 만들기**
   - **테스트 모드로 시작** 선택
   - **위치**: `asia-northeast3 (서울)` 권장

3. **Storage** → **시작하기**
   - **테스트 모드로 시작** 선택

4. **Hosting** → **시작하기**
   - Firebase CLI 설정 (자동으로 처리됨)

---

## 🌐 웹 배포

### 자동 배포 (권장)
```bash
./scripts/deploy_web.sh
```

### 수동 배포
```bash
# 의존성 설치
flutter pub get

# 웹 빌드
flutter build web --release --web-renderer html

# Firebase 배포
firebase deploy --only hosting
```

### 배포 결과
- **라이브 URL**: https://bugcash.web.app
- **관리 URL**: https://console.firebase.google.com/project/bugcash/hosting

---

## 🤖 Android 앱 배포

### 사전 요구사항
- `android/app/google-services.json` 파일 필요
- Android SDK 설치 및 Flutter 환경 구성

### 자동 빌드 (권장)
```bash
./scripts/build_android.sh
```

### 수동 빌드
```bash
# 의존성 설치
flutter pub get

# Debug APK 빌드
flutter build apk --debug

# Release APK 빌드
flutter build apk --release

# AAB 빌드 (Play Store용)
flutter build appbundle --release
```

### 빌드 결과물
- **Debug APK**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **AAB Bundle**: `build/app/outputs/bundle/release/app-release.aab`

### Google Play 배포
1. [Google Play Console](https://play.google.com/console) 접속
2. **앱 만들기** → **BugCash**
3. **출시 관리** → **앱 번들 탐색기**
4. `app-release.aab` 업로드
5. 스토어 등록정보 작성 및 심사 제출

---

## 🍎 iOS 앱 배포 (macOS 필요)

### 사전 요구사항
- macOS 환경
- Xcode 설치
- `ios/Runner/GoogleService-Info.plist` 파일 필요
- Apple Developer 계정

### 자동 빌드 (권장)
```bash
./scripts/build_ios.sh
```

### 수동 빌드
```bash
# 의존성 설치
flutter pub get

# CocoaPods 설치
cd ios && pod install --repo-update && cd ..

# iOS 빌드
flutter build ios --release
```

### App Store 배포
1. `ios/Runner.xcworkspace` 파일을 Xcode로 열기
2. **Signing & Capabilities**에서 개발자 계정 설정
3. **Product** → **Archive**로 앱 아카이브
4. **Window** → **Organizer**에서 **Distribute App**
5. App Store Connect에 업로드
6. [App Store Connect](https://appstoreconnect.apple.com)에서 앱 정보 입력 및 심사 제출

---

## 🎯 자동화 스크립트

### 전체 배포 스크립트
```bash
./scripts/deploy_all.sh
```

**선택 옵션:**
1. 웹만 배포
2. Android만 빌드
3. iOS만 빌드 (macOS 필요)
4. 웹 + Android
5. 웹 + iOS (macOS 필요)
6. Android + iOS (macOS 필요)
7. 모든 플랫폼 (웹 + Android + iOS)

### 스크립트 권한 설정
```bash
chmod +x scripts/*.sh
```

---

## 🔧 개발 환경 설정

### Flutter 개발 서버 실행
```bash
# 웹 브라우저에서 실행
flutter run -d chrome --web-port=8080

# Android 에뮬레이터에서 실행
flutter run -d android

# iOS 시뮬레이터에서 실행 (macOS)
flutter run -d ios
```

### Firebase 에뮬레이터 실행 (개발용)
```bash
firebase emulators:start
```

---

## 📊 배포 후 모니터링

### Firebase Console에서 확인할 것들
1. **Analytics**: 사용자 행동 분석
2. **Crashlytics**: 앱 충돌 리포트
3. **Performance**: 앱 성능 모니터링
4. **Hosting**: 웹 트래픽 및 성능
5. **Firestore**: 데이터베이스 사용량

### 주요 메트릭
- **웹 사용자 수**: Firebase Analytics
- **앱 다운로드 수**: Play Console / App Store Connect
- **버그 리포트 수**: Firestore Database
- **사용자 포인트 현황**: Firestore Database

---

## 🆘 문제 해결

### 자주 발생하는 문제들

#### Firebase 연결 오류
```bash
# Firebase 재로그인
firebase logout
firebase login

# 프로젝트 확인
firebase projects:list
firebase use bugcash
```

#### Android 빌드 오류
```bash
# Gradle 캐시 정리
cd android && ./gradlew clean && cd ..

# Flutter 정리
flutter clean
flutter pub get
```

#### iOS 빌드 오류
```bash
# CocoaPods 재설치
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

---

## 🎉 배포 완료 체크리스트

- [ ] Firebase 프로젝트 설정 완료
- [ ] 웹 앱 Firebase Hosting 배포
- [ ] Android APK/AAB 빌드 성공
- [ ] iOS 앱 빌드 성공 (macOS 환경)
- [ ] Google Play Console 앱 등록
- [ ] App Store Connect 앱 등록
- [ ] Firebase Analytics 설정
- [ ] 앱 스토어 설명 및 스크린샷 준비
- [ ] 베타 테스트 진행
- [ ] 프로덕션 배포

---

## 🔐 Cloud Functions & Security 배포

### 1단계: Toss Payments Secret Key 설정

#### 개발 환경 (.env 파일)
```bash
cd functions
echo "TOSS_SECRET_KEY=test_sk_YOUR_SECRET_KEY" > .env
```

#### 프로덕션 환경 (Firebase 환경 변수)
```bash
# 방법 1: Firebase Functions Config (권장)
firebase functions:config:set toss.secret_key="live_sk_YOUR_SECRET_KEY"

# 방법 2: Secret Manager 사용 (더 안전)
firebase functions:secrets:set TOSS_SECRET_KEY
# 프롬프트에서 실제 키 입력
```

### 2단계: Cloud Functions 배포

#### 전체 함수 배포
```bash
firebase deploy --only functions
```

#### 특정 함수만 배포
```bash
# 결제 검증 함수
firebase deploy --only functions:verifyTossPayment

# 출금 처리 함수
firebase deploy --only functions:processWithdrawal

# 거래 검증 함수
firebase deploy --only functions:validateWalletTransaction

# 거래 모니터링 트리거
firebase deploy --only functions:onTransactionCreated
```

### 3단계: Firestore Security Rules 배포
```bash
firebase deploy --only firestore:rules
```

**중요**: Security Rules는 반드시 배포해야 합니다!
- wallets 컬렉션: 클라이언트 쓰기 차단
- transactions 컬렉션: Cloud Functions만 쓰기 가능

### 4단계: 배포된 함수 목록 확인
```bash
firebase functions:list
```

**주요 함수들:**
- `verifyTossPayment` - Toss 결제 서버 검증 및 포인트 충전
- `validateWalletTransaction` - 거래 전 유효성 검사 (잔액, 한도)
- `processWithdrawal` - 관리자 출금 승인/거부
- `onTransactionCreated` - 의심 거래 자동 모니터링

### 5단계: 배포 후 테스트

#### 로컬 에뮬레이터로 테스트 (권장)
```bash
# Functions + Firestore 에뮬레이터 시작
firebase emulators:start --only functions,firestore,auth

# Flutter 앱에서 에뮬레이터 연결 (main.dart에서 설정)
```

#### 프로덕션 테스트
1. Flutter 앱에서 실제 결제 진행
2. Firebase Console → Functions → Logs 확인
3. Firestore → transactions/wallets 컬렉션 데이터 확인
4. 거래 내역 정상 생성 여부 확인

### 6단계: 보안 체크리스트
- [ ] Toss Secret Key가 .env 파일에만 있고 Git에 커밋되지 않았는지 확인
- [ ] .gitignore에 functions/.env 포함 확인
- [ ] Firestore Rules 배포 완료 (wallets/transactions 쓰기 차단)
- [ ] Cloud Functions 리전이 asia-northeast1로 설정 확인
- [ ] Firebase Console에서 함수 실행 권한 확인
- [ ] 관리자 계정에 isAdmin=true 설정 확인

### 7단계: 모니터링 설정

#### 실시간 로그 확인
```bash
# 전체 로그 스트림
firebase functions:log

# 특정 함수 로그만
firebase functions:log --only verifyTossPayment

# 에러만 필터링
firebase functions:log --only verifyTossPayment | grep ERROR
```

#### Firebase Console에서 모니터링
1. Functions → Health 탭
   - 실행 시간
   - 오류율
   - 호출 횟수
2. Firestore → Usage 탭
   - 읽기/쓰기 작업 수
   - 저장소 사용량
3. Alerts 컬렉션
   - 의심 거래 알림 확인

### 8단계: 문제 해결

#### 함수 호출 실패 (permission-denied)
```bash
# Firebase Authentication 설정 확인
firebase auth:export users.json
# 사용자 UID와 Functions 인증 일치 확인
```

#### 환경 변수 접근 불가
```bash
# 현재 설정된 환경 변수 확인
firebase functions:config:get

# 재설정 후 재배포
firebase functions:config:set toss.secret_key="YOUR_KEY"
firebase deploy --only functions
```

#### Toss API 호출 오류
- Secret Key 형식 확인 (test_sk_* 또는 live_sk_*)
- Toss Developers Console에서 키 활성화 상태 확인
- API 요청 로그 확인 (firebase functions:log)

#### Security Rules 위반
```bash
# Rules 문법 검사
firebase deploy --only firestore:rules --dry-run

# Rules 재배포
firebase deploy --only firestore:rules
```

### 9단계: 비용 예상 (한국 리전 기준)

#### Cloud Functions (무료 할당량)
- 호출: 200만 회/월
- 컴퓨팅: 400,000 GB-초/월
- 네트워크: 5GB/월

#### 예상 월간 비용 (소규모 서비스)
- 결제 1000건/월: 약 $0.20
- 출금 처리 100건/월: 약 $0.02
- 거래 모니터링 트리거: 약 $0.10
- **총 예상 비용**: $0-2/월

#### 예상 월간 비용 (중규모 서비스)
- 결제 10,000건/월: 약 $2
- 출금 처리 1,000건/월: 약 $0.20
- 거래 모니터링: 약 $1
- **총 예상 비용**: $5-10/월

### 10단계: 성능 최적화

#### Cold Start 개선
```javascript
// functions/index.js 상단에 추가
const functions = require('firebase-functions').region('asia-northeast1');
// 최소 인스턴스 유지 (유료 플랜 필요)
exports.verifyTossPayment = functions
  .runWith({ minInstances: 1 })
  .https.onCall(async (data, context) => { ... });
```

#### 타임아웃 설정
```javascript
exports.verifyTossPayment = functions
  .runWith({ timeoutSeconds: 30, memory: '256MB' })
  .https.onCall(async (data, context) => { ... });
```

---

**🚀 축하합니다! BugCash 앱이 성공적으로 배포되었습니다! 🚀**