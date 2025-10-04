const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
admin.initializeApp({
  projectId: 'bugcash',
});

const db = admin.firestore();

async function checkFirestoreData() {
  console.log('🔍 Checking Firestore data...\n');

  try {
    // 1. mission_workflows 문서 가져오기
    const workflowRef = db.collection('mission_workflows').doc('rflsZbhOAfno0pm9VtXn');
    const workflowDoc = await workflowRef.get();

    if (!workflowDoc.exists) {
      console.log('❌ Workflow document not found!');
      return;
    }

    const data = workflowDoc.data();

    console.log('✅ Workflow Document Found');
    console.log('─'.repeat(80));
    console.log('📋 currentState:', data.currentState);
    console.log('📅 stateUpdatedAt:', data.stateUpdatedAt?.toDate());
    console.log('👤 stateUpdatedBy:', data.stateUpdatedBy);
    console.log('');

    // 2. dailyInteractions 확인
    const dailyInteractions = data.dailyInteractions || [];

    if (dailyInteractions.length === 0) {
      console.log('❌ No dailyInteractions found!');
      return;
    }

    console.log('📊 Daily Interactions:');
    console.log('─'.repeat(80));

    dailyInteractions.forEach((interaction) => {
      const dayNumber = interaction.dayNumber;

      console.log(`\n📅 Day ${dayNumber}:`);
      console.log('   ├─ testerCompleted:', interaction.testerCompleted);
      console.log('   ├─ testerCompletedAt:', interaction.testerCompletedAt?.toDate());
      console.log('   ├─ testerFeedback:', interaction.testerFeedback || 'N/A');

      const screenshots = interaction.testerScreenshots || [];
      if (screenshots.length > 0) {
        console.log(`   ├─ testerScreenshots (${screenshots.length}):`);
        screenshots.forEach((url, i) => {
          console.log(`   │  ├─ [${i}] ${url}`);
        });
      } else {
        console.log('   ├─ testerScreenshots: ❌ EMPTY or NULL');
      }

      const testerData = interaction.testerData || {};
      if (Object.keys(testerData).length > 0) {
        console.log('   ├─ testerData:');
        if (testerData.bugReport) {
          console.log('   │  ├─ bugReport:', testerData.bugReport);
        }
        if (testerData.questionAnswers) {
          console.log('   │  └─ questionAnswers:', testerData.questionAnswers);
        }
      }

      console.log('   ├─ providerApproved:', interaction.providerApproved);
      console.log('   └─ providerFeedback:', interaction.providerFeedback || 'N/A');
    });

    console.log('\n' + '─'.repeat(80));

    // 3. notifications 확인
    console.log('\n🔔 Checking Notifications...');
    console.log('─'.repeat(80));

    const notificationsSnapshot = await db.collection('notifications')
      .where('data.workflowId', '==', 'rflsZbhOAfno0pm9VtXn')
      .orderBy('createdAt', 'desc')
      .limit(5)
      .get();

    if (notificationsSnapshot.empty) {
      console.log('❌ No notifications found for this workflow!');
    } else {
      console.log(`✅ Found ${notificationsSnapshot.size} notifications:\n`);

      notificationsSnapshot.forEach((doc) => {
        const notifData = doc.data();
        console.log('📬 Notification ID:', doc.id);
        console.log('   ├─ title:', notifData.title);
        console.log('   ├─ message:', notifData.message);
        console.log('   ├─ userId:', notifData.userId);
        console.log('   ├─ userType:', notifData.userType);
        console.log('   ├─ isRead:', notifData.isRead);
        console.log('   ├─ createdAt:', notifData.createdAt?.toDate());
        console.log('   └─ data:', notifData.data);
        console.log('');
      });
    }

    console.log('─'.repeat(80));
    console.log('✅ Firestore check completed!');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Stack trace:', error.stack);
  } finally {
    process.exit(0);
  }
}

checkFirestoreData();
