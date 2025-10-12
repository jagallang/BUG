import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/utils/logger.dart';
import '../core/error/error_handler.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  static const String missionsCollection = 'missions';
  static const String usersCollection = 'users';
  static const String bugReportsCollection = 'bug_reports';
  static const String pointTransactionsCollection = 'point_transactions';

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
        
        // Add keywords for search functionality
        if (data['keywords'] == null) {
          final title = data['title']?.toString().toLowerCase() ?? '';
          final description = data['description']?.toString().toLowerCase() ?? '';
          final company = data['company']?.toString().toLowerCase() ?? '';
          final category = data['category']?.toString().toLowerCase() ?? '';
          
          data['keywords'] = [
            title,
            description,
            company,
            category,
            ...title.split(' '),
            ...description.split(' '),
            ...company.split(' '),
          ].where((keyword) => keyword.isNotEmpty).toSet().toList();
        }
        
        return data;
      }).toList();
    } catch (e, stackTrace) {
      final error = ErrorHandler.handleError(e, stackTrace);
      AppLogger.error('Failed to get missions', 'Firebase', error);
      throw error;
    }
  }

  static Future<String?> createMission(Map<String, dynamic> missionData) async {
    try {
      missionData['createdAt'] = FieldValue.serverTimestamp();
      missionData['updatedAt'] = FieldValue.serverTimestamp();
      
      final DocumentReference docRef = await _firestore
          .collection(missionsCollection)
          .add(missionData);
      
      AppLogger.info('Mission created with ID: ${docRef.id}', 'Firebase');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create mission', 'Firebase', e);
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
      
      AppLogger.info('Mission updated: $missionId', 'Firebase');
      return true;
    } catch (e) {
      AppLogger.error('Failed to update mission', 'Firebase', e);
      return false;
    }
  }

  static Future<bool> deleteMission(String missionId) async {
    try {
      await _firestore
          .collection(missionsCollection)
          .doc(missionId)
          .delete();
      
      AppLogger.info('Mission deleted: $missionId', 'Firebase');
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete mission', 'Firebase', e);
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
      AppLogger.error('Failed to get user data', 'Firebase', e);
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
      
      AppLogger.info('User data updated: $userId', 'Firebase');
      return true;
    } catch (e) {
      AppLogger.error('Failed to update user data', 'Firebase', e);
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
      
      AppLogger.info('Bug report submitted with ID: ${docRef.id}', 'Firebase');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to submit bug report', 'Firebase', e);
      return null;
    }
  }

  // 파일 업로드
  static Future<String?> uploadFile(File file, String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      AppLogger.info('File uploaded successfully: $path', 'Firebase');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Failed to upload file: $path', 'Firebase', e);
      return null;
    }
  }

  // 포인트 관련 기능
  static Future<bool> addPointTransaction(Map<String, dynamic> transactionData) async {
    try {
      transactionData['createdAt'] = FieldValue.serverTimestamp();
      
      // 트랜잭션 기록 추가
      await _firestore
          .collection(pointTransactionsCollection)
          .add(transactionData);
      
      // 사용자 총 포인트 업데이트
      final userId = transactionData['userId'];
      final amount = transactionData['amount'] as int;
      final type = transactionData['type'] as String;
      
      final increment = type == 'spent' ? -amount : amount;
      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .update({
            'totalPoints': FieldValue.increment(increment),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      AppLogger.info('Point transaction added: ${transactionData['type']} ${transactionData['amount']}', 'Firebase');
      return true;
    } catch (e) {
      AppLogger.error('Failed to add point transaction', 'Firebase', e);
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPointTransactions(String userId, {int limit = 20}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(pointTransactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get point transactions', 'Firebase', e);
      return [];
    }
  }

  static Future<bool> awardPointsForBugReport(String userId, String missionId, int points) async {
    final transactionData = {
      'userId': userId,
      'amount': points,
      'type': 'earned',
      'source': 'bug_report',
      'description': '버그 리포트 제출 보상',
      'missionId': missionId,
    };
    
    return await addPointTransaction(transactionData);
  }

  static Future<bool> awardPointsForMissionCompletion(String userId, String missionId, int points) async {
    final transactionData = {
      'userId': userId,
      'amount': points,
      'type': 'earned',
      'source': 'mission_complete',
      'description': '미션 완료 보상',
      'missionId': missionId,
    };
    
    return await addPointTransaction(transactionData);
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
      AppLogger.error('Failed to get rankings', 'Firebase', e);
      return [];
    }
  }

  // 데모 데이터 초기화 (개발용)
  static Future<void> initializeDemoData() async {
    AppLogger.info('Initializing demo data...', 'Firebase');
      
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
          'downloadLinks': {
            'playStore': 'https://play.google.com/store/apps/details?id=com.shopapp.demo',
            'appStore': 'https://apps.apple.com/app/shopapp-demo/id123456789',
          },
          'requirements': [
            'Android 7.0 이상 또는 iOS 12.0 이상',
            '결제 테스트 경험 선호',
            '상세한 버그 리포트 작성 가능'
          ],
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
          'downloadLinks': {
            'playStore': 'https://play.google.com/store/apps/details?id=com.gamecenter.test',
            'apkDirect': 'https://github.com/gamecenter/releases/download/v2.1.0/gamecenter-release.apk',
          },
          'requirements': [
            '모바일 게임 경험 필수',
            'UI/UX 피드백 제공 가능',
            '스크린샷 첨부 가능'
          ],
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
          'downloadLinks': {
            'playStore': 'https://play.google.com/store/apps/details?id=com.banktest.secure',
            'appStore': 'https://apps.apple.com/app/banktest-secure/id987654321',
            'apkDirect': 'https://banktest.com/downloads/secure-banking-test.apk',
          },
          'requirements': [
            '보안 테스트 경험 필수',
            '금융 앱 사용 경험',
            '상세한 보안 취약점 리포트 작성',
            'OWASP 모바일 보안 가이드 숙지'
          ],
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

        AppLogger.info('Demo data initialized successfully', 'Firebase');
      } catch (e) {
        AppLogger.error('Failed to initialize demo data', 'Firebase', e);
      }
  }
}