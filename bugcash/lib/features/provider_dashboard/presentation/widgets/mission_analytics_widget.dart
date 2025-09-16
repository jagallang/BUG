import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/mission_monitoring_provider.dart';

class MissionAnalyticsWidget extends ConsumerWidget {
  final String missionId;
  final String providerId;

  const MissionAnalyticsWidget({
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
        children: [
          // Overall Performance
          _buildOverallPerformance(context, mission, statistics),
          
          SizedBox(height: 16.h),
          
          // ROI Analysis
          _buildROIAnalysis(context, mission, statistics),
          
          SizedBox(height: 16.h),
          
          // Quality Insights
          _buildQualityInsights(context, statistics),
          
          SizedBox(height: 16.h),
          
          // Efficiency Metrics
          _buildEfficiencyMetrics(context, statistics),
          
          SizedBox(height: 16.h),
          
          // Recommendations
          _buildRecommendations(context, mission, statistics),
        ],
      ),
    );
  }

  Widget _buildOverallPerformance(
    BuildContext context,
    MissionMonitoringData mission,
    MissionStatistics? statistics,
  ) {
    final performanceScore = _calculatePerformanceScore(mission, statistics);
    
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
                Text(
                  '전체 성과',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // Performance Score Circle
            Center(
              child: SizedBox(
                width: 120.w,
                height: 120.w,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: performanceScore / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getPerformanceColor(performanceScore),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            performanceScore.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: _getPerformanceColor(performanceScore),
                            ),
                          ),
                          Text(
                            '성과 점수',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Performance breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceMetric(
                  '참여도',
                  '${((mission.activeParticipants / mission.totalParticipants) * 100).toStringAsFixed(0)}%',
                  Colors.blue,
                ),
                _buildPerformanceMetric(
                  '완료율',
                  '${((mission.completedCount / mission.totalParticipants) * 100).toStringAsFixed(0)}%',
                  Colors.green,
                ),
                _buildPerformanceMetric(
                  '품질',
                  statistics != null 
                      ? '${(statistics.averageQualityScore * 100).toStringAsFixed(0)}%'
                      : 'N/A',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildROIAnalysis(
    BuildContext context,
    MissionMonitoringData mission,
    MissionStatistics? statistics,
  ) {
    final totalCost = mission.completedCount * mission.rewardPoints;
    final expectedBugsFound = statistics?.approvedSubmissions ?? 0;
    final costPerBug = expectedBugsFound > 0 ? totalCost / expectedBugsFound : 0;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.green,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'ROI 분석',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: _buildROIItem(
                    '총 지급 포인트',
                    '${totalCost}P',
                    Icons.monetization_on,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildROIItem(
                    '발견된 이슈',
                    '$expectedBugsFound개',
                    Icons.bug_report,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            Row(
              children: [
                Expanded(
                  child: _buildROIItem(
                    '이슈당 비용',
                    costPerBug > 0 ? '${costPerBug.toStringAsFixed(0)}P' : 'N/A',
                    Icons.calculate,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildROIItem(
                    '예상 절약 비용',
                    '${expectedBugsFound * 50000}원',
                    Icons.savings,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.thumb_up, color: Colors.green, size: 20.w),
                  SizedBox(height: 4.h),
                  Text(
                    'ROI: ${((expectedBugsFound * 50000 - totalCost * 10) / (totalCost * 10) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    '투자 대비 효과적인 테스팅',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildROIItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityInsights(BuildContext context, MissionStatistics? statistics) {
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
                  Icons.stars,
                  color: Colors.amber,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '품질 분석',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Quality metrics
            Row(
              children: [
                Expanded(
                  child: _buildQualityMetric(
                    '승인률',
                    '${((statistics.approvedSubmissions / statistics.totalSubmissions) * 100).toStringAsFixed(1)}%',
                    Colors.green,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQualityMetric(
                    '반려율',
                    '${((statistics.rejectedSubmissions / statistics.totalSubmissions) * 100).toStringAsFixed(1)}%',
                    Colors.red,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQualityMetric(
                    '평균 품질',
                    '${(statistics.averageQualityScore * 100).toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Issue type distribution
            Text(
              '이슈 유형별 분포',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            ...statistics.issueTypeDistribution.entries.map((entry) {
              final total = statistics.issueTypeDistribution.values.reduce((a, b) => a + b);
              final percentage = (entry.value / total * 100);
              
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60.w,
                      child: Text(
                        entry.key,
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 16.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: _getIssueTypeColor(entry.key),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 40.w,
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
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

  Widget _buildQualityMetric(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyMetrics(BuildContext context, MissionStatistics? statistics) {
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
                  Icons.speed,
                  color: Colors.indigo,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '효율성 지표',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 2,
              children: [
                _buildEfficiencyItem(
                  '평균 완료 시간',
                  '${statistics.averageCompletionTime.toStringAsFixed(0)}분',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildEfficiencyItem(
                  '시간당 제출',
                  '${(statistics.totalSubmissions / 24).toStringAsFixed(1)}건',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildEfficiencyItem(
                  '테스터 참여율',
                  '85%',
                  Icons.people,
                  Colors.purple,
                ),
                _buildEfficiencyItem(
                  '재참여율',
                  '72%',
                  Icons.repeat,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyItem(String label, String value, IconData icon, Color color) {
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
                    fontSize: 14.sp,
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

  Widget _buildRecommendations(
    BuildContext context,
    MissionMonitoringData mission,
    MissionStatistics? statistics,
  ) {
    final recommendations = _generateRecommendations(mission, statistics);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '개선 제안',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            ...recommendations.map((recommendation) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: recommendation.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: recommendation.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      recommendation.icon,
                      color: recommendation.color,
                      size: 20.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.title,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: recommendation.color,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            recommendation.description,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  double _calculatePerformanceScore(
    MissionMonitoringData mission,
    MissionStatistics? statistics,
  ) {
    double score = 0;
    
    // Participation score (40%)
    final participationRate = mission.activeParticipants / mission.totalParticipants;
    score += participationRate * 40;
    
    // Completion score (30%)
    final completionRate = mission.completedCount / mission.totalParticipants;
    score += completionRate * 30;
    
    // Quality score (30%)
    if (statistics != null) {
      score += statistics.averageQualityScore * 30;
    }
    
    return score.clamp(0.0, 100.0);
  }

  Color _getPerformanceColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
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

  List<Recommendation> _generateRecommendations(
    MissionMonitoringData mission,
    MissionStatistics? statistics,
  ) {
    final recommendations = <Recommendation>[];
    
    // Check participation rate
    final participationRate = mission.activeParticipants / mission.totalParticipants;
    if (participationRate < 0.7) {
      recommendations.add(Recommendation(
        title: '참여율 개선 필요',
        description: '보상을 늘리거나 미션 설명을 더 명확하게 작성해보세요',
        icon: Icons.people,
        color: Colors.blue,
      ));
    }
    
    // Check quality
    if (statistics != null && statistics.averageQualityScore < 0.7) {
      recommendations.add(Recommendation(
        title: '품질 향상 필요',
        description: '더 자세한 가이드라인을 제공하거나 예시를 추가해보세요',
        icon: Icons.star,
        color: Colors.orange,
      ));
    }
    
    // Check completion time
    if (statistics != null && statistics.averageCompletionTime > 60) {
      recommendations.add(Recommendation(
        title: '완료 시간 최적화',
        description: '미션을 더 작은 단위로 나누거나 복잡도를 조정해보세요',
        icon: Icons.timer,
        color: Colors.purple,
      ));
    }
    
    // Default positive feedback
    if (recommendations.isEmpty) {
      recommendations.add(Recommendation(
        title: '우수한 성과!',
        description: '현재 미션이 매우 잘 운영되고 있습니다. 이 패턴을 다른 미션에도 적용해보세요',
        icon: Icons.thumb_up,
        color: Colors.green,
      ));
    }
    
    return recommendations;
  }
}

class Recommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Recommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}