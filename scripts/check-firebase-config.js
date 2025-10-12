#!/usr/bin/env node

/**
 * Firebase 설정 확인 및 Authentication 상태 점검 스크립트
 */

const fs = require('fs');
const path = require('path');

console.log('🔥 Firebase 설정 확인 스크립트');
console.log('================================\n');

// 1. google-services.json 파일 확인
const googleServicesPath = '../bugcash/android/app/google-services.json';
const fullPath = path.join(__dirname, googleServicesPath);

if (!fs.existsSync(fullPath)) {
  console.log('❌ google-services.json 파일을 찾을 수 없습니다.');
  console.log(`   경로: ${fullPath}`);
  process.exit(1);
}

console.log('✅ google-services.json 파일이 존재합니다.');

try {
  const googleServices = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
  const projectId = googleServices.project_info?.project_id;
  const projectNumber = googleServices.project_info?.project_number;

  console.log(`   프로젝트 ID: ${projectId}`);
  console.log(`   프로젝트 번호: ${projectNumber}`);
  console.log(`   앱 개수: ${googleServices.client?.length || 0}\n`);

  // 2. Firebase Console 설정 안내
  console.log('📋 Firebase Console 설정 확인 사항:');
  console.log('----------------------------------');
  console.log('1. Firebase Console 접속:');
  console.log(`   https://console.firebase.google.com/project/${projectId}`);
  console.log('');
  console.log('2. Authentication 서비스 확인:');
  console.log('   ⚠️  Authentication > Sign-in method > 이메일/비밀번호 활성화 필요');
  console.log('   ⚠️  Authentication이 비활성화되어 있으면 CONFIGURATION_NOT_FOUND 오류 발생');
  console.log('');
  console.log('3. 테스트 계정 목록 (자동 생성 대상):');

  // 3. 테스트 계정 목록 표시
  const testAccounts = [
    { email: 'admin@techcorp.com', type: 'Provider', name: '김관리자' },
    { email: 'provider@gamedev.com', type: 'Provider', name: '이공급자' },
    { email: 'company@fintech.com', type: 'Provider', name: '박기업' },
    { email: 'developer@startup.com', type: 'Provider', name: '최개발자' },
    { email: 'qa@enterprise.com', type: 'Provider', name: '정QA' },
    { email: 'tester1@gmail.com', type: 'Tester', name: '김테스터' },
    { email: 'tester2@gmail.com', type: 'Tester', name: '이사용자' },
    { email: 'tester3@gmail.com', type: 'Tester', name: '박검증자' },
    { email: 'tester4@gmail.com', type: 'Tester', name: '최버그헌터' },
    { email: 'tester5@gmail.com', type: 'Tester', name: '정모바일테스터' },
    { email: 'tester6@naver.com', type: 'Tester', name: '강웹테스터' }
  ];

  testAccounts.forEach((account, index) => {
    console.log(`   ${index + 1}. ${account.email} (${account.type}) - ${account.name}`);
  });

  console.log('');
  console.log('🔧 문제 해결 단계:');
  console.log('------------------');
  console.log('1. Firebase Console에서 Authentication 활성화');
  console.log('2. 이메일/비밀번호 로그인 방법 활성화');
  console.log('3. 앱에서 테스트 계정으로 로그인 시도');
  console.log('4. 자동으로 Firebase Auth에 계정 생성됨');
  console.log('');
  console.log('💡 HybridAuthService가 Mock과 Firebase Auth를 자동으로 연결합니다.');

} catch (error) {
  console.log('❌ google-services.json 파일 파싱 오류:', error.message);
}