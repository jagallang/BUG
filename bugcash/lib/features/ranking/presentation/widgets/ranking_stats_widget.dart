import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RankingStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  
  const RankingStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 전체 통계',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        _buildStatsGrid(),
        SizedBox(height: 24.h),
        _buildActivityChart(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final totalUsers = stats['totalUsers'] ?? 1250;
    final totalPoints = stats['totalPoints'] ?? 45000;
    final totalMissions = stats['totalMissions'] ?? 890;
    final avgPointsPerUser = totalUsers > 0 ? (totalPoints / totalUsers).round() : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: '총 테스터',
          value: _formatNumber(totalUsers),
          icon: Icons.people,
          color: const Color(0xFF007AFF),
          subtitle: '등록된 테스터 수',
        ),
        _buildStatCard(
          title: '누적 포인트',
          value: '${_formatNumber(totalPoints)}P',
          icon: Icons.stars,
          color: const Color(0xFFFFD700),
          subtitle: '전체 획득 포인트',
        ),
        _buildStatCard(
          title: '완료 미션',
          value: _formatNumber(totalMissions),
          icon: Icons.task_alt,
          color: const Color(0xFF00BFA5),
          subtitle: '총 완료된 미션',
        ),
        _buildStatCard(
          title: '평균 포인트',
          value: '${_formatNumber(avgPointsPerUser)}P',
          icon: Icons.trending_up,
          color: const Color(0xFFFF6B6B),
          subtitle: '테스터당 평균',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18.w,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF6C757D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📈 주간 활동',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  '최근 7일',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF007AFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildWeeklyChart(),
          SizedBox(height: 16.h),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Mock data for weekly activity
    final weekData = [
      {'day': '월', 'missions': 45, 'users': 120},
      {'day': '화', 'missions': 62, 'users': 145},
      {'day': '수', 'missions': 38, 'users': 98},
      {'day': '목', 'missions': 55, 'users': 132},
      {'day': '금', 'missions': 78, 'users': 156},
      {'day': '토', 'missions': 34, 'users': 89},
      {'day': '일', 'missions': 42, 'users': 95},
    ];

    final maxMissions = weekData.map((e) => e['missions'] as int).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weekData.map((data) {
          final missions = data['missions'] as int;
          final day = data['day'] as String;
          final height = (missions / maxMissions) * 100.h;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$missions',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF6C757D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                width: 24.w,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF007AFF).withValues(alpha: 0.8),
                      const Color(0xFF007AFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                day,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF6C757D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('완료된 미션', const Color(0xFF007AFF)),
        SizedBox(width: 20.w),
        _buildLegendItem('활성 사용자', const Color(0xFF00BFA5)),
      ],
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
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}