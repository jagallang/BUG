class SearchHistory {
  final String query;
  final DateTime createdAt;

  const SearchHistory({
    required this.query,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      query: json['query'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistory &&
          runtimeType == other.runtimeType &&
          query == other.query;

  @override
  int get hashCode => query.hashCode;

  @override
  String toString() => 'SearchHistory(query: $query, createdAt: $createdAt)';
}

class SearchFilter {
  final List<String> categories;
  final List<String> difficulties;
  final int? minReward;
  final int? maxReward;
  final int? maxDaysLeft;
  final bool? hasAvailableSlots;

  const SearchFilter({
    this.categories = const [],
    this.difficulties = const [],
    this.minReward,
    this.maxReward,
    this.maxDaysLeft,
    this.hasAvailableSlots,
  });

  bool get hasFilters =>
      categories.isNotEmpty ||
      difficulties.isNotEmpty ||
      minReward != null ||
      maxReward != null ||
      maxDaysLeft != null ||
      hasAvailableSlots != null;

  SearchFilter copyWith({
    List<String>? categories,
    List<String>? difficulties,
    int? minReward,
    int? maxReward,
    int? maxDaysLeft,
    bool? hasAvailableSlots,
  }) {
    return SearchFilter(
      categories: categories ?? this.categories,
      difficulties: difficulties ?? this.difficulties,
      minReward: minReward ?? this.minReward,
      maxReward: maxReward ?? this.maxReward,
      maxDaysLeft: maxDaysLeft ?? this.maxDaysLeft,
      hasAvailableSlots: hasAvailableSlots ?? this.hasAvailableSlots,
    );
  }

  SearchFilter clear() {
    return const SearchFilter();
  }

  @override
  String toString() {
    return 'SearchFilter(categories: $categories, difficulties: $difficulties, minReward: $minReward, maxReward: $maxReward, maxDaysLeft: $maxDaysLeft, hasAvailableSlots: $hasAvailableSlots)';
  }
}