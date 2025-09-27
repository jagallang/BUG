import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/mission_management_model.dart';

/// 미션 상태를 표시하는 배지 위젯
class MissionStatusBadge extends StatelessWidget {
  final DailyMissionStatus status;
  final bool isLarge;

  const MissionStatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeData = _getBadgeData(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12.w : 8.w,
        vertical: isLarge ? 8.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: badgeData.color,
        borderRadius: BorderRadius.circular(isLarge ? 20.r : 16.r),
        boxShadow: [
          BoxShadow(
            color: badgeData.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeData.icon,
            color: Colors.white,
            size: isLarge ? 18.sp : 14.sp,
          ),
          SizedBox(width: isLarge ? 6.w : 4.w),
          Text(
            badgeData.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLarge ? 14.sp : 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeData _getBadgeData(DailyMissionStatus status) {
    switch (status) {
      case DailyMissionStatus.pending:
        return _BadgeData(
          color: const Color(0xFF9E9E9E), // 회색
          icon: Icons.schedule,
          text: '대기중',
        );
      case DailyMissionStatus.inProgress:
        return _BadgeData(
          color: const Color(0xFF2196F3), // 파란색
          icon: Icons.play_circle,
          text: '진행중',
        );
      case DailyMissionStatus.completed:
        return _BadgeData(
          color: const Color(0xFFFF9800), // 주황색
          icon: Icons.pending,
          text: '검토대기',
        );
      case DailyMissionStatus.approved:
        return _BadgeData(
          color: const Color(0xFF4CAF50), // 초록색
          icon: Icons.check_circle,
          text: '승인완료',
        );
      case DailyMissionStatus.rejected:
        return _BadgeData(
          color: const Color(0xFFF44336), // 빨간색
          icon: Icons.cancel,
          text: '수정필요',
        );
    }
  }
}

class _BadgeData {
  final Color color;
  final IconData icon;
  final String text;

  _BadgeData({
    required this.color,
    required this.icon,
    required this.text,
  });
}