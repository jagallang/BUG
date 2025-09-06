import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MissionsTabSimple extends StatelessWidget {
  const MissionsTabSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text(
            '미션 관리',
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
                _buildSimpleMissionCard(
                  title: '첫 번째 버그 찾기',
                  description: '앱에서 발생하는 첫 번째 버그를 발견하고 리포트하세요',
                  status: '진행중',
                  statusColor: Colors.blue,
                  reward: '5,000 BUG',
                ),
                _buildSimpleMissionCard(
                  title: 'UI/UX 개선사항 제안',
                  description: '사용자 인터페이스의 개선점을 찾아 제안해주세요',
                  status: '모집중',
                  statusColor: Colors.green,
                  reward: '3,000 BUG',
                ),
                _buildSimpleMissionCard(
                  title: '성능 테스트',
                  description: '앱의 성능을 테스트하고 느린 부분을 찾아주세요',
                  status: '완료',
                  statusColor: Colors.grey,
                  reward: '10,000 BUG',
                ),
                _buildSimpleMissionCard(
                  title: '보안 취약점 점검',
                  description: '앱의 보안 취약점을 찾고 리포트해주세요',
                  status: '검토중',
                  statusColor: Colors.orange,
                  reward: '15,000 BUG',
                ),
                _buildSimpleMissionCard(
                  title: '접근성 테스트',
                  description: '앱의 접근성을 테스트하고 개선사항을 제안하세요',
                  status: '일시정지',
                  statusColor: Colors.grey,
                  reward: '7,000 BUG',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMissionCard({
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required String reward,
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
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.assignment, color: statusColor, size: 24.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '리워드: $reward',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          // 미션 상세 페이지로 이동
        },
      ),
    );
  }
}