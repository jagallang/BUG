import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Firebase 컬렉션 생성 도구
/// Flutter 앱에서 직접 Firestore 컬렉션을 생성합니다.
class FirestoreCollectionCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase 초기화
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase 초기화 완료');
  }

  /// tester_applications 컬렉션 생성
  static Future<void> createTesterApplicationsCollection() async {
    print('📋 tester_applications 컬렉션 생성 시작...');

    try {
      // 샘플 Document 1: 대기 중인 신청
      final pendingApplication = {
        'appId': 'eUOdv8wASX7RfSGMin7c',
        'testerId': 'CazdCJYsxGMxEOzXGTen3AY5Kom2',
        'providerId': 'provider_demo_123',

        'status': 'pending',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': '',

        'appliedAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'startedAt': null,
        'completedAt': null,

        'testerInfo': {
          'name': '김테스터',
          'email': 'tester@example.com',
          'experience': '중급',
          'motivation': '앱 품질 향상에 기여하고 싶습니다.',
          'deviceModel': 'SM-S926N',
          'deviceOS': 'Android 15',
          'deviceVersion': 'API 35'
        },

        'missionInfo': {
          'appName': 'BugCash Demo App',
          'totalDays': 14,
          'dailyReward': 5000,
          'totalReward': 70000,
          'requirements': [
            '일일 30분 이상 앱 사용',
            '피드백 작성 필수',
            '버그 발견 시 즉시 신고'
          ]
        },

        'progress': {
          'currentDay': 0,
          'progressPercentage': 0.0,
          'todayCompleted': false,
          'bugsReported': 0,
          'feedbackSubmitted': 0,
          'totalPoints': 0
        }
      };

      // 샘플 Document 2: 승인된 신청
      final approvedApplication = {
        'appId': 'eUOdv8wASX7RfSGMin7c',
        'testerId': 'active_tester_456',
        'providerId': 'provider_demo_123',

        'status': 'approved',
        'statusUpdatedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T09:00:00.000Z')),
        'statusUpdatedBy': 'provider_demo_123',

        'appliedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T05:00:00.000Z')),
        'approvedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T09:00:00.000Z')),
        'startedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T09:00:00.000Z')),
        'completedAt': null,

        'testerInfo': {
          'name': '이활동',
          'email': 'active@example.com',
          'experience': '고급',
          'motivation': '전문적인 QA 경험을 쌓고 싶습니다.',
          'deviceModel': 'iPhone 15 Pro',
          'deviceOS': 'iOS 17',
          'deviceVersion': '17.5.1'
        },

        'missionInfo': {
          'appName': 'BugCash Demo App',
          'totalDays': 14,
          'dailyReward': 5000,
          'totalReward': 70000,
          'requirements': [
            '일일 30분 이상 앱 사용',
            '피드백 작성 필수',
            '버그 발견 시 즉시 신고'
          ]
        },

        'progress': {
          'currentDay': 3,
          'progressPercentage': 21.4,
          'todayCompleted': false,
          'bugsReported': 2,
          'feedbackSubmitted': 3,
          'totalPoints': 15000
        }
      };

      // 샘플 Document 3: 완료된 신청
      final completedApplication = {
        'appId': 'eUOdv8wASX7RfSGMin7c',
        'testerId': 'completed_tester_789',
        'providerId': 'provider_demo_123',

        'status': 'completed',
        'statusUpdatedAt': Timestamp.fromDate(DateTime.parse('2025-09-19T10:00:00.000Z')),
        'statusUpdatedBy': 'provider_demo_123',

        'appliedAt': Timestamp.fromDate(DateTime.parse('2025-09-05T05:00:00.000Z')),
        'approvedAt': Timestamp.fromDate(DateTime.parse('2025-09-05T10:00:00.000Z')),
        'startedAt': Timestamp.fromDate(DateTime.parse('2025-09-05T10:00:00.000Z')),
        'completedAt': Timestamp.fromDate(DateTime.parse('2025-09-19T10:00:00.000Z')),

        'testerInfo': {
          'name': '박완료',
          'email': 'completed@example.com',
          'experience': '고급',
          'motivation': '앱 품질 향상에 성공적으로 기여했습니다.',
          'deviceModel': 'Galaxy S24 Ultra',
          'deviceOS': 'Android 14',
          'deviceVersion': 'API 34'
        },

        'missionInfo': {
          'appName': 'BugCash Demo App',
          'totalDays': 14,
          'dailyReward': 5000,
          'totalReward': 70000,
          'requirements': [
            '일일 30분 이상 앱 사용',
            '피드백 작성 필수',
            '버그 발견 시 즉시 신고'
          ]
        },

        'progress': {
          'currentDay': 14,
          'progressPercentage': 100.0,
          'todayCompleted': true,
          'bugsReported': 8,
          'feedbackSubmitted': 14,
          'totalPoints': 70000,
          'latestFeedback': '14일 테스트 완료, 전반적으로 만족스러운 앱입니다.',
          'averageRating': 4.8
        }
      };

      // 컬렉션에 문서 추가
      print('📄 Document 1 (pending) 추가 중...');
      await _firestore.collection('tester_applications').add(pendingApplication);
      print('✅ Document 1 추가 완료');

      print('📄 Document 2 (approved) 추가 중...');
      await _firestore.collection('tester_applications').add(approvedApplication);
      print('✅ Document 2 추가 완료');

      print('📄 Document 3 (completed) 추가 중...');
      await _firestore.collection('tester_applications').add(completedApplication);
      print('✅ Document 3 추가 완료');

      print('🎉 tester_applications 컬렉션 생성 완료!');

    } catch (error) {
      print('❌ tester_applications 컬렉션 생성 중 오류: $error');
      rethrow;
    }
  }

  /// daily_interactions 컬렉션 생성
  static Future<void> createDailyInteractionsCollection() async {
    print('📅 daily_interactions 컬렉션 생성 시작...');

    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

      // 샘플 일일 상호작용 1: 오늘 (대기중)
      final todayInteraction = {
        'applicationId': 'application_001',
        'date': today,
        'dayNumber': 3,

        'tester': {
          'submitted': false,
          'submittedAt': null,
          'feedback': '',
          'screenshots': <String>[],
          'bugReports': <String>[],
          'sessionDuration': 0,
          'appRating': null
        },

        'provider': {
          'reviewed': false,
          'reviewedAt': null,
          'approved': false,
          'pointsAwarded': 0,
          'providerComment': '',
          'needsImprovement': false
        },

        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp()
      };

      // 샘플 일일 상호작용 2: 어제 (완료됨)
      final yesterdayInteraction = {
        'applicationId': 'application_001',
        'date': yesterday,
        'dayNumber': 2,

        'tester': {
          'submitted': true,
          'submittedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1, hours: 23))),
          'feedback': '앱이 전반적으로 잘 작동합니다. 로그인 속도가 빨라졌네요.',
          'screenshots': ['screenshot_001.jpg'],
          'bugReports': <String>[],
          'sessionDuration': 35,
          'appRating': 4
        },

        'provider': {
          'reviewed': true,
          'reviewedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1, hours: 22))),
          'approved': true,
          'pointsAwarded': 5000,
          'providerComment': '좋은 피드백 감사합니다.',
          'needsImprovement': false
        },

        'status': 'approved',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1, hours: 22)))
      };

      // 컬렉션에 문서 추가
      print('📄 오늘 상호작용 추가 중...');
      await _firestore.collection('daily_interactions').doc('application_001_$today').set(todayInteraction);
      print('✅ 오늘 상호작용 추가 완료');

      print('📄 어제 상호작용 추가 중...');
      await _firestore.collection('daily_interactions').doc('application_001_$yesterday').set(yesterdayInteraction);
      print('✅ 어제 상호작용 추가 완료');

      print('🎉 daily_interactions 컬렉션 생성 완료!');

    } catch (error) {
      print('❌ daily_interactions 컬렉션 생성 중 오류: $error');
      rethrow;
    }
  }

  /// apps 컬렉션 생성
  static Future<void> createAppsCollection() async {
    print('📱 apps 컬렉션 생성 시작...');

    try {
      final appData = {
        'appId': 'eUOdv8wASX7RfSGMin7c',
        'appName': 'BugCash Demo App',
        'providerId': 'provider_demo_123',

        'missionConfig': {
          'isActive': true,
          'maxTesters': 10,
          'currentTesters': 3,
          'testingPeriod': 14,
          'dailyReward': 5000,
          'requirements': [
            '일일 30분 이상 앱 사용',
            '피드백 작성 필수',
            '버그 발견 시 즉시 신고'
          ]
        },

        'stats': {
          'totalApplications': 15,
          'pendingApplications': 2,
          'activeTesters': 3,
          'completedTesters': 10,
          'totalBugsFound': 25,
          'averageRating': 4.2
        },

        'createdAt': Timestamp.fromDate(DateTime.parse('2025-09-15T00:00:00.000Z')),
        'updatedAt': FieldValue.serverTimestamp()
      };

      print('📄 앱 정보 추가 중...');
      await _firestore.collection('apps').doc('eUOdv8wASX7RfSGMin7c').set(appData);
      print('✅ 앱 정보 추가 완료');

      print('🎉 apps 컬렉션 생성 완료!');

    } catch (error) {
      print('❌ apps 컬렉션 생성 중 오류: $error');
      rethrow;
    }
  }

  /// 모든 컬렉션 생성
  static Future<void> createAllCollections() async {
    print('🚀 Firebase 컬렉션 생성 시작...');
    print('프로젝트 ID: bugcash');
    print('');

    try {
      await createTesterApplicationsCollection();
      print('');

      await createDailyInteractionsCollection();
      print('');

      await createAppsCollection();
      print('');

      print('🎉 모든 컬렉션 생성 완료!');
      print('');
      print('생성된 컬렉션:');
      print('- tester_applications (3개 문서)');
      print('- daily_interactions (2개 문서)');
      print('- apps (1개 문서)');
      print('');
      print('Firebase Console에서 확인하세요: https://console.firebase.google.com/u/0/project/bugcash/firestore');

    } catch (error) {
      print('❌ 전체 프로세스 중 오류 발생: $error');
      rethrow;
    }
  }
}