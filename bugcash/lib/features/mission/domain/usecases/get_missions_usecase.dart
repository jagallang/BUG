import '../entities/mission_workflow_entity.dart';
import '../repositories/mission_repository.dart';

/// Get Missions UseCase
/// 다양한 조건으로 미션 목록 조회
class GetMissionsUseCase {
  final MissionRepository _repository;

  GetMissionsUseCase(this._repository);

  /// 공급자의 미션 조회
  Future<List<MissionWorkflowEntity>> getProviderMissions(String providerId) async {
    if (providerId.isEmpty) {
      throw ArgumentError('providerId cannot be empty');
    }
    return await _repository.getProviderMissions(providerId);
  }

  /// 테스터의 미션 조회
  Future<List<MissionWorkflowEntity>> getTesterMissions(String testerId) async {
    if (testerId.isEmpty) {
      throw ArgumentError('testerId cannot be empty');
    }
    return await _repository.getTesterMissions(testerId);
  }

  /// 특정 앱의 테스터 신청 목록 조회
  Future<List<MissionWorkflowEntity>> getAppTesterApplications(String appId) async {
    if (appId.isEmpty) {
      throw ArgumentError('appId cannot be empty');
    }
    return await _repository.getAppTesterApplications(appId);
  }

  /// 특정 앱의 승인된 테스터 조회
  Future<List<MissionWorkflowEntity>> getAppApprovedTesters(String appId) async {
    if (appId.isEmpty) {
      throw ArgumentError('appId cannot be empty');
    }
    return await _repository.getAppApprovedTesters(appId);
  }

  /// 특정 미션 상세 조회
  Future<MissionWorkflowEntity?> getMissionById(String missionId) async {
    if (missionId.isEmpty) {
      throw ArgumentError('missionId cannot be empty');
    }
    return await _repository.getMissionById(missionId);
  }

  /// 테스터의 진행 중인 미션 조회
  Future<MissionWorkflowEntity?> getTesterActiveMission(String testerId) async {
    if (testerId.isEmpty) {
      throw ArgumentError('testerId cannot be empty');
    }
    return await _repository.getTesterActiveMission(testerId);
  }

  // ========================================
  // Cache Management (v2.24.6)
  // ========================================

  /// v2.24.6: 공급자 캐시 무효화 (refreshMissions 전에 호출)
  void invalidateProviderCache(String providerId) {
    _repository.invalidateProviderCache(providerId);
  }

  /// v2.24.6: 테스터 캐시 무효화
  void invalidateTesterCache(String testerId) {
    _repository.invalidateTesterCache(testerId);
  }
}
