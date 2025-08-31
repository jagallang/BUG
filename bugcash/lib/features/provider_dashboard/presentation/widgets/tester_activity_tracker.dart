import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/mission_monitoring_provider.dart';

class TesterActivityTracker extends ConsumerWidget {
  final String missionId;
  final String providerId;

  const TesterActivityTracker({
    super.key,
    required this.missionId,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(missionMonitoringProvider);
    
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

    final statistics = monitoringState.statistics[missionId];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Top Performers Section
          if (statistics != null)
            _buildTopPerformers(context, statistics.topPerformers),
          
          SizedBox(height: 16.h),
          
          // Activity Timeline
          _buildActivityTimeline(context, statistics),
          
          SizedBox(height: 16.h),
          
          // Performance Metrics
          _buildPerformanceMetrics(context, statistics),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(BuildContext context, List<TesterPerformance> performers) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Text(
                  '상위 테스터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...performers.take(3).map((performer) => 
              _buildPerformerItem(context, performer, performers.indexOf(performer) + 1)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerItem(BuildContext context, TesterPerformance performer, int rank) {
    final medalColor = rank == 1 ? Colors.amber : rank == 2 ? Colors.grey : Colors.brown;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: rank == 1 ? Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2) : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: medalColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          // Tester info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performer.testerName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.assignment_turned_in, size: 14.w, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(
                      '${performer.submissionsCount}건',
                      style: TextStyle(fontSize: 11.sp, color: Colors.green),
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.schedule, size: 14.w, color: Colors.blue),
                    SizedBox(width: 4.w),
                    Text(
                      '평균 ${performer.averageTime.inMinutes}분',
                      style: TextStyle(fontSize: 11.sp, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Quality score
          Column(
            children: [
              Text(
                '품질',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getQualityColor(performer.qualityScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${(performer.qualityScore * 100).round()}%',
                  style: TextStyle(
                    color: _getQualityColor(performer.qualityScore),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(BuildContext context, MissionStatistics? statistics) {
    if (statistics == null) {
      return Card(
        child: Container(
          height: 200.h,
          padding: EdgeInsets.all(16.w),
          child: const Center(
            child: Text(
              '활동 데이터를 불러오는 중...',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '최근 활동',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ..._generateRecentActivities().map((activity) => 
              _buildActivityItem(context, activity)
            ),
          ],
        ),
      ),
    );
  }

  List<ActivityItem> _generateRecentActivities() {
    // Mock recent activities - replace with actual data
    return [
      ActivityItem(
        testerName: '김철수',
        action: '버그 리포트 제출',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: ActivityType.submission,
      ),
      ActivityItem(
        testerName: '이영희',
        action: '테스트 완료',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: ActivityType.completion,
      ),
      ActivityItem(
        testerName: '박민수',
        action: '미션 참여',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: ActivityType.participation,
      ),
      ActivityItem(
        testerName: '정수진',
        action: '추가 정보 제출',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: ActivityType.update,
      ),
      ActivityItem(
        testerName: '최동훈',
        action: '스크린샷 업로드',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: ActivityType.upload,
      ),
    ];
  }

  Widget _buildActivityItem(BuildContext context, ActivityItem activity) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // Activity icon
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: _getActivityTypeColor(activity.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActivityTypeIcon(activity.type),
              color: _getActivityTypeColor(activity.type),
              size: 18.w,
            ),
          ),
          SizedBox(width: 12.w),
          
          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      activity.testerName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(activity.timestamp),
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
          
          // Status indicator
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: _getActivityTypeColor(activity.type),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, MissionStatistics? statistics) {
    if (statistics == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '성과 지표',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // Metrics grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 2.5,
              children: [
                _buildMetricItem(
                  '참여율',
                  '85%',
                  Icons.people,
                  Colors.blue,
                ),
                _buildMetricItem(
                  '완료율',
                  '72%',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildMetricItem(
                  '평균 품질',
                  '${(statistics.averageQualityScore * 100).toStringAsFixed(1)}%',
                  Icons.star,
                  Colors.orange,
                ),
                _buildMetricItem(
                  '재참여율',
                  '65%',
                  Icons.repeat,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(double quality) {
    if (quality >= 0.9) return Colors.green;
    if (quality >= 0.7) return Colors.blue;
    if (quality >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.submission:
        return Colors.blue;
      case ActivityType.completion:
        return Colors.green;
      case ActivityType.participation:
        return Colors.purple;
      case ActivityType.update:
        return Colors.orange;
      case ActivityType.upload:
        return Colors.teal;
    }
  }

  IconData _getActivityTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.submission:
        return Icons.send;
      case ActivityType.completion:
        return Icons.check_circle;
      case ActivityType.participation:
        return Icons.person_add;
      case ActivityType.update:
        return Icons.edit;
      case ActivityType.upload:
        return Icons.cloud_upload;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
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
}

// Activity models
enum ActivityType {
  submission,
  completion,
  participation,
  update,
  upload,
}

class ActivityItem {
  final String testerName;
  final String action;
  final DateTime timestamp;
  final ActivityType type;

  ActivityItem({
    required this.testerName,
    required this.action,
    required this.timestamp,
    required this.type,
  });
}