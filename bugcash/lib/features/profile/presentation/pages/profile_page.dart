import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/management_item.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/firebase_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../points/presentation/pages/point_history_page.dart';
import 'profile_edit_page.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Get actual user ID from auth provider
      final userId = CurrentUserService.getCurrentUserIdOrDefault();
      final userData = await FirebaseService.getUserData(userId);
      
      if (mounted) {
        setState(() {
          userProfile = userData ?? {
            'name': '익명 사용자',
            'email': 'anonymous@bugcash.com',
            'totalPoints': 0,
            'tier': 'BRONZE',
            'completedMissions': 0,
            'joinedAt': DateTime.now().toIso8601String(),
          };
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load user profile', 'Profile', e);
      if (mounted) {
        setState(() {
          isLoading = false;
          userProfile = {
            'name': '익명 사용자',
            'email': 'anonymous@bugcash.com',
            'totalPoints': 0,
            'tier': 'BRONZE',
            'completedMissions': 0,
            'joinedAt': DateTime.now().toIso8601String(),
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('👤 프로필'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditPage(),
                ),
              );
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            tooltip: '프로필 편집',
          ),
          IconButton(
            onPressed: () {
              _showProviderManagement(context);
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            tooltip: '앱 공급자 관리',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: 24.h),
                    _buildPointsCard(),
                    SizedBox(height: 16.h),
                    _buildStatsCard(),
                    SizedBox(height: 24.h),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          CircleAvatar(
            radius: 50.r,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person,
              size: 50.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            userProfile?['name'] ?? '익명 사용자',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            userProfile?['email'] ?? 'anonymous@bugcash.com',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _getTierColor(userProfile?['tier'] ?? 'BRONZE').withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '${userProfile?['tier'] ?? 'BRONZE'} 테스터',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: _getTierColor(userProfile?['tier'] ?? 'BRONZE'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    final totalPoints = userProfile?['totalPoints'] ?? 0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldStart,
            AppColors.goldEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: AppColors.goldText,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보유 포인트',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.goldText.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(totalPoints)} P',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldText,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PointHistoryPage(
                    userId: CurrentUserService.getCurrentUserIdOrDefault(), // Dynamic user ID
                  ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.history,
                color: AppColors.goldText,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final completedMissions = userProfile?['completedMissions'] ?? 0;
    final joinedDays = userProfile?['joinedAt'] != null 
        ? DateTime.now().difference(DateTime.parse(userProfile!['joinedAt'])).inDays 
        : 0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            '활동 통계',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildStatItem(
                Icons.flag,
                '완료한 미션',
                '$completedMissions개',
                AppColors.success,
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                Icons.calendar_today,
                '가입일',
                '$joinedDays일 전',
                AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.history,
          title: '포인트 내역',
          subtitle: '포인트 획득/사용 내역을 확인하세요',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PointHistoryPage(
                  userId: CurrentUserService.getCurrentUserIdOrDefault(), // Dynamic user ID
                ),
              ),
            );
          },
        ),
        SizedBox(height: 12.h),
        _buildActionButton(
          icon: Icons.edit,
          title: '프로필 편집',
          subtitle: '개인정보 및 설정을 변경하세요',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileEditPage(),
              ),
            );
          },
        ),
        SizedBox(height: 32.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '우상단 관리자 아이콘을 클릭해보세요!',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'BRONZE':
        return const Color(0xFFCD7F32);
      case 'SILVER':
        return const Color(0xFFC0C0C0);
      case 'GOLD':
        return AppColors.goldText;
      case 'PLATINUM':
        return const Color(0xFFE5E4E2);
      default:
        return AppColors.textHint;
    }
  }

  void _showProviderManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(20.w),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 앱 공급자 관리',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20.h),
            const ManagementItem(
              icon: Icons.assignment,
              title: '미션 생성 및 관리',
            ),
            const ManagementItem(
              icon: Icons.monitor_heart,
              title: '테스터 현황 모니터링',
            ),
            const ManagementItem(
              icon: Icons.bug_report,
              title: '버그 리포트 확인',
            ),
            const ManagementItem(
              icon: Icons.analytics,
              title: '통계 및 분석',
            ),
            const ManagementItem(
              icon: Icons.payments,
              title: '리워드 지급 관리',
            ),
            SizedBox(height: 20.h),
            Text(
              '완전한 관리 대시보드를 제공합니다!',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}