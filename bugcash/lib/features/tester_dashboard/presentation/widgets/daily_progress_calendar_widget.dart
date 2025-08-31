import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/mission_model.dart';

class DailyProgressCalendarWidget extends StatelessWidget {
  final MissionCardWithProgress mission;
  final Function(DailyMissionProgress)? onTapDay;

  const DailyProgressCalendarWidget({
    super.key,
    required this.mission,
    this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSummary(context),
          SizedBox(height: 16.h),
          _buildCalendarGrid(context),
          if (mission.shouldShowToday) ...[
            SizedBox(height: 16.h),
            _buildTodayHighlight(context),
          ],
        ],
      ),
    );
  }


  Widget _buildProgressSummary(BuildContext context) {
    return Row(
      children: [
        _buildSummaryItem('완료', mission.completedDays.toString(), Colors.green),
        SizedBox(width: 16.w),
        _buildSummaryItem('진행중', (mission.totalDays - mission.completedDays - _getPendingDays()).toString(), Colors.blue),
        SizedBox(width: 16.w),
        _buildSummaryItem('대기', _getPendingDays().toString(), Colors.grey),
        const Spacer(),
        Text(
          '총 ${mission.totalDays}일',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    // Sort daily progress by date
    final sortedProgress = List<DailyMissionProgress>.from(mission.dailyProgress)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate grid dimensions
    const int columns = 7; // 한 주의 일수
    final int rows = (sortedProgress.length / columns).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일일 진행 현황',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        
        // Calendar Header (요일)
        _buildWeekHeader(),
        SizedBox(height: 4.h),
        
        // Calendar Grid
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: List.generate(rows, (row) {
              return Row(
                children: List.generate(columns, (col) {
                  final index = row * columns + col;
                  if (index >= sortedProgress.length) {
                    return Expanded(child: _buildEmptyCell());
                  }
                  return Expanded(
                    child: _buildProgressCell(sortedProgress[index]),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekHeader() {
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: weekDays.map((day) => Expanded(
        child: Container(
          height: 24.h,
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildProgressCell(DailyMissionProgress dayProgress) {
    Color backgroundColor;
    Color borderColor;
    Widget icon;
    
    switch (dayProgress.status) {
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        icon = Icon(Icons.check, size: 10.w, color: Colors.green);
        break;
      case 'in_progress':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        borderColor = Colors.blue;
        icon = Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        );
        break;
      case 'missed':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
        icon = Icon(Icons.close, size: 10.w, color: Colors.red);
        break;
      default: // pending
        backgroundColor = dayProgress.isToday 
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.05);
        borderColor = dayProgress.isToday 
            ? Colors.orange 
            : Colors.grey.shade300;
        icon = dayProgress.isToday 
            ? Icon(Icons.today, size: 10.w, color: Colors.orange)
            : Container(
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              );
    }

    return GestureDetector(
      onTap: () => onTapDay?.call(dayProgress),
      child: Container(
        height: 32.h,
        margin: EdgeInsets.all(0.5.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: dayProgress.isToday ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                dayProgress.date.day.toString(),
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: dayProgress.isToday ? FontWeight.bold : FontWeight.w500,
                  color: dayProgress.isToday 
                      ? Colors.orange.shade800 
                      : Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Flexible(
              child: icon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      height: 32.h,
      margin: EdgeInsets.all(0.5.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  Widget _buildTodayHighlight(BuildContext context) {
    final todayProgress = mission.todayProgress!;
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.today,
              color: Colors.white,
              size: 16.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 미션 - ${todayProgress.fullLabel}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                if (todayProgress.status == 'completed') 
                  Text(
                    '완료됨 ✓',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    '진행률: ${(todayProgress.progressPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          if (todayProgress.status != 'completed')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '시작하기',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20.w,
            ),
        ],
      ),
    );
  }

  int _getPendingDays() {
    return mission.dailyProgress.where((p) => p.status == 'pending' && !p.isToday).length;
  }

}