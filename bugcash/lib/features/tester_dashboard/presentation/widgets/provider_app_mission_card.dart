import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class ProviderAppMissionCard extends StatelessWidget {
  final Map<String, dynamic> mission;
  final VoidCallback? onTap;

  const ProviderAppMissionCard({
    super.key,
    required this.mission,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProviderApp = mission['isProviderApp'] == true;
    final originalAppData = mission['originalAppData'] as Map<String, dynamic>?;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isProviderApp 
            ? Border.all(color: AppColors.primary, width: 2) 
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // App icon or placeholder
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: isProviderApp 
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: isProviderApp 
                          ? Border.all(color: AppColors.primary, width: 1) 
                          : null,
                    ),
                    child: Icon(
                      isProviderApp ? Icons.smartphone : Icons.assignment,
                      color: isProviderApp ? AppColors.primary : Colors.grey[600],
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mission['title'] ?? '제목 없음',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isProviderApp) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          mission['company'] ?? '회사 정보 없음',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Description
              Text(
                mission['description'] ?? '설명 없음',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12.h),
              
              // Mission info
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.monetization_on,
                    label: '${mission['reward'] ?? 0}원',
                    color: Colors.green,
                  ),
                  SizedBox(width: 8.w),
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${mission['currentParticipants'] ?? 0}/${mission['maxParticipants'] ?? 0}',
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8.w),
                  _buildInfoChip(
                    icon: Icons.schedule,
                    label: mission['difficulty'] ?? 'medium',
                    color: Colors.orange,
                  ),
                ],
              ),
              
              // Provider app specific actions
              if (isProviderApp && originalAppData != null) ...[
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchApp(originalAppData),
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(_getInstallButtonText(originalAppData)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAppDetails(context, originalAppData),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('상세정보'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getInstallButtonText(Map<String, dynamic> appData) {
    final installType = appData['installType'] as String? ?? 'play_store';
    switch (installType) {
      case 'play_store':
        return 'Play Store';
      case 'apk_upload':
        return 'APK 다운로드';
      case 'testflight':
        return 'TestFlight';
      case 'enterprise':
        return '앱 설치';
      default:
        return '앱 설치';
    }
  }

  Future<void> _launchApp(Map<String, dynamic> appData) async {
    final appUrl = appData['appUrl'] as String?;
    if (appUrl != null && appUrl.isNotEmpty) {
      final uri = Uri.parse(appUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showAppDetails(BuildContext context, Map<String, dynamic> appData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appData['appName'] ?? '앱 이름 없음',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              _buildDetailRow('카테고리', appData['category'] ?? '정보 없음'),
              SizedBox(height: 8.h),
              _buildDetailRow('설치 방식', _getInstallTypeText(appData['installType'])),
              SizedBox(height: 8.h),
              _buildDetailRow('참여 테스터', '${appData['activeTesters'] ?? 0}/${appData['totalTesters'] ?? 0}'),
              SizedBox(height: 8.h),
              _buildDetailRow('진행률', '${(appData['progressPercentage'] ?? 0).toInt()}%'),
              
              SizedBox(height: 16.h),
              
              Text(
                '설명',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                appData['description'] ?? '설명이 없습니다.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              
              SizedBox(height: 24.h),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchApp(appData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    _getInstallButtonText(appData),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _getInstallTypeText(String? installType) {
    switch (installType) {
      case 'play_store':
        return 'Google Play Store';
      case 'apk_upload':
        return 'APK 직접 다운로드';
      case 'testflight':
        return 'TestFlight (iOS 베타)';
      case 'enterprise':
        return '기업용 배포';
      default:
        return '알 수 없음';
    }
  }
}