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

**🚀 축하합니다! BugCash 앱이 성공적으로 배포되었습니다! 🚀**