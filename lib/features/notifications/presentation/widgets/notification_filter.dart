import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/notification_model.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationFilter extends StatelessWidget {
  final NotificationType? selectedType;
  final Function(NotificationType?) onFilterChanged;

  const NotificationFilter({
    super.key,
    this.selectedType,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '알림 필터',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (selectedType != null)
                  GestureDetector(
                    onTap: () => onFilterChanged(null),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '전체 보기',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                _buildFilterOption(
                  type: null,
                  title: '전체',
                  icon: Icons.all_inbox,
                  color: AppColors.textSecondary,
                  description: '모든 종류의 알림',
                ),
                SizedBox(height: 12.h),
                _buildFilterOption(
                  type: NotificationType.mission,
                  title: '미션',
                  icon: Icons.assignment,
                  color: AppColors.primary,
                  description: '새로운 미션 및 미션 관련 알림',
                ),
                SizedBox(height: 12.h),
                _buildFilterOption(
                  type: NotificationType.points,
                  title: '포인트',
                  icon: Icons.monetization_on,
                  color: AppColors.goldText,
                  description: '포인트 적립 및 사용 내역',
                ),
                SizedBox(height: 12.h),
                _buildFilterOption(
                  type: NotificationType.ranking,
                  title: '랭킹',
                  icon: Icons.emoji_events,
                  color: AppColors.success,
                  description: '랭킹 변동 및 순위 관련 알림',
                ),
                SizedBox(height: 12.h),
                _buildFilterOption(
                  type: NotificationType.system,
                  title: '시스템',
                  icon: Icons.info,
                  color: AppColors.info,
                  description: '시스템 업데이트 및 공지사항',
                ),
                SizedBox(height: 12.h),
                _buildFilterOption(
                  type: NotificationType.marketing,
                  title: '홍보',
                  icon: Icons.campaign,
                  color: Colors.purple,
                  description: '이벤트 및 프로모션 정보',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required NotificationType? type,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onFilterChanged(type),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppColors.textHint.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}