import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/user_ranking.dart';

class PodiumWidget extends StatelessWidget {
  final List<UserRanking> topThree;
  
  const PodiumWidget({
    super.key,
    required this.topThree,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.length < 3) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 200.h,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Stack(
        children: [
          _buildPodiumBase(),
          _buildWinnerPositions(),
        ],
      ),
    );
  }

  Widget _buildPodiumBase() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place podium
          Expanded(
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFC0C0C0).withValues(alpha: 0.8),
                    const Color(0xFFC0C0C0),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🥈',
                      style: TextStyle(fontSize: 24.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '2nd',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // First place podium (highest)
          Expanded(
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.8),
                    const Color(0xFFFFD700),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🥇',
                      style: TextStyle(fontSize: 32.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '1st',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Third place podium
          Expanded(
            child: Container(
              height: 60.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFCD7F32).withValues(alpha: 0.8),
                    const Color(0xFFCD7F32),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🥉',
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '3rd',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerPositions() {
    return Positioned.fill(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Second place user
          Expanded(
            child: _buildWinnerCard(topThree[1], 2),
          ),
          // First place user  
          Expanded(
            child: _buildWinnerCard(topThree[0], 1),
          ),
          // Third place user
          Expanded(
            child: _buildWinnerCard(topThree[2], 3),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCard(UserRanking user, int position) {
    double topMargin;
    Color cardColor;
    
    switch (position) {
      case 1:
        topMargin = 0;
        cardColor = const Color(0xFFFFD700);
        break;
      case 2:
        topMargin = 20.h;
        cardColor = const Color(0xFFC0C0C0);
        break;
      case 3:
        topMargin = 40.h;
        cardColor = const Color(0xFFCD7F32);
        break;
      default:
        topMargin = 0;
        cardColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(top: topMargin, left: 4.w, right: 4.w),
      child: Column(
        children: [
          // Profile avatar
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // User info card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: cardColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${user.totalPoints}P',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${user.completedMissions}개 완료',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}