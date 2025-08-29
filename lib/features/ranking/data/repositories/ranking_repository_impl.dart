import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_ranking.dart';
import '../../domain/repositories/ranking_repository.dart';

class RankingRepositoryImpl implements RankingRepository {
  final FirebaseFirestore _firestore;
  
  RankingRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;
  
  @override
  Future<List<UserRanking>> getRankings({
    String period = 'all',
    String category = 'all',
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('user_rankings');
      
      // Apply category filter
      if (category != 'all') {
        query = query.where('categories', arrayContains: category);
      }
      
      // Apply period filter
      if (period != 'all') {
        final now = DateTime.now();
        DateTime startDate;
        
        switch (period) {
          case 'daily':
            startDate = DateTime(now.year, now.month, now.day);
            break;
          case 'weekly':
            startDate = now.subtract(Duration(days: now.weekday - 1));
            break;
          case 'monthly':
            startDate = DateTime(now.year, now.month, 1);
            break;
          default:
            startDate = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        query = query.where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      // Order by total points and limit results
      query = query.orderBy('totalPoints', descending: true).limit(limit);
      
      final snapshot = await query.get();
      
      final rankings = snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final data = doc.data();
        data['userId'] = doc.id;
        data['rank'] = index + 1; // Assign rank based on order
        return UserRanking.fromJson(data);
      }).toList();
      
      return rankings;
    } catch (e) {
      // Return demo data if Firebase fails
      return _getDemoRankings(category: category, limit: limit);
    }
  }
  
  @override
  Future<UserRanking?> getUserRanking(String userId, {
    String period = 'all',
    String category = 'all',
  }) async {
    try {
      final doc = await _firestore.collection('user_rankings').doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      data['userId'] = doc.id;
      
      // Calculate user's rank by counting users with higher points
      final higherRankedCount = await _firestore
          .collection('user_rankings')
          .where('totalPoints', isGreaterThan: data['totalPoints'])
          .count()
          .get();
      
      data['rank'] = higherRankedCount.count! + 1;
      
      return UserRanking.fromJson(data);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> updateUserRanking(String userId, {
    required int points,
    String? category,
  }) async {
    try {
      final docRef = _firestore.collection('user_rankings').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data()!;
          final currentPoints = data['totalPoints'] ?? 0;
          final currentMissions = data['completedMissions'] ?? 0;
          final categoryPoints = Map<String, int>.from(data['categoryPoints'] ?? {});
          
          // Update category points if specified
          if (category != null) {
            categoryPoints[category] = (categoryPoints[category] ?? 0) + points;
          }
          
          transaction.update(docRef, {
            'totalPoints': currentPoints + points,
            'completedMissions': currentMissions + 1,
            'categoryPoints': categoryPoints,
            'lastActive': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new ranking entry
          final categoryPoints = <String, int>{};
          if (category != null) {
            categoryPoints[category] = points;
          }
          
          transaction.set(docRef, {
            'totalPoints': points,
            'completedMissions': 1,
            'categoryPoints': categoryPoints,
            'lastActive': FieldValue.serverTimestamp(),
            'username': 'User_$userId', // Default username
          });
        }
      });
    } catch (e) {
      // Silently fail for demo purposes
    }
  }
  
  @override
  Future<List<String>> getAvailableCategories() async {
    return [
      'all',
      '웹사이트',
      '모바일앱',
      '게임',
      'API',
      '데스크톱',
      '보안',
      'UI/UX',
    ];
  }
  
  @override
  Future<Map<String, dynamic>> getRankingStats() async {
    try {
      final snapshot = await _firestore.collection('user_rankings').get();
      
      return {
        'totalUsers': snapshot.docs.length,
        'totalPoints': snapshot.docs.fold<int>(
          0, 
          (total, doc) => total + (doc.data()['totalPoints'] ?? 0) as int,
        ),
        'totalMissions': snapshot.docs.fold<int>(
          0,
          (total, doc) => total + (doc.data()['completedMissions'] ?? 0) as int,
        ),
      };
    } catch (e) {
      return {
        'totalUsers': 1250,
        'totalPoints': 45000,
        'totalMissions': 890,
      };
    }
  }
  
  List<UserRanking> _getDemoRankings({String category = 'all', int limit = 50}) {
    final demoData = [
      {
        'userId': 'demo_1',
        'username': 'BugHunter_Pro',
        'totalPoints': 15420,
        'completedMissions': 89,
        'badge': 'gold',
        'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
        'categoryPoints': {'웹사이트': 8200, '모바일앱': 4120, '보안': 3100},
      },
      {
        'userId': 'demo_2', 
        'username': 'SecurityExpert',
        'totalPoints': 12890,
        'completedMissions': 67,
        'badge': 'silver',
        'lastActive': DateTime.now().subtract(const Duration(hours: 5)),
        'categoryPoints': {'보안': 9890, '웹사이트': 2000, 'API': 1000},
      },
      {
        'userId': 'demo_3',
        'username': 'MobileTestPro',
        'totalPoints': 11340,
        'completedMissions': 78,
        'badge': 'bronze',
        'lastActive': DateTime.now().subtract(const Duration(hours: 1)),
        'categoryPoints': {'모바일앱': 8340, 'UI/UX': 2000, '게임': 1000},
      },
      {
        'userId': 'demo_4',
        'username': 'WebAnalyst',
        'totalPoints': 9870,
        'completedMissions': 56,
        'badge': 'rising_star',
        'lastActive': DateTime.now().subtract(const Duration(minutes: 30)),
        'categoryPoints': {'웹사이트': 6870, 'API': 2000, 'UI/UX': 1000},
      },
      {
        'userId': 'demo_5',
        'username': 'GameTester_X',
        'totalPoints': 8560,
        'completedMissions': 45,
        'badge': 'bug_hunter',
        'lastActive': DateTime.now().subtract(const Duration(hours: 8)),
        'categoryPoints': {'게임': 7560, '모바일앱': 1000},
      },
      {
        'userId': 'demo_6',
        'username': 'UIExpert',
        'totalPoints': 7890,
        'completedMissions': 52,
        'lastActive': DateTime.now().subtract(const Duration(hours: 12)),
        'categoryPoints': {'UI/UX': 6890, '웹사이트': 1000},
      },
      {
        'userId': 'demo_7',
        'username': 'APITester',
        'totalPoints': 6780,
        'completedMissions': 38,
        'lastActive': DateTime.now().subtract(const Duration(days: 1)),
        'categoryPoints': {'API': 5780, '웹사이트': 1000},
      },
      {
        'userId': 'demo_8',
        'username': 'QualityAssurance',
        'totalPoints': 5670,
        'completedMissions': 34,
        'lastActive': DateTime.now().subtract(const Duration(days: 2)),
        'categoryPoints': {'웹사이트': 3670, '모바일앱': 2000},
      },
    ];
    
    return demoData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return UserRanking(
        userId: data['userId'] as String,
        username: data['username'] as String,
        totalPoints: data['totalPoints'] as int,
        completedMissions: data['completedMissions'] as int,
        rank: index + 1,
        badge: data['badge'] as String?,
        lastActive: data['lastActive'] as DateTime,
        categoryPoints: Map<String, int>.from(data['categoryPoints'] as Map),
      );
    }).take(limit).toList();
  }
}