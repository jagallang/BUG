import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/project_status_constants.dart';

class AppStatusBadge extends StatelessWidget {
  final String status;

  const AppStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // v2.186.29: ProjectStatusConstants 사용으로 일관성 확보
  // v2.186.31: 색상도 ProjectStatusConstants 사용
  Color _getStatusColor(String status) {
    return ProjectStatusConstants.getStatusColor(status);
  }

  String _getStatusText(String status) {
    return ProjectStatusConstants.getDisplayName(status);
  }
}