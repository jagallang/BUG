import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BugReportReviewPanel extends ConsumerWidget {
  final String missionId;
  final String providerId;

  const BugReportReviewPanel({
    super.key,
    required this.missionId,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (missionId.isEmpty) {
      return Center(
        child: Text(
          '미션을 선택해주세요',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Review Status Summary
          _buildReviewStatusSummary(context),
          
          SizedBox(height: 16.h),
          
          // Filter Tabs
          _buildFilterTabs(context),
          
          SizedBox(height: 16.h),
          
          // Reports List
          _buildReportsList(context),
        ],
      ),
    );
  }

  Widget _buildReviewStatusSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '검토 현황',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  '대기중',
                  '8',
                  Icons.pending_actions,
                  Colors.orange,
                  '긴급 검토 필요',
                ),
                _buildStatusItem(
                  '승인',
                  '15',
                  Icons.check_circle,
                  Colors.green,
                  '품질 우수',
                ),
                _buildStatusItem(
                  '반려',
                  '3',
                  Icons.cancel,
                  Colors.red,
                  '추가 정보 필요',
                ),
                _buildStatusItem(
                  '보류',
                  '2',
                  Icons.pause_circle,
                  Colors.grey,
                  '개발팀 확인중',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String count,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.w),
        ),
        SizedBox(height: 8.h),
        Text(
          count,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(25.r),
            color: Theme.of(context).colorScheme.primary,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '대기중'),
            Tab(text: '승인'),
            Tab(text: '반려'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(BuildContext context) {
    final mockReports = _generateMockReports();
    
    return Column(
      children: mockReports
          .map((report) => _buildReportCard(context, report))
          .toList(),
    );
  }

  Widget _buildReportCard(BuildContext context, BugReport report) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Priority indicator
                Container(
                  width: 4.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(report.priority),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 12.w),
                
                // Report info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            report.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(report.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              _getStatusText(report.status),
                              style: TextStyle(
                                color: _getStatusColor(report.status),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14.w, color: Colors.blue),
                          SizedBox(width: 4.w),
                          Text(
                            report.testerName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(Icons.schedule, size: 14.w, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            _formatTime(report.submittedAt),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Description
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 12.h),
            
            // Tags and severity
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(report.severity).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    report.severity,
                    style: TextStyle(
                      color: _getSeverityColor(report.severity),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    report.category,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (report.hasAttachments)
                  Icon(
                    Icons.attach_file,
                    size: 16.w,
                    color: Colors.grey,
                  ),
                if (report.screenshotCount > 0) ...[
                  SizedBox(width: 8.w),
                  Row(
                    children: [
                      Icon(
                        Icons.image,
                        size: 16.w,
                        color: Colors.green,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${report.screenshotCount}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReportDetails(context, report),
                    icon: const Icon(Icons.visibility),
                    label: const Text('상세 보기'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (report.status == ReviewStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveReport(context, report),
                      icon: const Icon(Icons.check),
                      label: const Text('승인'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectReport(context, report),
                      icon: const Icon(Icons.close),
                      label: const Text('반려'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewHistory(context, report),
                      icon: const Icon(Icons.history),
                      label: const Text('검토 이력'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BugReport> _generateMockReports() {
    return [
      BugReport(
        id: '1',
        title: '앱 실행 시 크래시 발생',
        description: '안드로이드 14에서 앱 실행 시 즉시 종료되는 문제가 발생합니다. 스플래시 화면도 표시되지 않고 바로 꺼집니다.',
        testerName: '김철수',
        submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: ReviewStatus.pending,
        priority: Priority.high,
        severity: '심각',
        category: 'Crash',
        hasAttachments: true,
        screenshotCount: 3,
      ),
      BugReport(
        id: '2',
        title: '로그인 버튼 반응 없음',
        description: 'iOS에서 로그인 버튼을 터치해도 반응이 없습니다. 다른 버튼들은 정상 작동합니다.',
        testerName: '이영희',
        submittedAt: DateTime.now().subtract(const Duration(hours: 4)),
        status: ReviewStatus.approved,
        priority: Priority.medium,
        severity: '보통',
        category: 'UI/UX',
        hasAttachments: false,
        screenshotCount: 2,
      ),
      BugReport(
        id: '3',
        title: '데이터 로딩 속도 느림',
        description: '메인 화면의 데이터 로딩이 매우 느립니다. Wi-Fi 환경에서도 10초 이상 소요됩니다.',
        testerName: '박민수',
        submittedAt: DateTime.now().subtract(const Duration(hours: 6)),
        status: ReviewStatus.rejected,
        priority: Priority.low,
        severity: '경미',
        category: 'Performance',
        hasAttachments: true,
        screenshotCount: 1,
      ),
      BugReport(
        id: '4',
        title: '다크모드 색상 오류',
        description: '다크모드에서 일부 텍스트가 보이지 않습니다. 배경색과 텍스트 색상이 같아 보입니다.',
        testerName: '정수진',
        submittedAt: DateTime.now().subtract(const Duration(hours: 8)),
        status: ReviewStatus.pending,
        priority: Priority.medium,
        severity: '보통',
        category: 'UI/UX',
        hasAttachments: false,
        screenshotCount: 4,
      ),
    ];
  }

  void _showReportDetails(BuildContext context, BugReport report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600.w,
          constraints: BoxConstraints(maxHeight: 700.h),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      color: Colors.white,
                      size: 24.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        report.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report info
                      _buildDetailSection('리포터 정보', [
                        '테스터: ${report.testerName}',
                        '제출일: ${_formatTime(report.submittedAt)}',
                        '우선순위: ${_getPriorityText(report.priority)}',
                        '심각도: ${report.severity}',
                      ]),
                      
                      SizedBox(height: 16.h),
                      
                      _buildDetailSection('상세 설명', [report.description]),
                      
                      SizedBox(height: 16.h),
                      
                      _buildDetailSection('재현 단계', [
                        '1. 앱 실행',
                        '2. 메인 화면에서 로그인 버튼 터치',
                        '3. 반응 없음 확인',
                      ]),
                      
                      if (report.screenshotCount > 0) ...[
                        SizedBox(height: 16.h),
                        _buildDetailSection('첨부 파일', [
                          '스크린샷 ${report.screenshotCount}개',
                          '로그 파일 포함',
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    if (report.status == ReviewStatus.pending) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _approveReport(context, report);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('승인'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _rejectReport(context, report);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('반려'),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('닫기'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        )),
      ],
    );
  }

  void _approveReport(BuildContext context, BugReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${report.title} 리포트가 승인되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectReport(BuildContext context, BugReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${report.title} 리포트가 반려되었습니다'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showReviewHistory(BuildContext context, BugReport report) {
    // Show review history dialog
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.low:
        return '낮음';
      case Priority.medium:
        return '보통';
      case Priority.high:
        return '높음';
    }
  }

  Color _getStatusColor(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.pending:
        return Colors.orange;
      case ReviewStatus.approved:
        return Colors.green;
      case ReviewStatus.rejected:
        return Colors.red;
      case ReviewStatus.onHold:
        return Colors.grey;
    }
  }

  String _getStatusText(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.pending:
        return '대기중';
      case ReviewStatus.approved:
        return '승인';
      case ReviewStatus.rejected:
        return '반려';
      case ReviewStatus.onHold:
        return '보류';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case '심각':
        return Colors.red;
      case '보통':
        return Colors.orange;
      case '경미':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inMinutes}분 전';
    }
  }
}

// Models
enum ReviewStatus { pending, approved, rejected, onHold }
enum Priority { low, medium, high }

class BugReport {
  final String id;
  final String title;
  final String description;
  final String testerName;
  final DateTime submittedAt;
  final ReviewStatus status;
  final Priority priority;
  final String severity;
  final String category;
  final bool hasAttachments;
  final int screenshotCount;

  BugReport({
    required this.id,
    required this.title,
    required this.description,
    required this.testerName,
    required this.submittedAt,
    required this.status,
    required this.priority,
    required this.severity,
    required this.category,
    required this.hasAttachments,
    required this.screenshotCount,
  });
}