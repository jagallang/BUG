import '../repositories/mission_repository.dart';

/// Create Mission Application UseCase
/// Single Responsibility: 미션 신청 생성
class CreateMissionUseCase {
  final MissionRepository _repository;

  CreateMissionUseCase(this._repository);

  Future<String> execute(CreateMissionParams params) async {
    // 비즈니스 로직 검증
    _validateParams(params);

    // Repository 호출
    return await _repository.createMissionApplication(
      appId: params.appId,
      appName: params.appName,
      testerId: params.testerId,
      testerName: params.testerName,
      testerEmail: params.testerEmail,
      experience: params.experience,
      motivation: params.motivation,
      providerId: params.providerId,
      providerName: params.providerName,
      totalDays: params.totalDays,
      dailyReward: params.dailyReward,
    );
  }

  void _validateParams(CreateMissionParams params) {
    if (params.appId.isEmpty) {
      throw ArgumentError('appId cannot be empty');
    }
    if (params.testerId.isEmpty) {
      throw ArgumentError('testerId cannot be empty');
    }
    if (params.experience.isEmpty) {
      throw ArgumentError('experience cannot be empty');
    }
    if (params.motivation.isEmpty) {
      throw ArgumentError('motivation cannot be empty');
    }
    if (params.motivation.length < 20) {
      throw ArgumentError('motivation must be at least 20 characters');
    }
    if (params.totalDays < 1 || params.totalDays > 30) {
      throw ArgumentError('totalDays must be between 1 and 30');
    }
    if (params.dailyReward < 0) {
      throw ArgumentError('dailyReward cannot be negative');
    }
  }
}

/// Create Mission Parameters
class CreateMissionParams {
  final String appId;
  final String appName;
  final String testerId;
  final String testerName;
  final String testerEmail;
  final String experience;
  final String motivation;
  final String? providerId;
  final String? providerName;
  final int totalDays;
  final int dailyReward;

  const CreateMissionParams({
    required this.appId,
    required this.appName,
    required this.testerId,
    required this.testerName,
    required this.testerEmail,
    required this.experience,
    required this.motivation,
    this.providerId,
    this.providerName,
    this.totalDays = 14,
    this.dailyReward = 5000,
  });
}
