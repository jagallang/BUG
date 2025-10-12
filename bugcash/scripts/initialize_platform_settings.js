const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = require('../bugcash-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'bugcash'
});

const db = admin.firestore();

// 기본 설정값 (Cloud Function의 getDefaultSettings와 동일)
const defaultSettings = {
  rewards: {
    signupBonus: {
      enabled: true,
      amount: 5000,
      description: '회원가입 시 지급되는 포인트',
      conditions: {
        requireEmailVerification: false,
        onlyNewUsers: true
      }
    },
    projectCompletionBonus: {
      enabled: true,
      testerAmount: 1000,
      providerAmount: 1000,
      description: '14일 프로젝트 완료 시 양쪽에 지급',
      conditions: {
        minDays: 14,
        requireAllDaysCompleted: true,
        requireBothPartiesConfirm: true
      }
    },
    dailyMissionReward: {
      enabled: true,
      baseAmount: 50,
      description: '일일 미션 완료 시 지급',
      conditions: {
        maxPerDay: 10,
        requirePhotoEvidence: true
      }
    }
  },

  withdrawal: {
    minAmount: 30000,
    allowedUnits: 10000,
    feeRate: 0.18,
    description: '출금 설정: 최소 30,000P, 10,000P 단위, 수수료 18%',
    autoApprove: false,
    processingDays: 5,
    conditions: {
      requireKyc: true,
      minAccountAgeDays: 7,
      minTransactionCount: 5
    }
  },

  platform: {
    appRegistration: {
      cost: 5000,
      description: '앱 등록 비용',
      refundPolicy: {
        enabled: true,
        withinDays: 7,
        refundRate: 1.0
      }
    },
    missionCreation: {
      cost: 1000,
      description: '미션 생성 비용',
      freeTrials: 3
    },
    commissionRate: {
      tester: 0.03,
      provider: 0.03,
      description: '플랫폼 수수료율 (양쪽 3%)'
    }
  },

  abuse_prevention: {
    multiAccountDetection: {
      enabled: true,
      checkDeviceId: true,
      checkIpAddress: true,
      checkBankAccount: true,
      maxAccountsPerDevice: 1
    },
    withdrawalRestrictions: {
      requireKyc: true,
      maxDailyWithdrawals: 3,
      maxDailyAmount: 500000,
      cooldownHours: 24,
      suspiciousPatternCheck: true
    },
    pointAbuseDetection: {
      enabled: true,
      maxPointsPerDay: 10000,
      flagRapidAccumulation: true,
      autoSuspendThreshold: 50000
    }
  }
};

// 초기화 함수
async function initializePlatformSettings() {
  console.log('🚀 플랫폼 설정 초기화 시작...\n');

  const batch = db.batch();
  const timestamp = admin.firestore.FieldValue.serverTimestamp();

  // 각 설정 타입별로 문서 생성
  for (const [settingType, settingData] of Object.entries(defaultSettings)) {
    const docRef = db.collection('platform_settings').doc(settingType);

    // 이미 존재하는지 확인
    const docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      console.log(`⚠️  ${settingType} 설정이 이미 존재합니다. 건너뜁니다.`);
      continue;
    }

    batch.set(docRef, {
      ...settingData,
      createdAt: timestamp,
      updatedAt: timestamp,
      createdBy: 'system',
      version: 1
    });

    console.log(`✅ ${settingType} 설정 생성 준비 완료`);
  }

  // 배치 실행
  await batch.commit();
  console.log('\n🎉 모든 플랫폼 설정이 성공적으로 초기화되었습니다!');

  // 생성된 설정 확인
  console.log('\n📋 생성된 설정 목록:');
  const settingsSnapshot = await db.collection('platform_settings').get();
  settingsSnapshot.forEach(doc => {
    console.log(`   - ${doc.id}`);
  });

  console.log('\n✨ 초기화 완료!\n');
}

// 실행
initializePlatformSettings()
  .then(() => {
    console.log('스크립트가 성공적으로 완료되었습니다.');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ 오류 발생:', error);
    process.exit(1);
  });
