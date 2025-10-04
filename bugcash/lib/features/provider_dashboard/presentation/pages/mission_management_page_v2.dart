import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../../features/mission/domain/entities/mission_workflow_entity.dart';
import '../../../../features/mission/presentation/providers/mission_providers.dart';
import '../../../provider_dashboard/presentation/pages/app_management_page.dart';
import '../../../provider_dashboard/presentation/pages/daily_mission_review_page.dart';

/// v2.14.0: Clean Architecture로 전환된 미션관리 페이지
/// 실시간 리스너 → 폴링 기반 상태 관리
class MissionManagementPageV2 extends ConsumerStatefulWidget {
  final ProviderAppModel app;

  const MissionManagementPageV2({
    super.key,
    required this.app,
  });

  @override
  ConsumerState<MissionManagementPageV2> createState() => _MissionManagementPageV2State();
}

class _MissionManagementPageV2State extends ConsumerState<MissionManagementPageV2>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // v2.24.0: 대량 미션 생성을 위한 선택 상태
  final Set<String> _selectedMissionIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // v2.14.7: 프로덕션 디버깅을 위한 print 로그
    print('📱 [MissionManagementV2] 페이지 초기화');
    print('   ├─ appId: ${widget.app.id}');
    print('   ├─ appName: ${widget.app.appName}');
    print('   └─ providerId: ${widget.app.providerId}');

    FeatureFlagUtils.logFeatureUsage('mission_management_page_v2', widget.app.providerId);

    // ✅ v2.20.0: 앱별 폴링 시작 (해당 앱의 테스터만 표시)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // v2.14.4: dispose 후 ref 사용 방지
      if (mounted) {
        try {
          print('🔄 [MissionManagementV2] 앱별 폴링 시작 시도...');
          print('   ├─ appId: ${widget.app.id}');
          print('   └─ providerId: ${widget.app.providerId}');

          ref.read(missionStateNotifierProvider.notifier)
            .startPollingForApp(widget.app.id, widget.app.providerId);

          print('✅ [MissionManagementV2] 폴링 시작 완료');
        } catch (e) {
          print('❌ [MissionManagementV2] 폴링 시작 실패: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    // ✅ v2.14.4: 폴링 중지 (try-catch로 안전하게)
    try {
      ref.read(missionStateNotifierProvider.notifier).stopPolling();
      AppLogger.info('✅ Polling stopped', 'MissionManagementV2');
    } catch (e) {
      AppLogger.warning('⚠️ Failed to stop polling in dispose: $e', 'MissionManagementV2');
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '미션관리 v2.20.0',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              widget.app.appName,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // ✅ 수동 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(missionStateNotifierProvider.notifier).refreshMissions();
            },
            tooltip: '수동 새로고침',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: '테스터'),
            Tab(text: '오늘'),
            Tab(text: '완료'),
            Tab(text: '종료'),
            Tab(text: '삭제요청'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTesterRecruitmentTab(),
          _buildTodayMissionsTab(),
          _buildCompletedMissionsTab(),
          _buildSettlementTab(),
          _buildDeletionRequestsTab(),
        ],
      ),
    );
  }

  /// v2.14.0: Clean Architecture - 테스터 탭
  Widget _buildTesterRecruitmentTab() {
    return Consumer(
      builder: (context, ref, child) {
        final missionsState = ref.watch(missionStateNotifierProvider);

        return missionsState.when(
          initial: () {
            print('⏳ [MissionManagementV2] 테스터탭 State: INITIAL');
            return const Center(child: Text('초기화 중...'));
          },
          loading: () {
            print('🔄 [MissionManagementV2] 테스터탭 State: LOADING');
            return const Center(child: CircularProgressIndicator());
          },
          loaded: (missions, isRefreshing) {
            // 대기중 신청 필터링
            final pendingApplications = missions
                .where((m) => m.status == MissionWorkflowStatus.applicationSubmitted)
                .toList();

            // v2.15.0: 승인된 테스터 전체 필터링 (진행중, 완료 포함)
            // v2.24.4: dailyMissionCompleted 상태 추가 (검토 대기 중인 테스터 포함)
            // v2.25.13: dailyMissionApproved 상태 추가 (일일 미션 승인 후 대기 중인 테스터 포함)
            final approvedTesters = missions
                .where((m) =>
                    m.status == MissionWorkflowStatus.approved ||
                    m.status == MissionWorkflowStatus.inProgress ||
                    m.status == MissionWorkflowStatus.testingCompleted ||
                    m.status == MissionWorkflowStatus.dailyMissionCompleted ||
                    m.status == MissionWorkflowStatus.dailyMissionApproved ||
                    m.status == MissionWorkflowStatus.submissionCompleted)
                .toList();

            // 상태별 개수 집계
            final approvedCount = approvedTesters.where((m) => m.status == MissionWorkflowStatus.approved).length;
            final inProgressCount = approvedTesters.where((m) => m.status == MissionWorkflowStatus.inProgress).length;
            final testingCompletedCount = approvedTesters.where((m) => m.status == MissionWorkflowStatus.testingCompleted).length;
            final submissionCompletedCount = approvedTesters.where((m) => m.status == MissionWorkflowStatus.submissionCompleted).length;

            print('✅ [MissionManagementV2] 테스터탭 State: LOADED');
            print('   ├─ 전체 미션: ${missions.length}개');
            print('   ├─ 신청 대기: ${pendingApplications.length}개');
            print('   └─ 승인된 테스터 전체: ${approvedTesters.length}개');
            print('      ├─ 대기중: $approvedCount개');
            print('      ├─ 진행중: $inProgressCount개');
            print('      ├─ 테스트완료: $testingCompletedCount개');
            print('      └─ 제출완료: $submissionCompletedCount개');

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 새로고침 표시
                  if (isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  // 섹션 1: 테스터 신청 대기중
                  _buildPendingSection(pendingApplications),

                  // 섹션 2: 승인된 테스터
                  _buildApprovedSection(approvedTesters),
                ],
              ),
            );
          },
          error: (message, exception) {
            print('❌ [MissionManagementV2] 테스터탭 State: ERROR');
            print('   └─ 메시지: $message');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text('오류가 발생했습니다'),
                  SizedBox(height: 8.h),
                  Text(message, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(missionStateNotifierProvider.notifier).refreshMissions();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingSection(List<MissionWorkflowEntity> applications) {
    if (applications.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 40.sp, color: Colors.grey),
                SizedBox(height: 12.h),
                Text(
                  '신청 대기중인 테스터가 없습니다',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, size: 20.sp, color: Colors.orange),
              SizedBox(width: 8.w),
              Text(
                '테스터 신청 대기중 (${applications.length}명)',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index];
            return _buildTesterApplicationCard(application);
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildApprovedSection(List<MissionWorkflowEntity> approvedTesters) {
    if (approvedTesters.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 40.sp, color: Colors.green[300]),
                SizedBox(height: 12.h),
                Text(
                  '승인된 테스터가 없습니다',
                  style: TextStyle(fontSize: 14.sp, color: Colors.green[700]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // v2.24.0: approved 상태만 필터링 (미션만들기 가능한 테스터)
    final approvedOnlyTesters = approvedTesters
        .where((t) => t.status == MissionWorkflowStatus.approved)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // v2.24.0: 헤더 (전체 선택 체크박스 + 대량 생성 버튼)
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: Row(
            children: [
              // v2.24.0: 전체 선택 체크박스 (approved 상태만 선택 가능)
              if (approvedOnlyTesters.isNotEmpty)
                Checkbox(
                  value: _selectedMissionIds.isNotEmpty &&
                      _selectedMissionIds.length == approvedOnlyTesters.length,
                  tristate: _selectedMissionIds.isNotEmpty &&
                      _selectedMissionIds.length < approvedOnlyTesters.length,
                  onChanged: (value) => _toggleSelectAll(approvedOnlyTesters),
                ),
              Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '승인된 테스터 전체 (${approvedTesters.length}명)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // v2.24.0: 대량 미션 생성 버튼 (선택된 항목이 있을 때만 표시)
              if (_selectedMissionIds.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    // Phase 3에서 구현 예정
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phase 3에서 구현 예정 (선택: ${_selectedMissionIds.length}명)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  icon: Icon(Icons.play_arrow, size: 18.sp),
                  label: Text(
                    '선택한 ${_selectedMissionIds.length}명 미션만들기',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: approvedTesters.length,
          itemBuilder: (context, index) {
            final tester = approvedTesters[index];
            return _buildApprovedTesterCard(tester);
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  /// 테스터 신청 카드 (v2.14.0)
  Widget _buildTesterApplicationCard(MissionWorkflowEntity mission) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    mission.testerName.isNotEmpty
                      ? mission.testerName[0].toUpperCase()
                      : 'T',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.testerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        mission.testerEmail,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '대기중',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectMission(mission.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('거부'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveMission(mission.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('승인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 승인된 테스터 카드 (v2.14.0)
  /// v2.24.0: 체크박스 추가
  Widget _buildApprovedTesterCard(MissionWorkflowEntity mission) {
    final isApproved = mission.status == MissionWorkflowStatus.approved;
    final isSelected = _selectedMissionIds.contains(mission.id);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // v2.24.0: approved 상태만 체크박스 표시
                if (isApproved)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleSelection(mission.id),
                  ),
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.testerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        mission.testerEmail,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(mission.status),
              ],
            ),
            // v2.23.0: 승인된 상태일 때 '미션만들기' 버튼 표시
            if (mission.status == MissionWorkflowStatus.approved) ...[
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startMission(mission.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: const Icon(Icons.add_task, color: Colors.white),
                  label: const Text(
                    '미션만들기',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// v2.15.0: 미션 상태 배지 생성 헬퍼
  Widget _buildStatusBadge(MissionWorkflowStatus status) {
    String label;
    Color color;

    switch (status) {
      case MissionWorkflowStatus.approved:
        label = '대기중';
        color = Colors.orange;
        break;
      case MissionWorkflowStatus.inProgress:
        label = '진행중';
        color = Colors.blue;
        break;
      case MissionWorkflowStatus.testingCompleted:
        label = '테스트완료';
        color = Colors.purple;
        break;
      case MissionWorkflowStatus.submissionCompleted:
        label = '제출완료';
        color = Colors.green;
        break;
      default:
        label = status.name;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 오늘 미션 탭 - 진행 중인 미션 표시
  Widget _buildTodayMissionsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final missionsState = ref.watch(missionStateNotifierProvider);

        return missionsState.when(
          initial: () {
            print('⏳ [MissionManagementV2] 오늘탭 State: INITIAL');
            return const Center(child: Text('초기화 중...'));
          },
          loading: () {
            print('🔄 [MissionManagementV2] 오늘탭 State: LOADING');
            return const Center(child: CircularProgressIndicator());
          },
          loaded: (missions, isRefreshing) {
            // v2.25.04: 진행 중 + 검토 대기 + 승인 완료 필터링
            final inProgressMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.inProgress)
                .toList();

            final reviewPendingMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.dailyMissionCompleted)
                .toList();

            final approvedMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.dailyMissionApproved)
                .toList();

            print('✅ [MissionManagementV2] 오늘탭 State: LOADED');
            print('   ├─ 전체 미션: ${missions.length}개');
            print('   ├─ 진행중: ${inProgressMissions.length}개');
            print('   ├─ 검토 대기: ${reviewPendingMissions.length}개');
            print('   └─ 승인 완료: ${approvedMissions.length}개');

            final totalTodayMissions = inProgressMissions.length + reviewPendingMissions.length + approvedMissions.length;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  if (totalTodayMissions == 0)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 100.h),
                            Icon(Icons.assignment_outlined, size: 64.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            Text(
                              '오늘 처리할 미션이 없습니다',
                              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // v2.22.0: 검토 대기 섹션
                        if (reviewPendingMissions.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                            child: Row(
                              children: [
                                Icon(Icons.rate_review, size: 20.sp, color: Colors.orange),
                                SizedBox(width: 8.w),
                                Text(
                                  '검토 대기중 (${reviewPendingMissions.length}건)',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: reviewPendingMissions.length,
                            itemBuilder: (context, index) {
                              print('📝 [오늘탭-검토대기] Building card ${index + 1}/${reviewPendingMissions.length}');
                              final mission = reviewPendingMissions[index];
                              return _buildReviewPendingMissionCard(mission);
                            },
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // v2.25.04: 승인 완료 섹션 (다음 날 미션 만들기 대기)
                        if (approvedMissions.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
                                SizedBox(width: 8.w),
                                Text(
                                  '승인 완료 (${approvedMissions.length}건)',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: approvedMissions.length,
                            itemBuilder: (context, index) {
                              final mission = approvedMissions[index];
                              return _buildApprovedMissionCard(mission);
                            },
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // 진행 중 섹션
                        if (inProgressMissions.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                            child: Row(
                              children: [
                                Icon(Icons.play_circle_filled, size: 20.sp, color: Colors.blue),
                                SizedBox(width: 8.w),
                                Text(
                                  '진행 중 (${inProgressMissions.length}건)',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: inProgressMissions.length,
                            itemBuilder: (context, index) {
                              final mission = inProgressMissions[index];
                              return _buildInProgressMissionCard(mission);
                            },
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
          error: (message, exception) {
            print('❌ [MissionManagementV2] 오늘탭 State: ERROR');
            print('   └─ 메시지: $message');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text('오류가 발생했습니다'),
                  SizedBox(height: 8.h),
                  Text(message, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 완료 미션 탭 - 테스팅 완료된 미션
  Widget _buildCompletedMissionsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final missionsState = ref.watch(missionStateNotifierProvider);

        return missionsState.when(
          initial: () => const Center(child: Text('초기화 중...')),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (missions, isRefreshing) {
            final completedMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.testingCompleted)
                .toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  if (completedMissions.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 100.h),
                          Icon(Icons.check_circle_outline, size: 64.sp, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            '완료된 미션이 없습니다',
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      itemCount: completedMissions.length,
                      itemBuilder: (context, index) {
                        final mission = completedMissions[index];
                        return _buildCompletedMissionCard(mission);
                      },
                    ),
                ],
              ),
            );
          },
          error: (message, exception) => Center(child: Text('오류: $message')),
        );
      },
    );
  }

  /// 종료 탭 - 제출 완료된 미션
  Widget _buildSettlementTab() {
    return Consumer(
      builder: (context, ref, child) {
        final missionsState = ref.watch(missionStateNotifierProvider);

        return missionsState.when(
          initial: () => const Center(child: Text('초기화 중...')),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (missions, isRefreshing) {
            final settledMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.submissionCompleted)
                .toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  if (settledMissions.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 100.h),
                          Icon(Icons.done_all, size: 64.sp, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            '종료된 미션이 없습니다',
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      itemCount: settledMissions.length,
                      itemBuilder: (context, index) {
                        final mission = settledMissions[index];
                        return _buildSettledMissionCard(mission);
                      },
                    ),
                ],
              ),
            );
          },
          error: (message, exception) => Center(child: Text('오류: $message')),
        );
      },
    );
  }

  /// 삭제요청 탭 - 취소된 미션
  Widget _buildDeletionRequestsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final missionsState = ref.watch(missionStateNotifierProvider);

        return missionsState.when(
          initial: () => const Center(child: Text('초기화 중...')),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (missions, isRefreshing) {
            final cancelledMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.cancelled)
                .toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  if (cancelledMissions.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 100.h),
                          Icon(Icons.delete_sweep, size: 64.sp, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            '삭제 요청이 없습니다',
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      itemCount: cancelledMissions.length,
                      itemBuilder: (context, index) {
                        final mission = cancelledMissions[index];
                        return _buildCancelledMissionCard(mission);
                      },
                    ),
                ],
              ),
            );
          },
          error: (message, exception) => Center(child: Text('오류: $message')),
        );
      },
    );
  }

  /// 진행 중 미션 카드
  /// v2.22.0: 검토 대기중인 미션 카드
  Widget _buildReviewPendingMissionCard(MissionWorkflowEntity mission) {
    // v2.24.5: Debug - 카드 렌더링 확인
    print('🔍 [ReviewPendingCard] Rendering for mission: ${mission.id}');
    print('   ├─ testerName: ${mission.testerName}');
    print('   ├─ dailyInteractions.length: ${mission.dailyInteractions.length}');

    // 가장 최근 제출된 일일 미션 찾기
    final submittedInteractions = mission.dailyInteractions
        .where((i) => i.testerCompleted && !i.providerApproved)
        .toList()
      ..sort((a, b) => b.dayNumber.compareTo(a.dayNumber));

    print('   ├─ submittedInteractions.length: ${submittedInteractions.length}');

    // v2.24.4: dailyMissionCompleted 상태면 최소한 Day 1은 제출되었다고 가정
    final latestDayNumber = submittedInteractions.isNotEmpty
        ? submittedInteractions.first.dayNumber
        : 1; // 0 대신 1 사용

    print('   └─ latestDayNumber: $latestDayNumber');

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, size: 20.sp, color: Colors.orange),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mission.testerName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '검토 대기중',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              mission.testerEmail,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Day $latestDayNumber 제출됨',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 리뷰 페이지로 이동
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DailyMissionReviewPage(
                          mission: mission,
                          dayNumber: latestDayNumber,
                        ),
                      ),
                    );

                    // 리뷰 완료 후 목록 새로고침
                    if (result == true && mounted) {
                      ref.read(missionStateNotifierProvider.notifier).refreshMissions();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: Size(100, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '상세보기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// v2.25.04: 승인 완료 미션 카드 (다음 날 미션 만들기 버튼 포함)
  Widget _buildApprovedMissionCard(MissionWorkflowEntity mission) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mission.testerName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '승인 완료',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              mission.testerEmail,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  'Day ${mission.completedDays} 승인 완료',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 16.sp, color: Colors.orange),
                SizedBox(width: 4.w),
                Text(
                  'Day ${mission.completedDays + 1} 미션 생성 필요',
                  style: TextStyle(fontSize: 14.sp, color: Colors.orange[700], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // 다음 날 미션 생성
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('다음 날 미션 생성'),
                      content: Text(
                        'Day ${mission.completedDays + 1} 미션을 생성하시겠습니까?\n\n'
                        '테스터가 다음 날 미션을 시작할 수 있게 됩니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('생성'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await _attemptCreateMission(mission);
                  }
                },
                icon: Icon(Icons.add_circle_outline, size: 20.sp),
                label: Text(
                  'Day ${mission.completedDays + 1} 미션 만들기',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressMissionCard(MissionWorkflowEntity mission) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled, size: 20.sp, color: Colors.blue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mission.testerName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '진행중',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              mission.testerEmail,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  '${mission.completedDays}/${mission.totalDays}일 완료',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                ),
                const Spacer(),
                Text(
                  '${(mission.completionRate * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            LinearProgressIndicator(
              value: mission.completionRate,
              backgroundColor: Colors.grey[200],
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// 완료된 미션 카드
  Widget _buildCompletedMissionCard(MissionWorkflowEntity mission) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mission.testerName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${mission.estimatedTotalReward}원',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '완료일: ${mission.completedAt?.toString().substring(0, 10) ?? 'N/A'}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 종료된 미션 카드
  Widget _buildSettledMissionCard(MissionWorkflowEntity mission) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.done_all, size: 20.sp, color: Colors.blue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mission.testerName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${mission.estimatedTotalReward}원',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '종료일: ${mission.completedAt?.toString().substring(0, 10) ?? 'N/A'}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 취소된 미션 카드
  Widget _buildCancelledMissionCard(MissionWorkflowEntity mission) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, size: 20.sp, color: Colors.red),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mission.testerName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '취소됨',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              mission.testerEmail,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Command Methods (v2.14.0 - Clean Architecture)
  // ========================================

  /// ✅ 미션 승인 (낙관적 업데이트)
  Future<void> _approveMission(String missionId) async {
    try {
      await ref.read(missionStateNotifierProvider.notifier)
        .approveMission(missionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 테스터를 승인했습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 승인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ 미션 거부 (낙관적 업데이트)
  Future<void> _rejectMission(String missionId) async {
    try {
      await ref.read(missionStateNotifierProvider.notifier)
        .rejectMission(missionId, '공급자가 거부함');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 테스터 신청을 거부했습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 거부 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ 미션 시작 (낙관적 업데이트)
  /// v2.23.0: 미션 생성 및 "오늘" 탭 자동 전환
  Future<void> _startMission(String missionId) async {
    try {
      await ref.read(missionStateNotifierProvider.notifier)
        .startMission(missionId);

      if (mounted) {
        // ✨ v2.23.0: "오늘" 탭으로 자동 전환
        _tabController.animateTo(1); // 1 = "오늘" 탭 인덱스

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 미션이 생성되었습니다. "오늘" 탭에서 확인하세요'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 미션 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// v2.24.0: 개별 테스터 선택/해제
  void _toggleSelection(String missionId) {
    setState(() {
      if (_selectedMissionIds.contains(missionId)) {
        _selectedMissionIds.remove(missionId);
      } else {
        _selectedMissionIds.add(missionId);
      }
    });
  }

  /// v2.24.0: 전체 선택/해제
  void _toggleSelectAll(List<MissionWorkflowEntity> approvedTesters) {
    setState(() {
      final approvedIds = approvedTesters
          .where((t) => t.status == MissionWorkflowStatus.approved)
          .map((t) => t.id)
          .toList();

      if (_selectedMissionIds.length == approvedIds.length) {
        _selectedMissionIds.clear(); // 전체 해제
      } else {
        _selectedMissionIds.clear();
        _selectedMissionIds.addAll(approvedIds); // 전체 선택
      }
    });
  }

  /// v2.25.16: 미션 생성 시도 (이미 존재하면 다음 미션 제안)
  /// v2.25.17: specificDay를 targetDay로 전달하여 재귀 호출 시 특정 날짜 생성
  Future<void> _attemptCreateMission(MissionWorkflowEntity mission, {int? specificDay}) async {
    try {
      final service = ref.read(missionWorkflowServiceProvider);
      await service.createNextDayMission(
        workflowId: mission.id,
        providerId: mission.providerId,
        targetDay: specificDay,  // v2.25.17: 특정 날짜 지정
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Day ${specificDay ?? mission.completedDays + 1} 미션이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        // 상태 새로고침
        ref.read(missionStateNotifierProvider.notifier).startPollingForApp(
          mission.appId,
          mission.providerId,
        );
      }
    } on MissionAlreadyExistsException catch (e) {
      // v2.25.16: 미션이 이미 존재하면 다음 날 미션 생성 제안
      if (mounted) {
        final nextDay = e.dayNumber + 1;

        // 다음 날 미션 생성 제안 다이얼로그
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 28.sp),
                SizedBox(width: 8.w),
                Text('Day ${e.dayNumber} 이미 존재'),
              ],
            ),
            content: Text(
              'Day ${e.dayNumber} 미션이 이미 생성되어 있습니다.\n\n'
              'Day $nextDay 미션을 생성하시겠습니까?',
              style: TextStyle(fontSize: 15.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Day $nextDay 생성'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          // 재귀적으로 다음 날 미션 생성 시도
          await _attemptCreateMission(mission, specificDay: nextDay);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
