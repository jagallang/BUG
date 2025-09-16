import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/firebase_service.dart';
import '../../../../services/test_session_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../bug_report/presentation/pages/bug_report_page.dart';

class MissionDetailPage extends ConsumerStatefulWidget {
  final String missionId;
  final Map<String, dynamic>? missionData;

  const MissionDetailPage({
    super.key,
    required this.missionId,
    this.missionData,
  });

  @override
  ConsumerState<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends ConsumerState<MissionDetailPage> {
  Map<String, dynamic>? mission;
  bool isLoading = true;
  bool isParticipating = false;

  @override
  void initState() {
    super.initState();
    if (widget.missionData != null) {
      mission = widget.missionData;
      isLoading = false;
    } else {
      _loadMissionDetail();
    }
  }

  Future<void> _loadMissionDetail() async {
    try {
      // TODO: Implement getMissionById in FirebaseService
      final missions = await FirebaseService.getMissions();
      final missionDetail = missions.firstWhere(
        (m) => m['id'] == widget.missionId,
        orElse: () => {},
      );
      
      if (mounted) {
        setState(() {
          mission = missionDetail;
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load mission detail', 'MissionDetail', e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _participateInMission() async {
    setState(() {
      isParticipating = true;
    });

    try {
      // 현재 사용자 정보 가져오기
      final currentUserId = CurrentUserService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // TestSession 생성
      final testSessionService = ref.read(testSessionServiceProvider);

      // 미션 데이터에서 필요한 정보 추출
      final missionId = widget.missionId;
      final providerId = mission?['createdBy'] ?? mission?['providerId'] ?? 'default_provider';
      final appId = mission?['appId'] ?? missionId;
      final totalRewardPoints = mission?['reward'] ?? 2000;

      AppLogger.info('🎯 Mission data: ${mission?.keys.toList()}', 'MissionDetail');
      AppLogger.info('📍 createdBy: ${mission?['createdBy']}', 'MissionDetail');
      AppLogger.info('📍 providerId: ${mission?['providerId']}', 'MissionDetail');
      AppLogger.info('🆔 Final providerId selected: $providerId', 'MissionDetail');
      AppLogger.info('Creating test session: missionId=$missionId, testerId=$currentUserId, providerId=$providerId', 'MissionDetail');

      // TestSession 생성 (pending 상태로)
      final sessionId = await testSessionService.createTestSession(
        missionId: missionId,
        testerId: currentUserId,
        providerId: providerId,
        appId: appId,
        totalRewardPoints: totalRewardPoints,
      );

      AppLogger.info('Test session created successfully: $sessionId', 'MissionDetail');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션 참여 신청이 완료되었습니다! 공급자의 승인을 기다려주세요.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('Failed to participate in mission', 'MissionDetail', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 참여에 실패했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isParticipating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (mission == null || mission!.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('미션 정보를 불러올 수 없습니다.'),
              ),
            )
          else
            SliverToBoxAdapter(
              child: _buildContent(),
            ),
        ],
      ),
      bottomNavigationBar: mission != null && mission!.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          mission?['title'] ?? '미션 상세',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.bug_report,
              size: 80.sp,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          SizedBox(height: 16.h),
          _buildDescriptionCard(),
          SizedBox(height: 16.h),
          _buildAppDownloadCard(),
          SizedBox(height: 16.h),
          _buildRequirementsCard(),
          SizedBox(height: 16.h),
          _buildStatsCard(),
          SizedBox(height: 100.h), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.monetization_on,
              '보상',
              '${mission?['reward'] ?? 0} 포인트',
              AppColors.success,
            ),
            Divider(height: 24.h),
            _buildInfoRow(
              Icons.calendar_today,
              '마감일',
              _formatDate(mission?['deadline']),
              AppColors.warning,
            ),
            Divider(height: 24.h),
            _buildInfoRow(
              Icons.speed,
              '난이도',
              mission?['difficulty'] ?? 'Medium',
              AppColors.info,
            ),
            Divider(height: 24.h),
            _buildInfoRow(
              Icons.category,
              '카테고리',
              mission?['category'] ?? '일반',
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textHint,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '미션 설명',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              mission?['description'] ?? '상세 설명이 없습니다.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    final requirements = mission?['requirements'] as List<dynamic>? ?? 
      ['Android 또는 iOS 디바이스', '테스트 경험 1회 이상', '버그 리포트 작성 가능'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '참여 조건',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...requirements.map((req) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      req.toString(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDownloadCard() {
    // 미션 데이터에서 앱 다운로드 링크들을 가져옵니다
    final downloadLinks = mission?['downloadLinks'] as Map<String, dynamic>? ?? {
      'playStore': 'https://play.google.com/store/apps/details?id=com.example.testapp',
      'appStore': 'https://apps.apple.com/app/test-app/id123456789',
      'apkDirect': 'https://github.com/example/testapp/releases/download/v1.0.0/app-release.apk',
    };
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '테스트 앱 설치',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              '아래 링크를 통해 테스트할 앱을 먼저 설치하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),
            
            // Play Store 링크
            if (downloadLinks['playStore'] != null)
              _buildDownloadButton(
                icon: Icons.play_arrow,
                title: '구글 플레이 스토어',
                subtitle: 'Android 사용자',
                url: downloadLinks['playStore'],
                color: AppColors.success,
              ),
            
            if (downloadLinks['playStore'] != null && 
                (downloadLinks['appStore'] != null || downloadLinks['apkDirect'] != null))
              SizedBox(height: 12.h),
            
            // App Store 링크  
            if (downloadLinks['appStore'] != null)
              _buildDownloadButton(
                icon: Icons.apple,
                title: 'Apple App Store',
                subtitle: 'iOS 사용자',
                url: downloadLinks['appStore'],
                color: AppColors.info,
              ),
            
            if (downloadLinks['appStore'] != null && downloadLinks['apkDirect'] != null)
              SizedBox(height: 12.h),
            
            // 직접 APK 다운로드
            if (downloadLinks['apkDirect'] != null)
              _buildDownloadButton(
                icon: Icons.android,
                title: 'APK 직접 다운로드',
                subtitle: 'Android APK 파일',
                url: downloadLinks['apkDirect'],
                color: AppColors.warning,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
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
                  SizedBox(height: 2.h),
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
              Icons.launch,
              color: color,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('링크를 열 수 없습니다: $url'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to launch URL: $url', 'MissionDetail', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크 실행 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildStatsCard() {
    final participants = mission?['participantCount'] ?? 0;
    final maxParticipants = mission?['maxParticipants'] ?? 1;
    final progress = (participants / maxParticipants).clamp(0.0, 1.0);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '참여 현황',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$participants / $maxParticipants 명',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.progressBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? AppColors.warning : AppColors.primary,
              ),
              minHeight: 8.h,
            ),
            if (progress > 0.8)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: AppColors.warning,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '마감 임박!',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BugReportPage(
                        missionId: widget.missionId,
                        missionTitle: mission?['title'],
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.bug_report, size: 18.sp),
                label: Text(
                  '버그 리포트',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isParticipating ? null : _participateInMission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: isParticipating
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '미션 참여하기',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '날짜 미정';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return '날짜 미정';
      }
      
      final remaining = dateTime.difference(DateTime.now()).inDays;
      if (remaining < 0) {
        return '마감됨';
      } else if (remaining == 0) {
        return '오늘 마감';
      } else if (remaining == 1) {
        return '내일 마감';
      } else {
        return '$remaining일 남음';
      }
    } catch (e) {
      return '날짜 미정';
    }
  }
}