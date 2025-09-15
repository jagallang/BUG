import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Data Source - 실제 Firestore 데이터 관리
/// Clean Architecture의 Data Layer에 위치
abstract class FirebaseDataSource {
  // Provider 관련 데이터
  Future<Map<String, dynamic>> getProviderProfile(String providerId);
  Future<List<Map<String, dynamic>>> getProviderApps(String providerId);
  Future<List<Map<String, dynamic>>> getProviderMissions(String providerId);
  Future<List<Map<String, dynamic>>> getProviderBugReports(String providerId);
  Future<Map<String, dynamic>> getProviderDashboardStats(String providerId);
  Stream<List<Map<String, dynamic>>> getProviderRecentActivities(String providerId);

  // Tester 관련 데이터
  Future<Map<String, dynamic>> getTesterProfile(String testerId);
  Future<List<Map<String, dynamic>>> getTesterMissions(String testerId);
  Future<List<Map<String, dynamic>>> getTesterEarnings(String testerId);
  Future<Map<String, dynamic>> getTesterStats(String testerId);

  // Mission 관련 데이터
  Stream<List<Map<String, dynamic>>> getAvailableMissions();
  Future<Map<String, dynamic>> getMissionDetails(String missionId);
  Stream<List<Map<String, dynamic>>> getMissionParticipants(String missionId);

  // App 관련 데이터
  Future<Map<String, dynamic>> getApp(String appId);
  Future<Map<String, dynamic>> getAppDetails(String appId);
  Stream<List<Map<String, dynamic>>> getAppBugReports(String appId);
  Future<Map<String, dynamic>> getAppAnalytics(String appId);
  Future<String> createApp(Map<String, dynamic> appData);
  Future<void> updateApp(String appId, Map<String, dynamic> data);
  Future<void> deleteApp(String appId);

  // Provider 업데이트 메서드
  Future<void> updateProviderProfile(String providerId, Map<String, dynamic> data);

  // Bug Report 관련 데이터
  Future<Map<String, dynamic>> getBugReportDetails(String reportId);
  Stream<List<Map<String, dynamic>>> getBugReportComments(String reportId);
}

