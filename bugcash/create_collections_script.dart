import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 독립적인 Firebase 컬렉션 생성 스크립트
/// dart run create_collections_script.dart 로 실행
void main() async {
  print('🔥 Firebase 컬렉션 생성 스크립트 시작');

  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCL7xdDHLHB9CggpjUHQI6mNcKEw_eHGJo',
        appId: '1:335851774651:web:de7faa31e7b6e4b02d5c87',
        messagingSenderId: '335851774651',
        projectId: 'bugcash',
        authDomain: 'bugcash.firebaseapp.com',
        storageBucket: 'bugcash.firebasestorage.app',
        measurementId: 'G-4WEL6GLCNC',
      ),
    );

    print('✅ Firebase 초기화 완료');

    final firestore = FirebaseFirestore.instance;

    // 1. tester_applications 컬렉션 생성
    print('\n📋 tester_applications 컬렉션 생성 중...');
    await createTesterApplicationsCollection(firestore);

    // 2. daily_interactions 컬렉션 생성
    print('\n📅 daily_interactions 컬렉션 생성 중...');
    await createDailyInteractionsCollection(firestore);

    // 3. apps 컬렉션 생성
    print('\n📱 apps 컬렉션 생성 중...');
    await createAppsCollection(firestore);

    print('\n🎉 모든 컬렉션 생성 완료!');
    print('Firebase Console에서 확인: https://console.firebase.google.com/u/0/project/bugcash/firestore');

  } catch (e) {
    print('❌ 오류 발생: $e');
    exit(1);
  }

  exit(0);
}

Future<void> createTesterApplicationsCollection(FirebaseFirestore firestore) async {
  final collection = firestore.collection('tester_applications');

  // Document 1: 대기 중인 신청
  final pendingDoc = {
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
      'deviceVersion': 'API 35',
    },
    'missionInfo': {
      'appName': 'BugCash Demo App',
      'totalDays': 14,
      'dailyReward': 5000,
      'totalReward': 70000,
      'requirements': [
        '일일 30분 이상 앱 사용',
        '피드백 작성 필수',
        '버그 발견 시 즉시 신고',
      ],
    },
    'progress': {
      'currentDay': 0,
      'progressPercentage': 0.0,
      'todayCompleted': false,
      'bugsReported': 0,
      'feedbackSubmitted': 0,
      'totalPoints': 0,
    },
  };

  // Document 2: 승인된 신청
  final approvedDoc = {
    'appId': 'eUOdv8wASX7RfSGMin7c',
    'testerId': 'active_tester_456',
    'providerId': 'provider_demo_123',
    'status': 'approved',
    'statusUpdatedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T09:00:00Z')),
    'statusUpdatedBy': 'provider_demo_123',
    'appliedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T05:00:00Z')),
    'approvedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T09:00:00Z')),
    'startedAt': Timestamp.fromDate(DateTime.parse('2025-09-17T09:00:00Z')),
    'completedAt': null,
    'testerInfo': {
      'name': '이활동',
      'email': 'active@example.com',
      'experience': '고급',
      'motivation': '전문적인 QA 경험을 쌓고 싶습니다.',
      'deviceModel': 'iPhone 15 Pro',
      'deviceOS': 'iOS 17',
      'deviceVersion': '17.5.1',
    },
    'missionInfo': {
      'appName': 'BugCash Demo App',
      'totalDays': 14,
      'dailyReward': 5000,
      'totalReward': 70000,
      'requirements': [
        '일일 30분 이상 앱 사용',
        '피드백 작성 필수',
        '버그 발견 시 즉시 신고',
      ],
    },
    'progress': {
      'currentDay': 3,
      'progressPercentage': 21.4,
      'todayCompleted': false,
      'bugsReported': 2,
      'feedbackSubmitted': 3,
      'totalPoints': 15000,
    },
  };

  // Document 3: 완료된 신청
  final completedDoc = {
    'appId': 'eUOdv8wASX7RfSGMin7c',
    'testerId': 'completed_tester_789',
    'providerId': 'provider_demo_123',
    'status': 'completed',
    'statusUpdatedAt': Timestamp.fromDate(DateTime.parse('2025-09-19T10:00:00Z')),
    'statusUpdatedBy': 'provider_demo_123',
    'appliedAt': Timestamp.fromDate(DateTime.parse('2025-09-05T05:00:00Z')),
    'approvedAt': Timestamp.fromDate(DateTime.parse('2025-09-05T10:00:00Z')),
    'startedAt': Timestamp.fromDate(DateTime.parse('2025-09-05T10:00:00Z')),
    'completedAt': Timestamp.fromDate(DateTime.parse('2025-09-19T10:00:00Z')),
    'testerInfo': {
      'name': '박완료',
      'email': 'completed@example.com',
      'experience': '고급',
      'motivation': '앱 품질 향상에 성공적으로 기여했습니다.',
      'deviceModel': 'Galaxy S24 Ultra',
      'deviceOS': 'Android 14',
      'deviceVersion': 'API 34',
    },
    'missionInfo': {
      'appName': 'BugCash Demo App',
      'totalDays': 14,
      'dailyReward': 5000,
      'totalReward': 70000,
      'requirements': [
        '일일 30분 이상 앱 사용',
        '피드백 작성 필수',
        '버그 발견 시 즉시 신고',
      ],
    },
    'progress': {
      'currentDay': 14,
      'progressPercentage': 100.0,
      'todayCompleted': true,
      'bugsReported': 8,
      'feedbackSubmitted': 14,
      'totalPoints': 70000,
      'latestFeedback': '14일 테스트 완료, 전반적으로 만족스러운 앱입니다.',
      'averageRating': 4.8,
    },
  };

  // 문서들 추가
  print('📄 Document 1 (pending) 추가...');
  await collection.add(pendingDoc);

  print('📄 Document 2 (approved) 추가...');
  await collection.add(approvedDoc);

  print('📄 Document 3 (completed) 추가...');
  await collection.add(completedDoc);

  print('✅ tester_applications 컬렉션 생성 완료');
}

