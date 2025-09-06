import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/tester_dashboard_provider.dart' as provider;
import '../../../../models/mission_model.dart';
import 'daily_mission_progress_widget.dart';

class ActiveMissionsWidget extends ConsumerStatefulWidget {
  final String testerId;

  const ActiveMissionsWidget({
    super.key,
    required this.testerId,
  });

  @override
  ConsumerState<ActiveMissionsWidget> createState() => _ActiveMissionsWidgetState();
}

class _ActiveMissionsWidgetState extends ConsumerState<ActiveMissionsWidget> {
  String selectedFilter = '전체';
  
  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(provider.testerDashboardProvider);
    final activeMissions = dashboardState.activeMissions;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          
          // Filter and sort tabs
          _buildFilterTabs(),
          
          SizedBox(height: 16.h),
          
          // Active missions list with daily progress
          Expanded(
            child: activeMissions.isEmpty
                ? _buildEmptyState(context)
                : _buildMissionsWithDailyProgress(activeMissions),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsWithDailyProgress(List<provider.MissionCard> missions) {
    // Convert MissionCard to MissionCardWithProgress (mock data for demo)
    final missionsWithProgress = missions.map((mission) => _convertToMissionWithProgress(mission)).toList();
    
    return ListView.builder(
      itemCount: missionsWithProgress.length,
      itemBuilder: (context, index) {
        return DailyMissionProgressWidget(
          mission: missionsWithProgress[index],
          onTapToday: () => _handleTodayMission(missionsWithProgress[index]),
          onTapDay: (dayProgress) => _handleDayProgress(dayProgress),
        );
      },
    );
  }
  
  MissionCardWithProgress _convertToMissionWithProgress(provider.MissionCard mission) {
    // Generate mock daily progress for demonstration
    final startDate = mission.startedAt ?? DateTime.now().subtract(const Duration(days: 5));
    const totalDays = 7; // Assume 7-day mission
    
    final dailyProgress = List.generate(totalDays, (index) {
      final date = startDate.add(Duration(days: index));
      final isToday = _isToday(date);
      final dayNumber = index + 1;
      
      // Generate realistic progress based on day
      String status;
      double progressPercentage = 0.0;
      bool isCompleted = false;
      List<String> completedTasks = [];
      
      if (date.isBefore(DateTime.now())) {
        if (index < 3) {
          status = 'completed';
          progressPercentage = 1.0;
          isCompleted = true;
          completedTasks = ['기본 기능 테스트 완료', 'UI 검증 완료'];
        } else if (index < 5) {
          status = 'in_progress';
          progressPercentage = 0.6;
          completedTasks = ['로그인 테스트 완료'];
        } else {
          status = 'pending';
        }
      } else if (isToday) {
        status = 'pending';
        if (mission.progress != null && mission.progress! > 0) {
          status = 'in_progress';
          progressPercentage = 0.3;
          completedTasks = ['초기 설정 테스트'];
        }
      } else {
        status = 'pending';
      }
      
      return DailyMissionProgress(
        missionId: mission.id,
        testerId: widget.testerId,
        date: date,
        dayNumber: dayNumber,
        progressPercentage: progressPercentage,
        isCompleted: isCompleted,
        isToday: isToday,
        status: status,
        completedTasks: completedTasks,
        notes: isCompleted ? '성공적으로 완료되었습니다' : null,
        startedAt: status != 'pending' ? date.add(const Duration(hours: 9)) : null,
        completedAt: isCompleted ? date.add(const Duration(hours: 18)) : null,
      );
    });
    
    final calculatedProgress = totalDays > 0 
        ? (dailyProgress.where((p) => p.isCompleted).length / totalDays)
        : 0.0;
    
    return MissionCardWithProgress(
      id: mission.id,
      title: mission.title,
      appName: mission.appName,
      type: mission.type,
      rewardPoints: mission.rewardPoints,
      estimatedMinutes: mission.estimatedMinutes,
      deadline: mission.deadline,
      startedAt: mission.startedAt,
      overallProgress: calculatedProgress,
      dailyProgress: dailyProgress,
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  void _handleTodayMission(MissionCardWithProgress mission) {
    final todayProgress = mission.todayProgress;
    if (todayProgress != null) {
      _showTodayMissionDialog(mission, todayProgress);
    }
  }
  
  void _handleDayProgress(DailyMissionProgress dayProgress) {
    _showDayProgressDialog(dayProgress);
  }
  
  void _showTodayMissionDialog(MissionCardWithProgress mission, DailyMissionProgress todayProgress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오늘의 미션 - ${todayProgress.dayLabel}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('미션: ${mission.title}'),
            SizedBox(height: 8.h),
            Text('진행률: ${(todayProgress.progressPercentage * 100).toStringAsFixed(0)}%'),
            SizedBox(height: 8.h),
            if (todayProgress.completedTasks.isNotEmpty) ...[
              const Text('완료된 작업:'),
              ...todayProgress.completedTasks.map((task) => 
                Padding(
                  padding: EdgeInsets.only(left: 16.w),
                  child: Text('• $task'),
                )
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          if (!todayProgress.isCompleted)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTodayMission(mission);
              },
              child: Text(todayProgress.status == 'in_progress' ? '계속하기' : '시작하기'),
            ),
        ],
      ),
    );
  }
  
  void _showDayProgressDialog(DailyMissionProgress dayProgress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${dayProgress.fullLabel} 진행 상황'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: ${_getStatusText(dayProgress.status)}'),
            SizedBox(height: 8.h),
            Text('진행률: ${(dayProgress.progressPercentage * 100).toStringAsFixed(0)}%'),
            if (dayProgress.completedTasks.isNotEmpty) ...[
              SizedBox(height: 8.h),
              const Text('완료된 작업:'),
              ...dayProgress.completedTasks.map((task) => 
                Padding(
                  padding: EdgeInsets.only(left: 16.w),
                  child: Text('• $task'),
                )
              ),
            ],
            if (dayProgress.notes != null) ...[
              SizedBox(height: 8.h),
              Text('메모: ${dayProgress.notes}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '완료';
      case 'in_progress':
        return '진행중';
      case 'pending':
        return '대기중';
      case 'missed':
        return '놓침';
      default:
        return '알 수 없음';
    }
  }
  
  void _startTodayMission(MissionCardWithProgress mission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('오늘의 미션을 시작합니다: ${mission.title}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip('전체', selectedFilter == '전체', () {
              setState(() {
                selectedFilter = '전체';
              });
            }),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildFilterChip('오늘 할 일', selectedFilter == '오늘 할 일', () {
              setState(() {
                selectedFilter = '오늘 할 일';
              });
            }),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildFilterChip('진행중', selectedFilter == '진행중', () {
              setState(() {
                selectedFilter = '진행중';
              });
            }),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildFilterChip('완료', selectedFilter == '완료', () {
              setState(() {
                selectedFilter = '완료';
              });
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: isSelected 
                ? Colors.white 
                : Colors.grey.shade700,
            fontWeight: isSelected 
                ? FontWeight.bold 
                : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64.w,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            '진행 중인 미션이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '새로운 미션을 찾아 참여해보세요!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to mission discovery tab
            },
            icon: const Icon(Icons.search),
            label: const Text('미션 찾기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}