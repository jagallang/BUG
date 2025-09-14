import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/test_session_service.dart';
import '../../../../models/test_session_model.dart';
import '../../../../core/utils/logger.dart';

class DailyTestApprovalWidget extends ConsumerStatefulWidget {
  final String providerId;

  const DailyTestApprovalWidget({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<DailyTestApprovalWidget> createState() => _DailyTestApprovalWidgetState();
}

class _DailyTestApprovalWidgetState extends ConsumerState<DailyTestApprovalWidget> {
  String _selectedFilter = '전체';

  @override
  Widget build(BuildContext context) {
    final testSessionsAsync = ref.watch(providerTestSessionsProvider(widget.providerId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterRow(),
          Expanded(
            child: testSessionsAsync.when(
              data: (sessions) {
                final activeSessions = sessions.where(
                  (session) => session.status == TestSessionStatus.active
                ).toList();

                if (activeSessions.isEmpty) {
                  return _buildEmptyState();
                }

                // Extract daily test submissions that need approval
                final List<DailyTestSubmission> submissions = [];
                for (final session in activeSessions) {
                  for (final progress in session.dailyProgress) {
                    if (progress.status == DailyTestStatus.submitted) {
                      submissions.add(DailyTestSubmission(
                        session: session,
                        dailyProgress: progress,
                      ));
                    }
                  }
                }

                final filteredSubmissions = _getFilteredSubmissions(submissions);

                if (filteredSubmissions.isEmpty) {
                  return _buildNoSubmissionsState();
                }

                return _buildSubmissionsList(filteredSubmissions);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in, size: 24.w, color: Colors.indigo[700]),
          SizedBox(width: 12.w),
          Text(
            '일일 테스트 승인',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ref.invalidate(providerTestSessionsProvider(widget.providerId));
            },
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: DropdownButtonFormField<String>(
        value: _selectedFilter,
        decoration: InputDecoration(
          labelText: '필터',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        ),
        items: ['전체', '오늘 제출', '어제 제출', '이번 주 제출'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedFilter = newValue!;
          });
        },
      ),
    );
  }

  List<DailyTestSubmission> _getFilteredSubmissions(List<DailyTestSubmission> submissions) {
    if (_selectedFilter == '전체') return submissions;

    final now = DateTime.now();
    return submissions.where((submission) {
      final submittedAt = submission.dailyProgress.submittedAt;
      if (submittedAt == null) return false;

      switch (_selectedFilter) {
        case '오늘 제출':
          return submittedAt.day == now.day &&
                 submittedAt.month == now.month &&
                 submittedAt.year == now.year;
        case '어제 제출':
          final yesterday = now.subtract(const Duration(days: 1));
          return submittedAt.day == yesterday.day &&
                 submittedAt.month == yesterday.month &&
                 submittedAt.year == yesterday.year;
        case '이번 주 제출':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return submittedAt.isAfter(weekStart.subtract(const Duration(days: 1)));
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildSubmissionsList(List<DailyTestSubmission> submissions) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildSubmissionCard(DailyTestSubmission submission) {
    final session = submission.session;
    final progress = submission.dailyProgress;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${progress.day}일차 테스트',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '테스터: ${session.testerId}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '세션 ID: ${session.id}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '승인 대기',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Test duration and submission time
            Row(
              children: [
                _buildInfoChip('${progress.testDurationMinutes}분', Icons.timer, Colors.blue),
                SizedBox(width: 8.w),
                _buildInfoChip(_formatDateTime(progress.submittedAt!), Icons.schedule, Colors.green),
              ],
            ),

            SizedBox(height: 12.h),

            // Feedback from tester
            if (progress.feedbackFromTester != null && progress.feedbackFromTester!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '테스터 피드백',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      progress.feedbackFromTester!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Screenshots
            if (progress.screenshots.isNotEmpty) ...[
              Text(
                '스크린샷 (${progress.screenshots.length}개)',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 60.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: progress.screenshots.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[500],
                        size: 20.w,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Approval buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(session.id, progress.day),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('승인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectionDialog(session.id, progress.day),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('거부'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.w, color: color),
          SizedBox(width: 2.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            '진행 중인 테스트 세션이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '활성화된 테스트 세션이 있어야 일일 테스트를 승인할 수 있습니다',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubmissionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            '승인 대기 중인 테스트가 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '테스터가 일일 테스트를 제출하면 여기에 표시됩니다',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.w, color: Colors.red[300]),
          SizedBox(height: 16.h),
          Text(
            '데이터를 불러올 수 없습니다',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Future<void> _showApprovalDialog(String sessionId, int day) async {
    String? feedback;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${day}일차 테스트 승인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('이 테스트를 승인하시겠습니까?'),
              SizedBox(height: 16.h),
              TextField(
                decoration: InputDecoration(
                  labelText: '피드백 (선택사항)',
                  hintText: '테스터에게 전달할 메시지를 입력해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => feedback = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveDailyTest(sessionId, day, feedback);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('승인', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRejectionDialog(String sessionId, int day) async {
    String? reason;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${day}일차 테스트 거부'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('이 테스트를 거부하시겠습니까?'),
              SizedBox(height: 16.h),
              TextField(
                decoration: InputDecoration(
                  labelText: '거부 사유 (필수)',
                  hintText: '거부 사유를 입력해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => reason = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reason == null || reason!.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('거부 사유를 입력해주세요')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _rejectDailyTest(sessionId, day, reason!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('거부', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveDailyTest(String sessionId, int day, String? feedback) async {
    try {
      final testSessionService = ref.read(testSessionServiceProvider);
      await testSessionService.approveDailyTest(
        sessionId: sessionId,
        day: day,
        feedbackFromProvider: feedback,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${day}일차 테스트가 승인되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to approve daily test', 'DailyTestApprovalWidget', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('승인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectDailyTest(String sessionId, int day, String reason) async {
    try {
      final testSessionService = ref.read(testSessionServiceProvider);
      await testSessionService.rejectDailyTest(
        sessionId: sessionId,
        day: day,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${day}일차 테스트가 거부되었습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to reject daily test', 'DailyTestApprovalWidget', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거부 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Helper class for daily test submissions
class DailyTestSubmission {
  final TestSession session;
  final DailyTestProgress dailyProgress;

  DailyTestSubmission({
    required this.session,
    required this.dailyProgress,
  });
}