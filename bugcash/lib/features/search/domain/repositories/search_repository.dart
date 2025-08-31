abstract class SearchRepository {
  Future<void> addSearchHistory(String query);
  Future<List<String>> getSearchHistory();
  Future<void> clearSearchHistory();
  Future<void> removeSearchHistory(String query);
  
  Future<List<Map<String, dynamic>>> searchMissions({
    required String query,
    List<String> categories = const [],
    List<String> difficulties = const [],
    int? minReward,
    int? maxReward,
    int? maxDaysLeft,
    bool? hasAvailableSlots,
  });
  
  Future<List<String>> getPopularSearchTerms();
}