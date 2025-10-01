import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/mission_management_model.dart';
import 'mission_status_badge.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';

/// 일일 미션 카드 위젯
class DailyMissionCard extends StatelessWidget {
  final DailyMissionModel mission;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onSubmit;
  final VoidCallback? onResubmit;

  const DailyMissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.onStart,
    this.onSubmit,
    this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 타이틀과 상태 배지
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.missionTitle,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  MissionStatusBadge(
                    status: mission.status,
                    isLarge: true,
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // 미션 설명
              Text(
                mission.missionDescription,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12.h),

              // 미션 정보
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(mission.missionDate),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.monetization_on,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${mission.baseReward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // 거절 사유 표시 (거절된 경우)
              if (mission.status == DailyMissionStatus.rejected && mission.reviewNote != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16.sp,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '거절 사유',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        mission.reviewNote!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16.h),

              // 액션 버튼
              _buildActionButton(),
            ],
          ),
        ),
      ).withUserTypeCard(
        userType: 'tester',
        borderRadius: 16.r,
        withHover: true,
      );
  }

  Widget _buildActionButton() {
    switch (mission.status) {
      case DailyMissionStatus.pending:
        // currentState가 'application_submitted'면 승인 대기 중
        if (mission.currentState == 'application_submitted') {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null, // 비활성화
              icon: Icon(Icons.hourglass_empty, size: 18.sp),
              label: const Text('공급자 승인 대기 중'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.orange.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          );
        }

        // currentState가 'approved'면 미션 시작 가능
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onStart,
            icon: Icon(Icons.play_arrow, size: 18.sp),
            label: const Text('미션 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );

      case DailyMissionStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSubmit,
            icon: Icon(Icons.upload, size: 18.sp),
            label: const Text('미션 제출'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusPending,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );

      case DailyMissionStatus.completed:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: Icon(Icons.pending, size: 18.sp),
            label: const Text('검토 대기 중'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );

      case DailyMissionStatus.approved:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: Icon(Icons.check_circle, size: 18.sp),
            label: const Text('승인 완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );

      case DailyMissionStatus.rejected:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onResubmit,
            icon: Icon(Icons.refresh, size: 18.sp),
            label: const Text('재제출'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}