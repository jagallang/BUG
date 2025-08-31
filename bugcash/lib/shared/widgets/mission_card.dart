import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../features/mission/presentation/pages/mission_detail_page.dart';

class MissionCard extends StatelessWidget {
  final String appName;
  final int currentDay;
  final int totalDays;
  final int dailyPoints;
  final bool todayCompleted;
  
  const MissionCard({
    super.key,
    required this.appName,
    required this.currentDay,
    required this.totalDays,
    required this.dailyPoints,
    required this.todayCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MissionDetailPage(
                missionId: 'mission_${appName.toLowerCase()}',
                appName: appName,
                appUrl: 'https://play.google.com/store',
                description: '$appName 앱을 체험하고 사용자 경험을 공유해주세요. 다양한 기능을 탐색하며 앱의 장단점을 발견해보세요.',
                currentDay: currentDay,
                totalDays: totalDays,
                dailyPoints: dailyPoints,
                todayCompleted: todayCompleted,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        '🛍️',
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Day $currentDay/$totalDays',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cashGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '+${dailyPoints}P',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cashGreen,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: currentDay / totalDays,
                      minHeight: 8.h,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(currentDay / totalDays * 100).toInt()}% 완료',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            todayCompleted
                                ? Icons.check_circle
                                : Icons.schedule,
                            size: 16.sp,
                            color: todayCompleted
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            todayCompleted ? '오늘 완료' : '오늘 미션 대기',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: todayCompleted
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}