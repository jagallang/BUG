import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bugcash/lib/firebase_options.dart';

void main() async {
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('🔍 Checking Firestore data...\n');

  try {
    // 1. mission_workflows 문서 가져오기
    final workflowDoc = await firestore
        .collection('mission_workflows')
        .doc('rflsZbhOAfno0pm9VtXn')
        .get();

    if (!workflowDoc.exists) {
      print('❌ Workflow document not found!');
      return;
    }

    final data = workflowDoc.data()!;

    print('✅ Workflow Document Found');
    print('─' * 80);
    print('📋 currentState: ${data['currentState']}');
    print('📅 stateUpdatedAt: ${data['stateUpdatedAt']}');
    print('👤 stateUpdatedBy: ${data['stateUpdatedBy']}\n');

    // 2. dailyInteractions 확인
    final dailyInteractions = data['dailyInteractions'] as List<dynamic>?;

    if (dailyInteractions == null || dailyInteractions.isEmpty) {
      print('❌ No dailyInteractions found!');
      return;
    }

    print('📊 Daily Interactions:');
    print('─' * 80);

    for (var interaction in dailyInteractions) {
      final interactionMap = interaction as Map<String, dynamic>;
      final dayNumber = interactionMap['dayNumber'];

      print('\n📅 Day $dayNumber:');
      print('   ├─ testerCompleted: ${interactionMap['testerCompleted']}');
      print('   ├─ testerCompletedAt: ${interactionMap['testerCompletedAt']}');
      print('   ├─ testerFeedback: ${interactionMap['testerFeedback'] ?? 'N/A'}');

      final screenshots = interactionMap['testerScreenshots'] as List<dynamic>?;
      if (screenshots != null && screenshots.isNotEmpty) {
        print('   ├─ testerScreenshots (${screenshots.length}):');
        for (int i = 0; i < screenshots.length; i++) {
          print('   │  ├─ [$i] ${screenshots[i]}');
        }
      } else {
        print('   ├─ testerScreenshots: ❌ EMPTY or NULL');
      }

      final testerData = interactionMap['testerData'] as Map<String, dynamic>?;
      if (testerData != null && testerData.isNotEmpty) {
        print('   ├─ testerData:');
        if (testerData.containsKey('bugReport')) {
          print('   │  ├─ bugReport: ${testerData['bugReport']}');
        }
        if (testerData.containsKey('questionAnswers')) {
          print('   │  └─ questionAnswers: ${testerData['questionAnswers']}');
        }
      }

      print('   ├─ providerApproved: ${interactionMap['providerApproved']}');
      print('   └─ providerFeedback: ${interactionMap['providerFeedback'] ?? 'N/A'}');
    }

    print('\n' + '─' * 80);

    // 3. notifications 확인
    print('\n🔔 Checking Notifications...');
    print('─' * 80);

    final notifications = await firestore
        .collection('notifications')
        .where('data.workflowId', isEqualTo: 'rflsZbhOAfno0pm9VtXn')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    if (notifications.docs.isEmpty) {
      print('❌ No notifications found for this workflow!');
    } else {
      print('✅ Found ${notifications.docs.length} notifications:\n');

      for (var doc in notifications.docs) {
        final notifData = doc.data();
        print('📬 Notification ID: ${doc.id}');
        print('   ├─ title: ${notifData['title']}');
        print('   ├─ message: ${notifData['message']}');
        print('   ├─ userId: ${notifData['userId']}');
        print('   ├─ userType: ${notifData['userType']}');
        print('   ├─ isRead: ${notifData['isRead']}');
        print('   ├─ createdAt: ${notifData['createdAt']}');
        print('   └─ data: ${notifData['data']}\n');
      }
    }

    print('─' * 80);
    print('✅ Firestore check completed!');

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
