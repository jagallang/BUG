/// 프로젝트 상태(projects.status) 상수 및 한글 명칭 매핑
///
/// v2.186.29: 프로젝트 상태 표시 일관성 확보
/// - 기존: app_status_badge.dart와 app_management_page.dart에서 서로 다른 한글 표시
/// - 개선: 단일 진실 공급원(Single Source of Truth)으로 통합
class ProjectStatusConstants {
  ProjectStatusConstants._();

  // 프로젝트 상태 코드
  static const String draft = 'draft';
  static const String pending = 'pending';
  static const String open = 'open';
  static const String closed = 'closed';
  static const String rejected = 'rejected';

  // 프로젝트 상태별 한글 표시명
  static const Map<String, String> displayNames = {
    draft: '접수 대기',
    pending: '검토중',
    open: '모집중',
    closed: '완료',
    rejected: '거부됨',
  };

  /// 프로젝트 상태 코드를 한글 표시명으로 변환
  ///
  /// [status]: 프로젝트 상태 코드 (예: 'draft', 'open', 'closed')
  /// Returns: 한글 표시명 (예: '접수 대기', '모집중', '완료')
  ///
  /// 매칭되는 상태가 없으면 원본 status를 그대로 반환
  static String getDisplayName(String status) {
    final normalizedStatus = status.toLowerCase();
    return displayNames[normalizedStatus] ?? status;
  }

  /// 상태별 색상 코드 (향후 UI 통일을 위해)
  static const Map<String, String> statusColors = {
    draft: 'gray',
    pending: 'yellow',
    open: 'green',
    closed: 'blue',
    rejected: 'red',
  };
}
