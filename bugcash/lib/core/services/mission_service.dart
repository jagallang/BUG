import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../../models/mission_model.dart';
import '../utils/logger.dart';
import '../constants/firestore_constants.dart';

class MissionService {
  // Create a new mission
  static Future<String> createMission({
    required String providerId,
    required String appId,
    required String title,
    required String description,
    required MissionType type,
    required MissionPriority priority,
    required MissionComplexity complexity,
    required MissionDifficulty difficulty,
    required DateTime startDate,
    required DateTime endDate,
    required int testingDuration,
    required int reportingDuration,
    required int maxTesters,
    required double baseReward,
    double? bonusReward,
    required List<String> platforms,
    required List<String> devices,
    required List<String> osVersions,
    required List<String> languages,
    required String experience,
    double? minRating,
    List<String>? specialSkills,
    String? instructions,
    List<String>? focusAreas,
    List<String>? excludedAreas,
  }) async {
    final missionData = {
      'providerId': providerId,
      'appId': appId,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'complexity': complexity.name,
      'difficulty': difficulty.name,
      'status': FirestoreConstants.statusDraft,
      'requirements': {
        'platforms': platforms,
        'devices': devices,
        'osVersions': osVersions,
        'languages': languages,
        'experience': experience,
        'minRating': minRating ?? FirestoreConstants.defaultMinRating,
        'specialSkills': specialSkills ?? <String>[],
      },
      'participation': {
        'maxTesters': maxTesters,
        'currentTesters': 0,
        'autoAssign': false,
        'inviteOnly': false,
      },
      'timeline': {
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'testingDuration': testingDuration,
        'reportingDuration': reportingDuration,
      },
      'rewards': {
        'baseReward': baseReward,
        'bonusReward': bonusReward ?? 0.0,
        'currency': FirestoreConstants.defaultCurrency,
        'paymentMethod': FirestoreConstants.defaultPaymentMethod,
        'bonusConditions': <String>[],
      },
      'attachments': <Map<String, dynamic>>[],
      'testingGuidelines': {
        'instructions': instructions ?? '',
        'testCases': <Map<String, dynamic>>[],
        'focusAreas': focusAreas ?? <String>[],
        'excludedAreas': excludedAreas ?? <String>[],
      },
      'analytics': {
        'views': 0,
        'applications': 0,
        'acceptanceRate': 0.0,
        'avgCompletionTime': 0,
        'satisfactionScore': 0.0,
      },
    };

    return await FirestoreService.create(FirestoreService.missions, missionData);
  }

  // Get mission by ID
  static Future<Mission?> getMission(String missionId) async {
    final data = await FirestoreService.read(FirestoreService.missions, missionId);
    if (data != null) {
      return Mission.fromFirestore(data);
    }
    return null;
  }

  // Update mission
  static Future<void> updateMission(String missionId, Map<String, dynamic> updates) async {
    await FirestoreService.update(FirestoreService.missions, missionId, updates);
  }

  // Delete mission
  static Future<void> deleteMission(String missionId) async {
    await FirestoreService.delete(FirestoreService.missions, missionId);
  }

  // Stream missions for provider
  static Stream<List<Mission>> streamProviderMissions(String providerId) {
    return FirestoreService.streamMissions(providerId: providerId).map(
      (dataList) => dataList.map((data) => Mission.fromFirestore(data)).toList(),
    );
  }

  // Stream active missions for testers
  static Stream<List<Mission>> streamActiveMissions({
    List<String>? types,
    String? difficulty,
    int? limit,
  }) {
    return FirestoreService.streamMissions(
      status: FirestoreConstants.statusActive,
      types: types,
      difficulty: difficulty,
      limit: limit,
    ).map(
      (dataList) => dataList.map((data) => Mission.fromFirestore(data)).toList(),
    );
  }

