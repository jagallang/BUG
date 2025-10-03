import '../repositories/mission_repository.dart';

/// Start Mission Use Case
/// 승인된 테스터의 미션을 시작합니다
class StartMissionUseCase {
  final MissionRepository _repository;

  StartMissionUseCase(this._repository);

  /// 미션 시작 실행
  ///
  /// [missionId] 시작할 미션의 ID
  ///
  /// Throws:
  /// - [ArgumentError] if missionId is empty
  /// - [Exception] if mission not found or not in approved status
  Future<void> execute(String missionId) async {
    if (missionId.isEmpty) {
      throw ArgumentError('missionId cannot be empty');
    }

    // Repository를 통해 미션 시작
    // Repository에서 상태 검증 및 변경 수행
    await _repository.startMission(missionId);
  }
}
