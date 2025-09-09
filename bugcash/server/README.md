# BugCash Server

BugCash 플랫폼의 백엔드 API 서버입니다.

## 🚀 개발 환경 설정

### 사전 요구사항

- Node.js 18+ 
- npm 또는 yarn
- Firebase Admin SDK 설정 (선택사항)
- AWS S3 설정 (선택사항)

### 빠른 시작

1. **의존성 설치**
   ```bash
   npm install
   ```

2. **환경 설정**
   ```bash
   # .env 파일이 자동 생성됩니다
   # 필요시 실제 Firebase/AWS 설정으로 업데이트하세요
   ```

3. **개발 서버 실행**
   ```bash
   npm run dev
   ```

서버가 http://localhost:3001 에서 실행됩니다.

### 스크립트

```bash
# 개발 서버 (핫 리로드 포함)
npm run dev

# 프로덕션 서버
npm start

# 테스트 실행
npm test

# Firebase Functions 배포
npm run deploy
```

## 📡 API 엔드포인트

### 헬스 체크
- `GET /health` - 서버 상태 확인

### 인증
- `POST /api/auth/register` - 사용자 등록
- `POST /api/auth/login` - 로그인
- `POST /api/auth/logout` - 로그아웃
- `GET /api/auth/profile` - 프로필 조회

### 미션
- `GET /api/missions` - 미션 목록
- `GET /api/missions/:id` - 미션 상세
- `POST /api/missions` - 미션 생성 (공급자)
- `POST /api/missions/:id/join` - 미션 참여 (테스터)

### 앱 관리
- `POST /api/apps` - 앱 등록
- `GET /api/apps/provider/:providerId` - 공급자별 앱 목록
- `GET /api/apps/:appId` - 앱 상세
- `PATCH /api/apps/:appId` - 앱 정보 수정
- `DELETE /api/apps/:appId` - 앱 삭제
- `POST /api/apps/:appId/join` - 앱 테스팅 참여

### 파일 업로드
- `POST /api/upload/apk` - APK 파일 업로드
- `POST /api/upload/image` - 이미지 업로드
- `GET /api/upload/download/:fileId` - 파일 다운로드
- `DELETE /api/upload/:fileId` - 파일 삭제

### 알림
- `GET /api/notifications/:userId` - 사용자 알림 목록
- `PATCH /api/notifications/:id/read` - 알림 읽음 처리
- `PATCH /api/notifications/user/:userId/read-all` - 모든 알림 읽음 처리

### 분석
- `GET /api/analytics/provider/:providerId` - 공급자 분석
- `GET /api/analytics/tester/:testerId` - 테스터 분석
- `GET /api/analytics/platform` - 플랫폼 분석
- `GET /api/analytics/mission/:missionId` - 미션 분석

## 🏗️ 프로젝트 구조

```
server/
├── src/
│   ├── routes/          # API 라우트
│   │   ├── auth.js      # 인증 관련
│   │   ├── apps.js      # 앱 관리
│   │   ├── missions.js  # 미션 관리
│   │   ├── upload.js    # 파일 업로드
│   │   ├── notifications.js
│   │   └── analytics.js
│   └── index.js         # 메인 서버 파일
├── .env                 # 환경 변수
├── .env.example         # 환경 변수 템플릿
├── package.json         # 프로젝트 설정
├── docker-compose.yml   # Docker 컨테이너 설정
└── Dockerfile          # Docker 이미지 설정
```

## 🔧 환경 변수

```env
# 서버 설정
NODE_ENV=development
PORT=3001

# Firebase 설정
FIREBASE_PROJECT_ID=bugcash-platform

# AWS 설정
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=bugcash-files

# 데이터베이스 설정
DATABASE_URL=postgresql://postgres:password@localhost:5432/bugcash
REDIS_URL=redis://localhost:6379

# 보안
JWT_SECRET=your_jwt_secret_key
ENCRYPTION_KEY=your_encryption_key
```

## 🐳 Docker 배포

```bash
# 개발 환경
docker-compose up -d

# 프로덕션 빌드
docker build -t bugcash-server .
docker run -p 3001:3001 bugcash-server
```

## 🧪 테스트

```bash
# 헬스 체크 테스트
curl http://localhost:3001/health

# 미션 목록 테스트
curl http://localhost:3001/api/missions

# 인증 테스트
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

## 📦 배포

### Firebase Functions

```bash
npm run deploy
```

### AWS/GCP

Docker 컨테이너를 사용하여 클라우드 플랫폼에 배포할 수 있습니다.

## 🛠️ 개발 모드

현재 서버는 개발 모드에서 Mock 데이터를 사용합니다:
- Firebase 연결 없이 작동
- AWS S3 없이 파일 업로드 시뮬레이션
- 메모리 기반 데이터 스토리지

실제 운영에서는 Firebase Admin SDK와 AWS S3 설정이 필요합니다.

## 🔒 보안 주의사항

- 실제 Firebase Admin SDK 키 파일은 저장소에 커밋하지 마세요
- AWS 액세스 키는 환경 변수나 IAM 역할을 사용하세요
- JWT 시크릿과 암호화 키는 안전하게 관리하세요

## 📞 지원

문제가 있으면 이슈를 생성해 주세요.