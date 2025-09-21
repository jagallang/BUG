import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../shared/models/mission_workflow_model.dart';
import '../../../shared/providers/unified_mission_provider.dart';

// 테스터 신청 모델
class TesterApplicationModel {
  final String id;
  final String appId;
  final String testerId;
  final String testerName;
  final String testerEmail;
  final String status; // pending, approved, rejected
  final String experience;
  final String motivation;
  final DateTime appliedAt;
  final DateTime? processedAt;
  final Map<String, dynamic> metadata;

  TesterApplicationModel({
    required this.id,
    required this.appId,
    required this.testerId,
    required this.testerName,
    required this.testerEmail,
    required this.status,
    required this.experience,
    required this.motivation,
    required this.appliedAt,
    this.processedAt,
    required this.metadata,
  });

  factory TesterApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TesterApplicationModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      testerId: data['testerId'] ?? '',
      testerName: data['testerName'] ?? '',
      testerEmail: data['testerEmail'] ?? '',
      status: data['status'] ?? 'pending',
      experience: data['experience'] ?? '',
      motivation: data['motivation'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'testerId': testerId,
      'testerName': testerName,
      'testerEmail': testerEmail,
      'status': status,
      'experience': experience,
      'motivation': motivation,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'metadata': metadata,
    };
  }
}

// 테스트 미션 모델
class TestMissionModel {
  final String id;
  final String appId;
  final String title;
  final String description;
  final String status; // active, paused, completed
  final DateTime createdAt;
  final DateTime dueDate;
  final int assignedCount;
  final int completedCount;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> metadata;

  TestMissionModel({
    required this.id,
    required this.appId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.dueDate,
    required this.assignedCount,
    required this.completedCount,
    required this.requirements,
    required this.metadata,
  });

  factory TestMissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestMissionModel(
      id: doc.id,
      appId: data['appId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedCount: data['assignedCount'] ?? 0,
      completedCount: data['completedCount'] ?? 0,
      requirements: data['requirements'] ?? {},
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appId': appId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedCount': assignedCount,
      'completedCount': completedCount,
      'requirements': requirements,
      'metadata': metadata,
    };
  }
}

// 앱 통계 모델
class AppStatisticsModel {
  final String appId;
  final int totalTesters;
  final int activeTesters;
  final int totalMissions;
  final int completedMissions;
  final int bugsFound;
  final int bugsResolved;
  final List<Map<String, dynamic>> recentActivities;

  AppStatisticsModel({
    required this.appId,
    required this.totalTesters,
    required this.activeTesters,
    required this.totalMissions,
    required this.completedMissions,
    required this.bugsFound,
    required this.bugsResolved,
    required this.recentActivities,
  });

  factory AppStatisticsModel.fromData(String appId, Map<String, dynamic> data) {
    return AppStatisticsModel(
      appId: appId,
      totalTesters: data['totalTesters'] ?? 0,
      activeTesters: data['activeTesters'] ?? 0,
      totalMissions: data['totalMissions'] ?? 0,
      completedMissions: data['completedMissions'] ?? 0,
      bugsFound: data['bugsFound'] ?? 0,
      bugsResolved: data['bugsResolved'] ?? 0,
      recentActivities: List<Map<String, dynamic>>.from(data['recentActivities'] ?? []),
    );
  }
}

// 🔥 새로운 워크플로우 기반 Provider - 앱별 테스터 목록 Provider
final appTestersProvider = StreamProvider.family<List<TesterApplicationModel>, String>((ref, appId) {
  AppLogger.info('🔄 WORKFLOW_PROVIDER: Loading testers for app: $appId (새 워크플로우 시스템 사용)', 'TesterManagement');

  final workflowService = MissionWorkflowService();

  return workflowService.getAppWorkflows(appId).map((workflows) {
    debugPrint('🔄 WORKFLOW_PROVIDER: ${workflows.length}개 워크플로우를 TesterApplicationModel로 변환');

    return workflows.map((workflow) {
      // MissionWorkflowModel을 TesterApplicationModel로 변환 (호환성 유지)
      return TesterApplicationModel(
        id: workflow.id,
        appId: workflow.appId,
        testerId: workflow.testerId,
        testerName: workflow.testerName,
        testerEmail: workflow.testerEmail,
        status: _mapWorkflowStateToStatus(workflow.currentState),
        experience: workflow.experience,
        motivation: workflow.motivation,
        appliedAt: workflow.appliedAt,
        processedAt: workflow.approvedAt,
        metadata: workflow.metadata,
      );
    }).toList();
  });
});

