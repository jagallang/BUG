import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/provider_app_entity.dart';

class ProviderAppModel extends ProviderAppEntity {
  const ProviderAppModel({
    required super.id,
    required super.providerId,
    required super.appName,
    required super.appUrl,
    required super.description,
    required super.category,
    required super.status,
    required super.totalTesters,
    required super.activeTesters,
    required super.totalBugs,
    required super.resolvedBugs,
    required super.progressPercentage,
    required super.createdAt,
    required super.updatedAt,
    required super.metadata,
  });

  factory ProviderAppModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 기본 metadata 가져오기
    final metadata = Map<String, dynamic>.from(data['metadata'] ?? {});

    // 최상위 rewards 필드가 있으면 metadata에 포함시키기
    final topLevelRewards = data['rewards'] as Map<String, dynamic>?;
    if (topLevelRewards != null) {
      metadata['rewards'] = topLevelRewards;
      // 안전성을 위한 디버깅 로그
      debugPrint('🔄 ProviderAppModel: 최상위 rewards 필드를 metadata에 병합 - ${data['appName']}');
      debugPrint('📊 topLevelRewards: $topLevelRewards');
    } else {
      debugPrint('⚠️ ProviderAppModel: 최상위 rewards 필드 없음 - ${data['appName']}');
    }

    return ProviderAppModel(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      appName: data['appName'] ?? '',
      appUrl: data['appUrl'] ?? data['appStoreUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'draft',
      totalTesters: data['totalTesters'] ?? data['maxTesters'] ?? 0,
      activeTesters: data['activeTesters'] ?? 0,
      totalBugs: data['totalBugs'] ?? 0,
      resolvedBugs: data['resolvedBugs'] ?? 0,
      progressPercentage: (data['progressPercentage'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: metadata,
    );
  }

  factory ProviderAppModel.fromEntity(ProviderAppEntity entity) {
    return ProviderAppModel(
      id: entity.id,
      providerId: entity.providerId,
      appName: entity.appName,
      appUrl: entity.appUrl,
      description: entity.description,
      category: entity.category,
      status: entity.status,
      totalTesters: entity.totalTesters,
      activeTesters: entity.activeTesters,
      totalBugs: entity.totalBugs,
      resolvedBugs: entity.resolvedBugs,
      progressPercentage: entity.progressPercentage,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      metadata: entity.metadata,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'appName': appName,
      'appUrl': appUrl,
      'description': description,
      'category': category,
      'status': status,
      'totalTesters': totalTesters,
      'activeTesters': activeTesters,
      'totalBugs': totalBugs,
      'resolvedBugs': resolvedBugs,
      'progressPercentage': progressPercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }
}