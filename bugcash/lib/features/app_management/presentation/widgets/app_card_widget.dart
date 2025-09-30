import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/provider_app_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/extensions/responsive_extensions.dart';
import 'app_status_badge.dart';

class AppCardWidget extends StatelessWidget {
  final ProviderAppEntity app;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const AppCardWidget({
    super.key,
    required this.app,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppColors.cardShadowMedium,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            AppStatusBadge(status: app.status),
            SizedBox(height: 16.h),

            // App Header
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.apps,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: TextStyle(
                          fontSize: 16.responsiveFont(context),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        app.category,
                        style: TextStyle(
                          fontSize: 14.responsiveFont(context),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20.sp,
                        ),
                        tooltip: '수정',
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                        tooltip: '삭제',
                      ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Description
            if (app.description.isNotEmpty) ...[
              Text(
                app.description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16.h),
            ],

            // Statistics
            Row(
              children: [
                _buildStatItem('테스터', '${app.activeTesters}/${app.totalTesters}'),
                SizedBox(width: 24.w),
                _buildStatItem('버그', '${app.resolvedBugs}/${app.totalBugs}'),
                SizedBox(width: 24.w),
                _buildStatItem('진행률', '${app.progressPercentage.toInt()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}