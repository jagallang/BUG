import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/search_history.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../../../core/utils/logger.dart';

// Repository provider
final searchRepositoryProvider = FutureProvider<SearchRepository>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final prefs = await SharedPreferences.getInstance();
  return SearchRepositoryImpl(firestore: firestore, prefs: prefs);
});

// Search state
class SearchState {
  final String query;
  final SearchFilter filter;
  final List<Map<String, dynamic>> results;
  final List<String> history;
  final List<String> popularTerms;
  final bool isLoading;
  final String? error;
  
  const SearchState({
    this.query = '',
    this.filter = const SearchFilter(),
    this.results = const [],
    this.history = const [],
    this.popularTerms = const [],
    this.isLoading = false,
    this.error,
  });
  
  SearchState copyWith({
    String? query,
    SearchFilter? filter,
    List<Map<String, dynamic>>? results,
    List<String>? history,
    List<String>? popularTerms,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      results: results ?? this.results,
      history: history ?? this.history,
      popularTerms: popularTerms ?? this.popularTerms,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Search state provider
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  
  SearchNotifier(this._repository) : super(const SearchState()) {
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    try {
      final history = await _repository.getSearchHistory();
      final popularTerms = await _repository.getPopularSearchTerms();
      
      state = state.copyWith(
        history: history,
        popularTerms: popularTerms,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> search(String query) async {
    AppLogger.debug('🔍 SearchNotifier.search called with: "$query"', 'SearchProvider');
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', results: [], error: null);
      return;
    }
    
    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
    );
    
    try {
      // Add to search history
      await _repository.addSearchHistory(query);
      
      // Perform search
      final results = await _repository.searchMissions(
        query: query,
        categories: state.filter.categories,
        difficulties: state.filter.difficulties,
        minReward: state.filter.minReward,
        maxReward: state.filter.maxReward,
        maxDaysLeft: state.filter.maxDaysLeft,
        hasAvailableSlots: state.filter.hasAvailableSlots,
      );
      
      // Update history
      final history = await _repository.getSearchHistory();
      
      state = state.copyWith(
        results: results,
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  void updateFilter(SearchFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    
    // Re-search with new filter if there's a query
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }
  
  void clearFilter() {
    state = state.copyWith(filter: const SearchFilter());
    
    // Re-search if there's a query
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }
  
  Future<void> removeFromHistory(String query) async {
    try {
      await _repository.removeSearchHistory(query);
      final history = await _repository.getSearchHistory();
      state = state.copyWith(history: history);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> clearHistory() async {
    try {
      await _repository.clearSearchHistory();
      state = state.copyWith(history: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  void clearResults() {
    state = state.copyWith(
      query: '',
      results: [],
      error: null,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.watch(searchRepositoryProvider).value;
  if (repository == null) {
    throw Exception('Repository not available');
  }
  return SearchNotifier(repository);
});