import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/services/mission_workflow_service.dart';  // v2.25.19: 복원
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

  // v2.34.0: 대량 미션 생성 기능 제거 (승인된 테스터 섹션 제거)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // v2.36.0: 5개 → 3개 탭으로 축소

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

          ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier)
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
    // v2.28.0: ref 사용 제거 - AutoDispose가 자동으로 폴링 중지
    // ❌ ref.read() 사용 금지 - dispose에서 ref 접근 불가
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.providerBluePrimary,
        elevation: 2,
        shadowColor: AppColors.providerBluePrimary.withValues(alpha: 0.3),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '미션관리 v2.20.0',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              widget.app.appName,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.providerBlueLight.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // ✅ 수동 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier).refreshMissions();
            },
            tooltip: '수동 새로고침',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.providerBlueLight.withValues(alpha: 0.7),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: '테스터'), // v2.36.0: 신청 대기 + 진행 중인 테스터
            Tab(text: '오늘'),   // v2.36.0: 일일 미션 검토
            Tab(text: '종료'),   // v2.36.0: 최종 완료된 미션
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTesterRecruitmentTab(), // v2.36.0: 테스터 모집 + 진행 중인 테스터
          _buildTodayMissionsTab(),     // v2.36.0: 오늘의 일일 미션
          _buildSettlementTab(),        // v2.36.0: 종료된 미션
        ],
      ),
    );
  }

  /// v2.14.0: Clean Architecture - 테스터 탭
  Widget _buildTesterRecruitmentTab() {
    return Consumer(
      builder: (context, ref, child) {
        final missionsState = ref.watch(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)));

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

            // v2.35.1: 진행 중인 테스터 - 승인 이후 모든 상태 표시 (정보 전용)
            // daily_mission_started는 inProgress로 매핑됨
            // v2.40.0: submissionCompleted 제외 (종료 탭으로 이동)
            final activeTesters = missions
                .where((m) =>
                    m.status == MissionWorkflowStatus.approved ||
                    m.status == MissionWorkflowStatus.inProgress ||  // daily_mission_started 포함
                    m.status == MissionWorkflowStatus.testingCompleted ||
                    m.status == MissionWorkflowStatus.dailyMissionCompleted ||
                    m.status == MissionWorkflowStatus.dailyMissionApproved)
                .toList();

            print('✅ [MissionManagementV2] 테스터탭 State: LOADED');
            print('   ├─ 전체 미션: ${missions.length}개');
            print('   ├─ 신청 대기: ${pendingApplications.length}개');
            print('   └─ 진행 중인 테스터: ${activeTesters.length}개');

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 새로고침 표시
                  if (isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  // 섹션 1: 테스터 신청 대기중
                  _buildPendingSection(pendingApplications),

                  // 섹션 2: 진행 중인 테스터 (v2.35.0)
                  _buildActiveTesterSection(activeTesters),
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
                      ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier).refreshMissions();
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

  /// v2.35.0: 진행 중인 테스터 섹션 (정보 전용, 버튼 없음)
  Widget _buildActiveTesterSection(List<MissionWorkflowEntity> activeTesters) {
    if (activeTesters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: Row(
            children: [
              Icon(Icons.people, size: 20.sp, color: Colors.blue),
              SizedBox(width: 8.w),
              Text(
                '진행 중인 테스터 (${activeTesters.length}명)',
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
          itemCount: activeTesters.length,
          itemBuilder: (context, index) {
            return _buildActiveTesterInfoCard(activeTesters[index]);
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  /// v2.35.0: 진행 중인 테스터 정보 카드 (버튼 없음, 읽기 전용)
  Widget _buildActiveTesterInfoCard(MissionWorkflowEntity mission) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.providerBlueLight.withValues(alpha: 0.3), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.providerBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                color: Colors.blue,
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
      ),
    );
  }

  /// 테스터 신청 카드 (v2.14.0)
  Widget _buildTesterApplicationCard(MissionWorkflowEntity mission) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.providerBlueLight.withValues(alpha: 0.3), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.providerBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    mission.testerName.isNotEmpty
                      ? mission.testerName[0].toUpperCase()
                      : 'T',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
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

  // v2.34.0: _buildApprovedTesterCard 제거 - 테스터탭에서 승인된 테스터 카드 제거

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
        final missionsState = ref.watch(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)));

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
            print('   └─ 검토 완료: ${approvedMissions.length}개'); // v2.37.0

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

                        // v2.37.0: 검토 완료 섹션 (다음 날 미션 만들기 대기)
                        if (approvedMissions.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
                                SizedBox(width: 8.w),
                                Text(
                                  '검토 완료 (${approvedMissions.length}건)', // v2.37.0
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

  // v2.36.0: _buildCompletedMissionsTab() 제거 - testingCompleted 상태 미사용

  /// v2.41.0: 종료 탭 - 제출 완료된 미션 (앱별 그룹화)
  Widget _buildSettlementTab() {
    return Consumer(
      builder: (context, ref, child) {
        final missionsState = ref.watch(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)));

        return missionsState.when(
          initial: () => const Center(child: Text('초기화 중...')),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (missions, isRefreshing) {
            final settledMissions = missions
                .where((m) => m.status == MissionWorkflowStatus.submissionCompleted)
                .toList();

            // v2.41.0: 현재 앱에 대한 종료된 미션만 표시 (이미 필터링됨)
            // appId는 이미 widget.app.id로 필터링되어 있으므로 별도 그룹화 불필요

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
                    Column(
                      children: [
                        // v2.42.0: 앱 정보 헤더
                        _buildAppInfoHeader(settledMissions.length),

                        // v2.41.0: 테스터 리스트
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: settledMissions.length,
                          itemBuilder: (context, index) {
                            final mission = settledMissions[index];
                            return _buildSettledMissionCard(mission);
                          },
                        ),
                      ],
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

  // v2.36.0: _buildDeletionRequestsTab() 제거 - cancelled 상태 미사용

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

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.providerBlueLight.withValues(alpha: 0.3), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.providerBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier).refreshMissions();
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

  /// v2.37.0: 검토 완료 미션 카드 (다음 날 미션 만들기 버튼 포함)
  Widget _buildApprovedMissionCard(MissionWorkflowEntity mission) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.providerBlueLight.withValues(alpha: 0.3), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.providerBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    '검토 완료', // v2.37.0
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
                  'Day ${mission.completedDays} 검토 완료', // v2.37.0
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            // v2.25.19: "Day X 미션 시작" 버튼 복원 (생성 대신 활성화)
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.play_arrow, size: 16.sp, color: Colors.orange),
                SizedBox(width: 4.w),
                Text(
                  'Day ${mission.completedDays + 1} 미션 활성화 필요',
                  style: TextStyle(fontSize: 14.sp, color: Colors.orange[700], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Day ${mission.completedDays + 1} 미션 시작'),
                      content: Text(
                        'Day ${mission.completedDays + 1} 미션을 시작하시겠습니까?\n\n'
                        '테스터가 오늘중 탭에서 Day ${mission.completedDays + 1} 미션을 볼 수 있게 됩니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('시작'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    try {
                      final service = ref.read(missionWorkflowServiceProvider);
                      await service.activateNextDayMission(
                        workflowId: mission.id,
                        providerId: mission.providerId,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Day ${mission.completedDays + 1} 미션이 시작되었습니다'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // 상태 새로고침
                        ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier).startPollingForApp(
                          mission.appId,
                          mission.providerId,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('미션 시작 실패: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: Icon(Icons.play_arrow, size: 20.sp),
                label: Text(
                  'Day ${mission.completedDays + 1} 시작',
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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.providerBlueLight.withValues(alpha: 0.3), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.providerBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
  // v2.36.0: _buildCompletedMissionCard() 제거 - testingCompleted 상태 미사용

  /// v2.41.0: 종료된 미션 카드 (ExpansionTile - 테스터 이메일 포함, 클릭 시 Day 기록 확장)
  Widget _buildSettledMissionCard(MissionWorkflowEntity mission) {
    // v2.40.0: 승인된 일일 미션 목록 가져오기 (날짜순 정렬)
    final approvedInteractions = mission.dailyInteractions
        .where((i) => i.providerApproved)
        .toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          leading: Icon(Icons.done_all, size: 20.sp, color: Colors.blue),
          title: Text(
            mission.testerName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              Text(
                mission.testerEmail,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '종료일: ${mission.completedAt?.toString().substring(0, 10) ?? 'N/A'}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Text(
            '${mission.estimatedTotalReward}원',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          children: [
            // v2.41.0: Day 전체 승인 기록 표시 (확장 시에만)
            if (approvedInteractions.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '일일 승인 기록',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...approvedInteractions.map((interaction) {
                      final approvedDate = interaction.providerApprovedAt;
                      final dateStr = approvedDate != null
                          ? '${approvedDate.year}-${approvedDate.month.toString().padLeft(2, '0')}-${approvedDate.day.toString().padLeft(2, '0')} ${approvedDate.hour.toString().padLeft(2, '0')}:${approvedDate.minute.toString().padLeft(2, '0')}'
                          : 'N/A';

                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 14.sp, color: Colors.green),
                            SizedBox(width: 6.w),
                            Text(
                              'Day ${interaction.dayNumber}:',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 취소된 미션 카드
  // v2.36.0: _buildCancelledMissionCard() 제거 - cancelled 상태 미사용

  /// v2.42.0: 종료 탭 앱 정보 헤더
  Widget _buildAppInfoHeader(int testerCount) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          // 앱 아이콘
          CircleAvatar(
            radius: 28.r,
            backgroundColor: Colors.blue,
            child: Text(
              widget.app.appName.isNotEmpty
                  ? widget.app.appName[0].toUpperCase()
                  : 'A',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // 앱 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.app.appName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '카테고리: ${widget.app.category}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          // 종료된 테스터 수
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Text(
                  '$testerCount',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Command Methods (v2.14.0 - Clean Architecture)
  // ========================================

  /// ✅ 미션 승인 (낙관적 업데이트)
  Future<void> _approveMission(String missionId) async {
    try {
      await ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier)
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
      await ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier)
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
      await ref.read(cleanArchAppMissionProvider((appId: widget.app.id, providerId: widget.app.providerId)).notifier)
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

  // v2.34.0: 체크박스 관련 함수 제거 (_toggleSelection, _toggleSelectAll)
  // 승인된 테스터 섹션이 제거되어 더 이상 필요 없음

  // v2.25.18: _attemptCreateMission 함수 삭제
  // 모든 Day 미션은 최초 승인 시 자동 생성되므로 이 함수는 더 이상 필요 없음
}
