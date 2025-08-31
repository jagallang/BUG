import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/mission_monitoring_provider.dart';

class MissionProgressDashboard extends ConsumerWidget {
  final String missionId;
  final String providerId;

  const MissionProgressDashboard({
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

    final mission = monitoringState.missions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => monitoringState.missions.first,
    );

    final statistics = monitoringState.statistics[missionId];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Overview Card
          _buildProgressOverview(context, mission),
          
          SizedBox(height: 16.h),
          
          // Real-time Activity Chart
          _buildActivityChart(context, statistics),
          
          SizedBox(height: 16.h),
          
          // Metrics Grid
          _buildMetricsGrid(context, mission, statistics),
          
          SizedBox(height: 16.h),
          
          // Issue Distribution
          if (statistics != null)
            _buildIssueDistribution(context, statistics),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(BuildContext context, MissionMonitoringData mission) {
    final progress = mission.progressPercentage;
    final remainingDays = mission.deadline?.difference(DateTime.now()).inDays;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(mission.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              _getStatusText(mission.status),
                              style: TextStyle(
                                color: _getStatusColor(mission.status),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (remainingDays != null) ...[
                            SizedBox(width: 8.w),
                            Icon(Icons.schedule, size: 14.w, color: Colors.grey),
                            SizedBox(width: 4.w),
                            Text(
                              '$remainingDays일 남음',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: remainingDays <= 3 ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '전체 진행률',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
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
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12.h,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Participation Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  '참여자',
                  '${mission.activeParticipants}/${mission.totalParticipants}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  '완료',
                  '${mission.completedCount}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  '검토 대기',
                  '${mission.pendingReviews}',
                  Icons.pending,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.w),
        SizedBox(height: 4.h),
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
            fontSize: 11.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityChart(BuildContext context, MissionStatistics? statistics) {
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
            Text(
              '24시간 활동 현황',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 200.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: statistics.hourlyActivity
                    .asMap()
                    .entries
                    .where((entry) => entry.key % 4 == 0) // Show every 4th hour
                    .map((entry) => _buildSimpleBar(
                          context,
                          '${entry.key}h',
                          entry.value.submissions,
                          entry.value.reviews,
                          entry.value.approvals,
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 12.h),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('제출', Colors.blue),
                SizedBox(width: 16.w),
                _buildLegendItem('검토', Colors.orange),
                SizedBox(width: 16.w),
                _buildLegendItem('승인', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBar(
    BuildContext context,
    String label,
    int submissions,
    int reviews,
    int approvals,
  ) {
    final maxValue = [submissions, reviews, approvals].reduce((a, b) => a > b ? a : b);
    final barHeight = 160.h;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Column(
          children: [
            // Bars
            SizedBox(
              height: barHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Submissions bar
                  Container(
                    width: 8.w,
                    height: maxValue > 0 ? (submissions / maxValue * barHeight * 0.8).clamp(2.0, barHeight * 0.8) : 2.h,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Reviews bar
                  Container(
                    width: 8.w,
                    height: maxValue > 0 ? (reviews / maxValue * barHeight * 0.8).clamp(2.0, barHeight * 0.8) : 2.h,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Approvals bar
                  Container(
                    width: 8.w,
                    height: maxValue > 0 ? (approvals / maxValue * barHeight * 0.8).clamp(2.0, barHeight * 0.8) : 2.h,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    MissionMonitoringData mission,
    MissionStatistics? statistics,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          '총 제출',
          statistics?.totalSubmissions.toString() ?? '-',
          Icons.upload_file,
          Colors.blue,
          subtitle: '승인: ${statistics?.approvedSubmissions ?? 0}',
        ),
        _buildMetricCard(
          context,
          '평균 완료 시간',
          statistics != null 
              ? '${statistics.averageCompletionTime.toStringAsFixed(1)}분'
              : '-',
          Icons.timer,
          Colors.orange,
        ),
        _buildMetricCard(
          context,
          '품질 점수',
          statistics != null 
              ? '${(statistics.averageQualityScore * 100).toStringAsFixed(1)}%'
              : '-',
          Icons.star,
          Colors.purple,
        ),
        _buildMetricCard(
          context,
          '보상 포인트',
          '${mission.rewardPoints}P',
          Icons.monetization_on,
          Colors.green,
          subtitle: '총 ${mission.completedCount * mission.rewardPoints}P 지급',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24.w),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIssueDistribution(BuildContext context, MissionStatistics statistics) {
    final total = statistics.issueTypeDistribution.values.reduce((a, b) => a + b);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이슈 유형 분포',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ...statistics.issueTypeDistribution.entries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80.w,
                      child: Text(
                        entry.key,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: entry.value / total,
                            child: Container(
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: _getIssueTypeColor(entry.key),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.draft:
        return Colors.grey;
      case MissionStatus.active:
        return Colors.green;
      case MissionStatus.inProgress:
        return Colors.blue;
      case MissionStatus.review:
        return Colors.orange;
      case MissionStatus.completed:
        return Colors.purple;
      case MissionStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(MissionStatus status) {
    switch (status) {
      case MissionStatus.draft:
        return '초안';
      case MissionStatus.active:
        return '활성';
      case MissionStatus.inProgress:
        return '진행중';
      case MissionStatus.review:
        return '검토중';
      case MissionStatus.completed:
        return '완료';
      case MissionStatus.cancelled:
        return '취소됨';
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.6) return Colors.orange;
    if (progress < 0.8) return Colors.blue;
    return Colors.green;
  }

  Color _getIssueTypeColor(String type) {
    switch (type) {
      case 'UI/UX':
        return Colors.blue;
      case 'Crash':
        return Colors.red;
      case 'Performance':
        return Colors.orange;
      case 'Feature':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}