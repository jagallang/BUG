import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MissionCard extends StatelessWidget {
  final String missionId;
  final String title;
  final String reward;
  final String deadline;
  final double progress;
  final Color color;
  final Map<String, dynamic>? missionData;
  final VoidCallback? onTap;

  const MissionCard({
    super.key,
    required this.missionId,
    required this.title,
    required this.reward,
    required this.deadline,
    required this.progress,
    required this.color,
    this.missionData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              Text(
                reward,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00BFA5),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '마감: $deadline',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF757575),
            ),
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
          SizedBox(height: 8.h),
          Text(
            '진행률: ${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
      ),
    );
  }
}