import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/test_session_model.dart';
import '../core/utils/logger.dart';

/// 테스트 세션 서비스
class TestSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 새로운 테스트 세션 생성 (pending 상태로 생성, 승인 대기)
  Future<String> createTestSession({
    required String missionId,
    required String testerId,
    required String providerId,
    required String appId,
    required int totalRewardPoints,
  }) async {
    try {
      final testSession = TestSession(
        id: '', // Firestore가 자동 생성
        missionId: missionId,
        testerId: testerId,
        providerId: providerId,
        appId: appId,
        status: TestSessionStatus.pending, // 승인 대기 상태
        createdAt: DateTime.now(),
        dailyProgress: const [], // 승인 후 일정 생성
        totalRewardPoints: totalRewardPoints,
      );

      final docRef = await _firestore
          .collection('test_sessions')
          .add(testSession.toFirestore());

      AppLogger.info('Test session created: ${docRef.id}', 'TestSessionService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create test session', 'TestSessionService', e);
      rethrow;
    }
  }

  /// 테스트 세션 승인 (공급자가 승인)
  Future<void> approveTestSession(String sessionId) async {
    try {
      // 14일간의 일정 생성
      final dailyProgress = _generateDailySchedule();

      await _firestore.collection('test_sessions').doc(sessionId).update({
        'status': TestSessionStatus.approved.name,
        'approvedAt': FieldValue.serverTimestamp(),
        'dailyProgress': dailyProgress.map((progress) => progress.toFirestore()).toList(),
      });

      AppLogger.info('Test session approved: $sessionId', 'TestSessionService');
    } catch (e) {
      AppLogger.error('Failed to approve test session', 'TestSessionService', e);
      rethrow;
    }
  }

  /// 테스트 세션 거부 (공급자가 거부)
  Future<void> rejectTestSession(String sessionId, {String? reason}) async {
    try {
      await _firestore.collection('test_sessions').doc(sessionId).update({
        'status': TestSessionStatus.rejected.name,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason ?? '공급자가 거부했습니다.',
      });

      AppLogger.info('Test session rejected: $sessionId', 'TestSessionService');
    } catch (e) {
      AppLogger.error('Failed to reject test session', 'TestSessionService', e);
      rethrow;
    }
  }

  /// 테스트 세션 시작
  Future<void> startTestSession(String sessionId) async {
    try {
      await _firestore.collection('test_sessions').doc(sessionId).update({
        'status': TestSessionStatus.active.name,
        'startedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Test session started: $sessionId', 'TestSessionService');
    } catch (e) {
      AppLogger.error('Failed to start test session', 'TestSessionService', e);
      rethrow;
    }
  }

  /// 일일 테스트 제출
  Future<void> submitDailyTest({
    required String sessionId,
    required int day,
    required String feedbackFromTester,
    required List<String> screenshots,
    required int testDurationMinutes,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final sessionDoc = await _firestore
          .collection('test_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Test session not found');
      }

      final session = TestSession.fromFirestore(sessionDoc);
      final updatedProgress = session.dailyProgress.map((progress) {
        if (progress.day == day) {
          return progress.copyWith(
            status: DailyTestStatus.submitted,
            submittedAt: DateTime.now(),
            feedbackFromTester: feedbackFromTester,
            screenshots: screenshots,
            testDurationMinutes: testDurationMinutes,
            metadata: additionalData ?? {},
          );
        }
        return progress;
      }).toList();

      await _firestore.collection('test_sessions').doc(sessionId).update({
        'dailyProgress': updatedProgress
            .map((progress) => progress.toFirestore())
            .toList(),
      });

      AppLogger.info(
          'Daily test submitted: $sessionId, Day: $day', 'TestSessionService');

      // 공급자에게 알림 전송
      await _sendDailyTestSubmissionNotification(
        sessionId: sessionId,
        day: day,
        providerId: session.providerId,
        testerId: session.testerId,
      );
    } catch (e) {
      AppLogger.error('Failed to submit daily test', 'TestSessionService', e);
      rethrow;
    }
  }

  /// 공급자가 일일 테스트 승인
  Future<void> approveDailyTest({
    required String sessionId,
    required int day,
    String? feedbackFromProvider,
  }) async {
    try {
      final sessionDoc = await _firestore
          .collection('test_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Test session not found');
      }

      final session = TestSession.fromFirestore(sessionDoc);
      final updatedProgress = session.dailyProgress.map((progress) {
        if (progress.day == day) {
          return progress.copyWith(
            status: DailyTestStatus.approved,
            approvedAt: DateTime.now(),
            feedbackFromProvider: feedbackFromProvider,
          );
        }
        return progress;
      }).toList();

      // 포인트 계산 (일일 포인트 + 보너스)
      final dailyPoints = (session.totalRewardPoints / 14).round();
      final newEarnedPoints = session.earnedPoints + dailyPoints;

      final updateData = {
        'dailyProgress': updatedProgress
            .map((progress) => progress.toFirestore())
            .toList(),
        'earnedPoints': newEarnedPoints,
      };

      // 14일차 완료 시 세션 완료 처리
      final completedDays = updatedProgress
          .where((p) => p.status == DailyTestStatus.approved)
          .length;

      if (completedDays >= 14) {
        updateData['status'] = TestSessionStatus.completed.name;
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('test_sessions')
          .doc(sessionId)
          .update(updateData);

      AppLogger.info(
          'Daily test approved: $sessionId, Day: $day', 'TestSessionService');

      // 테스터에게 승인 알림 전송
      await _sendDailyTestApprovalNotification(
        sessionId: sessionId,
        day: day,
        testerId: session.testerId,
        earnedPoints: dailyPoints,
        isCompleted: completedDays >= 14,
      );
    } catch (e) {
      AppLogger.error('Failed to approve daily test', 'TestSessionService', e);
      rethrow;
    }
  }

  /// 공급자가 일일 테스트 거부
  Future<void> rejectDailyTest({
    required String sessionId,
    required int day,
    required String reason,
  }) async {
    try {
      final sessionDoc = await _firestore
          .collection('test_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Test session not found');
      }

      final session = TestSession.fromFirestore(sessionDoc);
      final updatedProgress = session.dailyProgress.map((progress) {
        if (progress.day == day) {
          return progress.copyWith(
            status: DailyTestStatus.rejected,
            feedbackFromProvider: reason,
          );
        }
        return progress;
      }).toList();

      await _firestore.collection('test_sessions').doc(sessionId).update({
        'dailyProgress': updatedProgress
            .map((progress) => progress.toFirestore())
            .toList(),
      });

      AppLogger.info(
          'Daily test rejected: $sessionId, Day: $day', 'TestSessionService');

      // 테스터에게 재제출 요청 알림
      await _sendDailyTestRejectionNotification(
        sessionId: sessionId,
        day: day,
        testerId: session.testerId,
        reason: reason,
      );
    } catch (e) {
      AppLogger.error('Failed to reject daily test', 'TestSessionService', e);
      rethrow;
    }
  }

  /// 테스터의 테스트 세션들 조회
  Stream<List<TestSession>> getTestSessionsForTester(String testerId) {
    return _firestore
        .collection('test_sessions')
        .where('testerId', isEqualTo: testerId)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => TestSession.fromFirestore(doc))
              .toList();
          // 클라이언트 측에서 정렬
          sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sessions;
        });
  }

  /// 공급자의 테스트 세션들 조회
  Stream<List<TestSession>> getTestSessionsForProvider(String providerId) {
    AppLogger.info('🔍 Querying test sessions for providerId: $providerId', 'TestSessionService');

    return _firestore
        .collection('test_sessions')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
          AppLogger.info('📊 Firestore query result - Found ${snapshot.docs.length} documents', 'TestSessionService');

          if (snapshot.docs.isNotEmpty) {
            AppLogger.info('📄 First document data: ${snapshot.docs.first.data()}', 'TestSessionService');
          }

          final sessions = snapshot.docs
              .map((doc) {
                try {
                  final session = TestSession.fromFirestore(doc);
                  AppLogger.info('✅ Successfully parsed session: ${session.id} (status: ${session.status.name})', 'TestSessionService');
                  return session;
                } catch (e) {
                  AppLogger.error('❌ Failed to parse session from doc ${doc.id}', 'TestSessionService', e);
                  return null;
                }
              })
              .where((session) => session != null)
              .cast<TestSession>()
              .toList();

          // 클라이언트 측에서 정렬
          sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          AppLogger.info('🎯 Final result: ${sessions.length} valid sessions for providerId: $providerId', 'TestSessionService');
          return sessions;
        });
  }

  /// 공급자의 승인 대기 중인 테스트 세션들 조회
  Stream<List<TestSession>> getPendingTestSessionsForProvider(String providerId) {
    return _firestore
        .collection('test_sessions')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: TestSessionStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => TestSession.fromFirestore(doc))
              .toList();
          // 클라이언트 측에서 정렬
          sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sessions;
        });
  }

  /// 공급자의 활성 테스트 세션들 조회 (일일 승인이 필요한 세션들)
  Stream<List<TestSession>> getActiveTestSessionsForProvider(String providerId) {
    return _firestore
        .collection('test_sessions')
        .where('providerId', isEqualTo: providerId)
        .where('status', whereIn: [TestSessionStatus.approved.name, TestSessionStatus.active.name])
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => TestSession.fromFirestore(doc))
              .toList();
          // 클라이언트 측에서 정렬
          sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sessions;
        });
  }

  /// 특정 테스트 세션 조회
  Stream<TestSession?> getTestSession(String sessionId) {
    return _firestore
        .collection('test_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? TestSession.fromFirestore(doc) : null);
  }

  /// 14일 일정 생성
  List<DailyTestProgress> _generateDailySchedule() {
    final startDate = DateTime.now();
    return List.generate(14, (index) {
      return DailyTestProgress(
        day: index + 1,
        scheduledDate: startDate.add(Duration(days: index)),
        status: DailyTestStatus.pending,
      );
    });
  }

  /// 일일 테스트 제출 알림
  Future<void> _sendDailyTestSubmissionNotification({
    required String sessionId,
    required int day,
    required String providerId,
    required String testerId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': providerId,
        'type': 'daily_test_submitted',
        'title': '일일 테스트 제출됨',
        'message': '테스터가 $day일차 테스트를 제출했습니다.',
        'data': {
          'sessionId': sessionId,
          'day': day,
          'testerId': testerId,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      AppLogger.error('Failed to send submission notification', 'TestSessionService', e);
    }
  }

  /// 일일 테스트 승인 알림
  Future<void> _sendDailyTestApprovalNotification({
    required String sessionId,
    required int day,
    required String testerId,
    required int earnedPoints,
    required bool isCompleted,
  }) async {
    try {
      final title = isCompleted ? '테스트 완료!' : '일일 테스트 승인됨';
      final message = isCompleted
          ? '14일 테스트를 성공적으로 완료했습니다!'
          : '$day일차 테스트가 승인되었습니다. +${earnedPoints}P';

      await _firestore.collection('notifications').add({
        'recipientId': testerId,
        'type': isCompleted ? 'test_completed' : 'daily_test_approved',
        'title': title,
        'message': message,
        'data': {
          'sessionId': sessionId,
          'day': day,
          'earnedPoints': earnedPoints,
          'isCompleted': isCompleted,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      AppLogger.error('Failed to send approval notification', 'TestSessionService', e);
    }
  }

  /// 일일 테스트 거부 알림
  Future<void> _sendDailyTestRejectionNotification({
    required String sessionId,
    required int day,
    required String testerId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': testerId,
        'type': 'daily_test_rejected',
        'title': '재제출 요청',
        'message': '$day일차 테스트 재제출이 필요합니다.',
        'data': {
          'sessionId': sessionId,
          'day': day,
          'reason': reason,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      AppLogger.error('Failed to send rejection notification', 'TestSessionService', e);
    }
  }
}

/// Riverpod 프로바이더
final testSessionServiceProvider = Provider<TestSessionService>((ref) {
  return TestSessionService();
});

/// 테스터의 테스트 세션 목록 프로바이더
final testerTestSessionsProvider = StreamProvider.family<List<TestSession>, String>(
  (ref, testerId) {
    final service = ref.watch(testSessionServiceProvider);
    return service.getTestSessionsForTester(testerId);
  },
);

/// 공급자의 테스트 세션 목록 프로바이더
final providerTestSessionsProvider = StreamProvider.family<List<TestSession>, String>(
  (ref, providerId) {
    final service = ref.watch(testSessionServiceProvider);
    return service.getTestSessionsForProvider(providerId);
  },
);

/// 공급자의 승인 대기 테스트 세션 목록 프로바이더
final providerPendingTestSessionsProvider = StreamProvider.family<List<TestSession>, String>(
  (ref, providerId) {
    final service = ref.watch(testSessionServiceProvider);
    return service.getPendingTestSessionsForProvider(providerId);
  },
);

/// 공급자의 활성 테스트 세션 목록 프로바이더 (일일 승인이 필요한 세션들)
final providerActiveTestSessionsProvider = StreamProvider.family<List<TestSession>, String>(
  (ref, providerId) {
    final service = ref.watch(testSessionServiceProvider);
    return service.getActiveTestSessionsForProvider(providerId);
  },
);

/// 특정 테스트 세션 프로바이더
final testSessionProvider = StreamProvider.family<TestSession?, String>(
  (ref, sessionId) {
    final service = ref.watch(testSessionServiceProvider);
    return service.getTestSession(sessionId);
  },
);