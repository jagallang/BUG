import '../entities/mission_workflow_entity.dart';

/// Mission Repository Interface (Domain Layer)
/// 구현 세부사항과 독립적인 인터페이스
/// Data Layer에서 구현됨
abstract class MissionRepository {
  // ========================================
  // Query Methods (모두 Future - 실시간 리스너 제거)
  // ========================================

  /// 공급자의 모든 미션 조회
  Future<List<MissionWorkflowEntity>> getProviderMissions(String providerId);

  /// 테스터의 모든 미션 조회
  Future<List<MissionWorkflowEntity>> getTesterMissions(String testerId);

  /// 특정 앱의 테스터 신청 목록 조회
  Future<List<MissionWorkflowEntity>> getAppTesterApplications(String appId);

  /// 특정 앱의 승인된 테스터 목록 조회
  Future<List<MissionWorkflowEntity>> getAppApprovedTesters(String appId);

  /// 특정 미션 상세 조회
  Future<MissionWorkflowEntity?> getMissionById(String missionId);

  /// 테스터의 진행 중인 미션 조회 (단일)
  Future<MissionWorkflowEntity?> getTesterActiveMission(String testerId);

  // ========================================
  // Command Methods (CUD operations)
  // ========================================

  /// 미션 신청 생성
  /// v2.18.0: totalDays 기본값 14일 → 10일 변경
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
    int totalDays = 10,  // v2.18.0: 14 → 10
    int dailyReward = 5000,
  });

  /// 미션 승인
  Future<void> approveMission(String missionId);

  /// 미션 거부
  Future<void> rejectMission(String missionId, String reason);

  /// 미션 시작
  Future<void> startMission(String missionId);

  /// 일일 미션 완료 기록
  Future<void> markDailyMissionCompleted({
    required String missionId,
    required String testerId,
    required int dayNumber,
  });

  /// 미션 제출
  Future<void> submitMission({
    required String missionId,
    required String testerId,
    required int dayNumber,
    required List<String> bugReports,
    required List<String> screenshots,
    String? notes,
  });

  /// 미션 취소
  Future<void> cancelMission(String missionId, String reason);

  /// 미션 삭제
  Future<void> deleteMission(String missionId);

  // ========================================
  // Real-time Stream (선택적 - 진행 중 미션만)
  // ========================================

  /// 테스터의 활성 미션 실시간 감시 (선택적)
  /// 오직 진행 중인 미션 1개만 실시간 감시
  Stream<MissionWorkflowEntity?> watchActiveMission(String testerId);
}
