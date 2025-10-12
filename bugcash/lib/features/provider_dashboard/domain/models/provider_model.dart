import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProviderStatus {
  pending,    // 승인 대기중
  approved,   // 승인됨
  suspended,  // 일시정지
  rejected,   // 거부됨
}

enum AppStatus {
  draft,      // 초안
  review,     // 검토중
  active,     // 활성
  paused,     // 일시정지
  completed,  // 완료
  cancelled,  // 취소됨
}

enum AppType {
  android,    // 안드로이드
  ios,        // iOS
  web,        // 웹
  desktop,    // 데스크톱
}

enum AppCategory {
  productivity,   // 생산성
  entertainment,  // 엔터테인먼트
  education,      // 교육
  game,          // 게임
  social,        // 소셜
  finance,       // 금융
  health,        // 건강
  utility,       // 유틸리티
  shopping,      // 쇼핑
  travel,        // 여행
}

enum ContentRating {
  everyone,   // 전체 이용가
  teen,       // 12세 이상
  mature,     // 17세 이상
  adult,      // 성인
}

class ProviderModel extends Equatable {
  final String id;
  final String companyName;
  final String contactEmail;
  final String contactPerson;
  final String phoneNumber;
  final String? website;
  final String? description;
  final ProviderStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final List<String> appIds;
  final Map<String, dynamic> settings;
  final int totalBudget;
  final int usedBudget;
  final int totalMissions;
  final int activeMissions;
  final double averageRating;
  final int totalTesters;

