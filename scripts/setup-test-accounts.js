#!/usr/bin/env node

/**
 * Firebase Test Accounts Setup Script
 * BugCash 프로젝트용 테스트 계정을 Firebase Auth에 생성하는 스크립트
 */

const admin = require('firebase-admin');
const path = require('path');

// Firebase Admin SDK 초기화
// Google Services 파일에서 프로젝트 정보 읽기
const googleServicesPath = path.join(__dirname, '../bugcash/android/app/google-services.json');

try {
  const googleServices = require(googleServicesPath);
  const projectId = googleServices.project_info.project_id;

  // Firebase Admin SDK를 환경변수나 기본 자격증명으로 초기화
  // 실제 서비스 계정 키가 없는 경우를 위한 대체 방법
  admin.initializeApp({
    projectId: projectId,
    databaseURL: `https://${projectId}-default-rtdb.firebaseio.com`
  });

  console.log(`✅ Firebase Admin SDK 초기화 완료 (프로젝트: ${projectId})`);
} catch (error) {
  console.error('❌ Firebase Admin SDK 초기화 실패:', error.message);
  console.log('\n📝 해결 방법:');
  console.log('1. Firebase 콘솔에서 서비스 계정 키 다운로드');
  console.log('2. 환경변수 GOOGLE_APPLICATION_CREDENTIALS 설정');
  console.log('3. 또는 gcloud auth application-default login 실행');
  process.exit(1);
}

// 테스트 계정 데이터 (README.md와 동일)
const testAccounts = [
  // Provider (앱 공급자) 계정들
  {
    email: 'admin@techcorp.com',
    password: 'admin123',
    displayName: '김관리자',
    userType: 'provider',
    companyName: 'TechCorp Ltd.',
    role: '관리자',
  },
  {
    email: 'provider@gamedev.com',
    password: 'provider123',
    displayName: '이공급자',
    userType: 'provider',
    companyName: 'GameDev Studio',
    role: '개발팀',
  },
  {
    email: 'company@fintech.com',
    password: 'company123',
    displayName: '박기업',
    userType: 'provider',
    companyName: 'FinTech Solutions',
    role: '기업',
  },
  {
    email: 'developer@startup.com',
    password: 'dev123',
    displayName: '최개발자',
    userType: 'provider',
    companyName: 'Startup Inc.',
    role: '개발자',
  },
  {
    email: 'qa@enterprise.com',
    password: 'qa456',
    displayName: '정QA',
    userType: 'provider',
    companyName: 'Enterprise Solutions',
    role: 'QA',
  },

  // Tester (테스터) 계정들
  {
    email: 'tester1@gmail.com',
    password: 'tester123',
    displayName: '김테스터',
    userType: 'tester',
    specialization: '일반 앱 테스터',
  },
  {
    email: 'tester2@gmail.com',
    password: 'test456',
    displayName: '이사용자',
    userType: 'tester',
    specialization: 'UI/UX 전문 테스터',
  },
  {
    email: 'tester3@gmail.com',
    password: 'tester789',
    displayName: '박검증자',
    userType: 'tester',
    specialization: '보안 전문 테스터',
  },
  {
    email: 'tester4@gmail.com',
    password: 'test999',
    displayName: '최버그헌터',
    userType: 'tester',
    specialization: '버그 헌팅 전문가',
  },
  {
    email: 'tester5@gmail.com',
    password: 'tester555',
    displayName: '정모바일테스터',
    userType: 'tester',
    specialization: '모바일 앱 전문',
  },
  {
    email: 'tester6@naver.com',
    password: 'naver123',
    displayName: '강웹테스터',
    userType: 'tester',
    specialization: '웹 애플리케이션 전문',
  },
];

/**
 * 테스트 계정을 Firebase Auth에 생성
 */
async function createTestAccount(account) {
  try {
    // Firebase Auth에서 사용자 생성
    const userRecord = await admin.auth().createUser({
      email: account.email,
      password: account.password,
      displayName: account.displayName,
      emailVerified: true, // 테스트 계정이므로 이메일 검증 완료로 설정
    });

    // Firestore에 사용자 프로필 데이터 저장
    const userData = {
      uid: userRecord.uid,
      email: account.email,
      displayName: account.displayName,
      userType: account.userType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Provider 계정인 경우 추가 데이터
    if (account.userType === 'provider') {
      userData.companyName = account.companyName;
      userData.role = account.role;
      userData.approvedApps = 0;
      userData.totalTesters = 0;
    }

    // Tester 계정인 경우 추가 데이터
    if (account.userType === 'tester') {
      userData.specialization = account.specialization;
      userData.completedMissions = 0;
      userData.totalPoints = 0;
      userData.rating = 5.0;
      userData.experienceYears = Math.floor(Math.random() * 5) + 1; // 1-5년
    }

    // Firestore에 사용자 데이터 저장
    await admin.firestore()
      .collection('users')
      .doc(userRecord.uid)
      .set(userData);

    console.log(`✅ 계정 생성 완료: ${account.email} (${account.displayName})`);
    return { success: true, uid: userRecord.uid };

  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log(`⚠️ 계정이 이미 존재합니다: ${account.email}`);
      return { success: false, reason: 'already-exists' };
    } else {
      console.error(`❌ 계정 생성 실패: ${account.email} - ${error.message}`);
      return { success: false, reason: error.message };
    }
  }
}

/**
 * 모든 테스트 계정 생성
 */
async function setupAllTestAccounts() {
  console.log('🚀 BugCash 테스트 계정 설정 시작...\n');

  const results = {
    created: 0,
    existing: 0,
    failed: 0,
  };

  for (const account of testAccounts) {
    const result = await createTestAccount(account);

    if (result.success) {
      results.created++;
    } else if (result.reason === 'already-exists') {
      results.existing++;
    } else {
      results.failed++;
    }

    // API 요청 제한 방지를 위해 잠시 대기
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  console.log('\n📊 설정 완료 결과:');
  console.log(`✅ 새로 생성된 계정: ${results.created}개`);
  console.log(`⚠️ 이미 존재하는 계정: ${results.existing}개`);
  console.log(`❌ 생성 실패한 계정: ${results.failed}개`);
  console.log(`📱 총 테스트 계정 수: ${testAccounts.length}개`);

  if (results.failed === 0) {
    console.log('\n🎉 모든 테스트 계정이 성공적으로 설정되었습니다!');
    console.log('이제 Flutter 앱에서 다음 계정들로 로그인할 수 있습니다:\n');

    // 계정 목록 출력
    testAccounts.forEach(account => {
      const type = account.userType === 'provider' ? '🏢 공급자' : '👤 테스터';
      console.log(`${type}: ${account.email} / ${account.password}`);
    });
  }
}

/**
 * 메인 실행 함수
 */
async function main() {
  try {
    await setupAllTestAccounts();
  } catch (error) {
    console.error('❌ 스크립트 실행 중 오류 발생:', error);
    process.exit(1);
  } finally {
    // Firebase Admin SDK 연결 종료
    admin.app().delete();
  }
}

// 스크립트 직접 실행 시에만 main 함수 호출
if (require.main === module) {
  main();
}

module.exports = {
  setupAllTestAccounts,
  createTestAccount,
  testAccounts,
};