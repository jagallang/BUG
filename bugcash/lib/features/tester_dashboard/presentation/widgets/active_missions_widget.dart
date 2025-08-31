import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/tester_dashboard_provider.dart';
import '../../../../models/mission_model.dart';

class ActiveMissionsWidget extends ConsumerWidget {
  final String testerId;

  const ActiveMissionsWidget({
    super.key,
    required this.testerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(testerDashboardProvider);
    final activeMissions = dashboardState.activeMissions;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Header with stats
          _buildHeader(context, activeMissions),
          
          SizedBox(height: 16.h),
          
          // Active missions list
          Expanded(
            child: activeMissions.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: activeMissions.length,
                    itemBuilder: (context, index) {
                      return _buildActiveMissionCard(context, ref, activeMissions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<MissionCard> missions) {
    final completedToday = missions.where((m) => 
        m.startedAt != null && 
        m.startedAt!.day == DateTime.now().day &&
        m.progress == 1.0
    ).length;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                '진행 중인 미션',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${missions.length}개',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '오늘 완료',
                completedToday.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                context,
                '평균 진행률',
                missions.isNotEmpty 
                    ? '${((missions.map((m) => m.progress ?? 0).reduce((a, b) => a + b) / missions.length) * 100).toStringAsFixed(0)}%'
                    : '0%',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildStatItem(
                context,
                '긴급 미션',
                missions.where((m) => m.deadline != null && _isUrgent(m.deadline!)).length.toString(),
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.w),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveMissionCard(BuildContext context, WidgetRef ref, MissionCard mission) {
    final progress = mission.progress ?? 0.0;
    final isUrgent = mission.deadline != null && _isUrgent(mission.deadline!);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showMissionProgress(context, ref, mission),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: isUrgent ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Mission type icon
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: _getMissionTypeColor(mission.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _getMissionTypeIcon(mission.type),
                      color: _getMissionTypeColor(mission.type),
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // Title and app
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          mission.appName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status badge
                  if (isUrgent)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '긴급',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '진행률',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(progress),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8.h,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Mission info
              Row(
                children: [
                  Icon(Icons.schedule, size: 14.w, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    mission.startedAt != null 
                        ? '시작: ${_formatTime(mission.startedAt!)}'
                        : '${mission.estimatedMinutes}분 예상',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                  SizedBox(width: 12.w),
                  
                  Icon(Icons.monetization_on, size: 14.w, color: Colors.green),
                  SizedBox(width: 4.w),
                  Text(
                    '${mission.rewardPoints}P',
                    style: TextStyle(fontSize: 11.sp, color: Colors.green),
                  ),
                  
                  const Spacer(),
                  
                  if (mission.deadline != null)
                    Text(
                      _formatDeadline(mission.deadline!),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isUrgent ? Colors.red : Colors.grey,
                        fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMissionProgress(context, ref, mission),
                      icon: const Icon(Icons.visibility),
                      label: const Text('상세보기'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: progress >= 1.0 
                          ? null 
                          : () => _updateProgress(context, ref, mission),
                      icon: Icon(progress >= 1.0 ? Icons.check : Icons.edit),
                      label: Text(progress >= 1.0 ? '완료됨' : '진행하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: progress >= 1.0 
                            ? Colors.grey 
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
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

  void _showMissionProgress(BuildContext context, WidgetRef ref, MissionCard mission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16.w),
                  child: _buildProgressDetailContent(context, ref, mission),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDetailContent(BuildContext context, WidgetRef ref, MissionCard mission) {
    final progress = mission.progress ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: _getMissionTypeColor(mission.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _getMissionTypeIcon(mission.type),
                color: _getMissionTypeColor(mission.type),
                size: 30.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    mission.appName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: 24.h),
        
        // Progress section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Text(
                '진행률',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              
              // Circular progress
              SizedBox(
                width: 120.w,
                height: 120.w,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(progress),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Progress milestones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMilestone('시작', progress >= 0.1, Icons.play_circle),
                  _buildMilestone('진행중', progress >= 0.5, Icons.trending_up),
                  _buildMilestone('검토중', progress >= 0.8, Icons.rate_review),
                  _buildMilestone('완료', progress >= 1.0, Icons.check_circle),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24.h),
        
        // Mission details
        _buildDetailGrid(mission),
        
        SizedBox(height: 24.h),
        
        // Progress update button
        if (progress < 1.0)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _updateProgress(context, ref, mission);
              },
              icon: const Icon(Icons.edit),
              label: const Text('진행률 업데이트'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMilestone(String label, bool isCompleted, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : Colors.grey,
            size: 20.w,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: isCompleted ? Colors.green : Colors.grey,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGrid(MissionCard mission) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 2,
      children: [
        _buildDetailItem('보상', '${mission.rewardPoints}P', Icons.monetization_on, Colors.green),
        _buildDetailItem('예상시간', '${mission.estimatedMinutes}분', Icons.schedule, Colors.blue),
        _buildDetailItem('시작일', mission.startedAt != null ? _formatDate(mission.startedAt!) : 'N/A', Icons.calendar_today, Colors.purple),
        _buildDetailItem('마감일', mission.deadline != null ? _formatDate(mission.deadline!) : 'N/A', Icons.event, Colors.red),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18.w),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _updateProgress(BuildContext context, WidgetRef ref, MissionCard mission) {
    final currentProgress = mission.progress ?? 0.0;
    double newProgress = currentProgress;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('진행률 업데이트'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('현재 진행률: ${(currentProgress * 100).toStringAsFixed(0)}%'),
              SizedBox(height: 16.h),
              Slider(
                value: newProgress,
                min: currentProgress,
                max: 1.0,
                divisions: 20,
                label: '${(newProgress * 100).toStringAsFixed(0)}%',
                onChanged: (value) {
                  setState(() {
                    newProgress = value;
                  });
                },
              ),
              Text('새 진행률: ${(newProgress * 100).toStringAsFixed(0)}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(testerDashboardProvider.notifier)
                    .updateMissionProgress(mission.id, newProgress);
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('진행률이 ${(newProgress * 100).toStringAsFixed(0)}%로 업데이트되었습니다'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('업데이트'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getMissionTypeColor(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return Colors.red;
      case MissionType.featureTesting:
        return Colors.blue;
      case MissionType.usabilityTest:
        return Colors.green;
      case MissionType.performanceTest:
        return Colors.orange;
      case MissionType.survey:
        return Colors.purple;
      case MissionType.feedback:
        return Colors.indigo;
      case MissionType.functional:
        return Colors.blue;
      case MissionType.uiUx:
        return Colors.teal;
      case MissionType.performance:
        return Colors.deepOrange;
      case MissionType.security:
        return Colors.redAccent;
      case MissionType.compatibility:
        return Colors.amber;
      case MissionType.accessibility:
        return Colors.cyan;
      case MissionType.localization:
        return Colors.pink;
    }
  }

  IconData _getMissionTypeIcon(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return Icons.bug_report;
      case MissionType.featureTesting:
        return Icons.featured_play_list;
      case MissionType.usabilityTest:
        return Icons.touch_app;
      case MissionType.performanceTest:
        return Icons.speed;
      case MissionType.survey:
        return Icons.quiz;
      case MissionType.feedback:
        return Icons.feedback;
      case MissionType.functional:
        return Icons.functions;
      case MissionType.uiUx:
        return Icons.design_services;
      case MissionType.performance:
        return Icons.timeline;
      case MissionType.security:
        return Icons.security;
      case MissionType.compatibility:
        return Icons.devices;
      case MissionType.accessibility:
        return Icons.accessibility;
      case MissionType.localization:
        return Icons.language;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    if (progress < 1.0) return Colors.blue;
    return Colors.green;
  }

  bool _isUrgent(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inHours <= 24;
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 남음';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 남음';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 남음';
    } else {
      return '마감';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inMinutes}분 전';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}