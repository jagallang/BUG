import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/notification_model.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final fcmTokenAsync = ref.watch(fcmTokenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🔔 알림 설정'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralSettings(context, ref, settings),
              SizedBox(height: 24.h),
              _buildCategorySettings(context, ref, settings),
              SizedBox(height: 24.h),
              _buildTokenInfo(context, fcmTokenAsync),
              SizedBox(height: 24.h),
              _buildAdvancedSettings(context, ref),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: AppColors.textHint,
              ),
              SizedBox(height: 16.h),
              Text(
                '설정을 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: () => ref.refresh(notificationSettingsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context, WidgetRef ref, NotificationSettings settings) {
    return _buildSettingsSection(
      title: '일반 설정',
      icon: Icons.settings,
      children: [
        _buildSettingTile(
          title: '푸시 알림',
          subtitle: '앱에서 알림을 받습니다',
          value: settings.pushNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updatePushNotifications(value),
        ),
        _buildSettingTile(
          title: '이메일 알림',
          subtitle: '중요한 알림을 이메일로 받습니다',
          value: settings.emailNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updateSettings(settings.copyWith(emailNotifications: value)),
        ),
        _buildSettingTile(
          title: 'SMS 알림',
          subtitle: '긴급 알림을 SMS로 받습니다',
          value: settings.smsNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updateSettings(settings.copyWith(smsNotifications: value)),
        ),
      ],
    );
  }

  Widget _buildCategorySettings(BuildContext context, WidgetRef ref, NotificationSettings settings) {
    return _buildSettingsSection(
      title: '알림 카테고리',
      icon: Icons.category,
      children: [
        _buildSettingTile(
          title: '미션 알림',
          subtitle: '새로운 미션 및 미션 완료 알림',
          value: settings.missionNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updateMissionNotifications(value),
          leadingIcon: Icons.assignment,
          leadingColor: AppColors.primary,
        ),
        _buildSettingTile(
          title: '포인트 알림',
          subtitle: '포인트 적립 및 사용 알림',
          value: settings.pointsNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updatePointsNotifications(value),
          leadingIcon: Icons.monetization_on,
          leadingColor: AppColors.goldText,
        ),
        _buildSettingTile(
          title: '랭킹 알림',
          subtitle: '랭킹 변동 및 순위 관련 알림',
          value: settings.rankingNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updateRankingNotifications(value),
          leadingIcon: Icons.emoji_events,
          leadingColor: AppColors.success,
        ),
        _buildSettingTile(
          title: '시스템 알림',
          subtitle: '앱 업데이트 및 중요 공지사항',
          value: settings.systemNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updateSystemNotifications(value),
          leadingIcon: Icons.info,
          leadingColor: AppColors.info,
        ),
        _buildSettingTile(
          title: '홍보 알림',
          subtitle: '이벤트 및 프로모션 정보',
          value: settings.marketingNotifications,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .updateMarketingNotifications(value),
          leadingIcon: Icons.campaign,
          leadingColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTokenInfo(BuildContext context, AsyncValue<String?> fcmTokenAsync) {
    return _buildSettingsSection(
      title: 'FCM 토큰 정보',
      icon: Icons.security,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현재 FCM 토큰',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              fcmTokenAsync.when(
                data: (token) => token != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.textHint.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              token.length > 50 
                                  ? '${token.substring(0, 50)}...' 
                                  : token,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16.sp,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '토큰이 정상적으로 등록되었습니다',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16.sp,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '토큰을 가져올 수 없습니다',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Row(
                  children: [
                    Icon(
                      Icons.error,
                      size: 16.sp,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '토큰을 불러오는데 실패했습니다',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings(BuildContext context, WidgetRef ref) {
    return _buildSettingsSection(
      title: '고급 설정',
      icon: Icons.tune,
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.refresh,
              color: AppColors.info,
              size: 20.sp,
            ),
          ),
          title: Text(
            'FCM 토큰 새로고침',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '알림이 오지 않을 때 시도해보세요',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textHint,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 20.sp,
          ),
          onTap: () => _refreshFCMToken(context, ref),
        ),
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.notifications_off,
              color: Colors.red,
              size: 20.sp,
            ),
          ),
          title: Text(
            '모든 알림 끄기',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '일시적으로 모든 알림을 비활성화합니다',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textHint,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 20.sp,
          ),
          onTap: () => _disableAllNotifications(context, ref),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? leadingIcon,
    Color? leadingColor,
  }) {
    return ListTile(
      leading: leadingIcon != null
          ? Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: (leadingColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                leadingIcon,
                color: leadingColor ?? AppColors.primary,
                size: 16.sp,
              ),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textHint,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  void _refreshFCMToken(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FCM 토큰 새로고침'),
        content: const Text('FCM 토큰을 새로고침하시겠습니까?\n이 작업은 몇 초 정도 소요됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(fcmTokenProvider.notifier).refreshToken();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FCM 토큰을 새로고침했습니다')),
              );
            },
            child: const Text('새로고침'),
          ),
        ],
      ),
    );
  }

  void _disableAllNotifications(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 알림 끄기'),
        content: const Text('정말로 모든 알림을 끄시겠습니까?\n나중에 다시 개별적으로 설정할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              const disabledSettings = NotificationSettings(
                pushNotifications: false,
                emailNotifications: false,
                smsNotifications: false,
                missionNotifications: false,
                pointsNotifications: false,
                rankingNotifications: false,
                systemNotifications: false,
                marketingNotifications: false,
              );
              
              ref.read(notificationSettingsProvider.notifier).updateSettings(disabledSettings);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 알림을 비활성화했습니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('모두 끄기'),
          ),
        ],
      ),
    );
  }
}