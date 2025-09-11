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
    print('🚀 searchMissions called with query: "$query"');
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
    
    // 공급자가 등록한 앱들도 검색 결과에 포함
    await _includeProviderApps(results, query);
    
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
    
    // Client-side text search fallback (provider apps are already filtered)
    if (query.isNotEmpty) {
      final searchTerm = query.toLowerCase();
      results = results.where((mission) {
        // Skip filtering for provider apps as they're already filtered
        if (mission['isProviderApp'] == true) {
          return true;
        }
        
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

  // 공급자가 등록한 앱들을 검색 결과에 포함하는 메서드
  Future<void> _includeProviderApps(List<Map<String, dynamic>> results, String query) async {
    try {
      print('🔍 Searching provider_apps collection for query: "$query"');
      
      final providerAppsSnapshot = await _firestore
          .collection('provider_apps')
          .where('status', isEqualTo: 'active')
          .get();
      
      print('📱 Found ${providerAppsSnapshot.docs.length} provider apps');
      
      final providerApps = providerAppsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            print('📝 Provider app: ${data['appName']} - ${data['description']}');
            return data;
          })
          .where((app) {
            if (query.isEmpty) return true;
            
            final searchTerm = query.toLowerCase();
            final appName = (app['appName'] as String? ?? '').toLowerCase();
            final description = (app['description'] as String? ?? '').toLowerCase();
            final category = (app['category'] as String? ?? '').toLowerCase();
            
            final matches = appName.contains(searchTerm) ||
                   description.contains(searchTerm) ||
                   category.contains(searchTerm);
            
            print('🔎 App "${app['appName']}" matches query "$query": $matches');
            return matches;
          })
          .map((app) => _convertProviderAppToMissionFormat(app))
          .toList();
      
      print('✅ Adding ${providerApps.length} provider apps to search results');
      results.addAll(providerApps);
    } catch (e) {
      // 에러가 발생해도 기존 검색 결과는 유지
      print('❌ Error including provider apps: $e');
    }
  }

  // 공급자 앱 데이터를 미션 포맷으로 변환
  Map<String, dynamic> _convertProviderAppToMissionFormat(Map<String, dynamic> app) {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30)); // 30일 후 종료
    
    return {
      'id': 'provider_app_${app['id']}',
      'title': '${app['appName']} 테스팅',
      'description': app['description'] ?? '앱 테스팅 및 피드백 제공',
      'company': '공급자',
      'category': app['category'] ?? 'Other',
      'type': 'app_testing',
      'difficulty': 'medium',
      'reward': 5000, // 기본 리워드
      'maxParticipants': 50,
      'currentParticipants': app['activeTesters'] ?? 0,
      'status': 'active',
      'createdAt': app['createdAt'] ?? Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'requirements': ['앱 설치 가능', '피드백 작성'],
      'tags': ['앱테스팅', app['category']?.toString().toLowerCase() ?? 'other'],
      'isProviderApp': true, // 공급자 앱 구분용 플래그
      'originalAppData': app, // 원본 앱 데이터 보존
    };
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