Future<void> createDailyInteractionsCollection(FirebaseFirestore firestore) async {
  final collection = firestore.collection('daily_interactions');
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

  // 오늘 상호작용 (대기중)
  final todayDoc = {
    'applicationId': 'app_001',
    'date': today,
    'dayNumber': 3,
    'tester': {
      'submitted': false,
      'submittedAt': null,
      'feedback': '',
      'screenshots': <String>[],
      'bugReports': <String>[],
      'sessionDuration': 0,
      'appRating': null,
    },
    'provider': {
      'reviewed': false,
      'reviewedAt': null,
      'approved': false,
      'pointsAwarded': 0,
      'providerComment': '',
      'needsImprovement': false,
    },
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // 어제 상호작용 (완료됨)
  final yesterdayDoc = {
    'applicationId': 'app_001',
    'date': yesterday,
    'dayNumber': 2,
    'tester': {
      'submitted': true,
      'submittedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1, hours: 1))),
      'feedback': '앱이 전반적으로 잘 작동합니다. 로그인 속도가 빨라졌네요.',
      'screenshots': ['screenshot_001.jpg'],
      'bugReports': <String>[],
      'sessionDuration': 35,
      'appRating': 4,
    },
    'provider': {
      'reviewed': true,
      'reviewedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 22))),
      'approved': true,
      'pointsAwarded': 5000,
      'providerComment': '좋은 피드백 감사합니다.',
      'needsImprovement': false,
    },
    'status': 'approved',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 22))),
  };

  print('📄 오늘 상호작용 추가...');
  await collection.doc('app_001_$today').set(todayDoc);

  print('📄 어제 상호작용 추가...');
  await collection.doc('app_001_$yesterday').set(yesterdayDoc);

  print('✅ daily_interactions 컬렉션 생성 완료');
}

Future<void> createAppsCollection(FirebaseFirestore firestore) async {
  final collection = firestore.collection('apps');

  final appDoc = {
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
        '버그 발견 시 즉시 신고',
      ],
    },
    'stats': {
      'totalApplications': 15,
      'pendingApplications': 2,
      'activeTesters': 3,
      'completedTesters': 10,
      'totalBugsFound': 25,
      'averageRating': 4.2,
    },
    'createdAt': Timestamp.fromDate(DateTime.parse('2025-09-15T00:00:00Z')),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  print('📄 앱 정보 추가...');
  await collection.doc('eUOdv8wASX7RfSGMin7c').set(appDoc);

  print('✅ apps 컬렉션 생성 완료');
}