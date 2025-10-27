class ProviderAppEntity {
  final String id;
  final String providerId;
  final String appName;
  final String appUrl;
  final String? appTestUrl; // 웹 앱 시연 URL (옵션)
  final String description;
  final String category;
  final String status;
  final int totalTesters;
  final int activeTesters;
  final int totalBugs;
  final int resolvedBugs;
  final double progressPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final String? appSerialNumber; // v2.176.0: 앱 등록 고유번호 (형식: APP-{YYMMDD}-{0001})

  const ProviderAppEntity({
    required this.id,
    required this.providerId,
    required this.appName,
    required this.appUrl,
    this.appTestUrl,
    required this.description,
    required this.category,
    required this.status,
    required this.totalTesters,
    required this.activeTesters,
    required this.totalBugs,
    required this.resolvedBugs,
    required this.progressPercentage,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    this.appSerialNumber, // v2.176.0
  });

  ProviderAppEntity copyWith({
    String? id,
    String? providerId,
    String? appName,
    String? appUrl,
    String? appTestUrl,
    String? description,
    String? category,
    String? status,
    int? totalTesters,
    int? activeTesters,
    int? totalBugs,
    int? resolvedBugs,
    double? progressPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? appSerialNumber, // v2.176.0
  }) {
    return ProviderAppEntity(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      appName: appName ?? this.appName,
      appUrl: appUrl ?? this.appUrl,
      appTestUrl: appTestUrl ?? this.appTestUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      totalTesters: totalTesters ?? this.totalTesters,
      activeTesters: activeTesters ?? this.activeTesters,
      totalBugs: totalBugs ?? this.totalBugs,
      resolvedBugs: resolvedBugs ?? this.resolvedBugs,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      appSerialNumber: appSerialNumber ?? this.appSerialNumber, // v2.176.0
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderAppEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProviderAppEntity{id: $id, appName: $appName, status: $status}';
  }
}