import '../../domain/entities/mission_workflow_entity.dart';
import '../../domain/repositories/mission_repository.dart';
import '../datasources/mission_remote_datasource.dart';
import '../../../../core/utils/logger.dart';

/// Mission Repository Implementation (Data Layer)
/// Domain의 Repository Interface를 구현
/// Datasource와 통신하여 데이터 변환 담당
class MissionRepositoryImpl implements MissionRepository {
  final MissionRemoteDatasource _remoteDatasource;

  // 간단한 메모리 캐시 (5분 유효)
  final Map<String, _CachedData<List<MissionWorkflowEntity>>> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  MissionRepositoryImpl(this._remoteDatasource);

  // ========================================
  // Query Methods
  // ========================================

  @override
  Future<List<MissionWorkflowEntity>> getProviderMissions(String providerId) async {
    final cacheKey = 'provider_$providerId';

    // 캐시 확인
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      AppLogger.info('Cache hit: $cacheKey', 'MissionRepository');
      return _cache[cacheKey]!.data;
    }

    // Datasource 호출
    final models = await _remoteDatasource.fetchProviderMissions(providerId);
    final entities = models.map((m) => m.toEntity()).toList();

    // 캐시 저장
    _cache[cacheKey] = _CachedData(entities);

    return entities;
  }

  @override
  Future<List<MissionWorkflowEntity>> getTesterMissions(String testerId) async {
    final cacheKey = 'tester_$testerId';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      AppLogger.info('Cache hit: $cacheKey', 'MissionRepository');
      return _cache[cacheKey]!.data;
    }

    final models = await _remoteDatasource.fetchTesterMissions(testerId);
    final entities = models.map((m) => m.toEntity()).toList();

    _cache[cacheKey] = _CachedData(entities);

    return entities;
  }

  @override
  Future<List<MissionWorkflowEntity>> getAppTesterApplications(String appId) async {
    final cacheKey = 'app_applications_$appId';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      AppLogger.info('Cache hit: $cacheKey', 'MissionRepository');
      return _cache[cacheKey]!.data;
    }

    final models = await _remoteDatasource.fetchAppTesterApplications(appId);
    final entities = models.map((m) => m.toEntity()).toList();

    _cache[cacheKey] = _CachedData(entities);

    return entities;
  }

  @override
  Future<List<MissionWorkflowEntity>> getAppApprovedTesters(String appId) async {
    final cacheKey = 'app_approved_$appId';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      AppLogger.info('Cache hit: $cacheKey', 'MissionRepository');
      return _cache[cacheKey]!.data;
    }

    final models = await _remoteDatasource.fetchAppApprovedTesters(appId);
    final entities = models.map((m) => m.toEntity()).toList();

    _cache[cacheKey] = _CachedData(entities);

    return entities;
  }

  @override
  Future<MissionWorkflowEntity?> getMissionById(String missionId) async {
    final model = await _remoteDatasource.fetchMissionById(missionId);
    return model?.toEntity();
  }

  @override
  Future<MissionWorkflowEntity?> getTesterActiveMission(String testerId) async {
    final model = await _remoteDatasource.fetchTesterActiveMission(testerId);
    return model?.toEntity();
  }

  // ========================================
  // Command Methods
  // ========================================

  @override
  Future<String> createMissionApplication({
    required String appId,
    required String appName,
    required String testerId,
    required String testerName,
    required String testerEmail,
    required String experience,
    required String motivation,
    String? providerId,
    String? providerName,
    int totalDays = 14,
    int dailyReward = 5000,
  }) async {
    final missionId = await _remoteDatasource.createMissionApplication(
      appId: appId,
      appName: appName,
      testerId: testerId,
      testerName: testerName,
      testerEmail: testerEmail,
      experience: experience,
      motivation: motivation,
      providerId: providerId,
      providerName: providerName,
      totalDays: totalDays,
      dailyReward: dailyReward,
    );

    // 캐시 무효화
    _invalidateCache(testerId: testerId, appId: appId);

    return missionId;
  }

  @override
  Future<void> approveMission(String missionId) async {
    await _remoteDatasource.approveMission(missionId);

    // 캐시 무효화
    _invalidateAllCache();
  }

  @override
  Future<void> rejectMission(String missionId, String reason) async {
    await _remoteDatasource.rejectMission(missionId, reason);

    // 캐시 무효화
    _invalidateAllCache();
  }

  @override
  Future<void> startMission(String missionId) async {
    await _remoteDatasource.startMission(missionId);

    // 캐시 무효화
    _invalidateAllCache();
  }

  @override
  Future<void> markDailyMissionCompleted({
    required String missionId,
    required String testerId,
    required int dayNumber,
  }) async {
    await _remoteDatasource.markDailyMissionCompleted(
      missionId: missionId,
      dayNumber: dayNumber,
    );

    // 캐시 무효화
    _invalidateCache(testerId: testerId);
  }

  @override
  Future<void> submitMission({
    required String missionId,
    required String testerId,
    required int dayNumber,
    required List<String> bugReports,
    required List<String> screenshots,
    String? notes,
  }) async {
    // TODO: 미션 제출 구현
    throw UnimplementedError('submitMission not implemented yet');
  }

  @override
  Future<void> cancelMission(String missionId, String reason) async {
    await _remoteDatasource.cancelMission(missionId, reason);

    // 캐시 무효화
    _invalidateAllCache();
  }

  @override
  Future<void> deleteMission(String missionId) async {
    await _remoteDatasource.deleteMission(missionId);

    // 캐시 무효화
    _invalidateAllCache();
  }

  // ========================================
  // Real-time Stream
  // ========================================

  @override
  Stream<MissionWorkflowEntity?> watchActiveMission(String testerId) {
    return _remoteDatasource
        .watchActiveMission(testerId)
        .map((model) => model?.toEntity());
  }

  // ========================================
  // Cache Management
  // ========================================

  /// 특정 캐시 무효화
  void _invalidateCache({String? testerId, String? providerId, String? appId}) {
    if (testerId != null) {
      _cache.remove('tester_$testerId');
    }
    if (providerId != null) {
      _cache.remove('provider_$providerId');
    }
    if (appId != null) {
      _cache.remove('app_applications_$appId');
      _cache.remove('app_approved_$appId');
    }
  }

  /// 전체 캐시 무효화
  void _invalidateAllCache() {
    _cache.clear();
    AppLogger.info('All cache invalidated', 'MissionRepository');
  }
}

/// 캐시된 데이터 래퍼
class _CachedData<T> {
  final T data;
  final DateTime timestamp;

  _CachedData(this.data) : timestamp = DateTime.now();

  bool get isValid {
    return DateTime.now().difference(timestamp) < MissionRepositoryImpl._cacheDuration;
  }
}
