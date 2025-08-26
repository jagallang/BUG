import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String missionsCollection = 'missions';
  static const String usersCollection = 'users';
  static const String bugReportsCollection = 'bug_reports';

  // 미션 데이터 CRUD
  static Future<List<Map<String, dynamic>>> getMissions() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(missionsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting missions: $e');
      }
      return [];
    }
  }

  static Future<String?> createMission(Map<String, dynamic> missionData) async {
    try {
      missionData['createdAt'] = FieldValue.serverTimestamp();
      missionData['updatedAt'] = FieldValue.serverTimestamp();
      
      final DocumentReference docRef = await _firestore
          .collection(missionsCollection)
          .add(missionData);
      
      if (kDebugMode) {
        print('Mission created with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating mission: $e');
      }
      return null;
    }
  }

  static Future<bool> updateMission(String missionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(missionsCollection)
          .doc(missionId)
          .update(updates);
      
      if (kDebugMode) {
        print('Mission updated: $missionId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating mission: $e');
      }
      return false;
    }
  }

  static Future<bool> deleteMission(String missionId) async {
    try {
      await _firestore
          .collection(missionsCollection)
          .doc(missionId)
          .delete();
      
      if (kDebugMode) {
        print('Mission deleted: $missionId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting mission: $e');
      }
      return false;
    }
  }

  // 사용자 데이터 관리
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user data: $e');
      }
      return null;
    }
  }

  static Future<bool> createOrUpdateUser(String userId, Map<String, dynamic> userData) async {
    try {
      userData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .set(userData, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('User data updated: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user data: $e');
      }
      return false;
    }
  }

  // 버그 리포트 관리
  static Future<String?> submitBugReport(Map<String, dynamic> bugReportData) async {
    try {
      bugReportData['createdAt'] = FieldValue.serverTimestamp();
      bugReportData['status'] = 'pending';
      
      final DocumentReference docRef = await _firestore
          .collection(bugReportsCollection)
          .add(bugReportData);
      
      if (kDebugMode) {
        print('Bug report submitted with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting bug report: $e');
      }
      return null;
    }
  }

  // 랭킹 데이터 조회
  static Future<List<Map<String, dynamic>>> getUserRankings({int limit = 10}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(usersCollection)
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting rankings: $e');
      }
      return [];
    }
  }

  // 데모 데이터 초기화 (개발용)
  static Future<void> initializeDemoData() async {
    if (kDebugMode) {
      print('Initializing demo data...');
      
      // 데모 미션 데이터
      final List<Map<String, dynamic>> demoMissions = [
        {
          'title': 'ShopApp 버그 테스트',
          'description': '쇼핑앱의 결제 플로우에서 버그를 찾아주세요',
          'reward': 5000,
          'category': 'E-commerce',
          'difficulty': 'Medium',
          'status': 'active',
          'deadline': DateTime.now().add(const Duration(days: 30)),
          'participantCount': 15,
          'maxParticipants': 50,
        },
        {
          'title': 'GameCenter UI 검증',
          'description': '게임센터 UI/UX 개선사항을 테스트해주세요',
          'reward': 8000,
          'category': 'Gaming',
          'difficulty': 'Easy',
          'status': 'active',
          'deadline': DateTime.now().add(const Duration(days: 20)),
          'participantCount': 8,
          'maxParticipants': 30,
        },
        {
          'title': '뱅킹앱 보안 테스트',
          'description': '금융앱의 보안 취약점을 찾아주세요',
          'reward': 12000,
          'category': 'Finance',
          'difficulty': 'Hard',
          'status': 'active',
          'deadline': DateTime.now().add(const Duration(days: 45)),
          'participantCount': 3,
          'maxParticipants': 20,
        },
      ];

      // 데모 사용자 데이터
      final Map<String, dynamic> demoUser = {
        'name': '데모 사용자',
        'email': 'demo@bugcash.com',
        'totalPoints': 15500,
        'tier': 'GOLD',
        'completedMissions': 12,
        'joinedAt': DateTime.now().subtract(const Duration(days: 90)),
        'isProvider': true,
      };

      try {
        // 미션 데이터 추가
        for (final mission in demoMissions) {
          await createMission(mission);
        }

        // 데모 사용자 추가
        await createOrUpdateUser('demo_user', demoUser);

        if (kDebugMode) {
          print('Demo data initialized successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing demo data: $e');
        }
      }
    }
  }
}