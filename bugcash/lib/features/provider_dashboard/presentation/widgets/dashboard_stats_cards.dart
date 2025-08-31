import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/provider_model.dart';

class DashboardStatsCards extends StatelessWidget {
  final DashboardStats stats;

  const DashboardStatsCards({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '총 앱',
                value: stats.totalApps.toString(),
                subtitle: '활성: ${stats.activeApps}',
                icon: Icons.apps,
                color: colorScheme.primary,
                gradientColors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '총 미션',
                value: stats.totalMissions.toString(),
                subtitle: '활성: ${stats.activeMissions}',
                icon: Icons.assignment,
                color: colorScheme.secondary,
                gradientColors: [
                  colorScheme.secondary,
                  colorScheme.secondary.withValues(alpha: 0.7),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '버그 리포트',
                value: stats.totalBugReports.toString(),
                subtitle: '해결: ${stats.resolvedBugReports}',
                icon: Icons.bug_report,
                color: Colors.orange,
                gradientColors: [
                  Colors.orange,
                  Colors.orange.withValues(alpha: 0.7),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '테스터',
                value: stats.totalTesters.toString(),
                subtitle: '활성: ${stats.activeTesters}',
                icon: Icons.people,
                color: Colors.green,
                gradientColors: [
                  Colors.green,
                  Colors.green.withValues(alpha: 0.7),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '총 수익',
                value: '₩${_formatCurrency(stats.totalRevenue)}',
                subtitle: '평균 평점: ${stats.averageAppRating.toStringAsFixed(1)}',
                icon: Icons.attach_money,
                color: Colors.purple,
                gradientColors: [
                  Colors.purple,
                  Colors.purple.withValues(alpha: 0.7),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '완료율',
                value: '${_calculateCompletionRate().toStringAsFixed(1)}%',
                subtitle: '완료: ${stats.completedMissions}',
                icon: Icons.check_circle,
                color: Colors.teal,
                gradientColors: [
                  Colors.teal,
                  Colors.teal.withValues(alpha: 0.7),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: 32.w,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  double _calculateCompletionRate() {
    if (stats.totalMissions == 0) return 0.0;
    return (stats.completedMissions / stats.totalMissions) * 100;
  }
}