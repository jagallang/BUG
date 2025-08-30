import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/mission_progress_dashboard.dart';
import '../widgets/tester_activity_tracker.dart';
import '../widgets/bug_report_review_panel.dart';
import '../widgets/mission_analytics_widget.dart';
import '../providers/mission_monitoring_provider.dart';

class MissionMonitoringPage extends ConsumerStatefulWidget {
  final String providerId;
  final String? missionId;

  const MissionMonitoringPage({
    super.key,
    required this.providerId,
    this.missionId,
  });

  @override
  ConsumerState<MissionMonitoringPage> createState() => _MissionMonitoringPageState();
}

class _MissionMonitoringPageState extends ConsumerState<MissionMonitoringPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedMissionId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedMissionId = widget.missionId;
    
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(missionMonitoringProvider.notifier).loadMissions(widget.providerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(missionMonitoringProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('미션 모니터링'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '진행 상태', icon: Icon(Icons.dashboard)),
            Tab(text: '테스터 활동', icon: Icon(Icons.people)),
            Tab(text: '리포트 검토', icon: Icon(Icons.rate_review)),
            Tab(text: '분석', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          // 자동 새로고침 토글
          IconButton(
            icon: Icon(
              monitoringState.isAutoRefreshEnabled 
                  ? Icons.sync 
                  : Icons.sync_disabled,
              color: monitoringState.isAutoRefreshEnabled 
                  ? Colors.green 
                  : Colors.grey,
            ),
            onPressed: () {
              ref.read(missionMonitoringProvider.notifier).toggleAutoRefresh();
            },
            tooltip: '자동 새로고침 ${monitoringState.isAutoRefreshEnabled ? "켜짐" : "꺼짐"}',
          ),
          // 수동 새로고침
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: monitoringState.isLoading ? null : () {
              ref.read(missionMonitoringProvider.notifier).refreshData();
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          // 미션 선택 드롭다운
          if (monitoringState.missions.isNotEmpty)
            _buildMissionSelector(monitoringState),
          
          // 메인 콘텐츠
          Expanded(
            child: monitoringState.isLoading && monitoringState.missions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : monitoringState.error != null
                    ? _buildErrorWidget(monitoringState.error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // 진행 상태 대시보드
                          MissionProgressDashboard(
                            missionId: _selectedMissionId ?? '',
                            providerId: widget.providerId,
                          ),
                          
                          // 테스터 활동 추적
                          TesterActivityTracker(
                            missionId: _selectedMissionId ?? '',
                            providerId: widget.providerId,
                          ),
                          
                          // 버그 리포트 검토
                          BugReportReviewPanel(
                            missionId: _selectedMissionId ?? '',
                            providerId: widget.providerId,
                          ),
                          
                          // 분석 대시보드
                          MissionAnalyticsWidget(
                            missionId: _selectedMissionId ?? '',
                            providerId: widget.providerId,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSelector(MissionMonitoringState state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Icon(
            Icons.task_alt,
            size: 20.w,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMissionId,
              decoration: InputDecoration(
                labelText: '미션 선택',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
              ),
              items: state.missions.map((mission) {
                return DropdownMenuItem(
                  value: mission.id,
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: _getMissionStatusColor(mission.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          mission.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${mission.completedCount}/${mission.totalParticipants}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMissionId = value;
                });
                if (value != null) {
                  ref.read(missionMonitoringProvider.notifier)
                      .selectMission(value);
                }
              },
            ),
          ),
          SizedBox(width: 12.w),
          // 미션 상태 요약
          if (_selectedMissionId != null)
            _buildMissionStatusSummary(state),
        ],
      ),
    );
  }

  Widget _buildMissionStatusSummary(MissionMonitoringState state) {
    final mission = state.missions.firstWhere(
      (m) => m.id == _selectedMissionId,
      orElse: () => state.missions.first,
    );
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getMissionStatusColor(mission.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _getMissionStatusColor(mission.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMissionStatusIcon(mission.status),
            size: 16.w,
            color: _getMissionStatusColor(mission.status),
          ),
          SizedBox(width: 6.w),
          Text(
            _getMissionStatusText(mission.status),
            style: TextStyle(
              color: _getMissionStatusColor(mission.status),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.w,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),
          Text(
            '데이터를 불러올 수 없습니다',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(missionMonitoringProvider.notifier).refreshData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Color _getMissionStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.draft:
        return Colors.grey;
      case MissionStatus.active:
        return Colors.green;
      case MissionStatus.inProgress:
        return Colors.blue;
      case MissionStatus.review:
        return Colors.orange;
      case MissionStatus.completed:
        return Colors.purple;
      case MissionStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getMissionStatusIcon(MissionStatus status) {
    switch (status) {
      case MissionStatus.draft:
        return Icons.edit;
      case MissionStatus.active:
        return Icons.play_circle;
      case MissionStatus.inProgress:
        return Icons.trending_up;
      case MissionStatus.review:
        return Icons.rate_review;
      case MissionStatus.completed:
        return Icons.check_circle;
      case MissionStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getMissionStatusText(MissionStatus status) {
    switch (status) {
      case MissionStatus.draft:
        return '초안';
      case MissionStatus.active:
        return '활성';
      case MissionStatus.inProgress:
        return '진행중';
      case MissionStatus.review:
        return '검토중';
      case MissionStatus.completed:
        return '완료';
      case MissionStatus.cancelled:
        return '취소됨';
    }
  }
}