  const ProviderModel({
    required this.id,
    required this.companyName,
    required this.contactEmail,
    required this.contactPerson,
    required this.phoneNumber,
    this.website,
    this.description,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    required this.appIds,
    required this.settings,
    required this.totalBudget,
    required this.usedBudget,
    required this.totalMissions,
    required this.activeMissions,
    required this.averageRating,
    required this.totalTesters,
  });

  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderModel(
      id: doc.id,
      companyName: data['companyName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      website: data['website'],
      description: data['description'],
      status: ProviderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProviderStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
      appIds: List<String>.from(data['appIds'] ?? []),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      totalBudget: data['totalBudget'] ?? 0,
      usedBudget: data['usedBudget'] ?? 0,
      totalMissions: data['totalMissions'] ?? 0,
      activeMissions: data['activeMissions'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalTesters: data['totalTesters'] ?? 0,
    );
  }

  factory ProviderModel.fromMap(String id, Map<String, dynamic> data) {
    return ProviderModel(
      id: id,
      companyName: data['companyName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      website: data['website'],
      description: data['description'],
      status: ProviderStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => ProviderStatus.pending,
      ),
      createdAt: data['createdAt'] is String 
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      approvedAt: data['approvedAt'] is String 
          ? DateTime.tryParse(data['approvedAt'])
          : null,
      approvedBy: data['approvedBy'],
      appIds: List<String>.from(data['appIds'] ?? []),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      totalBudget: data['totalBudget'] ?? 0,
      usedBudget: data['usedBudget'] ?? 0,
      totalMissions: data['totalMissions'] ?? 0,
      activeMissions: data['activeMissions'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalTesters: data['totalTesters'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyName': companyName,
      'contactEmail': contactEmail,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'website': website,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'appIds': appIds,
      'settings': settings,
      'totalBudget': totalBudget,
      'usedBudget': usedBudget,
      'totalMissions': totalMissions,
      'activeMissions': activeMissions,
      'averageRating': averageRating,
      'totalTesters': totalTesters,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? companyName,
    String? contactEmail,
    String? contactPerson,
    String? phoneNumber,
    String? website,
    String? description,
    ProviderStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    List<String>? appIds,
    Map<String, dynamic>? settings,
    int? totalBudget,
    int? usedBudget,
    int? totalMissions,
    int? activeMissions,
    double? averageRating,
    int? totalTesters,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPerson: contactPerson ?? this.contactPerson,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      appIds: appIds ?? this.appIds,
      settings: settings ?? this.settings,
      totalBudget: totalBudget ?? this.totalBudget,
      usedBudget: usedBudget ?? this.usedBudget,
      totalMissions: totalMissions ?? this.totalMissions,
      activeMissions: activeMissions ?? this.activeMissions,
      averageRating: averageRating ?? this.averageRating,
      totalTesters: totalTesters ?? this.totalTesters,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyName,
    contactEmail,
    contactPerson,
    phoneNumber,
    website,
    description,
    status,
    createdAt,
    approvedAt,
    approvedBy,
    appIds,
    settings,
    totalBudget,
    usedBudget,
    totalMissions,
    activeMissions,
    averageRating,
    totalTesters,
  ];
}

class AppModel extends Equatable {
  final String id;
  final String providerId;
  final String appName;
  final String description;
  final AppCategory category;
  final AppType type;
  final String? packageName;
  final String? version;
  final String? shortDescription;
  final String? developer;
  final String? contactEmail;
  final String? website;
  final String? privacyPolicyUrl;
  final ContentRating? contentRating;
  final double? targetAge;
  final bool isFreemium;
  final bool containsAds;
  final bool requiresPermissions;
  final List<String> keywords;
  final String? iconUrl;
  final List<String> screenshotUrls;
  final String? binaryUrl;
  final String? releaseNotes;
  final String? bundleId;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final String? apkUrl;
  final AppStatus status;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final int totalMissions;
  final int activeMissions;
  final int completedMissions;
  final int totalBugReports;
  final int totalTesters;
  final double averageRating;
  final int totalRatings;
  final int totalDownloads;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const AppModel({
    required this.id,
    required this.providerId,
    required this.appName,
    required this.description,
    required this.category,
    required this.type,
    this.packageName,
    this.version,
    this.shortDescription,
    this.developer,
    this.contactEmail,
    this.website,
    this.privacyPolicyUrl,
    this.contentRating,
    this.targetAge,
    this.isFreemium = false,
    this.containsAds = false,
    this.requiresPermissions = false,
    this.keywords = const [],
    this.iconUrl,
    required this.screenshotUrls,
    this.binaryUrl,
    this.releaseNotes,
    this.bundleId,
    this.playStoreUrl,
    this.appStoreUrl,
    this.apkUrl,
    required this.status,
    required this.createdAt,
    this.lastUpdated,
    required this.totalMissions,
    required this.activeMissions,
    required this.completedMissions,
    required this.totalBugReports,
    required this.totalTesters,
    required this.averageRating,
    required this.totalRatings,
    required this.totalDownloads,
    this.updatedAt,
    required this.metadata,
  });

  factory AppModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppModel(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      appName: data['appName'] ?? '',
      description: data['description'] ?? '',
      category: AppCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => AppCategory.productivity,
      ),
      type: AppType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AppType.android,
      ),
      version: data['version'],
      shortDescription: data['shortDescription'],
      developer: data['developer'],
      contactEmail: data['contactEmail'],
      website: data['website'],
      privacyPolicyUrl: data['privacyPolicyUrl'],
      contentRating: data['contentRating'] != null
          ? ContentRating.values.firstWhere(
              (e) => e.name == data['contentRating'],
              orElse: () => ContentRating.everyone,
            )
          : null,
      targetAge: data['targetAge']?.toDouble(),
      isFreemium: data['isFreemium'] ?? false,
      containsAds: data['containsAds'] ?? false,
      requiresPermissions: data['requiresPermissions'] ?? false,
      keywords: List<String>.from(data['keywords'] ?? []),
      screenshotUrls: List<String>.from(data['screenshotUrls'] ?? []),
      binaryUrl: data['binaryUrl'],
      releaseNotes: data['releaseNotes'],
      packageName: data['packageName'],
      bundleId: data['bundleId'],
      playStoreUrl: data['playStoreUrl'],
      appStoreUrl: data['appStoreUrl'],
      apkUrl: data['apkUrl'],
      status: AppStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AppStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      totalRatings: data['totalRatings'] ?? 0,
      totalDownloads: data['totalDownloads'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      iconUrl: data['iconUrl'],
      totalMissions: data['totalMissions'] ?? 0,
      activeMissions: data['activeMissions'] ?? 0,
      completedMissions: data['completedMissions'] ?? 0,
      totalBugReports: data['totalBugReports'] ?? 0,
      totalTesters: data['totalTesters'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory AppModel.fromMap(String id, Map<String, dynamic> data) {
    return AppModel(
      id: id,
      providerId: data['providerId'] ?? '',
      appName: data['name'] ?? '',
      description: data['description'] ?? '',
      category: AppCategory.values.firstWhere(
        (e) => e.name == (data['category'] ?? 'productivity'),
        orElse: () => AppCategory.productivity,
      ),
      type: AppType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'android'),
        orElse: () => AppType.android,
      ),
      version: data['version'] ?? '1.0.0',
      shortDescription: data['shortDescription'],
      developer: data['developer'],
      contactEmail: data['contactEmail'],
      website: data['website'],
      privacyPolicyUrl: data['privacyPolicyUrl'],
      contentRating: data['contentRating'] != null
          ? ContentRating.values.firstWhere(
              (e) => e.name == data['contentRating'],
              orElse: () => ContentRating.everyone,
            )
          : null,
      targetAge: data['targetAge']?.toDouble(),
      isFreemium: data['isFreemium'] ?? false,
      containsAds: data['containsAds'] ?? false,
      requiresPermissions: data['requiresPermissions'] ?? false,
      keywords: List<String>.from(data['keywords'] ?? []),
      screenshotUrls: List<String>.from(data['screenshots'] ?? []),
      binaryUrl: data['binaryUrl'],
      releaseNotes: data['releaseNotes'],
      packageName: data['packageName'],
      bundleId: data['bundleId'],
      playStoreUrl: data['playStoreUrl'],
      appStoreUrl: data['appStoreUrl'],
      apkUrl: data['apkUrl'],
      status: AppStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'draft'),
        orElse: () => AppStatus.draft,
      ),
      createdAt: data['createdAt'] is String 
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] is String 
          ? DateTime.tryParse(data['lastUpdated'])
          : null,
      totalRatings: data['totalRatings'] ?? 0,
      totalDownloads: data['totalDownloads'] ?? 0,
      updatedAt: data['updatedAt'] is String 
          ? DateTime.tryParse(data['updatedAt'])
          : null,
      iconUrl: data['iconUrl'],
      totalMissions: data['totalMissions'] ?? 0,
      activeMissions: data['activeMissions'] ?? 0,
      completedMissions: data['completedMissions'] ?? 0,
      totalBugReports: data['totalBugReports'] ?? 0,
      totalTesters: data['totalTesters'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'name': appName,
      'description': description,
      'category': category.name,
      'type': type.name,
      'version': version,
      'shortDescription': shortDescription,
      'developer': developer,
      'contactEmail': contactEmail,
      'website': website,
      'privacyPolicyUrl': privacyPolicyUrl,
      'contentRating': contentRating?.name,
      'targetAge': targetAge,
      'isFreemium': isFreemium,
      'containsAds': containsAds,
      'requiresPermissions': requiresPermissions,
      'keywords': keywords,
      'screenshots': screenshotUrls,
      'binaryUrl': binaryUrl,
      'releaseNotes': releaseNotes,
      'packageName': packageName,
      'bundleId': bundleId,
      'playStoreUrl': playStoreUrl,
      'appStoreUrl': appStoreUrl,
      'apkUrl': apkUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'totalRatings': totalRatings,
      'totalDownloads': totalDownloads,
      'updatedAt': updatedAt?.toIso8601String(),
      'iconUrl': iconUrl,
      'totalMissions': totalMissions,
      'activeMissions': activeMissions,
      'completedMissions': completedMissions,
      'totalBugReports': totalBugReports,
      'totalTesters': totalTesters,
      'averageRating': averageRating,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'appName': appName,
      'description': description,
      'category': category.name,
      'type': type.name,
      'version': version,
      'shortDescription': shortDescription,
      'developer': developer,
      'contactEmail': contactEmail,
      'website': website,
      'privacyPolicyUrl': privacyPolicyUrl,
      'contentRating': contentRating?.name,
      'targetAge': targetAge,
      'isFreemium': isFreemium,
      'containsAds': containsAds,
      'requiresPermissions': requiresPermissions,
      'keywords': keywords,
      'screenshotUrls': screenshotUrls,
      'binaryUrl': binaryUrl,
      'releaseNotes': releaseNotes,
      'packageName': packageName,
      'bundleId': bundleId,
      'playStoreUrl': playStoreUrl,
      'appStoreUrl': appStoreUrl,
      'apkUrl': apkUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'totalRatings': totalRatings,
      'totalDownloads': totalDownloads,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'iconUrl': iconUrl,
      'totalMissions': totalMissions,
      'activeMissions': activeMissions,
      'completedMissions': completedMissions,
      'totalBugReports': totalBugReports,
      'totalTesters': totalTesters,
      'averageRating': averageRating,
      'metadata': metadata,
    };
  }

  AppModel copyWith({
    String? id,
    String? providerId,
    String? appName,
    String? description,
    AppCategory? category,
    AppType? type,
    String? version,
    String? shortDescription,
    String? developer,
    String? contactEmail,
    String? website,
    String? privacyPolicyUrl,
    ContentRating? contentRating,
    double? targetAge,
    bool? isFreemium,
    bool? containsAds,
    bool? requiresPermissions,
    List<String>? keywords,
    List<String>? screenshotUrls,
    String? binaryUrl,
    String? releaseNotes,
    String? packageName,
    String? bundleId,
    String? playStoreUrl,
    String? appStoreUrl,
    String? apkUrl,
    AppStatus? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
    int? totalRatings,
    int? totalDownloads,
    DateTime? updatedAt,
    String? iconUrl,
    int? totalMissions,
    int? activeMissions,
    int? completedMissions,
    int? totalBugReports,
    int? totalTesters,
    double? averageRating,
    Map<String, dynamic>? metadata,
  }) {
    return AppModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      appName: appName ?? this.appName,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      version: version ?? this.version,
      shortDescription: shortDescription ?? this.shortDescription,
      developer: developer ?? this.developer,
      contactEmail: contactEmail ?? this.contactEmail,
      website: website ?? this.website,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      contentRating: contentRating ?? this.contentRating,
      targetAge: targetAge ?? this.targetAge,
      isFreemium: isFreemium ?? this.isFreemium,
      containsAds: containsAds ?? this.containsAds,
      requiresPermissions: requiresPermissions ?? this.requiresPermissions,
      keywords: keywords ?? this.keywords,
      screenshotUrls: screenshotUrls ?? this.screenshotUrls,
      binaryUrl: binaryUrl ?? this.binaryUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      packageName: packageName ?? this.packageName,
      bundleId: bundleId ?? this.bundleId,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      appStoreUrl: appStoreUrl ?? this.appStoreUrl,
      apkUrl: apkUrl ?? this.apkUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalRatings: totalRatings ?? this.totalRatings,
      totalDownloads: totalDownloads ?? this.totalDownloads,
      updatedAt: updatedAt ?? this.updatedAt,
      iconUrl: iconUrl ?? this.iconUrl,
      totalMissions: totalMissions ?? this.totalMissions,
      activeMissions: activeMissions ?? this.activeMissions,
      completedMissions: completedMissions ?? this.completedMissions,
      totalBugReports: totalBugReports ?? this.totalBugReports,
      totalTesters: totalTesters ?? this.totalTesters,
      averageRating: averageRating ?? this.averageRating,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    providerId,
    appName,
    description,
    category,
    packageName,
    bundleId,
    playStoreUrl,
    appStoreUrl,
    apkUrl,
    status,
    createdAt,
    lastUpdated,
    category,
    type,
    version,
    shortDescription,
    developer,
    contactEmail,
    website,
    privacyPolicyUrl,
    contentRating,
    targetAge,
    isFreemium,
    containsAds,
    requiresPermissions,
    keywords,
    screenshotUrls,
    binaryUrl,
    releaseNotes,
    totalRatings,
    totalDownloads,
    updatedAt,
    iconUrl,
    totalMissions,
    activeMissions,
    completedMissions,
    totalBugReports,
    totalTesters,
    averageRating,
    metadata,
  ];
}

class DashboardStats extends Equatable {
  final int totalApps;
  final int activeApps;
  final int totalMissions;
  final int activeMissions;
  final int completedMissions;
  final int totalBugReports;
  final int pendingBugReports;
  final int resolvedBugReports;
  final int totalTesters;
  final int activeTesters;
  final double totalRevenue;
  final double averageAppRating;
  final Map<String, int> missionsByStatus;
  final Map<String, int> bugReportsByPriority;
  final List<Map<String, dynamic>> recentActivities;
  final Map<String, double> performanceMetrics;

