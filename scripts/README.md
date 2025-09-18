# BugCash Firebase 테스트 계정 설정

이 스크립트는 BugCash 프로젝트의 테스트 계정들을 Firebase Authentication에 실제로 생성하는 도구입니다.

## 🎯 목적

Mock 인증 시스템에서 실제 Firebase Auth로 전환하여 테스트 계정들이 실제로 로그인되도록 합니다.

## 📋 생성되는 테스트 계정

### 🏢 Provider (앱 공급자) 계정 (5개)
| 이메일 | 비밀번호 | 이름 | 회사명 |
|--------|----------|------|--------|
| admin@techcorp.com | admin123 | 김관리자 | TechCorp Ltd. |
| provider@gamedev.com | provider123 | 이공급자 | GameDev Studio |
| company@fintech.com | company123 | 박기업 | FinTech Solutions |
| developer@startup.com | dev123 | 최개발자 | Startup Inc. |
| qa@enterprise.com | qa456 | 정QA | Enterprise Solutions |

### 👤 Tester (테스터) 계정 (6개)
| 이메일 | 비밀번호 | 이름 | 전문분야 |
|--------|----------|------|---------|
| tester1@gmail.com | tester123 | 김테스터 | 일반 앱 테스터 |
| tester2@gmail.com | test456 | 이사용자 | UI/UX 전문 테스터 |
| tester3@gmail.com | tester789 | 박검증자 | 보안 전문 테스터 |
| tester4@gmail.com | test999 | 최버그헌터 | 버그 헌팅 전문가 |
| tester5@gmail.com | tester555 | 정모바일테스터 | 모바일 앱 전문 |
| tester6@naver.com | naver123 | 강웹테스터 | 웹 애플리케이션 전문 |

## 🚀 사용 방법

### 1. 의존성 설치
```bash
cd scripts
npm install
```

### 2. Firebase 서비스 계정 키 확인
스크립트는 다음 위치의 Google Services 파일을 사용합니다:
```
../bugcash/android/app/google-services.json
```

### 3. 테스트 계정 생성 실행
```bash
npm run setup
# 또는
node setup-test-accounts.js
```

### 4. 실행 결과 확인
스크립트 실행 후 다음과 같은 결과를 확인할 수 있습니다:
- ✅ 새로 생성된 계정 수
- ⚠️ 이미 존재하는 계정 수
- ❌ 생성 실패한 계정 수

## 📱 Flutter 앱에서 사용

테스트 계정 생성 완료 후, Flutter 앱에서 다음과 같이 사용할 수 있습니다:

1. **로그인 페이지에서 직접 입력**
   ```
   이메일: tester1@gmail.com
   비밀번호: tester123
   ```

2. **Mock 계정 다이얼로그 사용**
   - 로그인 페이지의 "테스트 계정으로 로그인" 버튼 클릭
   - 원하는 계정 선택하여 자동 로그인

## 🔧 Firebase 설정

### Firestore 컬렉션 구조
```
users/
├── {uid}/
    ├── uid: string
    ├── email: string
    ├── displayName: string
    ├── userType: 'provider' | 'tester'
    ├── createdAt: timestamp
    ├── lastLoginAt: timestamp
    └── ... (역할별 추가 필드)
```

### Provider 계정 추가 필드
```typescript
interface ProviderUser {
  companyName: string;
  role: string;
  approvedApps: number;
  totalTesters: number;
}
```

### Tester 계정 추가 필드
```typescript
interface TesterUser {
  specialization: string;
  completedMissions: number;
  totalPoints: number;
  rating: number;
  experienceYears: number;
}
```

## ⚠️ 주의사항

1. **Firebase 프로젝트 설정**: 올바른 Firebase 프로젝트에 연결되어 있는지 확인
2. **권한 설정**: Firebase Admin SDK 권한이 있는지 확인
3. **중복 실행**: 이미 존재하는 계정은 건너뛰므로 안전하게 재실행 가능
4. **비밀번호 보안**: 프로덕션 환경에서는 더 강력한 비밀번호 사용 권장

## 🛠️ 문제 해결

### Firebase Admin SDK 초기화 실패
```bash
❌ Firebase Admin SDK 초기화 실패: ENOENT: no such file or directory
```
**해결**: `../bugcash/android/app/google-services.json` 파일이 존재하는지 확인

### 권한 오류
```bash
❌ 계정 생성 실패: insufficient permissions
```
**해결**: Firebase 프로젝트의 Admin SDK 권한 설정 확인

### 이메일 중복 오류
```bash
⚠️ 계정이 이미 존재합니다: tester1@gmail.com
```
**해결**: 정상적인 동작입니다. 기존 계정을 건너뛰고 계속 진행합니다.

## 📚 추가 정보

- **Firebase Admin SDK**: [공식 문서](https://firebase.google.com/docs/admin/setup)
- **Firebase Authentication**: [공식 문서](https://firebase.google.com/docs/auth)
- **BugCash 프로젝트**: [GitHub 리포지토리](https://github.com/jagallang/BUG)