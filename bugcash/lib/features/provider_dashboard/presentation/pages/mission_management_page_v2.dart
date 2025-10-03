import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/utils/logger.dart';
import '../../../../features/mission/domain/entities/mission_workflow_entity.dart';
import '../../../../features/mission/presentation/providers/mission_providers.dart';
import '../../../provider_dashboard/presentation/pages/app_management_page.dart';

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

    // ✅ v2.14.0: 폴링 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // v2.14.4: dispose 후 ref 사용 방지
      if (mounted) {
        try {
          print('🔄 [MissionManagementV2] 폴링 시작 시도...');
          ref.read(missionStateNotifierProvider.notifier)
            .startPollingForProvider(widget.app.providerId);
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
              '미션관리 v2.14.0',
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
            final approvedTesters = missions
                .where((m) =>
                    m.status == MissionWorkflowStatus.approved ||
                    m.status == MissionWorkflowStatus.inProgress ||
                    m.status == MissionWorkflowStatus.testingCompleted ||
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
              SizedBox(width: 8.w),
              Text(
                '승인된 테스터 전체 (${approvedTesters.length}명)',
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
  Widget _buildApprovedTesterCard(MissionWorkflowEntity mission) {
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
            // v2.15.0: 대기중 상태일 때만 '미션 시작' 버튼 표시
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
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    '미션 시작',
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
            // 진행 중인 미션 필터링
            final inProgressMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.inProgress)
                .toList();

            print('✅ [MissionManagementV2] 오늘탭 State: LOADED');
            print('   ├─ 전체 미션: ${missions.length}개');
            print('   └─ 진행중: ${inProgressMissions.length}개');

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  if (inProgressMissions.isEmpty)
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
                              '진행 중인 미션이 없습니다',
                              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      itemCount: inProgressMissions.length,
                      itemBuilder: (context, index) {
                        final mission = inProgressMissions[index];
                        return _buildInProgressMissionCard(mission);
                      },
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
  Future<void> _startMission(String missionId) async {
    try {
      await ref.read(missionStateNotifierProvider.notifier)
        .startMission(missionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 미션이 시작되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 미션 시작 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
