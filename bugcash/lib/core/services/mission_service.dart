import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../../models/mission_model.dart';

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
      'status': MissionStatus.draft.name,
      'requirements': {
        'platforms': platforms,
        'devices': devices,
        'osVersions': osVersions,
        'languages': languages,
        'experience': experience,
        'minRating': minRating ?? 0.0,
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
        'currency': 'USD',
        'paymentMethod': 'cash',
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
      status: MissionStatus.active.name,
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
      'status': MissionStatus.active.name,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  // Complete mission
  static Future<void> completeMission(String missionId) async {
    await updateMission(missionId, {
      'status': MissionStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Pause/Resume mission
  static Future<void> pauseMission(String missionId) async {
    await updateMission(missionId, {
      'status': MissionStatus.paused.name,
    });
  }

  static Future<void> resumeMission(String missionId) async {
    await updateMission(missionId, {
      'status': MissionStatus.active.name,
    });
  }

  // Cancel mission
  static Future<void> cancelMission(String missionId) async {
    await updateMission(missionId, {
      'status': MissionStatus.cancelled.name,
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
    firestoreQuery = firestoreQuery.where('status', isEqualTo: MissionStatus.active.name);

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
      // 미션 신청 정보를 mission_applications 컬렉션에 저장
      final applicationId = await FirestoreService.create(
        FirestoreService.missionApplications,
        applicationData
      );

      // 미션의 analytics.applications 증가
      await incrementApplications(missionId);

      // 공급자에게 알림 전송 (추후 구현)
      // await _sendApplicationNotification(applicationData);

      return applicationId;
    } catch (e) {
      print('Error applying to mission: $e');
      rethrow;
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
      print('Error getting mission applications: $e');
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
      print('Error getting tester applications: $e');
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
      print('Error updating application status: $e');
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
      print('Error checking if user applied: $e');
      return false;
    }
  }
}