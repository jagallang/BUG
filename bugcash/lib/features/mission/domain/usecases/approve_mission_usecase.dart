import '../repositories/mission_repository.dart';
import '../entities/mission_workflow_entity.dart';

/// Approve Mission UseCase
/// Single Responsibility: 미션 승인
class ApproveMissionUseCase {
  final MissionRepository _repository;

  ApproveMissionUseCase(this._repository);

  Future<void> execute(String missionId) async {
    if (missionId.isEmpty) {
      throw ArgumentError('missionId cannot be empty');
    }

    // 미션 존재 여부 확인 (선택적)
    final mission = await _repository.getMissionById(missionId);
    if (mission == null) {
      throw Exception('Mission not found: $missionId');
    }

    // 이미 승인된 미션인지 확인
    if (mission.status != MissionWorkflowStatus.applicationSubmitted) {
      throw Exception('Mission is not in application_submitted state');
    }

    await _repository.approveMission(missionId);
  }
}

/// Reject Mission UseCase
/// Single Responsibility: 미션 거부
class RejectMissionUseCase {
  final MissionRepository _repository;

  RejectMissionUseCase(this._repository);

  Future<void> execute(String missionId, String reason) async {
    if (missionId.isEmpty) {
      throw ArgumentError('missionId cannot be empty');
    }
    if (reason.isEmpty) {
      throw ArgumentError('reason cannot be empty');
    }
    if (reason.length < 10) {
      throw ArgumentError('reason must be at least 10 characters');
    }

    await _repository.rejectMission(missionId, reason);
  }
}
