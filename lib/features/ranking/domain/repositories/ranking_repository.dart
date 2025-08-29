import '../models/user_ranking.dart';

abstract class RankingRepository {
  Future<List<UserRanking>> getRankings({
    String period = 'all',
    String category = 'all',
    int limit = 50,
  });
  
  Future<UserRanking?> getUserRanking(String userId, {
    String period = 'all',
    String category = 'all',
  });
  
  Future<void> updateUserRanking(String userId, {
    required int points,
    String? category,
  });
  
  Future<List<String>> getAvailableCategories();
  
  Future<Map<String, dynamic>> getRankingStats();
}