// 워크플로우 상태를 기존 상태로 매핑하는 헬퍼 함수
String _mapWorkflowStateToStatus(MissionWorkflowState state) {
  switch (state) {
    case MissionWorkflowState.applicationSubmitted:
      return 'pending';
    case MissionWorkflowState.applicationApproved:
    case MissionWorkflowState.missionInProgress:
    case MissionWorkflowState.dailyMissionStarted:
    case MissionWorkflowState.dailyMissionCompleted:
    case MissionWorkflowState.dailyMissionApproved:
    case MissionWorkflowState.projectCompleted:
    case MissionWorkflowState.projectApproved:
    case MissionWorkflowState.projectFinalized:
      return 'approved';
    case MissionWorkflowState.applicationRejected:
      return 'rejected';
    case MissionWorkflowState.paused:
      return 'paused';
    case MissionWorkflowState.cancelled:
      return 'cancelled';
  }
}

// 앱별 미션 목록 Provider
final appMissionsProvider = StreamProvider.family<List<TestMissionModel>, String>((ref, appId) {
  AppLogger.info('Loading missions for app: $appId', 'TesterManagement');

  return FirebaseFirestore.instance
      .collection('test_missions')
      .where('appId', isEqualTo: appId)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs
            .map((doc) => TestMissionModel.fromFirestore(doc))
            .toList();

        // 클라이언트 측에서 정렬
        docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return docs;
      });
});

// 앱별 통계 Provider
final appStatisticsProvider = StreamProvider.family<AppStatisticsModel, String>((ref, appId) async* {
  AppLogger.info('Loading statistics for app: $appId', 'TesterManagement');

  try {
    // 병렬로 데이터 수집
    final futures = await Future.wait([
      _getTesterStats(appId),
      _getMissionStats(appId),
      _getBugStats(appId),
      _getRecentActivities(appId),
    ]);

    final testerStats = futures[0] as Map<String, int>;
    final missionStats = futures[1] as Map<String, int>;
    final bugStats = futures[2] as Map<String, int>;
    final recentActivities = futures[3] as List<Map<String, dynamic>>;

    yield AppStatisticsModel(
      appId: appId,
      totalTesters: testerStats['total'] ?? 0,
      activeTesters: testerStats['active'] ?? 0,
      totalMissions: missionStats['total'] ?? 0,
      completedMissions: missionStats['completed'] ?? 0,
      bugsFound: bugStats['found'] ?? 0,
      bugsResolved: bugStats['resolved'] ?? 0,
      recentActivities: recentActivities,
    );
  } catch (e) {
    AppLogger.error('Failed to load app statistics', e.toString());
    yield AppStatisticsModel(
      appId: appId,
      totalTesters: 0,
      activeTesters: 0,
      totalMissions: 0,
      completedMissions: 0,
      bugsFound: 0,
      bugsResolved: 0,
      recentActivities: [],
    );
  }
});

// 테스터 관리 Provider
final testerManagementProvider = StateNotifierProvider<TesterManagementNotifier, TesterManagementState>((ref) {
  return TesterManagementNotifier(ref);
});

class TesterManagementState {
  final bool isLoading;
  final String? errorMessage;

  const TesterManagementState({
    this.isLoading = false,
    this.errorMessage,
  });

  TesterManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return TesterManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TesterManagementNotifier extends StateNotifier<TesterManagementState> {
  final Ref _ref;

  TesterManagementNotifier(this._ref) : super(const TesterManagementState());

  final _firestore = FirebaseFirestore.instance;

  // 🔥 새로운 워크플로우 기반 - 테스터 신청 승인/거부 처리
  Future<void> updateTesterApplication(String applicationId, String newStatus) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      debugPrint('🔄 WORKFLOW_PROVIDER: 새 워크플로우로 상태 업데이트 - $applicationId -> $newStatus');

      final workflowService = MissionWorkflowService();

      // 현재 로그인한 공급자 ID 가져오기
      final currentUser = FirebaseAuth.instance.currentUser;
      final providerId = currentUser?.uid ?? 'unknown_provider';

      // 새로운 워크플로우 시스템 사용 - 상태에 따라 분기
      if (newStatus == 'approved') {
        await workflowService.processMissionApplication(
          workflowId: applicationId,
          approved: true,
          processedBy: providerId,
          feedback: '신청이 승인되었습니다.',
        );
        AppLogger.info('🔄 WORKFLOW_PROVIDER: Tester application approved: $applicationId by $providerId (워크플로우 서비스 사용)', 'TesterManagement');
      } else if (newStatus == 'rejected') {
        await workflowService.processMissionApplication(
          workflowId: applicationId,
          approved: false,
          processedBy: providerId,
          feedback: '신청이 거부되었습니다.',
        );
        AppLogger.info('🔄 WORKFLOW_PROVIDER: Tester application rejected: $applicationId by $providerId (워크플로우 서비스 사용)', 'TesterManagement');
      } else {
        // 기존 로직 유지 (기타 상태 변경은 레거시 시스템 사용)
        await _ref.read(unifiedMissionNotifierProvider.notifier).updateTesterStatus(
          missionId: applicationId,
          newStatus: newStatus,
        );
        AppLogger.info('🔄 WORKFLOW_PROVIDER: Tester application status updated: $applicationId -> $newStatus (레거시 시스템 사용)', 'TesterManagement');
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to update tester application', e.toString());
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // 새 미션 생성
  Future<void> createMission({
    required String appId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final mission = {
        'appId': appId,
        'title': title,
        'description': description,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': Timestamp.fromDate(dueDate),
        'assignedCount': 0,
        'completedCount': 0,
        'requirements': {},
        'metadata': {},
      };

      final docRef = await _firestore.collection('test_missions').add(mission);

      // 승인된 테스터들에게 미션 할당
      await _assignMissionToApprovedTesters(appId, docRef.id);

      AppLogger.info('Mission created: $title for app: $appId', 'TesterManagement');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to create mission', e.toString());
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // 미션 상태 업데이트
  Future<void> updateMissionStatus(String missionId, String status) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _firestore.collection('test_missions').doc(missionId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Mission status updated: $missionId -> $status', 'TesterManagement');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to update mission status', e.toString());
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // 앱의 테스터 수 업데이트
  Future<void> _updateAppTesterCount(String applicationId, int increment) async {
    try {
      final applicationDoc = await _firestore
          .collection('tester_applications')
          .doc(applicationId)
          .get();

      if (applicationDoc.exists) {
        final appId = applicationDoc.data()!['appId'];

        await _firestore.collection('provider_apps').doc(appId).update({
          'activeTesters': FieldValue.increment(increment),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update app tester count: $e');
      }
    }
  }

  // 승인된 테스터들에게 미션 할당
  Future<void> _assignMissionToApprovedTesters(String appId, String missionId) async {
    try {
      final approvedTesters = await _firestore
          .collection('tester_applications')
          .where('appId', isEqualTo: appId)
          .where('status', isEqualTo: 'approved')
          .get();

      final batch = _firestore.batch();
      int assignedCount = 0;

      for (final testerDoc in approvedTesters.docs) {
        final assignment = {
          'missionId': missionId,
          'testerId': testerDoc.data()['testerId'],
          'appId': appId,
          'status': 'assigned', // assigned, in_progress, completed, failed
          'assignedAt': FieldValue.serverTimestamp(),
          'metadata': {},
        };

        final assignmentRef = _firestore.collection('mission_assignments').doc();
        batch.set(assignmentRef, assignment);
        assignedCount++;
      }

      // 미션의 할당된 테스터 수 업데이트
      batch.update(_firestore.collection('test_missions').doc(missionId), {
        'assignedCount': assignedCount,
      });

      await batch.commit();
      AppLogger.info('Mission assigned to $assignedCount testers', 'TesterManagement');
    } catch (e) {
      AppLogger.error('Failed to assign mission to testers', e.toString());
    }
  }
}

// Helper functions for statistics
Future<Map<String, int>> _getTesterStats(String appId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('tester_applications')
        .where('appId', isEqualTo: appId)
        .get();

    int total = snapshot.docs.length;
    int active = snapshot.docs.where((doc) => doc.data()['status'] == 'approved').length;

    return {'total': total, 'active': active};
  } catch (e) {
    return {'total': 0, 'active': 0};
  }
}

Future<Map<String, int>> _getMissionStats(String appId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('test_missions')
        .where('appId', isEqualTo: appId)
        .get();

    int total = snapshot.docs.length;
    int completed = snapshot.docs.where((doc) => doc.data()['status'] == 'completed').length;

    return {'total': total, 'completed': completed};
  } catch (e) {
    return {'total': 0, 'completed': 0};
  }
}

Future<Map<String, int>> _getBugStats(String appId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('bug_reports')
        .where('appId', isEqualTo: appId)
        .get();

    int found = snapshot.docs.length;
    int resolved = snapshot.docs.where((doc) => doc.data()['status'] == 'resolved').length;

    return {'found': found, 'resolved': resolved};
  } catch (e) {
    return {'found': 0, 'resolved': 0};
  }
}

Future<List<Map<String, dynamic>>> _getRecentActivities(String appId) async {
  try {
    final futures = await Future.wait([
      // 최근 테스터 신청
      FirebaseFirestore.instance
          .collection('tester_applications')
          .where('appId', isEqualTo: appId)
          .orderBy('appliedAt', descending: true)
          .limit(3)
          .get(),
      // 최근 미션 완료
      FirebaseFirestore.instance
          .collection('mission_assignments')
          .where('appId', isEqualTo: appId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(3)
          .get(),
    ]);

    final activities = <Map<String, dynamic>>[];

    // 테스터 신청 활동
    for (final doc in futures[0].docs) {
      final data = doc.data();
      activities.add({
        'type': 'tester_application',
        'description': '${data['testerName']}님이 테스터 신청했습니다',
        'timestamp': data['appliedAt'],
      });
    }

    // 미션 완료 활동
    for (final doc in futures[1].docs) {
      final data = doc.data();
      activities.add({
        'type': 'mission_completed',
        'description': '미션이 완료되었습니다',
        'timestamp': data['completedAt'],
      });
    }

    // 시간순으로 정렬
    activities.sort((a, b) {
      final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      return bTime.compareTo(aTime);
    });

    return activities.take(5).toList();
  } catch (e) {
    return [];
  }
}