  // Publish mission (change status from draft to active)
  static Future<void> publishMission(String missionId) async {
    await updateMission(missionId, {
      'status': FirestoreConstants.statusActive,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  // Complete mission
  static Future<void> completeMission(String missionId) async {
    await updateMission(missionId, {
      'status': FirestoreConstants.statusCompleted,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Pause/Resume mission
  static Future<void> pauseMission(String missionId) async {
    await updateMission(missionId, {
      'status': FirestoreConstants.statusPaused,
    });
  }

  static Future<void> resumeMission(String missionId) async {
    await updateMission(missionId, {
      'status': FirestoreConstants.statusActive,
    });
  }

  // Cancel mission
  static Future<void> cancelMission(String missionId) async {
    await updateMission(missionId, {
      'status': FirestoreConstants.statusCancelled,
    });
  }

  // Add attachment to mission
  static Future<void> addAttachment(
    String missionId,
    String name,
    String url,
    String type,
    int size,
  ) async {
    final mission = await getMission(missionId);
    if (mission != null) {
      final attachments = List<Map<String, dynamic>>.from(
        mission.attachments ?? <Map<String, dynamic>>[],
      );
      
      attachments.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'url': url,
        'type': type,
        'size': size,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      await updateMission(missionId, {'attachments': attachments});
    }
  }

  // Update mission analytics
  static Future<void> incrementViews(String missionId) async {
    final mission = await getMission(missionId);
    if (mission != null) {
      final currentViews = mission.analytics?['views'] ?? 0;
      await updateMission(missionId, {
        'analytics.views': currentViews + 1,
      });
    }
  }

  static Future<void> incrementApplications(String missionId) async {
    final mission = await getMission(missionId);
    if (mission != null) {
      final currentApplications = mission.analytics?['applications'] ?? 0;
      await updateMission(missionId, {
        'analytics.applications': currentApplications + 1,
      });
    }
  }

  // Search missions
  static Future<List<Mission>> searchMissions({
    String? query,
    List<String>? types,
    List<String>? difficulties,
    double? minReward,
    double? maxReward,
    List<String>? platforms,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> firestoreQuery = FirestoreService.missions;

    // Apply filters
    if (types != null && types.isNotEmpty) {
      firestoreQuery = firestoreQuery.where('type', whereIn: types);
    }

    if (difficulties != null && difficulties.isNotEmpty) {
      firestoreQuery = firestoreQuery.where('difficulty', whereIn: difficulties);
    }

    if (minReward != null) {
      firestoreQuery = firestoreQuery.where('rewards.baseReward', isGreaterThanOrEqualTo: minReward);
    }

    if (maxReward != null) {
      firestoreQuery = firestoreQuery.where('rewards.baseReward', isLessThanOrEqualTo: maxReward);
    }

    // Only active missions
    firestoreQuery = firestoreQuery.where('status', isEqualTo: FirestoreConstants.statusActive);

    // Order by creation date
    firestoreQuery = firestoreQuery.orderBy('createdAt', descending: true);

    if (limit != null) {
      firestoreQuery = firestoreQuery.limit(limit);
    }

    final snapshot = await firestoreQuery.get();
    List<Mission> missions = snapshot.docs.map((doc) {
      final data = {'id': doc.id, ...doc.data()};
      return Mission.fromFirestore(data);
    }).toList();

    // Apply text search if query is provided
    if (query != null && query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      missions = missions.where((mission) {
        return mission.title.toLowerCase().contains(queryLower) ||
               mission.description.toLowerCase().contains(queryLower);
      }).toList();
    }

    // Apply platform filter if provided
    if (platforms != null && platforms.isNotEmpty) {
      missions = missions.where((mission) {
        final missionPlatforms = mission.requirements?['platforms'] as List<String>? ?? [];
        return platforms.any((platform) => missionPlatforms.contains(platform));
      }).toList();
    }

    return missions;
  }

  // Get missions statistics
  static Future<Map<String, int>> getMissionStats({
    String? providerId,
  }) async {
    Query<Map<String, dynamic>> query = FirestoreService.missions;

    if (providerId != null) {
      query = query.where('providerId', isEqualTo: providerId);
    }

    final snapshot = await query.get();
    final missions = snapshot.docs;

    final stats = <String, int>{
      'total': missions.length,
      'draft': 0,
      'active': 0,
      'paused': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (final doc in missions) {
      final status = doc.data()['status'] as String? ?? 'draft';
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  // Apply to mission (테스터가 미션에 신청)
  Future<String> applyToMission(String missionId, Map<String, dynamic> applicationData) async {
    try {
      // 1. 중복 신청 체크
      final testerId = applicationData['testerId'];
      final hasApplied = await hasUserApplied(missionId, testerId);
      if (hasApplied) {
        throw Exception('이미 신청한 미션입니다.');
      }

      // 2. 미션 신청 정보를 mission_applications 컬렉션에 저장
      final applicationId = await FirestoreService.create(
        FirestoreService.missionApplications,
        applicationData
      );

      // 3. 새로운 tester_applications 컬렉션에도 저장 (확장 구조)
      final unifiedApplicationData = {
        ...applicationData,
        'id': applicationId,
        'appId': missionId, // appId로 missionId 사용
        'appName': applicationData['missionName'] ?? FirestoreConstants.unknownApp,
        'missionInfo': {
          'missionId': missionId,
          'appName': applicationData['missionName'] ?? FirestoreConstants.unknownApp,
          'dailyReward': applicationData['dailyReward'] ?? FirestoreConstants.defaultDailyReward,
          'totalDays': applicationData['totalDays'] ?? FirestoreConstants.defaultTotalDays,
          'requirements': applicationData['requirements'] ?? [],
        },
        'progress': {
          'currentDay': 0,
          'totalPoints': 0,
          'progressPercentage': 0.0,
          'todayCompleted': false,
          'latestFeedback': null,
          'averageRating': null,
        },
        'statusUpdatedAt': applicationData['appliedAt'],
      };

      await FirestoreService.create(
        FirestoreService.testerApplications,
        unifiedApplicationData
      );

      // 4. 미션의 analytics.applications 증가
      await incrementApplications(missionId);

      // 5. 공급자에게 실시간 알림 전송
      await _sendApplicationNotification(applicationData);

      return applicationId;
    } catch (e) {
      AppLogger.error('Error applying to mission', e.toString());
      rethrow;
    }
  }

  // 공급자에게 신청 알림 전송
  Future<void> _sendApplicationNotification(Map<String, dynamic> applicationData) async {
    try {
      final notificationData = {
        'recipientId': applicationData['providerId'],
        'senderId': applicationData['testerId'],
        'type': FirestoreConstants.notificationTypeMissionApplication,
        'title': '새 미션 신청',
        'message': '${applicationData['testerName']}님이 미션에 신청했습니다.',
        'missionId': applicationData['missionId'],
        'applicationId': applicationData['id'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'testerName': applicationData['testerName'],
          'testerEmail': applicationData['testerEmail'],
          'appName': applicationData['missionName'] ?? FirestoreConstants.unknownApp,
        },
      };

      await FirestoreService.create(
        FirestoreService.notifications,
        notificationData
      );

      AppLogger.info('Application notification sent to provider: ${applicationData['providerId']}', 'MissionService');
    } catch (e) {
      AppLogger.warning('Failed to send application notification: $e', 'MissionService');
      // 알림 전송 실패는 전체 프로세스를 중단시키지 않음
    }
  }

  // Get applications for a mission (공급자가 미션 신청자들 조회)
  static Future<List<MissionApplication>> getMissionApplications(String missionId) async {
    try {
      final query = FirestoreService.missionApplications
          .where('missionId', isEqualTo: missionId)
          .orderBy('appliedAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = {'id': doc.id, ...doc.data()};
        return MissionApplication.fromFirestore(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting mission applications', e.toString());
      return [];
    }
  }

  // Get applications by tester (테스터가 자신의 신청 내역 조회)
  static Future<List<MissionApplication>> getTesterApplications(String testerId) async {
    try {
      final query = FirestoreService.missionApplications
          .where('testerId', isEqualTo: testerId)
          .orderBy('appliedAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = {'id': doc.id, ...doc.data()};
        return MissionApplication.fromFirestore(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting tester applications', e.toString());
      return [];
    }
  }

  // Update application status (공급자가 신청 승인/거부)
  static Future<void> updateApplicationStatus(
    String applicationId,
    MissionApplicationStatus status, {
    String? responseMessage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (responseMessage != null) {
        updateData['responseMessage'] = responseMessage;
      }

      if (status == MissionApplicationStatus.accepted) {
        updateData['acceptedAt'] = FieldValue.serverTimestamp();
      } else if (status == MissionApplicationStatus.rejected) {
        updateData['rejectedAt'] = FieldValue.serverTimestamp();
      }

      await FirestoreService.update(
        FirestoreService.missionApplications,
        applicationId,
        updateData,
      );

      // 테스터에게 알림 전송 (추후 구현)
      // await _sendStatusUpdateNotification(applicationId, status);
    } catch (e) {
      AppLogger.error('Error updating application status', e.toString());
      rethrow;
    }
  }

  // Check if user already applied to mission
  static Future<bool> hasUserApplied(String missionId, String testerId) async {
    try {
      final query = FirestoreService.missionApplications
          .where('missionId', isEqualTo: missionId)
          .where('testerId', isEqualTo: testerId)
          .limit(1);

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking if user applied', e.toString());
      return false;
    }
  }

  // 상태 관리 시스템: 신청중 → 승인됨 → 일일미션중 → 미션완료 → 미션승인됨 → 프로젝트종료

  // 공급자가 테스터 신청을 승인
  static Future<void> approveApplication(String applicationId, {String? responseMessage}) async {
    try {
      // 1. mission_applications 업데이트
      await updateApplicationStatus(
        applicationId,
        MissionApplicationStatus.accepted,
        responseMessage: responseMessage ?? '신청이 승인되었습니다.',
      );

      // 2. tester_applications에서 해당 신청 찾아서 상태 업데이트
      final query = FirestoreService.testerApplications
          .where('id', isEqualTo: applicationId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await FirestoreService.update(
          FirestoreService.testerApplications,
          docId,
          {
            'status': FirestoreConstants.statusApproved,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'startedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      AppLogger.info('Application approved: $applicationId', 'MissionService');
    } catch (e) {
      AppLogger.error('Error approving application', e.toString());
      rethrow;
    }
  }

  // 공급자가 테스터 신청을 거부
  static Future<void> rejectApplication(String applicationId, {String? responseMessage}) async {
    try {
      // 1. mission_applications 업데이트
      await updateApplicationStatus(
        applicationId,
        MissionApplicationStatus.rejected,
        responseMessage: responseMessage ?? '신청이 거부되었습니다.',
      );

      // 2. tester_applications에서 해당 신청 찾아서 상태 업데이트
      final query = FirestoreService.testerApplications
          .where('id', isEqualTo: applicationId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await FirestoreService.update(
          FirestoreService.testerApplications,
          docId,
          {
            'status': FirestoreConstants.statusRejected,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      AppLogger.info('Application rejected: $applicationId', 'MissionService');
    } catch (e) {
      AppLogger.error('Error rejecting application', e.toString());
      rethrow;
    }
  }

  // 테스터가 일일 미션 시작
  static Future<void> startDailyMission(String applicationId) async {
    try {
      final query = FirestoreService.testerApplications
          .where('id', isEqualTo: applicationId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        final data = snapshot.docs.first.data();
        final progress = data['progress'] as Map<String, dynamic>? ?? {};

        await FirestoreService.update(
          FirestoreService.testerApplications,
          docId,
          {
            'status': FirestoreConstants.statusInProgress,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'progress.currentDay': (progress['currentDay'] ?? 0) + 1,
            'progress.todayCompleted': false,
          },
        );
      }

      AppLogger.info('Daily mission started: $applicationId', 'MissionService');
    } catch (e) {
      AppLogger.error('Error starting daily mission', e.toString());
      rethrow;
    }
  }

  // 테스터가 일일 미션 완료
  static Future<void> completeDailyMission(String applicationId, {
    String? feedback,
    int? rating,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final query = FirestoreService.testerApplications
          .where('id', isEqualTo: applicationId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        final data = snapshot.docs.first.data();
        final progress = data['progress'] as Map<String, dynamic>? ?? {};
        final missionInfo = data['missionInfo'] as Map<String, dynamic>? ?? {};

        final currentDay = progress['currentDay'] ?? 1;
        final totalDays = missionInfo['totalDays'] ?? 14;
        final dailyReward = missionInfo['dailyReward'] ?? 5000;
        final totalPoints = (progress['totalPoints'] ?? 0) + dailyReward;
        final progressPercentage = (currentDay / totalDays * 100).clamp(0.0, 100.0);

        final updateData = {
          'progress.todayCompleted': true,
          'progress.totalPoints': totalPoints,
          'progress.progressPercentage': progressPercentage,
          'progress.latestFeedback': feedback,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        };

        if (rating != null) {
          updateData['progress.averageRating'] = rating;
        }

        // 모든 일일 미션 완료 체크
        if (currentDay >= totalDays) {
          updateData['status'] = FirestoreConstants.statusCompleted;
          updateData['completedAt'] = FieldValue.serverTimestamp();
        }

        await FirestoreService.update(
          FirestoreService.testerApplications,
          docId,
          updateData,
        );
      }

      AppLogger.info('Daily mission completed: $applicationId', 'MissionService');
    } catch (e) {
      AppLogger.error('Error completing daily mission', e.toString());
      rethrow;
    }
  }

  // 공급자가 미션 완료를 승인
  static Future<void> approveMissionCompletion(String applicationId, {String? responseMessage}) async {
    try {
      final query = FirestoreService.testerApplications
          .where('id', isEqualTo: applicationId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;

        await FirestoreService.update(
          FirestoreService.testerApplications,
          docId,
          {
            'status': FirestoreConstants.statusMissionApproved,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'approvedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      AppLogger.info('Mission completion approved: $applicationId', 'MissionService');
    } catch (e) {
      AppLogger.error('Error approving mission completion', e.toString());
      rethrow;
    }
  }

  // 프로젝트 종료
  static Future<void> finalizeProject(String applicationId) async {
    try {
      final query = FirestoreService.testerApplications
          .where('id', isEqualTo: applicationId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;

        await FirestoreService.update(
          FirestoreService.testerApplications,
          docId,
          {
            'status': FirestoreConstants.statusProjectEnded,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'finalizedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      AppLogger.info('Project finalized: $applicationId', 'MissionService');
    } catch (e) {
      AppLogger.error('Error finalizing project', e.toString());
      rethrow;
    }
  }

  // 공급자가 미션의 모든 신청자들을 조회 (확장된 정보 포함)
  static Future<List<Map<String, dynamic>>> getEnhancedMissionApplications(String missionId) async {
    try {
      // tester_applications에서 해당 미션의 신청자들 조회
      final query = FirestoreService.testerApplications
          .where('missionId', isEqualTo: missionId)
          .orderBy('appliedAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'documentId': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting enhanced mission applications', e.toString());
      return [];
    }
  }
}