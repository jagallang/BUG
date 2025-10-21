import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../shared/models/mission_workflow_model.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../../core/services/mission_management_service.dart';
import '../../../shared/models/mission_management_model.dart';
import 'app_management_page.dart';
import '../widgets/daily_submission_review_dialog.dart';

class TesterManagementPage extends ConsumerStatefulWidget {
  final ProviderAppModel app;

  const TesterManagementPage({
    super.key,
    required this.app,
  });

  @override
  ConsumerState<TesterManagementPage> createState() => _TesterManagementPageState();
}

class _TesterManagementPageState extends ConsumerState<TesterManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MissionWorkflowService _workflowService = MissionWorkflowService();
  final MissionManagementService _missionManagementService = MissionManagementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    AppLogger.info('Mission Management Page initialized for app: ${widget.app.appName}', 'MissionManagement');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCleanAppId() {
    final appId = widget.app.id;
    // Remove provider_app_ prefix if present to match workflow system
    return appId.startsWith('provider_app_')
        ? appId.replaceFirst('provider_app_', '')
        : appId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.app.appName} - 미션 워크플로우',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 14.sp),
          tabs: const [
            Tab(text: '신청 관리', icon: Icon(Icons.person_add, size: 18)),
            Tab(text: '진행중 미션', icon: Icon(Icons.play_circle_outline, size: 18)),
            Tab(text: '완료 미션', icon: Icon(Icons.check_circle_outline, size: 18)),
            Tab(text: '분석', icon: Icon(Icons.analytics, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationsTab(),
          _buildActiveMissionsTab(),
          _buildCompletedMissionsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  // 탭 1: 신청 관리
  Widget _buildApplicationsTab() {
    final cleanAppId = _getCleanAppId();
    debugPrint('🔍 Provider TesterManagement - Original appId: ${widget.app.id}');
    debugPrint('🔍 Provider TesterManagement - Clean appId: $cleanAppId');
    debugPrint('🔍 Provider TesterManagement - Querying workflows for appId: $cleanAppId');

    return StreamBuilder<List<MissionWorkflowModel>>(
      stream: _workflowService.getAppWorkflows(cleanAppId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('워크플로우 데이터를 불러올 수 없습니다');
        }

        final workflows = snapshot.data ?? [];
        debugPrint('🔍 Provider TesterManagement - Total workflows found: ${workflows.length}');
        for (int i = 0; i < workflows.length; i++) {
          final w = workflows[i];
          debugPrint('🔍 Provider TesterManagement - Workflow $i: appId=${w.appId}, testerId=${w.testerId}, state=${w.currentState.name}');
        }

        final pendingApplications = workflows.where((w) =>
          w.currentState == MissionWorkflowState.applicationSubmitted).toList();
        debugPrint('🔍 Provider TesterManagement - Pending applications: ${pendingApplications.length}');

        if (pendingApplications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_add_disabled,
            title: '대기중인 신청이 없습니다',
            subtitle: '테스터들의 신청이 들어오면 여기에 표시됩니다',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: pendingApplications.length,
          itemBuilder: (context, index) {
            final workflow = pendingApplications[index];
            return _buildApplicationCard(workflow);
          },
        );
      },
    );
  }

  // 신청 카드 위젯
  Widget _buildApplicationCard(MissionWorkflowModel workflow) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(Icons.person, color: Colors.blue, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.testerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        workflow.testerEmail,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildWorkflowStateBadge(workflow.currentState),
              ],
            ),

            SizedBox(height: 16.h),

            // 경험 & 동기
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '경험',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    workflow.experience,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '지원 동기',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    workflow.motivation,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 미션 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(Icons.calendar_today, '${workflow.totalDays}일'),
                _buildInfoChip(Icons.attach_money, '일 ${workflow.dailyReward}원'),
                _buildInfoChip(Icons.date_range, _formatDate(workflow.appliedAt)),
              ],
            ),

            SizedBox(height: 16.h),

            // 액션 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleApplication(workflow, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('거부'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApplication(workflow, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('승인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  // 탭 2: 진행중 미션
  Widget _buildActiveMissionsTab() {
    return StreamBuilder<List<MissionWorkflowModel>>(
      stream: _workflowService.getAppWorkflows(_getCleanAppId()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workflows = snapshot.data ?? [];
        // v2.106.5: 진행중 미션 필터링 (applicationApproved 제거, inProgress 추가)
        final activeMissions = workflows.where((w) =>
          w.currentState == MissionWorkflowState.missionInProgress ||
          w.currentState == MissionWorkflowState.inProgress ||
          w.currentState == MissionWorkflowState.dailyMissionStarted ||
          w.currentState == MissionWorkflowState.dailyMissionCompleted ||
          w.currentState == MissionWorkflowState.dailyMissionApproved
        ).toList();

        if (activeMissions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_turned_in,
            title: '진행중인 미션이 없습니다',
            subtitle: '승인된 테스터의 미션이 여기에 표시됩니다',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: activeMissions.length,
          itemBuilder: (context, index) {
            final workflow = activeMissions[index];
            return _buildActiveMissionCard(workflow);
          },
        );
      },
    );
  }

  // 진행중 미션 카드
  Widget _buildActiveMissionCard(MissionWorkflowModel workflow) {
    final progress = (workflow.currentDay / workflow.totalDays * 100).clamp(0, 100);
    final todayInteraction = workflow.dailyInteractions.isNotEmpty
        ? workflow.dailyInteractions.lastWhere(
            (i) => i.dayNumber == workflow.currentDay,
            orElse: () => workflow.dailyInteractions.last,
          )
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Text(
                    '${workflow.currentDay}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.testerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${workflow.currentDay}일차 / ${workflow.totalDays}일',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildWorkflowStateBadge(workflow.currentState),
              ],
            ),

            SizedBox(height: 16.h),

            // 진행률 바
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '진행률',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8.h,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),

            // 오늘의 미션 상태
            if (todayInteraction != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _getMissionStatusColor(todayInteraction).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _getMissionStatusColor(todayInteraction).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getMissionStatusIcon(todayInteraction),
                          size: 16.sp,
                          color: _getMissionStatusColor(todayInteraction),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _getMissionStatusText(todayInteraction),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: _getMissionStatusColor(todayInteraction),
                          ),
                        ),
                      ],
                    ),

                    // 테스터 피드백
                    if (todayInteraction.testerFeedback != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        '테스터 피드백',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        todayInteraction.testerFeedback!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],

                    // 승인 버튼 (완료되었지만 미승인 상태)
                    if (todayInteraction.testerCompleted && !todayInteraction.providerApproved) ...[
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => DailySubmissionReviewDialog(
                                  workflowId: workflow.id,
                                  dayNumber: todayInteraction.dayNumber,
                                  interaction: todayInteraction,
                                  providerId: widget.app.providerId,
                                  onReviewed: () => setState(() {}),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('미션 승인'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // 통계
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('획득 리워드', '${workflow.totalEarnedReward}원', Colors.green),
                _buildStatItem('지급 리워드', '${workflow.totalPaidReward}원', Colors.blue),
                _buildStatItem('남은 일수', '${workflow.totalDays - workflow.currentDay}일', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 탭 3: 완료된 미션
  Widget _buildCompletedMissionsTab() {
    return StreamBuilder<List<MissionWorkflowModel>>(
      stream: _workflowService.getAppWorkflows(_getCleanAppId()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workflows = snapshot.data ?? [];
        final completedMissions = workflows.where((w) =>
          w.currentState == MissionWorkflowState.projectCompleted ||
          w.currentState == MissionWorkflowState.projectApproved ||
          w.currentState == MissionWorkflowState.projectFinalized
        ).toList();

        if (completedMissions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.done_all,
            title: '완료된 미션이 없습니다',
            subtitle: '완료된 미션이 여기에 표시됩니다',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: completedMissions.length,
          itemBuilder: (context, index) {
            final workflow = completedMissions[index];
            return _buildCompletedMissionCard(workflow);
          },
        );
      },
    );
  }

  // 완료 미션 카드
  Widget _buildCompletedMissionCard(MissionWorkflowModel workflow) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(Icons.check_circle, color: Colors.blue, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.testerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '완료: ${_formatDate(workflow.completedAt)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (workflow.finalRating != null)
                  Row(
                    children: List.generate(5, (index) => Icon(
                      Icons.star,
                      size: 16.sp,
                      color: index < workflow.finalRating!
                        ? Colors.amber
                        : Colors.grey[300],
                    )),
                  ),
              ],
            ),

            SizedBox(height: 16.h),

            // 완료 정보
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCompletionStat('총 일수', '${workflow.totalDays}일'),
                  _buildCompletionStat('총 리워드', '${workflow.totalEarnedReward}원'),
                  _buildCompletionStat('상태', workflow.currentState.displayName),
                ],
              ),
            ),

            // 최종 피드백
            if (workflow.finalFeedback != null) ...[
              SizedBox(height: 16.h),
              Text(
                '최종 피드백',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                workflow.finalFeedback!,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[800],
                ),
              ),
            ],

            // 최종 승인 버튼
            if (workflow.currentState == MissionWorkflowState.projectCompleted) ...[
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () => _showFinalApprovalDialog(workflow),
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('프로젝트 최종 승인'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 44.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 탭 4: 분석
  Widget _buildAnalyticsTab() {
    return StreamBuilder<List<MissionWorkflowModel>>(
      stream: _workflowService.getAppWorkflows(_getCleanAppId()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workflows = snapshot.data ?? [];

        if (workflows.isEmpty) {
          return _buildEmptyState(
            icon: Icons.analytics_outlined,
            title: '데이터가 없습니다',
            subtitle: '미션 데이터가 쌓이면 분석 정보가 표시됩니다',
          );
        }

        // 통계 계산
        final totalApplications = workflows.length;
        final approvedApplications = workflows.where((w) =>
          w.currentState != MissionWorkflowState.applicationSubmitted &&
          w.currentState != MissionWorkflowState.applicationRejected).length;
        final completedMissions = workflows.where((w) =>
          w.currentState == MissionWorkflowState.projectCompleted ||
          w.currentState == MissionWorkflowState.projectFinalized).length;
        final totalRewardPaid = workflows.fold<int>(0,
          (sum, w) => sum + w.totalPaidReward);
        final avgRating = workflows
          .where((w) => w.finalRating != null)
          .fold<double>(0, (sum, w) => sum + w.finalRating!) /
          (workflows.where((w) => w.finalRating != null).isNotEmpty
            ? workflows.where((w) => w.finalRating != null).length : 1);

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 요약 카드
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '미션 분석',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildAnalyticsRow('총 신청', '$totalApplications건', Icons.person_add),
                      _buildAnalyticsRow('승인된 신청', '$approvedApplications건', Icons.check_circle),
                      _buildAnalyticsRow('완료된 미션', '$completedMissions건', Icons.done_all),
                      _buildAnalyticsRow('지급된 리워드', '$totalRewardPaid원', Icons.attach_money),
                      _buildAnalyticsRow('평균 평점', '${avgRating.toStringAsFixed(1)}점', Icons.star),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // 테스터 순위
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '우수 테스터',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ...workflows
                        .where((w) => w.finalRating != null && w.finalRating! >= 4)
                        .take(5)
                        .map((w) => _buildTesterRankingItem(w)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 헬퍼 위젯들
  Widget _buildWorkflowStateBadge(MissionWorkflowState state) {
    Color color;
    switch (state) {
      case MissionWorkflowState.applicationSubmitted:
        color = Colors.orange;
        break;
      case MissionWorkflowState.applicationApproved:
      case MissionWorkflowState.missionInProgress:
      case MissionWorkflowState.dailyMissionStarted:
        color = Colors.blue;
        break;
      case MissionWorkflowState.dailyMissionCompleted:
      case MissionWorkflowState.dailyMissionApproved:
        color = Colors.green;
        break;
      case MissionWorkflowState.projectCompleted:
      case MissionWorkflowState.projectFinalized:
        color = Colors.purple;
        break;
      case MissionWorkflowState.applicationRejected:
      case MissionWorkflowState.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        state.displayName,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: Colors.grey[600]),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey[600]),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTesterRankingItem(MissionWorkflowModel workflow) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: Colors.amber[100],
            child: Icon(Icons.person, size: 16.sp, color: Colors.amber[700]),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              workflow.testerName,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          Row(
            children: List.generate(5, (index) => Icon(
              Icons.star,
              size: 14.sp,
              color: index < workflow.finalRating!
                ? Colors.amber
                : Colors.grey[300],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 헬퍼 메서드들
  Color _getMissionStatusColor(DailyMissionInteraction interaction) {
    if (interaction.providerApproved) return Colors.green;
    if (interaction.testerCompleted) return Colors.orange;
    if (interaction.testerStarted) return Colors.blue;
    return Colors.grey;
  }

  IconData _getMissionStatusIcon(DailyMissionInteraction interaction) {
    if (interaction.providerApproved) return Icons.check_circle;
    if (interaction.testerCompleted) return Icons.pending_actions;
    if (interaction.testerStarted) return Icons.play_circle_outline;
    return Icons.radio_button_unchecked;
  }

  String _getMissionStatusText(DailyMissionInteraction interaction) {
    if (interaction.providerApproved) return '승인 완료';
    if (interaction.testerCompleted) return '승인 대기중';
    if (interaction.testerStarted) return '진행중';
    return '시작 전';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 액션 메서드들
  Future<void> _handleApplication(MissionWorkflowModel workflow, bool approved) async {
    try {
      await _workflowService.processMissionApplication(
        workflowId: workflow.id,
        approved: approved,
        processedBy: widget.app.providerId,
        feedback: approved ? '신청이 승인되었습니다.' : '신청이 거부되었습니다.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? '신청을 승인했습니다' : '신청을 거부했습니다'),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('처리 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _showFinalApprovalDialog(MissionWorkflowModel workflow) {
    final feedbackController = TextEditingController();
    final bonusController = TextEditingController(text: '0');
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('프로젝트 최종 승인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('테스터: ${workflow.testerName}'),
              Text('총 ${workflow.totalDays}일 미션 완료'),
              SizedBox(height: 16.h),
              const Text('최종 평점'),
              Row(
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setState(() => rating = index + 1),
                  icon: Icon(
                    Icons.star,
                    color: index < rating ? Colors.amber : Colors.grey[300],
                  ),
                )),
              ),
              TextField(
                controller: bonusController,
                decoration: const InputDecoration(
                  labelText: '보너스 리워드 (선택사항)',
                  hintText: '추가 지급할 보너스 금액',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: '최종 피드백',
                  hintText: '테스터에게 전달할 최종 피드백을 입력하세요',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await _workflowService.finalizeProject(
                  workflowId: workflow.id,
                  providerId: widget.app.providerId,
                  finalFeedback: feedbackController.text.isNotEmpty
                    ? feedbackController.text : null,
                  finalRating: rating,
                  bonusReward: int.tryParse(bonusController.text) ?? 0,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('프로젝트를 최종 승인했습니다'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              child: const Text('최종 승인'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.red[300]),
          SizedBox(height: 16.h),
          Text(
            '오류 발생',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(MissionWorkflowModel workflow, DailyMissionInteraction interaction) {
    final rejectionReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${interaction.dayNumber}일차 미션 거절'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('테스터: ${workflow.testerName}'),
            SizedBox(height: 16.h),
            const Text(
              '거절 사유를 입력해주세요:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: rejectionReasonController,
              decoration: const InputDecoration(
                hintText: '스크린샷이 부족합니다, 테스트 시간이 부족합니다 등',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (rejectionReasonController.text.trim().isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('거절 사유를 입력해주세요'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context); // 거절 다이얼로그 닫기
              Navigator.pop(context); // 승인 다이얼로그 닫기

              try {
                // 일일 미션 ID 찾기 (interaction에서 생성)
                final missionId = '${workflow.id}_day_${interaction.dayNumber}';

                await _missionManagementService.updateMissionStatus(
                  missionId: missionId,
                  status: DailyMissionStatus.rejected,
                  note: rejectionReasonController.text.trim(),
                );

                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('일일 미션을 거절했습니다'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('거절 처리 중 오류가 발생했습니다: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );
  }
}