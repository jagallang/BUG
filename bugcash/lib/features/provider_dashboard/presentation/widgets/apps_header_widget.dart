import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppsHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onAddPressed;
  final String? addButtonText;
  final IconData? addButtonIcon;

  const AppsHeaderWidget({
    super.key,
    required this.title,
    this.onAddPressed,
    this.addButtonText,
    this.addButtonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (onAddPressed != null)
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: Icon(addButtonIcon ?? Icons.add),
            label: Text(addButtonText ?? '새 앱 등록'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
      ],
    );
  }
}