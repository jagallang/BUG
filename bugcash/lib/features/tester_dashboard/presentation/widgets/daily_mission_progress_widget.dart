import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/mission_model.dart';
import 'daily_progress_calendar_widget.dart';

class DailyMissionProgressWidget extends StatelessWidget {
  final MissionCardWithProgress mission;
  final VoidCallback? onTapToday;
  final Function(DailyMissionProgress)? onTapDay;

  const DailyMissionProgressWidget({
    super.key,
    required this.mission,
    this.onTapToday,
    this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildOverallProgress(context),
          _buildDailyProgressCalendar(context),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final todayProgress = mission.todayProgress;
    final isUrgent = mission.deadline != null && _isUrgent(mission.deadline!);

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Mission type icon
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _getMissionTypeColor(mission.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getMissionTypeIcon(mission.type),
              color: _getMissionTypeColor(mission.type),
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          
          // Mission info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  mission.appName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 12.w, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(
                      '${mission.rewardPoints}P',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.schedule, size: 12.w, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      '${mission.estimatedMinutes}분',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Today status badge
          if (todayProgress != null)
            _buildTodayBadge(context, todayProgress),
          
          // Urgent badge
          if (isUrgent)
            Container(
              margin: EdgeInsets.only(left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '긴급',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayBadge(BuildContext context, DailyMissionProgress todayProgress) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (todayProgress.status) {
      case 'completed':
        badgeColor = Colors.green;
        badgeText = '완료';
        badgeIcon = Icons.check_circle;
        break;
      case 'in_progress':
        badgeColor = Colors.blue;
        badgeText = '진행중';
        badgeIcon = Icons.play_circle;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = '오늘할일';
        badgeIcon = Icons.today;
        break;
      case 'missed':
        badgeColor = Colors.red;
        badgeText = '놓침';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = '대기';
        badgeIcon = Icons.schedule;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12.w, color: badgeColor),
          SizedBox(width: 4.w),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '전체 진행률',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${mission.completedDays}/${mission.totalDays}일 (${(mission.actualOverallProgress * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: mission.actualOverallProgress,
              minHeight: 8.h,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(mission.actualOverallProgress),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressCalendar(BuildContext context) {
    return DailyProgressCalendarWidget(
      mission: mission,
      onTapDay: onTapDay,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final todayProgress = mission.todayProgress;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Show detailed mission progress
              },
              icon: const Icon(Icons.timeline),
              label: const Text('전체 진행률'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          if (todayProgress != null && !todayProgress.isCompleted)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onTapToday,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  todayProgress.status == 'in_progress' 
                      ? '계속하기' 
                      : '오늘 미션 시작',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            )
          else if (todayProgress?.isCompleted == true)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle),
                label: const Text('오늘 완료'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.schedule),
                label: const Text('대기중'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getMissionTypeColor(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return Colors.red;
      case MissionType.featureTesting:
        return Colors.blue;
      case MissionType.usabilityTest:
        return Colors.green;
      case MissionType.performanceTest:
        return Colors.orange;
      case MissionType.survey:
        return Colors.purple;
      case MissionType.feedback:
        return Colors.indigo;
      case MissionType.functional:
        return Colors.blue;
      case MissionType.uiUx:
        return Colors.teal;
      case MissionType.performance:
        return Colors.deepOrange;
      case MissionType.security:
        return Colors.redAccent;
      case MissionType.compatibility:
        return Colors.amber;
      case MissionType.accessibility:
        return Colors.cyan;
      case MissionType.localization:
        return Colors.pink;
    }
  }

  IconData _getMissionTypeIcon(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return Icons.bug_report;
      case MissionType.featureTesting:
        return Icons.featured_play_list;
      case MissionType.usabilityTest:
        return Icons.touch_app;
      case MissionType.performanceTest:
        return Icons.speed;
      case MissionType.survey:
        return Icons.quiz;
      case MissionType.feedback:
        return Icons.feedback;
      case MissionType.functional:
        return Icons.functions;
      case MissionType.uiUx:
        return Icons.design_services;
      case MissionType.performance:
        return Icons.timeline;
      case MissionType.security:
        return Icons.security;
      case MissionType.compatibility:
        return Icons.devices;
      case MissionType.accessibility:
        return Icons.accessibility;
      case MissionType.localization:
        return Icons.language;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    if (progress < 1.0) return Colors.blue;
    return Colors.green;
  }

  bool _isUrgent(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inHours <= 24;
  }
}