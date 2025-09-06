import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MissionsTabTest extends StatelessWidget {
  const MissionsTabTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '미션 관리',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // 미션 생성 기능 (개발 중)
                },
                icon: const Icon(Icons.add),
                label: const Text('미션 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // 더미 데이터 리스트
          Expanded(
            child: ListView(
              children: [
                _buildMissionCard(
                  title: '첫 번째 버그 찾기',
                  description: '앱에서 발생하는 첫 번째 버그를 발견하고 리포트하세요',
                  status: '진행중',
                  statusColor: Colors.blue,
                  reward: '5,000 BUG',
                  participants: 12,
                  maxParticipants: 50,
                  icon: Icons.bug_report,
                  iconColor: Colors.red,
                ),
                _buildMissionCard(
                  title: 'UI/UX 개선사항 제안',
                  description: '사용자 인터페이스의 개선점을 찾아 제안해주세요',
                  status: '모집중',
                  statusColor: Colors.green,
                  reward: '3,000 BUG',
                  participants: 8,
                  maxParticipants: 30,
                  icon: Icons.design_services,
                  iconColor: Colors.purple,
                ),
                _buildMissionCard(
                  title: '성능 테스트',
                  description: '앱의 성능을 테스트하고 느린 부분을 찾아주세요',
                  status: '완료',
                  statusColor: Colors.grey,
                  reward: '10,000 BUG',
                  participants: 25,
                  maxParticipants: 25,
                  icon: Icons.speed,
                  iconColor: Colors.orange,
                ),
                _buildMissionCard(
                  title: '보안 취약점 점검',
                  description: '앱의 보안 취약점을 찾고 리포트해주세요',
                  status: '검토중',
                  statusColor: Colors.orange,
                  reward: '15,000 BUG',
                  participants: 3,
                  maxParticipants: 10,
                  icon: Icons.security,
                  iconColor: Colors.red,
                ),
                _buildMissionCard(
                  title: '접근성 테스트',
                  description: '앱의 접근성을 테스트하고 개선사항을 제안하세요',
                  status: '일시정지',
                  statusColor: Colors.grey,
                  reward: '7,000 BUG',
                  participants: 0,
                  maxParticipants: 15,
                  icon: Icons.accessibility,
                  iconColor: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required String reward,
    required int participants,
    required int maxParticipants,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 미션 헤더
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
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
              ],
            ),
            SizedBox(height: 16.h),
            
            // 미션 정보
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.monetization_on,
                    label: '리워드',
                    value: reward,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.people,
                    label: '참여자',
                    value: '$participants/$maxParticipants',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: '마감',
                    value: '7일 남음',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // 미션 상세보기
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '상세보기',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: status == '완료' || status == '일시정지' ? null : () {
                      // 미션 관리
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '미션 관리',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}