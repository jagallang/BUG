import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/responsive_wrapper.dart';
import '../pages/mission_detail_page.dart';

/// 미션 카드 위젯
class MissionCardWidget extends StatelessWidget {
  final dynamic mission;
  final String title;
  final String description;
  final String reward;
  final String deadline;
  final String participants;
  final VoidCallback? onMissionUpdated;

  const MissionCardWidget({
    super.key,
    required this.mission,
    required this.title,
    required this.description,
    required this.reward,
    required this.deadline,
    required this.participants,
    this.onMissionUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MissionDetailPage(mission: mission),
            ),
          );

          // 미션 신청 결과 처리
          if (result != null && onMissionUpdated != null) {
            if (result is Map<String, dynamic> && result['success'] == true) {
              // 미션 신청 성공 - 데이터 새로고침
              onMissionUpdated!();
            } else if (result == true) {
              // 기존 호환성을 위한 단순 성공 처리
              onMissionUpdated!();
            }
          }
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: ResponsiveWrapper.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      reward,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      deadline,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(Icons.people, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      participants,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}