/// Firebase Data Source 구현체
class FirebaseDataSourceImpl implements FirebaseDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDataSourceImpl _instance = FirebaseDataSourceImpl._internal();
  factory FirebaseDataSourceImpl() => _instance;
  FirebaseDataSourceImpl._internal();

  static FirebaseDataSourceImpl get instance => _instance;
  
  @override
  Future<Map<String, dynamic>> getProviderProfile(String providerId) async {
    final doc = await _firestore.collection('providers').doc(providerId).get();
    if (!doc.exists) {
      throw Exception('Provider not found');
    }
    return {'id': doc.id, ...doc.data()!};
  }
  
  @override
  Future<List<Map<String, dynamic>>> getProviderApps(String providerId) async {
    final querySnapshot = await _firestore
        .collection('apps')
        .where('providerId', isEqualTo: providerId)
        .get();

    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  @override
  Future<List<Map<String, dynamic>>> getProviderMissions(String providerId) async {
    final querySnapshot = await _firestore
        .collection('missions')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  @override
  Future<List<Map<String, dynamic>>> getProviderBugReports(String providerId) async {
    final apps = await getProviderApps(providerId);
    final appIds = apps.map((app) => app['id']).toList();

    if (appIds.isEmpty) return [];

    final querySnapshot = await _firestore
        .collection('bugReports')
        .where('appId', whereIn: appIds)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  @override
  Future<Map<String, dynamic>> getProviderDashboardStats(String providerId) async {
    final statsDoc = await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('stats')
        .doc('dashboard')
        .get();

    if (statsDoc.exists) {
      return statsDoc.data()!;
    }

    // Calculate stats if not cached
    final apps = await getProviderApps(providerId);
    final missions = await getProviderMissions(providerId);
    final bugReports = await getProviderBugReports(providerId);

    return {
      'totalApps': apps.length,
      'activeApps': apps.where((a) => a['status'] == 'active').length,
      'totalMissions': missions.length,
      'activeMissions': missions.where((m) => m['status'] == 'active').length,
      'completedMissions': missions.where((m) => m['status'] == 'completed').length,
      'totalBugReports': bugReports.length,
      'openBugReports': bugReports.where((b) => b['status'] == 'open').length,
      'resolvedBugReports': bugReports.where((b) => b['status'] == 'resolved').length,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
  
  @override
  Stream<List<Map<String, dynamic>>> getProviderRecentActivities(String providerId) {
    return _firestore
        .collection('activities')
        .where('providerId', isEqualTo: providerId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }
  
  @override
  Future<Map<String, dynamic>> getTesterProfile(String testerId) async {
    final doc = await _firestore.collection('testers').doc(testerId).get();
    if (!doc.exists) {
      throw Exception('Tester not found');
    }
    return {'id': doc.id, ...doc.data()!};
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTesterMissions(String testerId) async {
    final querySnapshot = await _firestore
        .collection('missions')
        .where('participants', arrayContains: testerId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTesterEarnings(String testerId) async {
    final querySnapshot = await _firestore
        .collection('earnings')
        .where('testerId', isEqualTo: testerId)
        .orderBy('earnedAt', descending: true)
        .limit(50)
        .get();

    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  @override
  Future<Map<String, dynamic>> getTesterStats(String testerId) async {
    final statsDoc = await _firestore
        .collection('testers')
        .doc(testerId)
        .collection('stats')
        .doc('dashboard')
        .get();

    if (statsDoc.exists) {
      return statsDoc.data()!;
    }

    // Calculate stats if not cached
    final missions = await getTesterMissions(testerId);
    final earnings = await getTesterEarnings(testerId);

    return {
      'totalMissions': missions.length,
      'activeMissions': missions.where((m) => m['status'] == 'in_progress').length,
      'completedMissions': missions.where((m) => m['status'] == 'completed').length,
      'totalEarnings': earnings.fold<int>(0, (total, e) => total + (e['points'] as int)),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
  
  @override
  Stream<List<Map<String, dynamic>>> getAvailableMissions() {
    return _firestore
        .collection('missions')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }
  
  @override
  Future<Map<String, dynamic>> getMissionDetails(String missionId) async {
    final doc = await _firestore.collection('missions').doc(missionId).get();
    if (!doc.exists) {
      throw Exception('Mission not found');
    }
    return {'id': doc.id, ...doc.data()!};
  }
  
  @override
  Stream<List<Map<String, dynamic>>> getMissionParticipants(String missionId) {
    return _firestore
        .collection('missions')
        .doc(missionId)
        .collection('participants')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }
  
  @override
  Future<Map<String, dynamic>> getAppDetails(String appId) async {
    final doc = await _firestore.collection('apps').doc(appId).get();
    if (!doc.exists) {
      throw Exception('App not found');
    }
    return {'id': doc.id, ...doc.data()!};
  }
  
  @override
  Stream<List<Map<String, dynamic>>> getAppBugReports(String appId) {
    return _firestore
        .collection('bugReports')
        .where('appId', isEqualTo: appId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }
  
  @override
  Future<Map<String, dynamic>> getAppAnalytics(String appId) async {
    final analyticsDoc = await _firestore
        .collection('apps')
        .doc(appId)
        .collection('analytics')
        .doc('summary')
        .get();

    if (analyticsDoc.exists) {
      return analyticsDoc.data()!;
    }

    // Return empty analytics if not found
    return {
      'totalMissions': 0,
      'activeMissions': 0,
      'completedMissions': 0,
      'totalBugReports': 0,
      'criticalBugs': 0,
      'resolvedBugs': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
  
  @override
  Future<Map<String, dynamic>> getBugReportDetails(String reportId) async {
    final doc = await _firestore.collection('bugReports').doc(reportId).get();
    if (!doc.exists) {
      throw Exception('Bug report not found');
    }
    return {'id': doc.id, ...doc.data()!};
  }
  
  @override
  Stream<List<Map<String, dynamic>>> getBugReportComments(String reportId) {
    return _firestore
        .collection('bugReports')
        .doc(reportId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }
  
  // Authentication methods removed - use FirebaseAuth directly
  
  // All mock data initialization methods removed

  // App CRUD methods
  @override
  Future<Map<String, dynamic>> getApp(String appId) async {
    final doc = await _firestore.collection('apps').doc(appId).get();
    if (!doc.exists) {
      throw Exception('App not found');
    }
    return {'id': doc.id, ...doc.data()!};
  }

  @override
  Future<String> createApp(Map<String, dynamic> appData) async {
    final docRef = await _firestore.collection('apps').add({
      ...appData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<void> updateApp(String appId, Map<String, dynamic> data) async {
    await _firestore.collection('apps').doc(appId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteApp(String appId) async {
    await _firestore.collection('apps').doc(appId).delete();
  }

  // Provider update method
  @override
  Future<void> updateProviderProfile(String providerId, Map<String, dynamic> data) async {
    await _firestore.collection('providers').doc(providerId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}