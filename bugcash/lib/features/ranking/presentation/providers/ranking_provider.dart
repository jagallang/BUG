import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_ranking.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../../data/repositories/ranking_repository_impl.dart';

// Repository provider
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return RankingRepositoryImpl(firestore: firestore);
});

// Ranking state
class RankingState {
  final List<UserRanking> rankings;
  final UserRanking? currentUserRanking;
  final RankingFilter filter;
  final Map<String, dynamic> stats;
  final List<String> availableCategories;
  final bool isLoading;
  final String? error;
  
  const RankingState({
    this.rankings = const [],
    this.currentUserRanking,
    this.filter = const RankingFilter(),
    this.stats = const {},
    this.availableCategories = const [],
    this.isLoading = false,
    this.error,
  });
  
  RankingState copyWith({
    List<UserRanking>? rankings,
    UserRanking? currentUserRanking,
    RankingFilter? filter,
    Map<String, dynamic>? stats,
    List<String>? availableCategories,
    bool? isLoading,
    String? error,
  }) {
    return RankingState(
      rankings: rankings ?? this.rankings,
      currentUserRanking: currentUserRanking ?? this.currentUserRanking,
      filter: filter ?? this.filter,
      stats: stats ?? this.stats,
      availableCategories: availableCategories ?? this.availableCategories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Ranking state notifier
class RankingNotifier extends StateNotifier<RankingState> {
  final RankingRepository _repository;
  
  RankingNotifier(this._repository) : super(const RankingState()) {
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    await Future.wait([
      loadRankings(),
      loadStats(),
      loadCategories(),
    ]);
  }
  
  Future<void> loadRankings({RankingFilter? newFilter}) async {
    final filter = newFilter ?? state.filter;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      filter: filter,
    );
    
    try {
      final rankings = await _repository.getRankings(
        period: filter.period,
        category: filter.category,
        limit: filter.limit,
      );
      
      state = state.copyWith(
        rankings: rankings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> loadUserRanking(String userId) async {
    try {
      final userRanking = await _repository.getUserRanking(
        userId,
        period: state.filter.period,
        category: state.filter.category,
      );
      
      state = state.copyWith(currentUserRanking: userRanking);
    } catch (e) {
      // Silently fail for user ranking
    }
  }
  
  Future<void> loadStats() async {
    try {
      final stats = await _repository.getRankingStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Use default stats on error
    }
  }
  
  Future<void> loadCategories() async {
    try {
      final categories = await _repository.getAvailableCategories();
      state = state.copyWith(availableCategories: categories);
    } catch (e) {
      // Use default categories on error
    }
  }
  
  void updateFilter({
    String? period,
    String? category,
    int? limit,
  }) {
    final newFilter = state.filter.copyWith(
      period: period,
      category: category,
      limit: limit,
    );
    
    loadRankings(newFilter: newFilter);
  }
  
  Future<void> refresh() async {
    await _loadInitialData();
  }
  
  Future<void> updateUserPoints(String userId, int points, {String? category}) async {
    try {
      await _repository.updateUserRanking(
        userId,
        points: points,
        category: category,
      );
      
      // Refresh rankings after update
      await loadRankings();
      await loadUserRanking(userId);
    } catch (e) {
      // Silently fail for demo purposes
    }
  }
}

// Provider for ranking state
final rankingProvider = StateNotifierProvider<RankingNotifier, RankingState>((ref) {
  final repository = ref.watch(rankingRepositoryProvider);
  return RankingNotifier(repository);
});

// Provider for top 3 rankings (for widgets that only need top performers)
final top3RankingsProvider = Provider<List<UserRanking>>((ref) {
  final rankings = ref.watch(rankingProvider).rankings;
  return rankings.take(3).toList();
});

// Provider for current user rank (requires user ID)
final currentUserRankProvider = FutureProvider.family<UserRanking?, String>((ref, userId) async {
  final repository = ref.watch(rankingRepositoryProvider);
  final filter = ref.watch(rankingProvider).filter;
  
  return await repository.getUserRanking(
    userId,
    period: filter.period,
    category: filter.category,
  );
});