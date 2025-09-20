// Firestore 컬렉션 이름과 관련 상수들
class FirestoreConstants {
  // 컬렉션 이름
  static const String users = 'users';
  static const String providers = 'providers';
  static const String testers = 'testers';
  static const String missions = 'missions';
  static const String apps = 'apps';
  static const String providerApps = 'provider_apps';
  static const String missionApplications = 'mission_applications';
  static const String testerApplications = 'tester_applications';
  static const String bugReports = 'bug_reports';
  static const String payments = 'payments';
  static const String notifications = 'notifications';
  static const String testSessions = 'test_sessions';
  static const String testMissions = 'test_missions';
  static const String missionAssignments = 'mission_assignments';

  // 기본값
  static const int defaultDailyReward = 5000;
  static const int defaultTotalDays = 14;
  static const int defaultTestingDuration = 30;
  static const double defaultMinRating = 0.0;
  static const String defaultCurrency = 'USD';
  static const String defaultPaymentMethod = 'cash';

  // 상태값
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusActive = 'active';
  static const String statusPaused = 'paused';
  static const String statusCancelled = 'cancelled';
  static const String statusDraft = 'draft';
  static const String statusMissionApproved = 'mission_approved';
  static const String statusProjectEnded = 'project_ended';

  // 미션 타입
  static const String missionTypeFunctional = 'functional';
  static const String missionTypeUsability = 'usability';
  static const String missionTypePerformance = 'performance';
  static const String missionTypeSecurity = 'security';

  // 알림 타입
  static const String notificationTypeMissionApplication = 'missionApplication';
  static const String notificationTypeStatusUpdate = 'statusUpdate';

  // 경험 레벨
  static const String experienceBeginner = 'beginner';
  static const String experienceIntermediate = 'intermediate';
  static const String experienceAdvanced = 'advanced';
  static const String experienceExpert = 'expert';

  // 앱 카테고리
  static const String categoryUtility = 'utility';
  static const String categoryGame = 'game';
  static const String categorySocial = 'social';
  static const String categoryEducation = 'education';
  static const String categoryBusiness = 'business';
  static const String categoryLifestyle = 'lifestyle';

  // 쿼리 제한값
  static const int defaultQueryLimit = 20;
  static const int maxParticipants = 10;
  static const int minParticipants = 1;

  // 기타 상수
  static const String unknownUser = 'Unknown User';
  static const String unknownApp = '앱 정보 로딩 중...';
  static const String loadingTester = '테스터 정보 로딩 중...';
  static const String defaultMotivation = '새로운 앱을 테스트하며 버그를 찾는 것에 관심이 있습니다.';
}