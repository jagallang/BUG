import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  
  SearchRepositoryImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  }) : _firestore = firestore, _prefs = prefs;
  
  static const String _searchHistoryKey = 'search_history';
  
  @override
  Future<void> addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final history = await getSearchHistory();
    
    // Remove if already exists
    history.remove(query);
    
    // Add to beginning
    history.insert(0, query);
    
    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeLast();
    }
    
    await _prefs.setStringList(_searchHistoryKey, history);
  }
  
  @override
  Future<List<String>> getSearchHistory() async {
    return _prefs.getStringList(_searchHistoryKey) ?? [];
  }
  
  @override
  Future<void> clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
  }
  
  @override
  Future<void> removeSearchHistory(String query) async {
    final history = await getSearchHistory();
    history.remove(query);
    await _prefs.setStringList(_searchHistoryKey, history);
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchMissions({
    required String query,
    List<String> categories = const [],
    List<String> difficulties = const [],
    int? minReward,
    int? maxReward,
    int? maxDaysLeft,
    bool? hasAvailableSlots,
  }) async {
    Query<Map<String, dynamic>> queryRef = _firestore.collection('missions');
    
    // Text search (simplified - Firebase doesn't have full-text search)
    if (query.isNotEmpty) {
      queryRef = queryRef.where('keywords', arrayContainsAny: [
        query.toLowerCase(),
        ...query.toLowerCase().split(' '),
      ]);
    }
    
    // Category filter
    if (categories.isNotEmpty) {
      queryRef = queryRef.where('category', whereIn: categories);
    }
    
    // Difficulty filter
    if (difficulties.isNotEmpty) {
      queryRef = queryRef.where('difficulty', whereIn: difficulties);
    }
    
    // Reward range filter
    if (minReward != null) {
      queryRef = queryRef.where('reward', isGreaterThanOrEqualTo: minReward);
    }
    if (maxReward != null) {
      queryRef = queryRef.where('reward', isLessThanOrEqualTo: maxReward);
    }
    
    // Available slots filter
    if (hasAvailableSlots == true) {
      queryRef = queryRef.where('currentParticipants', isLessThan: FieldPath.fromString('maxParticipants'));
    }
    
    final snapshot = await queryRef.limit(50).get();
    List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    
    // Client-side filtering for days left
    if (maxDaysLeft != null) {
      final now = DateTime.now();
      results = results.where((mission) {
        final endDate = (mission['endDate'] as Timestamp?)?.toDate();
        if (endDate == null) return false;
        final daysLeft = endDate.difference(now).inDays;
        return daysLeft <= maxDaysLeft;
      }).toList();
    }
    
    // Client-side text search fallback
    if (query.isNotEmpty) {
      final searchTerm = query.toLowerCase();
      results = results.where((mission) {
        final title = (mission['title'] as String? ?? '').toLowerCase();
        final description = (mission['description'] as String? ?? '').toLowerCase();
        final company = (mission['company'] as String? ?? '').toLowerCase();
        
        return title.contains(searchTerm) ||
               description.contains(searchTerm) ||
               company.contains(searchTerm);
      }).toList();
    }
    
    return results;
  }
  
  @override
  Future<List<String>> getPopularSearchTerms() async {
    try {
      final snapshot = await _firestore
          .collection('search_analytics')
          .orderBy('count', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['term'] as String)
          .toList();
    } catch (e) {
      // Return default popular terms if analytics not available
      return [
        '버그헌팅',
        '모바일앱',
        '웹사이트',
        '보안테스트',
        'UI/UX',
        '게임',
        '전자상거래',
        '금융앱',
        '교육앱',
        '소셜미디어',
      ];
    }
  }
}