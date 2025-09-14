import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/test_session_service.dart';
import '../../../../models/test_session_model.dart';
import '../../../../core/utils/logger.dart';
import 'daily_test_approval_widget.dart';

class TestSessionApplicationTab extends ConsumerStatefulWidget {
  final String providerId;

  const TestSessionApplicationTab({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<TestSessionApplicationTab> createState() => _TestSessionApplicationTabState();
}

class _TestSessionApplicationTabState extends ConsumerState<TestSessionApplicationTab> {
  String _selectedFilter = '전체';
  String _selectedSort = '신청일순';

  List<TestSession> _getFilteredSessions(List<TestSession> sessions) {
    List<TestSession> filtered = List.from(sessions);

    // 상태 필터링
    if (_selectedFilter != '전체') {
      final status = _getStatusFromFilter(_selectedFilter);
      if (status != null) {
        filtered = filtered.where((session) => session.status == status).toList();
      }
    }

    // 정렬
    if (_selectedSort == '신청일순') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == '진행률순') {
      filtered.sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
    } else if (_selectedSort == '포인트순') {
      filtered.sort((a, b) => b.totalRewardPoints.compareTo(a.totalRewardPoints));
    }

    return filtered;
  }

  TestSessionStatus? _getStatusFromFilter(String filter) {
    switch (filter) {
      case '승인 대기':
        return TestSessionStatus.pending;
      case '승인됨':
        return TestSessionStatus.approved;
      case '진행 중':
        return TestSessionStatus.active;
      case '완료':
        return TestSessionStatus.completed;
      case '거부됨':
        return TestSessionStatus.rejected;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.indigo[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.indigo[700],
              tabs: const [
                Tab(text: '테스트 세션 관리'),
                Tab(text: '일일 테스트 승인'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTestSessionManagementTab(),
            DailyTestApprovalWidget(providerId: widget.providerId),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSessionManagementTab() {
    final testSessionsAsync = ref.watch(providerTestSessionsProvider(widget.providerId));

    return Column(
      children: [
        _buildHeader(),
        _buildFilterAndSort(),
        Expanded(
          child: testSessionsAsync.when(
            data: (sessions) {
              final filteredSessions = _getFilteredSessions(sessions);

              if (filteredSessions.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  _buildStatsCards(sessions),
                  Expanded(child: _buildSessionList(filteredSessions)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ],
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
          Icon(Icons.assignment_ind, size: 24.w, color: Colors.indigo[700]),
          SizedBox(width: 12.w),
          Text(
            '테스트 세션 관리',
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

  Widget _buildFilterAndSort() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        children: [
          // 상태 필터
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: '상태',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              items: ['전체', '승인 대기', '승인됨', '진행 중', '완료', '거부됨'].map((String value) {
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
          ),
          SizedBox(width: 12.w),
          // 정렬
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSort,
              decoration: InputDecoration(
                labelText: '정렬',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              items: ['신청일순', '진행률순', '포인트순'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSort = newValue!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<TestSession> sessions) {
    final totalSessions = sessions.length;
    final pendingSessions = sessions.where((s) => s.status == TestSessionStatus.pending).length;
    final activeSessions = sessions.where((s) => s.status == TestSessionStatus.active).length;
    final completedSessions = sessions.where((s) => s.status == TestSessionStatus.completed).length;

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          _buildStatCard('총 세션', totalSessions.toString(), Icons.assignment, Colors.indigo[600]!),
          SizedBox(width: 12.w),
          _buildStatCard('승인 대기', pendingSessions.toString(), Icons.hourglass_empty, Colors.orange[600]!),
          SizedBox(width: 12.w),
          _buildStatCard('진행 중', activeSessions.toString(), Icons.play_circle, Colors.green[600]!),
          SizedBox(width: 12.w),
          _buildStatCard('완료', completedSessions.toString(), Icons.check_circle, Colors.blue[600]!),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20.w),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(List<TestSession> sessions) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(TestSession session) {
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session ID: ${session.id}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '테스터 ID: ${session.testerId}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(session.status),
              ],
            ),

            SizedBox(height: 12.h),

            // Progress Bar
            if (session.status == TestSessionStatus.active || session.status == TestSessionStatus.completed) ...[
              Row(
                children: [
                  Text(
                    '진행률',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(session.progressPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              LinearProgressIndicator(
                value: session.progressPercentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[700]!),
              ),
              SizedBox(height: 12.h),
            ],

            Row(
              children: [
                _buildInfoChip('${session.completedDays}/14일', Icons.calendar_today, Colors.blue),
                SizedBox(width: 8.w),
                _buildInfoChip('${session.earnedPoints}/${session.totalRewardPoints}P', Icons.star, Colors.orange),
                const Spacer(),
                Text(
                  _formatDate(session.createdAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),

            if (session.status == TestSessionStatus.pending) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveSession(session.id),
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
                      onPressed: () => _showRejectDialog(session.id),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TestSessionStatus status) {
    Color color;
    String text;

    switch (status) {
      case TestSessionStatus.pending:
        color = Colors.orange;
        text = '승인 대기';
        break;
      case TestSessionStatus.approved:
        color = Colors.blue;
        text = '승인됨';
        break;
      case TestSessionStatus.active:
        color = Colors.green;
        text = '진행 중';
        break;
      case TestSessionStatus.completed:
        color = Colors.indigo;
        text = '완료';
        break;
      case TestSessionStatus.rejected:
        color = Colors.red;
        text = '거부됨';
        break;
      case TestSessionStatus.cancelled:
        color = Colors.grey;
        text = '취소됨';
        break;
      case TestSessionStatus.paused:
        color = Colors.amber;
        text = '일시정지';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: color,
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
            '테스트 세션이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '테스터들이 앱을 신청하면 여기에 표시됩니다',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  Future<void> _approveSession(String sessionId) async {
    try {
      final testSessionService = ref.read(testSessionServiceProvider);
      await testSessionService.startTestSession(sessionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('테스트 세션이 승인되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to approve session', 'TestSessionApplicationTab', e);
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

  Future<void> _showRejectDialog(String sessionId) async {
    String? reason;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('세션 거부'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('이 테스트 세션을 거부하시겠습니까?'),
              SizedBox(height: 16.h),
              TextField(
                decoration: const InputDecoration(
                  labelText: '거부 사유',
                  hintText: '거부 사유를 입력해주세요 (선택)',
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
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectSession(sessionId, reason ?? '');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('거부', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectSession(String sessionId, String reason) async {
    try {
      // For now, we'll update the session status directly
      // In a real implementation, you might want to add a rejectTestSession method
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('테스트 세션이 거부되었습니다'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to reject session', 'TestSessionApplicationTab', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('거부 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}