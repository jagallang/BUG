import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/tester_dashboard_provider.dart';

class TesterProfileWidget extends ConsumerWidget {
  final String testerId;

  const TesterProfileWidget({
    super.key,
    required this.testerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(testerDashboardProvider);
    final profile = dashboardState.testerProfile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(context, profile),
          
          SizedBox(height: 16.h),
          
          // Level Progress
          _buildLevelProgress(context, profile),
          
          SizedBox(height: 16.h),
          
          // Statistics
          _buildStatistics(context, profile),
          
          SizedBox(height: 16.h),
          
          // Skills & Interests
          _buildSkillsAndInterests(context, profile),
          
          SizedBox(height: 16.h),
          
          // Achievements
          _buildAchievements(context, profile),
          
          SizedBox(height: 16.h),
          
          // Settings
          _buildSettings(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, TesterProfile profile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 50.w,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: profile.profileImage != null 
                      ? NetworkImage(profile.profileImage!)
                      : null,
                  child: profile.profileImage == null
                      ? Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'T',
                          style: TextStyle(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _editProfileImage(context),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16.w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Name and Level
            Text(
              profile.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getLevelColor(profile.level).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getLevelIcon(profile.level),
                    color: _getLevelColor(profile.level),
                    size: 16.w,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _getLevelText(profile.level),
                    style: TextStyle(
                      color: _getLevelColor(profile.level),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Join date
            Text(
              '가입일: ${_formatJoinDate(profile.joinedDate)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, TesterProfile profile) {
    final nextLevel = _getNextLevel(profile.level);
    final currentLevelXP = _getLevelMinXP(profile.level);
    final nextLevelXP = _getLevelMinXP(nextLevel);
    final progress = nextLevel != profile.level 
        ? (profile.experiencePoints - currentLevelXP) / (nextLevelXP - currentLevelXP)
        : 1.0;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue, size: 20.w),
                SizedBox(width: 8.w),
                Text(
                  '레벨 진행도',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${profile.experiencePoints} XP',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            Row(
              children: [
                Text(
                  _getLevelText(profile.level),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _getLevelColor(profile.level),
                  ),
                ),
                const Spacer(),
                if (nextLevel != profile.level)
                  Text(
                    _getLevelText(nextLevel),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _getLevelColor(nextLevel),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 6.h),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12.h,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(profile.level)),
              ),
            ),
            
            if (nextLevel != profile.level) ...[
              SizedBox(height: 6.h),
              Text(
                '다음 레벨까지 ${nextLevelXP - profile.experiencePoints} XP',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, TesterProfile profile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '활동 통계',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 1.5,
              children: [
                _buildStatItem(
                  '완료 미션',
                  '${profile.completedMissions}개',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  '성공률',
                  '${(profile.successRate * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildStatItem(
                  '평균 평점',
                  '${profile.averageRating.toStringAsFixed(1)}/5.0',
                  Icons.star,
                  Colors.orange,
                ),
                _buildStatItem(
                  '총 포인트',
                  '${profile.totalPoints}P',
                  Icons.monetization_on,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsAndInterests(BuildContext context, TesterProfile profile) {
    return Column(
      children: [
        // Skills
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.blue, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      '보유 스킬',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _editSkills(context, profile),
                      child: const Text('편집'),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: profile.skills.map((skill) => Chip(
                    label: Text(skill),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12.sp,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Interests
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      '관심 분야',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _editInterests(context, profile),
                      child: const Text('편집'),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: profile.interests.map((interest) => Chip(
                    label: Text(interest),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12.sp,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(BuildContext context, TesterProfile profile) {
    final achievements = _getMockAchievements(profile);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20.w),
                SizedBox(width: 8.w),
                Text(
                  '업적',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 1,
              children: achievements.map((achievement) => 
                _buildAchievementItem(achievement)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: achievement.isUnlocked 
            ? Colors.amber.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: achievement.isUnlocked 
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            color: achievement.isUnlocked ? Colors.amber.shade700 : Colors.grey,
            size: 24.w,
          ),
          SizedBox(height: 4.h),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: achievement.isUnlocked ? Colors.amber.shade700 : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '설정',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            _buildSettingItem(
              '프로필 수정',
              '이름, 이메일 등 기본 정보를 수정합니다',
              Icons.edit,
              () => _editProfile(context),
            ),
            _buildSettingItem(
              '알림 설정',
              '미션 알림 및 앱 알림을 관리합니다',
              Icons.notifications,
              () => _manageNotifications(context),
            ),
            _buildSettingItem(
              '계정 관리',
              '비밀번호 변경 및 계정 보안을 관리합니다',
              Icons.security,
              () => _manageAccount(context),
            ),
            _buildSettingItem(
              '고객 지원',
              '문의하기 및 도움말을 확인합니다',
              Icons.help,
              () => _showSupport(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 20.w),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20.w),
      onTap: onTap,
    );
  }

  // Helper methods
  Color _getLevelColor(TesterLevel level) {
    switch (level) {
      case TesterLevel.beginner:
        return Colors.green;
      case TesterLevel.intermediate:
        return Colors.blue;
      case TesterLevel.advanced:
        return Colors.purple;
      case TesterLevel.expert:
        return Colors.red;
    }
  }

  IconData _getLevelIcon(TesterLevel level) {
    switch (level) {
      case TesterLevel.beginner:
        return Icons.school;
      case TesterLevel.intermediate:
        return Icons.trending_up;
      case TesterLevel.advanced:
        return Icons.star;
      case TesterLevel.expert:
        return Icons.diamond;
    }
  }

  String _getLevelText(TesterLevel level) {
    switch (level) {
      case TesterLevel.beginner:
        return '초보 테스터';
      case TesterLevel.intermediate:
        return '중급 테스터';
      case TesterLevel.advanced:
        return '고급 테스터';
      case TesterLevel.expert:
        return '전문가';
    }
  }

  TesterLevel _getNextLevel(TesterLevel currentLevel) {
    switch (currentLevel) {
      case TesterLevel.beginner:
        return TesterLevel.intermediate;
      case TesterLevel.intermediate:
        return TesterLevel.advanced;
      case TesterLevel.advanced:
        return TesterLevel.expert;
      case TesterLevel.expert:
        return TesterLevel.expert;
    }
  }

  int _getLevelMinXP(TesterLevel level) {
    switch (level) {
      case TesterLevel.beginner:
        return 0;
      case TesterLevel.intermediate:
        return 1000;
      case TesterLevel.advanced:
        return 3000;
      case TesterLevel.expert:
        return 5000;
    }
  }

  List<Achievement> _getMockAchievements(TesterProfile profile) {
    return [
      Achievement('첫 미션', Icons.flag, profile.completedMissions > 0),
      Achievement('베테랑', Icons.star, profile.completedMissions >= 10),
      Achievement('마스터', Icons.diamond, profile.completedMissions >= 50),
      Achievement('완벽주의자', Icons.trending_up, profile.successRate >= 0.9),
      Achievement('인기 테스터', Icons.favorite, profile.averageRating >= 4.5),
      Achievement('포인트왕', Icons.monetization_on, profile.totalPoints >= 10000),
    ];
  }

  String _formatJoinDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // Action methods
  void _editProfileImage(BuildContext context) {
    // Implement profile image editing
  }

  void _editSkills(BuildContext context, TesterProfile profile) {
    // Implement skills editing
  }

  void _editInterests(BuildContext context, TesterProfile profile) {
    // Implement interests editing
  }

  void _editProfile(BuildContext context) {
    // Implement profile editing
  }

  void _manageNotifications(BuildContext context) {
    // Implement notification management
  }

  void _manageAccount(BuildContext context) {
    // Implement account management
  }

  void _showSupport(BuildContext context) {
    // Implement support page
  }
}

// Achievement model
class Achievement {
  final String name;
  final IconData icon;
  final bool isUnlocked;

  Achievement(this.name, this.icon, this.isUnlocked);
}