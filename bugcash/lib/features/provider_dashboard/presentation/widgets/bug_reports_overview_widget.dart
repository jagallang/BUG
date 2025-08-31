import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';

class BugReportsOverviewWidget extends ConsumerWidget {
  final String providerId;
  final bool isFullView;

  const BugReportsOverviewWidget({
    super.key,
    required this.providerId,
    this.isFullView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bugReportsAsync = ref.watch(providerBugReportsProvider(providerId));
    final bugReportFilter = ref.watch(bugReportFilterProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            SizedBox(height: 16.h),
            if (isFullView) _buildFilterChips(context, ref, bugReportFilter),
            if (isFullView) SizedBox(height: 16.h),
            _buildBugReportsList(context, bugReportsAsync, isFullView),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isFullView ? '버그 리포트 관리' : '버그 리포트',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!isFullView)
          TextButton(
            onPressed: () {
              // Navigate to full view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('버그 리포트 관리 페이지로 이동합니다.')),
              );
            },
            child: const Text('더보기'),
          ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, String? currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '전체',
            isSelected: currentFilter == null,
            onTap: () => ref.read(bugReportFilterProvider.notifier).state = null,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '높은 우선순위',
            isSelected: currentFilter == 'high',
            onTap: () => ref.read(bugReportFilterProvider.notifier).state = 'high',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '보통 우선순위',
            isSelected: currentFilter == 'medium',
            onTap: () => ref.read(bugReportFilterProvider.notifier).state = 'medium',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '낮은 우선순위',
            isSelected: currentFilter == 'low',
            onTap: () => ref.read(bugReportFilterProvider.notifier).state = 'low',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '해결됨',
            isSelected: currentFilter == 'resolved',
            onTap: () => ref.read(bugReportFilterProvider.notifier).state = 'resolved',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildBugReportsList(BuildContext context, AsyncValue<List<Map<String, dynamic>>> bugReportsAsync, bool showAll) {
    return bugReportsAsync.when(
      data: (bugReports) {
        final displayReports = showAll ? bugReports : bugReports.take(3).toList();
        
        if (displayReports.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: displayReports.map((report) => _buildBugReportItem(context, report)).toList(),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(context, error),
    );
  }

  Widget _buildBugReportItem(BuildContext context, Map<String, dynamic> report) {
    final priority = report['priority'] as String? ?? 'low';
    final status = report['status'] as String? ?? 'open';
    final title = report['title'] as String? ?? '제목 없음';
    final description = report['description'] as String? ?? '설명 없음';
    final createdAt = report['createdAt'] as DateTime? ?? DateTime.now();
    final reporterName = report['reporterName'] as String? ?? '익명';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Priority Icon
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  _getPriorityIcon(priority),
                  color: _getPriorityColor(priority),
                  size: 16.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context, status),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildInfoItem(
                context: context,
                icon: Icons.person,
                label: '신고자',
                value: reporterName,
                color: Colors.blue,
              ),
              SizedBox(width: 16.w),
              _buildInfoItem(
                context: context,
                icon: Icons.schedule,
                label: '신고일',
                value: _formatDate(createdAt),
                color: Colors.orange,
              ),
              SizedBox(width: 16.w),
              _buildInfoItem(
                context: context,
                icon: Icons.flag,
                label: '우선순위',
                value: _getPriorityText(priority),
                color: _getPriorityColor(priority),
              ),
            ],
          ),
          if (isFullView) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewBugReportDetails(context, report),
                  icon: const Icon(Icons.visibility),
                  label: const Text('상세보기'),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => _respondToBugReport(context, report),
                  icon: const Icon(Icons.reply),
                  label: const Text('응답'),
                ),
                SizedBox(width: 8.w),
                if (status != 'resolved')
                  TextButton.icon(
                    onPressed: () => _resolveBugReport(context, report),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('해결'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case 'open':
        chipColor = Colors.red;
        statusText = '대기중';
        break;
      case 'in_progress':
        chipColor = Colors.orange;
        statusText = '진행중';
        break;
      case 'resolved':
        chipColor = Colors.green;
        statusText = '해결됨';
        break;
      case 'closed':
        chipColor = Colors.grey;
        statusText = '종료됨';
        break;
      default:
        chipColor = Colors.grey;
        statusText = '알 수 없음';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.keyboard_double_arrow_up;
      case 'medium':
        return Icons.keyboard_arrow_up;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.remove;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return '높음';
      case 'medium':
        return '보통';
      case 'low':
        return '낮음';
      default:
        return '알 수 없음';
    }
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              '$label: $value',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '1일 전';
    } else if (difference < 7) {
      return '${difference}일 전';
    } else if (difference < 30) {
      return '${difference ~/ 7}주 전';
    } else {
      return '${difference ~/ 30}개월 전';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(
              Icons.bug_report,
              size: 48.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              '신고된 버그가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '현재 처리할 버그 리포트가 없습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              '버그 리포트를 불러올 수 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터를 새로고침합니다.')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewBugReportDetails(BuildContext context, Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${report['title'] ?? '버그 리포트'} 상세정보를 확인합니다.')),
    );
  }

  void _respondToBugReport(BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('버그 리포트 응답'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${report['title'] ?? '버그 리포트'}에 응답하시겠습니까?'),
            SizedBox(height: 16.h),
            TextField(
              decoration: const InputDecoration(
                hintText: '응답 내용을 입력하세요...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('응답이 전송되었습니다.')),
              );
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  void _resolveBugReport(BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('버그 리포트 해결'),
        content: Text('${report['title'] ?? '이 버그 리포트'}를 해결된 것으로 표시하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('버그 리포트가 해결됨으로 표시되었습니다.')),
              );
            },
            child: const Text('해결'),
          ),
        ],
      ),
    );
  }
}