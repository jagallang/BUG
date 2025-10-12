# 🔐 API 키 설정 가이드

이 프로젝트를 설정하기 위해서는 여러 API 키들을 올바르게 구성해야 합니다.

## 🔥 Firebase 설정

### 1. Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트 생성
2. 프로젝트 설정에서 각 플랫폼별 앱 추가

### 2. 구성 파일 업데이트

#### Android
`android/app/google-services.json` 파일에서:
```json
{
  "api_key": [
    {
      "current_key": "여기에_실제_안드로이드_API_키_입력"
    }
  ]
}
```

#### Web
`web/index.html` 파일에서:
```javascript
const firebaseConfig = {
  apiKey: "여기에_실제_웹_API_키_입력",
  authDomain: "your-project.firebaseapp.com",
  // ... 다른 설정들
};
```

#### Flutter 옵션
`lib/firebase_options.dart` 파일에서:
- Web: `apiKey: '여기에_실제_웹_API_키_입력'`
- Android: `apiKey: '여기에_실제_안드로이드_API_키_입력'`

## 🤖 Google Gemini AI 설정

### 1. API 키 발급
1. [Google AI Studio](https://aistudio.google.com/app/apikey)에서 API 키 생성
2. 키를 안전한 곳에 보관

### 2. 환경 변수 설정

#### 개발 시 설정 방법:
```bash
# 명령줄에서 실행
flutter run --dart-define=GEMINI_API_KEY=your_actual_gemini_api_key_here
```

#### IDE 설정 (VS Code/Android Studio):
Additional run args에 다음 추가:
```
--dart-define=GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### 3. 프로덕션 환경
- CI/CD 파이프라인에서 환경 변수로 설정
- 클라우드 서비스의 Secret Manager 사용 권장

## 🔒 보안 주의사항

### ❌ 절대 하지 말 것:
- API 키를 코드에 직접 하드코딩
- 공개 리포지토리에 실제 키 커밋
- 클라이언트 사이드에 민감한 키 노출

### ✅ 권장 사항:
- 환경 변수 사용
- `.gitignore`에 민감한 파일 추가
- 정기적인 키 로테이션
- 키별 권한 최소화

## 🚀 빠른 시작

1. 이 가이드에 따라 모든 키 설정
2. 프로젝트 클론 후 dependencies 설치:
   ```bash
   flutter pub get
   ```
3. 환경 변수와 함께 앱 실행:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_key_here
   ```

## 🆘 문제 해결

### Gemini API 오류
- API 키가 올바르게 설정되었는지 확인
- API 키 권한 및 할당량 확인
- 네트워크 연결 상태 확인

### Firebase 연결 오류
- 프로젝트 ID와 구성이 일치하는지 확인
- 각 플랫폼별 설정이 올바른지 확인
- Firebase 프로젝트가 활성화되었는지 확인

---

> ⚠️ **경고**: 실제 API 키는 절대 버전 관리 시스템에 커밋하지 마세요!