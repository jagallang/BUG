// Provider Dashboard Repository Firebase Implementation
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../domain/models/provider_model.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';

class ProviderDashboardRepositoryImpl implements ProviderDashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ProviderModel?> getProviderInfo(String providerId) async {
    try {
      final doc = await _firestore.collection('providers').doc(providerId).get();
      
      if (!doc.exists) return null;
      
      return ProviderModel.fromMap(providerId, doc.data()!);
    } catch (e) {
      AppLogger.error('Failed to get provider info', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProviderInfo(String providerId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('providers').doc(providerId).update(data);
      AppLogger.info('Provider info updated: $providerId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update provider info', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProviderStatus(String providerId, ProviderStatus status) async {
    try {
      await _firestore.collection('providers').doc(providerId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Provider status updated: $providerId to ${status.name}', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update provider status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<AppModel>> getProviderApps(String providerId) async {
    try {
      final query = await _firestore
          .collection('projects')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs.map((doc) => AppModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      AppLogger.error('Failed to get provider apps', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<AppModel?> getApp(String appId) async {
    try {
      final doc = await _firestore.collection('projects').doc(appId).get();
      
      if (!doc.exists) return null;
      
      return AppModel.fromMap(appId, doc.data()!);
    } catch (e) {
      AppLogger.error('Failed to get app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> createApp(AppModel app) async {
    try {
      final docRef = _firestore.collection('projects').doc();
      
      await docRef.set({
        ...app.toMap(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
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
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('projects').doc(appId).update(data);
      AppLogger.info('App updated: $appId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update app', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateAppStatus(String appId, AppStatus status) async {
    try {
      await _firestore.collection('projects').doc(appId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('App status updated: $appId to ${status.name}', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update app status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteApp(String appId) async {
    try {
      await _firestore.collection('projects').doc(appId).delete();
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
          .collection('missions')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs.map((doc) => MissionModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      AppLogger.error('Failed to get provider missions', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<MissionModel>> getAppMissions(String appId) async {
    try {
      final query = await _firestore
          .collection('missions')
          .where('appId', isEqualTo: appId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs.map((doc) => MissionModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      AppLogger.error('Failed to get app missions', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<String> createMission(MissionModel mission) async {
    try {
      final docRef = _firestore.collection('missions').doc();
      
      await docRef.set({
        'id': docRef.id,
        'title': mission.title,
        'appName': mission.appName,
        'category': mission.category,
        'status': mission.status,
        'testers': mission.testers,
        'maxTesters': mission.maxTesters,
        'reward': mission.reward,
        'description': mission.description,
        'requirements': mission.requirements,
        'duration': mission.duration,
        'createdBy': mission.createdBy,
        'bugs': mission.bugs,
        'isHot': mission.isHot,
        'isNew': mission.isNew,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
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
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('missions').doc(missionId).update(data);
      AppLogger.info('Mission updated: $missionId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteMission(String missionId) async {
    try {
      await _firestore.collection('missions').doc(missionId).delete();
      AppLogger.info('Mission deleted: $missionId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to delete mission', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBugReports(String providerId) async {
    try {
      // Get provider's apps first
      final apps = await getProviderApps(providerId);
      final appIds = apps.map((app) => app.id).toList();
      
      if (appIds.isEmpty) return [];
      
      final query = await _firestore
          .collection('bug_reports')
          .where('appId', whereIn: appIds)
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Failed to get bug reports', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<DashboardStats> getDashboardStats(String providerId) async {
    try {
      // Get apps, missions, and bug reports
      final apps = await getProviderApps(providerId);
      final missions = await getProviderMissions(providerId);
      final bugReports = await getBugReports(providerId);
      
      // Calculate statistics
      final totalApps = apps.length;
      final activeApps = apps.where((app) => app.status == AppStatus.active).length;
      final totalMissions = missions.length;
      final activeMissions = missions.where((mission) => mission.status == 'active').length;
      final completedMissions = missions.where((mission) => mission.status == 'completed').length;
      final totalBugReports = bugReports.length;
      final resolvedBugReports = bugReports.where((report) => report['status'] == 'resolved').length;
      
      // Get financial data from payments collection
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('providerId', isEqualTo: providerId)
          .get();
      
      double totalRevenue = 0;
      for (var doc in paymentsQuery.docs) {
        final amount = doc.data()['amount'] ?? 0;
        totalRevenue += (amount as num).toDouble();
      }
      
      return DashboardStats(
        totalApps: totalApps,
        activeApps: activeApps,
        totalMissions: totalMissions,
        activeMissions: activeMissions,
        completedMissions: completedMissions,
        totalBugReports: totalBugReports,
        pendingBugReports: totalBugReports - resolvedBugReports,
        resolvedBugReports: resolvedBugReports,
        totalTesters: 0, // Calculate from mission participants
        activeTesters: 0,
        totalRevenue: totalRevenue,
        averageAppRating: 4.5, // Calculate from app ratings
        missionsByStatus: {
          'active': activeMissions,
          'completed': completedMissions,
          'pending': totalMissions - activeMissions - completedMissions,
        },
        bugReportsByPriority: {
          'high': bugReports.where((b) => b['severity'] == 'high').length,
          'medium': bugReports.where((b) => b['severity'] == 'medium').length,
          'low': bugReports.where((b) => b['severity'] == 'low').length,
        },
        recentActivities: const [], // Will be fetched separately
        performanceMetrics: {
          'responseTime': 24.5,
          'satisfaction': 4.5,
          'resolution': resolvedBugReports > 0 ? resolvedBugReports / totalBugReports : 0.0,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to get dashboard stats', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivities(String providerId) async {
    try {
      final query = await _firestore
          .collection('activities')
          .where('providerId', isEqualTo: providerId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Failed to get recent activities', 'ProviderDashboardRepository', e);
      return []; // Return empty list instead of rethrowing
    }
  }

  @override
  Future<Map<String, dynamic>> getTesterProfile(String testerId) async {
    try {
      final doc = await _firestore.collection('users').doc(testerId).get();
      
      if (!doc.exists) return {};
      
      return {'id': testerId, ...doc.data()!};
    } catch (e) {
      AppLogger.error('Failed to get tester profile', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAppBugReports(String appId) async {
    try {
      final query = await _firestore
          .collection('bug_reports')
          .where('appId', isEqualTo: appId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Failed to get app bug reports', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> updateBugReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection('bug_reports').doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Bug report status updated: $reportId to $status', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to update bug report status', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> addBugReportResponse(String reportId, String response) async {
    try {
      await _firestore.collection('bug_reports').doc(reportId).update({
        'response': response,
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Bug report response added: $reportId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to add bug report response', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getAppAnalytics(String appId) async {
    try {
      final missions = await getAppMissions(appId);
      final bugReports = await getAppBugReports(appId);
      
      return {
        'totalMissions': missions.length,
        'activeMissions': missions.where((m) => m.status == 'active').length,
        'completedMissions': missions.where((m) => m.status == 'completed').length,
        'totalBugReports': bugReports.length,
        'criticalBugs': bugReports.where((b) => b['severity'] == 'critical').length,
        'resolvedBugs': bugReports.where((b) => b['status'] == 'resolved').length,
        'averageResolutionTime': 24.5,
        'testerSatisfaction': 4.6,
      };
    } catch (e) {
      AppLogger.error('Failed to get app analytics', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMissionAnalytics(String missionId) async {
    try {
      final missionDoc = await _firestore.collection('missions').doc(missionId).get();
      
      if (!missionDoc.exists) {
        return {
          'views': 0,
          'applications': 0,
          'completions': 0,
          'bugReports': 0,
          'avgRating': 0.0,
          'avgCompletionTime': 0.0,
        };
      }
      
      final data = missionDoc.data()!;
      return {
        'views': data['views'] ?? 0,
        'applications': data['applications'] ?? 0,
        'completions': data['completions'] ?? 0,
        'bugReports': data['bugReports'] ?? 0,
        'avgRating': data['avgRating'] ?? 0.0,
        'avgCompletionTime': data['avgCompletionTime'] ?? 0.0,
      };
    } catch (e) {
      AppLogger.error('Failed to get mission analytics', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  // Real-time Streams
  @override
  Stream<ProviderModel> watchProviderInfo(String providerId) {
    return _firestore.collection('providers').doc(providerId).snapshots()
        .map((doc) => doc.exists ? ProviderModel.fromMap(providerId, doc.data()!) : throw Exception('Provider not found'));
  }

  @override
  Stream<List<AppModel>> watchProviderApps(String providerId) {
    return _firestore
        .collection('projects')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) => query.docs.map((doc) => AppModel.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Stream<List<MissionModel>> watchProviderMissions(String providerId) {
    return _firestore
        .collection('missions')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) => query.docs.map((doc) => MissionModel.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Stream<DashboardStats> watchDashboardStats(String providerId) {
    return Stream.fromFuture(getDashboardStats(providerId));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRecentActivities(String providerId) {
    return _firestore
        .collection('activities')
        .where('providerId', isEqualTo: providerId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((query) => query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Tester Management
  @override
  Future<List<Map<String, dynamic>>> getProviderTesters(String providerId) async {
    try {
      // Get testers who participated in provider's missions
      final missions = await getProviderMissions(providerId);
      final Set<String> testerIds = {};
      
      // Get participants from mission_participants collection
      for (var mission in missions) {
        final participantsQuery = await _firestore
            .collection('mission_participants')
            .where('missionId', isEqualTo: mission.id)
            .get();
        
        for (var doc in participantsQuery.docs) {
          final testerId = doc.data()['testerId'] as String?;
          if (testerId != null) {
            testerIds.add(testerId);
          }
        }
      }
      
      if (testerIds.isEmpty) return [];
      
      final testers = await Future.wait(
        testerIds.map((testerId) => getTesterProfile(testerId))
      );
      
      return testers.where((tester) => tester.isNotEmpty).toList();
    } catch (e) {
      AppLogger.error('Failed to get provider testers', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTesterHistory(String testerId) async {
    try {
      final query = await _firestore
          .collection('mission_completions')
          .where('testerId', isEqualTo: testerId)
          .orderBy('completedAt', descending: true)
          .get();
      
      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Failed to get tester history', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  // Financial Management
  @override
  Future<Map<String, dynamic>> getFinancialSummary(String providerId) async {
    try {
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('providerId', isEqualTo: providerId)
          .get();
      
      double totalSpent = 0;
      double thisMonthSpent = 0;
      double pendingPayments = 0;
      int totalMissions = 0;
      
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      for (var doc in paymentsQuery.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0) as num;
        final status = data['status'] ?? 'pending';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        totalSpent += amount.toDouble();
        totalMissions++;
        
        if (createdAt != null && createdAt.isAfter(startOfMonth)) {
          thisMonthSpent += amount.toDouble();
        }
        
        if (status == 'pending') {
          pendingPayments += amount.toDouble();
        }
      }
      
      final avgCostPerMission = totalMissions > 0 ? totalSpent / totalMissions : 0.0;
      
      return {
        'totalSpent': totalSpent,
        'thisMonthSpent': thisMonthSpent,
        'pendingPayments': pendingPayments,
        'avgCostPerMission': avgCostPerMission,
        'totalMissions': totalMissions,
        'costBreakdown': {
          'missionRewards': totalSpent * 0.8,
          'platformFees': totalSpent * 0.1,
          'bonusPayments': totalSpent * 0.1,
        }
      };
    } catch (e) {
      AppLogger.error('Failed to get financial summary', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentHistory(String providerId) async {
    try {
      final query = await _firestore
          .collection('payments')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Failed to get payment history', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> processPayment(String providerId, Map<String, dynamic> paymentData) async {
    try {
      await _firestore.collection('payments').add({
        'providerId': providerId,
        ...paymentData,
        'status': 'processing',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Payment processed for provider: $providerId', 'ProviderDashboardRepository');
    } catch (e) {
      AppLogger.error('Failed to process payment', 'ProviderDashboardRepository', e);
      rethrow;
    }
  }
}