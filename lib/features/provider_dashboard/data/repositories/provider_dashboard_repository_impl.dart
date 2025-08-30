import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../domain/models/provider_model.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';

class ProviderDashboardRepositoryImpl implements ProviderDashboardRepository {
  final FirebaseFirestore _firestore;

  ProviderDashboardRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _providersCollection = 'providers';
  static const String _appsCollection = 'provider_apps';
  static const String _missionsCollection = 'missions';
  static const String _bugReportsCollection = 'bug_reports';
  static const String _activitiesCollection = 'provider_activities';
  static const String _testersCollection = 'users';

  @override
  Future<ProviderModel?> getProviderInfo(String providerId) async {
    try {
      final doc = await _firestore.collection(_providersCollection).doc(providerId).get();
      if (!doc.exists) return null;
      
      return ProviderModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to get provider info', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProviderInfo(String providerId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_providersCollection).doc(providerId).update({
        ...data,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Provider info updated: $providerId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update provider info', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProviderStatus(String providerId, ProviderStatus status) async {
    try {
      await _firestore.collection(_providersCollection).doc(providerId).update({
        'status': status.name,
        'lastUpdated': FieldValue.serverTimestamp(),
        if (status == ProviderStatus.approved) 'approvedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Provider status updated: $providerId -> ${status.name}', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update provider status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<AppModel>> getProviderApps(String providerId) async {
    try {
      final query = await _firestore
          .collection(_appsCollection)
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => AppModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Failed to get provider apps', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<AppModel?> getApp(String appId) async {
    try {
      final doc = await _firestore.collection(_appsCollection).doc(appId).get();
      if (!doc.exists) return null;
      
      return AppModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to get app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> createApp(AppModel app) async {
    try {
      final docRef = await _firestore.collection(_appsCollection).add(app.toFirestore());
      
      AppLogger.info('App created: ${docRef.id}', 'ProviderDashboardRepository');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateApp(String appId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_appsCollection).doc(appId).update({
        ...data,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('App updated: $appId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateAppStatus(String appId, AppStatus status) async {
    try {
      await _firestore.collection(_appsCollection).doc(appId).update({
        'status': status.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('App status updated: $appId -> ${status.name}', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update app status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteApp(String appId) async {
    try {
      await _firestore.collection(_appsCollection).doc(appId).delete();
      
      AppLogger.info('App deleted: $appId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to delete app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<MissionModel>> getProviderMissions(String providerId) async {
    try {
      final query = await _firestore
          .collection(_missionsCollection)
          .where('createdBy', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => MissionModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Failed to get provider missions', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<MissionModel>> getAppMissions(String appId) async {
    try {
      final query = await _firestore
          .collection(_missionsCollection)
          .where('appId', isEqualTo: appId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => MissionModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Failed to get app missions', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> createMission(MissionModel mission) async {
    try {
      final docRef = await _firestore.collection(_missionsCollection).add(mission.toFirestore());
      
      AppLogger.info('Mission created: ${docRef.id}', 'ProviderDashboardRepository');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateMission(String missionId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_missionsCollection).doc(missionId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Mission updated: $missionId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteMission(String missionId) async {
    try {
      await _firestore.collection(_missionsCollection).doc(missionId).delete();
      
      AppLogger.info('Mission deleted: $missionId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to delete mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBugReports(String providerId) async {
    try {
      final query = await _firestore
          .collection(_bugReportsCollection)
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get bug reports', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAppBugReports(String appId) async {
    try {
      final query = await _firestore
          .collection(_bugReportsCollection)
          .where('appId', isEqualTo: appId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get app bug reports', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateBugReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection(_bugReportsCollection).doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Bug report status updated: $reportId -> $status', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update bug report status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> addBugReportResponse(String reportId, String response) async {
    try {
      await _firestore.collection(_bugReportsCollection).doc(reportId).update({
        'providerResponse': response,
        'responseAt': FieldValue.serverTimestamp(),
        'status': 'responded',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Bug report response added: $reportId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to add bug report response', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<DashboardStats> getDashboardStats(String providerId) async {
    try {
      // Get provider apps
      final apps = await getProviderApps(providerId);
      final activeApps = apps.where((app) => app.status == AppStatus.active).length;
      
      // Get provider missions
      final missions = await getProviderMissions(providerId);
      final activeMissions = missions.where((m) => m.status == 'active').length;
      final completedMissions = missions.where((m) => m.status == 'completed').length;
      
      // Get bug reports
      final bugReports = await getBugReports(providerId);
      final pendingBugReports = bugReports.where((r) => r['status'] == 'pending').length;
      final resolvedBugReports = bugReports.where((r) => r['status'] == 'resolved').length;
      
      // Get recent activities
      final activities = await getRecentActivities(providerId);
      
      // Calculate metrics
      final totalTesters = apps.fold<int>(0, (sum, app) => sum + app.totalTesters);
      final averageAppRating = apps.isEmpty ? 0.0 : 
          apps.fold<double>(0.0, (sum, app) => sum + app.averageRating) / apps.length;
      
      // Mission status breakdown
      final missionsByStatus = <String, int>{};
      for (final mission in missions) {
        missionsByStatus[mission.status] = (missionsByStatus[mission.status] ?? 0) + 1;
      }
      
      // Bug report priority breakdown
      final bugReportsByPriority = <String, int>{};
      for (final report in bugReports) {
        final priority = report['priority'] ?? 'medium';
        bugReportsByPriority[priority] = (bugReportsByPriority[priority] ?? 0) + 1;
      }
      
      return DashboardStats(
        totalApps: apps.length,
        activeApps: activeApps,
        totalMissions: missions.length,
        activeMissions: activeMissions,
        completedMissions: completedMissions,
        totalBugReports: bugReports.length,
        pendingBugReports: pendingBugReports,
        resolvedBugReports: resolvedBugReports,
        totalTesters: totalTesters,
        activeTesters: totalTesters, // Simplified for now
        totalRevenue: 0.0, // Would need payment data
        averageAppRating: averageAppRating,
        missionsByStatus: missionsByStatus,
        bugReportsByPriority: bugReportsByPriority,
        recentActivities: activities,
        performanceMetrics: _calculatePerformanceMetrics(missions, bugReports),
      );
    } catch (e) {
      AppLogger.error('Failed to get dashboard stats', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  Map<String, double> _calculatePerformanceMetrics(
    List<MissionModel> missions,
    List<Map<String, dynamic>> bugReports,
  ) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentMissions = missions.where((m) => 
        m.createdAt != null && m.createdAt!.isAfter(thirtyDaysAgo)).length;
    final recentBugReports = bugReports.where((r) => 
        r['createdAt'] != null && 
        (r['createdAt'] as Timestamp).toDate().isAfter(thirtyDaysAgo)).length;
    
    return {
      'missionCompletionRate': missions.isEmpty ? 0.0 : 
          missions.where((m) => m.status == 'completed').length / missions.length * 100,
      'averageResponseTime': 24.0, // Hours - would need actual calculation
      'bugResolutionRate': bugReports.isEmpty ? 0.0 :
          bugReports.where((r) => r['status'] == 'resolved').length / bugReports.length * 100,
      'recentActivityScore': (recentMissions + recentBugReports).toDouble(),
    };
  }

  @override
  Future<Map<String, dynamic>> getAppAnalytics(String appId) async {
    try {
      final app = await getApp(appId);
      if (app == null) throw Exception('App not found');
      
      final missions = await getAppMissions(appId);
      final bugReports = await getAppBugReports(appId);
      
      return {
        'app': app.toFirestore(),
        'totalMissions': missions.length,
        'activeMissions': missions.where((m) => m.status == 'active').length,
        'completedMissions': missions.where((m) => m.status == 'completed').length,
        'totalBugReports': bugReports.length,
        'resolvedBugReports': bugReports.where((r) => r['status'] == 'resolved').length,
        'averageRating': app.averageRating,
        'totalTesters': app.totalTesters,
        'conversionRate': missions.isEmpty ? 0.0 :
            missions.where((m) => m.status == 'completed').length / missions.length * 100,
      };
    } catch (e) {
      AppLogger.error('Failed to get app analytics', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMissionAnalytics(String missionId) async {
    try {
      final missionDoc = await _firestore.collection(_missionsCollection).doc(missionId).get();
      if (!missionDoc.exists) throw Exception('Mission not found');
      
      final mission = MissionModel.fromFirestore(missionDoc);
      
      // Get mission participants
      final participants = await _firestore
          .collection('user_missions')
          .where('missionId', isEqualTo: missionId)
          .get();
      
      // Get mission bug reports
      final bugReports = await _firestore
          .collection(_bugReportsCollection)
          .where('missionId', isEqualTo: missionId)
          .get();
      
      return {
        'mission': mission.toFirestore(),
        'totalParticipants': participants.size,
        'completedParticipants': participants.docs
            .where((doc) => doc.data()['status'] == 'completed').length,
        'totalBugReports': bugReports.size,
        'avgCompletionTime': 0.0, // Would need actual calculation
        'successRate': participants.size > 0 ? 
            participants.docs.where((doc) => doc.data()['status'] == 'completed').length / 
            participants.size * 100 : 0.0,
      };
    } catch (e) {
      AppLogger.error('Failed to get mission analytics', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivities(String providerId) async {
    try {
      final query = await _firestore
          .collection(_activitiesCollection)
          .where('providerId', isEqualTo: providerId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get recent activities', 'ProviderDashboardRepository', e);
      return []; // Return empty list on error
    }
  }

  @override
  Stream<ProviderModel> watchProviderInfo(String providerId) {
    return _firestore
        .collection(_providersCollection)
        .doc(providerId)
        .snapshots()
        .map((doc) => ProviderModel.fromFirestore(doc));
  }

  @override
  Stream<List<AppModel>> watchProviderApps(String providerId) {
    return _firestore
        .collection(_appsCollection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<MissionModel>> watchProviderMissions(String providerId) {
    return _firestore
        .collection(_missionsCollection)
        .where('createdBy', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MissionModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<DashboardStats> watchDashboardStats(String providerId) {
    return Stream.periodic(const Duration(minutes: 5), (count) => count)
        .asyncMap((_) => getDashboardStats(providerId));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRecentActivities(String providerId) {
    return _firestore
        .collection(_activitiesCollection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList());
  }

  // Implement remaining methods...
  @override
  Future<List<Map<String, dynamic>>> getProviderTesters(String providerId) async {
    // Implementation would get testers who participated in provider's missions
    return [];
  }

  @override
  Future<Map<String, dynamic>> getTesterProfile(String testerId) async {
    try {
      final doc = await _firestore.collection(_testersCollection).doc(testerId).get();
      return doc.exists ? {'id': doc.id, ...doc.data()!} : {};
    } catch (e) {
      AppLogger.error('Failed to get tester profile', 'ProviderDashboardRepository', e);
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTesterHistory(String testerId) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getFinancialSummary(String providerId) async {
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentHistory(String providerId) async {
    return [];
  }

  @override
  Future<void> processPayment(String providerId, Map<String, dynamic> paymentData) async {
    // Implementation for payment processing
  }
}