import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/tester_dashboard_provider.dart' as provider;
import '../../../../models/mission_model.dart';

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
  final Set<String> _expandedMissions = {};
  
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
        final mission = missionsWithProgress[index];
        final isExpanded = _expandedMissions.contains(mission.id);
        
        return _buildExpandableMissionCard(mission, isExpanded);
      },
    );
  }
  
  Widget _buildExpandableMissionCard(MissionCardWithProgress mission, bool isExpanded) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedMissions.remove(mission.id);
              } else {
                _expandedMissions.add(mission.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(16.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (always visible)
                  _buildMissionHeader(mission, isExpanded),
                  
                  // Collapsed view - show minimal info
                  if (!isExpanded) ...[
                    SizedBox(height: 12.h),
                    _buildCollapsedInfo(mission),
                  ],
                  
                  // Expanded view - show full progress widget
                  if (isExpanded) ...[
                    SizedBox(height: 16.h),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: 16.h),
                    _buildExpandedInfo(mission),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMissionHeader(MissionCardWithProgress mission, bool isExpanded) {
    return Row(
      children: [
        // Mission type icon
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: _getMissionTypeColor(mission.type.toString()).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            _getMissionTypeIcon(mission.type.toString()),
            color: _getMissionTypeColor(mission.type.toString()),
            size: 20.w,
          ),
        ),
        SizedBox(width: 12.w),
        
        // Mission title and app name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mission.title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: isExpanded ? null : 1,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                mission.appName,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Expand/Collapse icon
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          size: 24.w,
          color: Colors.grey[600],
        ),
      ],
    );
  }
  
  Widget _buildCollapsedInfo(MissionCardWithProgress mission) {
    final progress = (mission.overallProgress * 100).toInt();
    final daysLeft = mission.deadline?.difference(DateTime.now()).inDays ?? 0;
    
    return Row(
      children: [
        // Progress indicator
        SizedBox(
          width: 50.w,
          height: 50.w,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: mission.overallProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(mission.overallProgress),
                ),
                strokeWidth: 4.w,
              ),
              Center(
                child: Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        
        // Quick stats
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat(Icons.monetization_on, '${mission.rewardPoints}P', Colors.green),
              _buildQuickStat(Icons.timer, '${mission.estimatedMinutes}분', Colors.blue),
              _buildQuickStat(Icons.calendar_today, 'D-$daysLeft', daysLeft < 3 ? Colors.red : Colors.orange),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.w, color: color),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildExpandedInfo(MissionCardWithProgress mission) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress bar
          Text(
            '전체 진행률',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: mission.overallProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(mission.overallProgress),
            ),
            minHeight: 6.h,
          ),
          SizedBox(height: 4.h),
          Text(
            '${(mission.overallProgress * 100).toInt()}% 완료',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          
          // Daily progress calendar
          Text(
            '일별 진행 상황',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          _buildDailyProgressGrid(mission),
          SizedBox(height: 16.h),
          
          // Action buttons
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildActionButton(
                Icons.play_arrow,
                '오늘 미션',
                Colors.green,
                () => _handleTodayMission(mission),
              ),
              _buildActionButton(
                Icons.history,
                '진행 기록',
                Colors.blue,
                () => _showProgressHistory(mission),
              ),
              _buildActionButton(
                Icons.info_outline,
                '상세 정보',
                Colors.orange,
                () => _openMissionDetail(mission),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyProgressGrid(MissionCardWithProgress mission) {
    return SizedBox(
      height: 80.h, // Fixed height to prevent overflow
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0, // Adjusted aspect ratio
          crossAxisSpacing: 2.w, // Reduced spacing
          mainAxisSpacing: 2.h,
        ),
        itemCount: mission.dailyProgress.length > 7 ? 7 : mission.dailyProgress.length,
        itemBuilder: (context, index) {
          final dayProgress = mission.dailyProgress[index];
          return GestureDetector(
            onTap: () => _handleDayProgress(dayProgress),
            child: Container(
              decoration: BoxDecoration(
                color: _getDayColor(dayProgress),
                borderRadius: BorderRadius.circular(6.r),
                border: dayProgress.isToday
                    ? Border.all(color: Colors.blue, width: 1.w)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'D${dayProgress.dayNumber}',
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: dayProgress.isToday ? FontWeight.bold : FontWeight.normal,
                        color: dayProgress.isCompleted ? Colors.white : Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (dayProgress.progressPercentage > 0 && !dayProgress.isCompleted)
                    Flexible(
                      child: Text(
                        '${(dayProgress.progressPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (dayProgress.isCompleted)
                    Flexible(
                      child: Icon(
                        Icons.check,
                        size: 10.w,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.w, color: color),
            SizedBox(width: 3.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getDayColor(DailyMissionProgress dayProgress) {
    if (dayProgress.isCompleted) return Colors.green;
    if (dayProgress.progressPercentage > 0) return Colors.orange.withValues(alpha: 0.7);
    if (dayProgress.isToday) return Colors.blue.withValues(alpha: 0.2);
    return Colors.grey[200]!;
  }
  
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }
  
  Color _getMissionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bug':
        return Colors.red;
      case 'feature':
        return Colors.blue;
      case 'ui/ux':
        return Colors.purple;
      case 'performance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getMissionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bug':
        return Icons.bug_report;
      case 'feature':
        return Icons.add_box;
      case 'ui/ux':
        return Icons.palette;
      case 'performance':
        return Icons.speed;
      default:
        return Icons.assignment;
    }
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
  
  void _showProgressHistory(MissionCardWithProgress mission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mission.title} 진행 기록')),
    );
  }
  
  void _openMissionDetail(MissionCardWithProgress mission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mission.title} 상세 정보')),
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