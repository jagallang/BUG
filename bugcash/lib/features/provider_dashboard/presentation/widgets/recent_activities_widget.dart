import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';

class RecentActivitiesWidget extends ConsumerWidget {
  final String providerId;

  const RecentActivitiesWidget({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(recentActivitiesProvider(providerId));

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 16.h),
            _buildActivitiesList(context, activitiesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '최근 활동',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('전체 활동 로그 페이지로 이동합니다.')),
            );
          },
          child: const Text('전체 보기'),
        ),
      ],
    );
  }

  Widget _buildActivitiesList(BuildContext context, AsyncValue<List<Map<String, dynamic>>> activitiesAsync) {
    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyState(context);
        }

        // Show only the most recent 5 activities
        final recentActivities = activities.take(5).toList();

        return Column(
          children: recentActivities.map((activity) => _buildActivityItem(context, activity)).toList(),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(context, error),
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> activity) {
    final type = activity['type'] as String? ?? 'unknown';
    final title = activity['title'] as String? ?? '활동';
    final description = activity['description'] as String? ?? '';
    final timestamp = activity['timestamp'] as DateTime? ?? DateTime.now();
    final metadata = activity['metadata'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: _getActivityTypeColor(type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getActivityTypeColor(type).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              _getActivityTypeIcon(type),
              color: _getActivityTypeColor(type),
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          // Activity Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTimestamp(timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (metadata.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _buildMetadataChips(context, metadata),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChips(BuildContext context, Map<String, dynamic> metadata) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      children: metadata.entries.take(2).map((entry) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getActivityTypeColor(String type) {
    switch (type) {
      case 'app_created':
      case 'app_updated':
        return Colors.blue;
      case 'mission_created':
      case 'mission_completed':
        return Colors.green;
      case 'bug_reported':
      case 'bug_resolved':
        return Colors.orange;
      case 'user_joined':
      case 'user_activity':
        return Colors.purple;
      case 'payment_processed':
      case 'revenue_earned':
        return Colors.indigo;
      case 'system_notification':
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type) {
      case 'app_created':
        return Icons.add_circle_outline;
      case 'app_updated':
        return Icons.update;
      case 'mission_created':
        return Icons.assignment_add;
      case 'mission_completed':
        return Icons.check_circle_outline;
      case 'bug_reported':
        return Icons.bug_report;
      case 'bug_resolved':
        return Icons.check_circle;
      case 'user_joined':
        return Icons.person_add;
      case 'user_activity':
        return Icons.person;
      case 'payment_processed':
        return Icons.payment;
      case 'revenue_earned':
        return Icons.monetization_on;
      case 'system_notification':
        return Icons.notifications;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.circle;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              '최근 활동이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '앱이나 미션을 생성하면 여기에 표시됩니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
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
              '활동 기록을 불러올 수 없습니다',
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
}