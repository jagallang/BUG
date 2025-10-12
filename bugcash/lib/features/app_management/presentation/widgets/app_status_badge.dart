import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey[600]!;
      case 'pending':
        return Colors.orange;
      case 'open':
        return AppColors.primary;
      case 'closed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return '초안';
      case 'pending':
        return '검토중';
      case 'open':
        return '활성';
      case 'closed':
        return '종료';
      case 'rejected':
        return '거부됨';
      default:
        return status;
    }
  }
}