  const DashboardStats({
    required this.totalApps,
    required this.activeApps,
    required this.totalMissions,
    required this.activeMissions,
    required this.completedMissions,
    required this.totalBugReports,
    required this.pendingBugReports,
    required this.resolvedBugReports,
    required this.totalTesters,
    required this.activeTesters,
    required this.totalRevenue,
    required this.averageAppRating,
    required this.missionsByStatus,
    required this.bugReportsByPriority,
    required this.recentActivities,
    required this.performanceMetrics,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> data) {
    return DashboardStats(
      totalApps: data['totalApps'] ?? 0,
      activeApps: data['activeApps'] ?? 0,
      totalMissions: data['totalMissions'] ?? 0,
      activeMissions: data['activeMissions'] ?? 0,
      completedMissions: data['completedMissions'] ?? 0,
      totalBugReports: data['totalBugReports'] ?? 0,
      pendingBugReports: data['openBugReports'] ?? data['pendingBugReports'] ?? 0,
      resolvedBugReports: data['resolvedBugReports'] ?? 0,
      totalTesters: data['totalTesters'] ?? 0,
      activeTesters: data['activeTesters'] ?? 0,
      totalRevenue: (data['totalSpent'] ?? data['totalRevenue'] ?? 0.0).toDouble(),
      averageAppRating: (data['averageRating'] ?? data['averageAppRating'] ?? 0.0).toDouble(),
      missionsByStatus: Map<String, int>.from(data['missionsByStatus'] ?? {}),
      bugReportsByPriority: Map<String, int>.from(data['bugReportsByPriority'] ?? {}),
      recentActivities: List<Map<String, dynamic>>.from(data['recentActivities'] ?? []),
      performanceMetrics: Map<String, double>.from(data['performanceMetrics'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    totalApps,
    activeApps,
    totalMissions,
    activeMissions,
    completedMissions,
    totalBugReports,
    pendingBugReports,
    resolvedBugReports,
    totalTesters,
    activeTesters,
    totalRevenue,
    averageAppRating,
    missionsByStatus,
    bugReportsByPriority,
    recentActivities,
    performanceMetrics,
  ];
}