import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppsTabTest extends StatelessWidget {
  const AppsTabTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text(
            '앱 관리',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          
          // 더미 데이터 리스트
          Expanded(
            child: ListView(
              children: [
                _buildAppCard(
                  title: '버그캐시 테스트 앱 1',
                  subtitle: '테스트용 더미 앱입니다',
                  status: '활성',
                  statusColor: Colors.green,
                  icon: Icons.phone_android,
                  iconColor: Colors.blue,
                ),
                _buildAppCard(
                  title: '게임 테스터 앱',
                  subtitle: '게임 카테고리 테스트 앱',
                  status: '검토중',
                  statusColor: Colors.orange,
                  icon: Icons.gamepad,
                  iconColor: Colors.orange,
                ),
                _buildAppCard(
                  title: '교육용 앱',
                  subtitle: '교육 카테고리 앱',
                  status: '초안',
                  statusColor: Colors.blue,
                  icon: Icons.school,
                  iconColor: Colors.purple,
                ),
                _buildAppCard(
                  title: '일시정지된 앱',
                  subtitle: '테스트를 위해 잠시 중단',
                  status: '일시정지',
                  statusColor: Colors.grey,
                  icon: Icons.pause_circle,
                  iconColor: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          // 앱 상세 페이지로 이동
        },
      ),
    );
  }
}