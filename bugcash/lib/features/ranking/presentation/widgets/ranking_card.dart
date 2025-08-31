import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/user_ranking.dart';

class RankingCard extends StatelessWidget {
  final UserRanking ranking;
  
  const RankingCard({
    super.key,
    required this.ranking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildRankBadge(),
          SizedBox(width: 16.w),
          _buildProfileSection(),
          const Spacer(),
          _buildStatsSection(),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    Color badgeColor;
    String badgeText;
    
    if (ranking.rank <= 3) {
      switch (ranking.rank) {
        case 1:
          badgeColor = const Color(0xFFFFD700); // Gold
          badgeText = '🥇';
          break;
        case 2:
          badgeColor = const Color(0xFFC0C0C0); // Silver
          badgeText = '🥈';
          break;
        case 3:
          badgeColor = const Color(0xFFCD7F32); // Bronze
          badgeText = '🥉';
          break;
        default:
          badgeColor = const Color(0xFF007AFF);
          badgeText = '${ranking.rank}';
      }
    } else {
      badgeColor = const Color(0xFF6C757D);
      badgeText = '${ranking.rank}';
    }

    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ranking.rank <= 3
            ? Text(
                badgeText,
                style: TextStyle(
                  fontSize: 20.sp,
                ),
              )
            : Text(
                badgeText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  ranking.username,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ranking.badgeEmoji.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Text(
                  ranking.badgeEmoji,
                  style: TextStyle(fontSize: 16.sp),
                ),
              ],
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${ranking.completedMissions}개 미션 완료',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6C757D),
            ),
          ),
          SizedBox(height: 4.h),
          _buildCategoryTags(),
        ],
      ),
    );
  }

  Widget _buildCategoryTags() {
    final topCategories = ranking.categoryPoints.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final displayCategories = topCategories.take(2).toList();
    
    if (displayCategories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      children: displayCategories.map((entry) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            entry.key,
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF007AFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${ranking.totalPoints}P',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF007AFF),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _getLastActiveText(),
          style: TextStyle(
            fontSize: 10.sp,
            color: const Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  String _getLastActiveText() {
    final now = DateTime.now();
    final difference = now.difference(ranking.lastActive);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}