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
  final VoidCallback? onDelete;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onSubmit;
  final VoidCallback? onResubmit;

  const DailyMissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.onDelete,
    this.onStart,
    this.onComplete,
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
    // 디버그 로그
    print('🔍 [DailyMissionCard] _buildActionButton()');
    print('   ├─ currentState: ${mission.currentState}');
    print('   ├─ startedAt: ${mission.startedAt}');
    print('   ├─ completedAt: ${mission.completedAt}');
    print('   └─ status: ${mission.status}');

    // 1. 공급자 승인 대기 중 (application_submitted)
    if (mission.currentState == 'application_submitted') {
      return Row(
        children: [
          // 삭제 버튼
          if (onDelete != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete, size: 14.sp),
                label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
          if (onDelete != null) SizedBox(width: 6.w),
          // 승인 대기 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: Icon(Icons.hourglass_empty, size: 16.sp),
              label: Text('공급자 승인 대기 중', style: TextStyle(fontSize: 13.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.orange.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        ],
      );
    }

    // 2. 미션 시작 전 (application_approved + startedAt 없음)
    if (mission.currentState == 'application_approved' && mission.startedAt == null) {
      return Row(
        children: [
          // 삭제 버튼 (빨강)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete, size: 14.sp),
              label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          // 시작 버튼 (파랑)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: Icon(Icons.play_arrow, size: 14.sp),
              label: Text('시작', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        ],
      );
    }

    // 3. 미션 진행 중 (startedAt 있음 + completedAt 없음)
    if (mission.startedAt != null && mission.completedAt == null) {
      final elapsed = DateTime.now().difference(mission.startedAt!);
      final canComplete = elapsed.inMinutes >= 10;

      return Column(
        children: [
          // 타이머 표시 (10분 미경과 시)
          if (!canComplete) ...[
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 16.sp, color: Colors.orange),
                  SizedBox(width: 4.w),
                  Text(
                    '남은 시간: ${10 - elapsed.inMinutes}분 ${59 - (elapsed.inSeconds % 60)}초',
                    style: TextStyle(fontSize: 12.sp, color: Colors.orange[700], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
          ],

          // 완료 버튼과 삭제 버튼
          Row(
            children: [
              // 삭제 버튼
              if (onDelete != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete, size: 14.sp),
                    label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ),
              if (onDelete != null) SizedBox(width: 6.w),
              // 완료 버튼
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: canComplete ? onComplete : null,
                  icon: Icon(Icons.check_circle, size: 14.sp),
                  label: Text(
                    canComplete ? '미션 완료' : '10분 후 활성화',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canComplete ? Colors.orange : Colors.grey,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 4. 완료됨 + 제출 대기 (completedAt 있음 + status != completed)
    if (mission.completedAt != null && mission.status != DailyMissionStatus.completed) {
      return Row(
        children: [
          // 삭제 버튼
          if (onDelete != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete, size: 14.sp),
                label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
          if (onDelete != null) SizedBox(width: 6.w),
          // 제출 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: Icon(Icons.upload, size: 14.sp),
              label: Text('미션 제출', style: TextStyle(fontSize: 13.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        ],
      );
    }

    // 5. 제출 완료 (공급자 검토 대기)
    if (mission.status == DailyMissionStatus.completed) {
      return Row(
        children: [
          // 삭제 버튼
          if (onDelete != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete, size: 14.sp),
                label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
          if (onDelete != null) SizedBox(width: 6.w),
          // 검토 대기 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: Icon(Icons.pending, size: 14.sp),
              label: Text('검토 대기 중', style: TextStyle(fontSize: 13.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.7),
                disabledForegroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        ],
      );
    }

    // 6. 승인 완료
    if (mission.status == DailyMissionStatus.approved) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: Icon(Icons.check_circle, size: 14.sp),
          label: Text('승인 완료', style: TextStyle(fontSize: 13.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.green.withValues(alpha: 0.7),
            disabledForegroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      );
    }

    // 7. 거절됨 (재제출)
    if (mission.status == DailyMissionStatus.rejected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onResubmit,
          icon: Icon(Icons.refresh, size: 14.sp),
          label: Text('재제출', style: TextStyle(fontSize: 13.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      );
    }

    // 기본값 (예상치 못한 상태)
    return Row(
      children: [
        // 삭제 버튼
        if (onDelete != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete, size: 14.sp),
              label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        if (onDelete != null) SizedBox(width: 6.w),
        // 상태 확인 중 버튼
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: Icon(Icons.help_outline, size: 14.sp),
            label: Text('상태 확인 중', style: TextStyle(fontSize: 13.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}