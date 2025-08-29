import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ManagementItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const ManagementItem({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF00BFA5),
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}