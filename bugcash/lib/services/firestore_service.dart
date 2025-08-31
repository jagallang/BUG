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
      print('Error getting user: $e');
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
      final data = doc.data() as Map<String, dynamic>;
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
  Future<void> initializeDatabase() async {
    // Check if data already exists
    final missionsSnapshot = await _db.collection(missionsCollection).limit(1).get();
    if (missionsSnapshot.docs.isNotEmpty) {
      print('Database already initialized');
      return;
    }

    // Add sample missions
    final sampleMissions = [
      {
        'title': '쇼핑앱 결제 테스트',
        'appName': 'ShopEasy',
        'category': 'E-commerce',
        'status': 'active',
        'testers': 15,
        'maxTesters': 20,
        'reward': 8000,
        'description': '결제 시스템의 다양한 시나리오를 테스트해주세요.',
        'requirements': ['안드로이드 8.0 이상', '신용카드 등록', '앱스토어에서 다운로드'],
        'duration': 14,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'demo-provider',
        'bugs': 3,
        'isHot': true,
        'isNew': false,
      },
      {
        'title': '음식 주문 앱 UI 테스트',
        'appName': 'FoodDelivery',
        'category': 'Food & Drink',
        'status': 'completed',
        'testers': 25,
        'maxTesters': 25,
        'reward': 6000,
        'description': '사용자 인터페이스의 직관성과 편의성을 평가해주세요.',
        'requirements': ['iOS 14.0 이상', '위치 서비스 허용'],
        'duration': 7,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'demo-provider',
        'bugs': 7,
        'isHot': false,
        'isNew': false,
      },
      {
        'title': '게임 앱 성능 테스트',
        'appName': 'PuzzleGame',
        'category': 'Games',
        'status': 'draft',
        'testers': 0,
        'maxTesters': 30,
        'reward': 12000,
        'description': '다양한 기기에서의 게임 성능을 확인해주세요.',
        'requirements': ['RAM 4GB 이상', '저장공간 2GB 이상'],
        'duration': 21,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'demo-provider',
        'bugs': 0,
        'isHot': false,
        'isNew': true,
      },
    ];

    final batch = _db.batch();
    for (var mission in sampleMissions) {
      final docRef = _db.collection(missionsCollection).doc();
      batch.set(docRef, mission);
    }

    await batch.commit();
    print('Sample data initialized successfully');
  }
}