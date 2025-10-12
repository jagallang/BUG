import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  static const String missionsCollection = 'missions';
  static const String usersCollection = 'users';
  static const String submissionsCollection = 'submissions';
  static const String bugReportsCollection = 'bug_reports';

  // Users
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _db.collection(usersCollection).doc(uid).set(userData);
  }

  Future<DocumentSnapshot?> getUser(String uid) async {
    try {
      return await _db.collection(usersCollection).doc(uid).get();
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection(usersCollection).doc(uid).snapshots();
  }

  // Missions
  Future<String> createMission(Map<String, dynamic> missionData) async {
    final docRef = await _db.collection(missionsCollection).add(missionData);
    return docRef.id;
  }

  Future<void> updateMission(String missionId, Map<String, dynamic> data) async {
    await _db.collection(missionsCollection).doc(missionId).update(data);
  }

  Future<void> deleteMission(String missionId) async {
    await _db.collection(missionsCollection).doc(missionId).delete();
  }

  Stream<QuerySnapshot> getMissionsStream() {
    return _db
        .collection(missionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getActiveMissionsStream() {
    return _db
        .collection(missionsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot>> searchMissions(String query) async {
    if (query.isEmpty) {
      final result = await _db
          .collection(missionsCollection)
          .where('status', isEqualTo: 'active')
          .get();
      return result.docs;
    }
    
    // Simple text search (for better search, use Algolia or similar)
    final result = await _db
        .collection(missionsCollection)
        .where('status', isEqualTo: 'active')
        .get();
    
    return result.docs.where((doc) {
      final data = doc.data();
      final title = data['title']?.toString().toLowerCase() ?? '';
      final appName = data['appName']?.toString().toLowerCase() ?? '';
      final category = data['category']?.toString().toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
             appName.contains(query.toLowerCase()) ||
             category.contains(query.toLowerCase());
    }).toList();
  }

  // Bug Reports
  Future<String> createBugReport(Map<String, dynamic> bugData) async {
    final docRef = await _db.collection(bugReportsCollection).add(bugData);
    return docRef.id;
  }

  Stream<QuerySnapshot> getBugReportsForMission(String missionId) {
    return _db
        .collection(bugReportsCollection)
        .where('missionId', isEqualTo: missionId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Statistics
  Future<Map<String, int>> getMissionStats() async {
    final missionsSnapshot = await _db.collection(missionsCollection).get();
    final missions = missionsSnapshot.docs;
    
    int active = 0;
    int completed = 0;
    int draft = 0;
    int totalTesters = 0;
    int totalBugs = 0;
    
    for (var doc in missions) {
      final data = doc.data();
      final status = data['status'] as String?;
      final testers = data['testers'] as int? ?? 0;
      final bugs = data['bugs'] as int? ?? 0;
      
      totalTesters += testers;
      totalBugs += bugs;
      
      switch (status) {
        case 'active':
          active++;
          break;
        case 'completed':
          completed++;
          break;
        case 'draft':
          draft++;
          break;
      }
    }
    
    return {
      'total': missions.length,
      'active': active,
      'completed': completed,
      'draft': draft,
      'totalTesters': totalTesters,
      'totalBugs': totalBugs,
    };
  }

  // Batch operations
  Future<void> clearAllData() async {
    debugPrint('🗑️ 모든 더미 데이터를 삭제합니다...');

    // Delete all missions
    final missionsSnapshot = await _db.collection(missionsCollection).get();
    final batch = _db.batch();

    for (var doc in missionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete all bug reports
    final bugReportsSnapshot = await _db.collection(bugReportsCollection).get();
    for (var doc in bugReportsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete all submissions
    final submissionsSnapshot = await _db.collection(submissionsCollection).get();
    for (var doc in submissionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    debugPrint('✅ 모든 더미 데이터가 삭제되었습니다.');
  }
}