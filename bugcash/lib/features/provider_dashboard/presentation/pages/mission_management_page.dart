import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mission_management_service.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/utils/logger.dart';
import '../../../../features/shared/models/mission_management_model.dart';
import '../../../provider_dashboard/presentation/pages/app_management_page.dart';

/// 새로운 미션관리 페이지
/// v2.10.0: 5개 탭: 테스터 → 오늘 → 완료 → 종료 → 삭제요청
class MissionManagementPage extends ConsumerStatefulWidget {
  final ProviderAppModel app;

  const MissionManagementPage({
    super.key,
    required this.app,
  });

  @override
  ConsumerState<MissionManagementPage> createState() => _MissionManagementPageState();
}

class _MissionManagementPageState extends ConsumerState<MissionManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final MissionManagementService _missionService = MissionManagementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // 미션관리 페이지 진입 로그
    AppLogger.info(
      '📱 [미션관리] 페이지 초기화\n'
      '   ├─ appId: ${widget.app.id}\n'
      '   ├─ appName: ${widget.app.appName}\n'
      '   └─ providerId: ${widget.app.providerId}',
      'MissionManagement'
    );

    // Feature Flag 로깅
    FeatureFlagUtils.logFeatureUsage('mission_management_page', widget.app.providerId);
  }

  @override
  void dispose() {
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
              '미션관리',
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
            Tab(text: '테스터'), // v2.10.0: 대기 → 테스터로 변경
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

  /// v2.10.0: 테스터 탭 - 승인된 테스터 목록 항상 표시
  Widget _buildTesterRecruitmentTab() {
    return StreamBuilder<List<TesterApplicationModel>>(
      stream: _missionService.watchTesterApplications(widget.app.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text('오류가 발생했습니다: ${snapshot.error}'),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  '아직 신청한 테스터가 없습니다',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  '앱이 \'모집중\' 상태가 되면 테스터들이 신청할 수 있습니다',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index];
            return _buildTesterApplicationCard(application);
          },
        );
      },
    );
  }

  /// 오늘미션 탭 - 승인된 테스터 + 오늘의 미션 관리
  Widget _buildTodayMissionsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 1: 승인된 테스터 (미션 시작 대기중)
          StreamBuilder<List<TesterApplicationModel>>(
            stream: _missionService.watchApprovedTesters(widget.app.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(16.w),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final approvedTesters = snapshot.data ?? [];

              if (approvedTesters.isEmpty) {
                return const SizedBox.shrink(); // 승인된 테스터 없으면 숨김
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    child: Text(
                      '승인된 테스터 (미션 시작 대기)',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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
            },
          ),

          // 섹션 2: 오늘의 일일 미션
          StreamBuilder<List<DailyMissionModel>>(
            stream: _missionService.watchTodayMissions(widget.app.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(16.w),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Center(child: Text('오류가 발생했습니다: ${snapshot.error}')),
                );
              }

              final missions = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (missions.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                      child: Text(
                        '오늘의 일일 미션',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  if (missions.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.assignment_outlined, size: 48.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            Text(
                              '오늘 생성된 미션이 없습니다',
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
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: missions.length,
                      itemBuilder: (context, index) {
                        final mission = missions[index];
                        return _buildDailyMissionCard(mission);
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 완료미션 탭 - 승인된 미션 목록
  Widget _buildCompletedMissionsTab() {
    return StreamBuilder<List<DailyMissionModel>>(
      stream: _missionService.watchCompletedMissions(widget.app.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }

        final completedMissions = snapshot.data ?? [];

        if (completedMissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 48.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  '완료된 미션이 없습니다',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: completedMissions.length,
          itemBuilder: (context, index) {
            final mission = completedMissions[index];
            return _buildCompletedMissionCard(mission);
          },
        );
      },
    );
  }

  /// 종료 탭 - 프로젝트 완료 후 정산
  Widget _buildSettlementTab() {
    return StreamBuilder<List<MissionSettlementModel>>(
      stream: _missionService.watchSettlements(widget.app.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }

        final settlements = snapshot.data ?? [];

        if (settlements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calculate_outlined, size: 48.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  '정산 내역이 없습니다',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  '14일 프로젝트가 완료되면 정산이 생성됩니다',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: settlements.length,
          itemBuilder: (context, index) {
            final settlement = settlements[index];
            return _buildSettlementCard(settlement);
          },
        );
      },
    );
  }

  /// 테스터 신청 카드 위젯
  Widget _buildTesterApplicationCard(TesterApplicationModel application) {
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
                    application.testerName.isNotEmpty
                      ? application.testerName[0].toUpperCase()
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
                        application.testerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        application.testerEmail,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildApplicationStatusBadge(application.status),
              ],
            ),
            if (application.status == TesterApplicationStatus.pending) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reviewApplication(application.id, TesterApplicationStatus.rejected),
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
                      onPressed: () => _reviewApplication(application.id, TesterApplicationStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('승인'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 승인된 테스터 카드 위젯 (미션 시작 대기중)
  Widget _buildApprovedTesterCard(TesterApplicationModel application) {
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
                        application.testerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        application.testerEmail,
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '승인됨',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startMission(application.id),
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
        ),
      ),
    );
  }

  /// 일일 미션 카드 위젯
  Widget _buildDailyMissionCard(DailyMissionModel mission) {
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
                Expanded(
                  child: Text(
                    mission.missionTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildMissionStatusBadge(mission.status),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              mission.missionDescription,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.person, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  '테스터 ID: ${mission.testerId}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '보상: ${mission.baseReward}원',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (mission.status == DailyMissionStatus.completed) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reviewMission(mission.id, DailyMissionStatus.rejected),
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
                      onPressed: () => _reviewMission(mission.id, DailyMissionStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('승인'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 완료된 미션 카드 위젯
  Widget _buildCompletedMissionCard(DailyMissionModel mission) {
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
                Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mission.missionTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${mission.baseReward}원',
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
              '승인일: ${mission.approvedAt?.toString().substring(0, 10) ?? 'N/A'}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 정산 카드 위젯
  Widget _buildSettlementCard(MissionSettlementModel settlement) {
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
                Expanded(
                  child: Text(
                    settlement.testerName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: settlement.isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    settlement.isPaid ? '지급완료' : '지급대기',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: settlement.isPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSettlementInfo('완료율', '${(settlement.completionRate * 100).toInt()}%'),
                _buildSettlementInfo('완료 미션', '${settlement.completedMissions}/${settlement.totalDays}'),
                _buildSettlementInfo('기본 보상', '${settlement.totalBaseReward}원'),
                _buildSettlementInfo('보너스', '${settlement.bonusReward}원'),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '최종 금액: ${settlement.finalAmount}원',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (!settlement.isPaid) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _markSettlementAsPaid(settlement.id),
                  child: const Text('지급 완료 처리'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 신청 상태 배지
  Widget _buildApplicationStatusBadge(TesterApplicationStatus status) {
    Color color;
    String text;

    switch (status) {
      case TesterApplicationStatus.pending:
        color = Colors.orange;
        text = '대기중';
        break;
      case TesterApplicationStatus.approved:
        color = Colors.green;
        text = '승인됨';
        break;
      case TesterApplicationStatus.rejected:
        color = Colors.red;
        text = '거부됨';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 미션 상태 배지
  Widget _buildMissionStatusBadge(DailyMissionStatus status) {
    Color color;
    String text;

    switch (status) {
      case DailyMissionStatus.pending:
        color = Colors.grey;
        text = '대기중';
        break;
      case DailyMissionStatus.inProgress:
        color = Colors.blue;
        text = '진행중';
        break;
      case DailyMissionStatus.completed:
        color = Colors.orange;
        text = '완료요청';
        break;
      case DailyMissionStatus.approved:
        color = Colors.green;
        text = '승인됨';
        break;
      case DailyMissionStatus.rejected:
        color = Colors.red;
        text = '거부됨';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 정산 정보 위젯
  Widget _buildSettlementInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 테스터 신청 검토
  Future<void> _reviewApplication(String applicationId, TesterApplicationStatus status) async {
    try {
      await _missionService.reviewTesterApplication(
        applicationId: applicationId,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == TesterApplicationStatus.approved ? '테스터를 승인했습니다' : '테스터 신청을 거부했습니다'),
            backgroundColor: status == TesterApplicationStatus.approved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 미션 시작 (승인된 테스터)
  Future<void> _startMission(String workflowId) async {
    try {
      await _missionService.startMissionForTester(workflowId: workflowId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션이 시작되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 시작 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 미션 검토
  Future<void> _reviewMission(String missionId, DailyMissionStatus status) async {
    try {
      await _missionService.updateMissionStatus(
        missionId: missionId,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == DailyMissionStatus.approved ? '미션을 승인했습니다' : '미션을 거부했습니다'),
            backgroundColor: status == DailyMissionStatus.approved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 오늘 미션 자동 생성
  Future<void> _generateTodayMissions() async {
    try {
      await _missionService.generateDailyMissions(widget.app.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오늘 미션이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 정산 지급 완료 처리
  Future<void> _markSettlementAsPaid(String settlementId) async {
    try {
      await _missionService.markSettlementAsPaid(settlementId: settlementId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정산 지급 완료 처리되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 삭제요청 탭 - 테스터가 요청한 미션 삭제 목록
  Widget _buildDeletionRequestsTab() {
    return StreamBuilder<List<MissionDeletionModel>>(
      stream: _missionService.watchDeletionRequests(widget.app.providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.w, color: Colors.red[300]),
                SizedBox(height: 16.h),
                Text(
                  '데이터를 불러올 수 없습니다',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final deletionRequests = (snapshot.data ?? [])
            .where((deletion) => !deletion.providerAcknowledged)
            .toList();

        if (deletionRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_sweep, size: 64.w, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  '삭제 요청이 없습니다',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '테스터의 미션 삭제 요청이 표시됩니다',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: deletionRequests.length,
          itemBuilder: (context, index) {
            final deletion = deletionRequests[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더: 미션 정보
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'Day ${deletion.dayNumber}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            deletion.missionTitle,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // 앱 이름
                    Row(
                      children: [
                        Icon(Icons.apps, size: 16.sp, color: Colors.grey[600]),
                        SizedBox(width: 6.w),
                        Text(
                          deletion.appName,
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // 테스터 정보
                    Row(
                      children: [
                        Icon(Icons.person, size: 16.sp, color: Colors.grey[600]),
                        SizedBox(width: 6.w),
                        Text(
                          deletion.testerName,
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // 삭제 요청 시간
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16.sp, color: Colors.grey[600]),
                        SizedBox(width: 6.w),
                        Text(
                          _formatDateTime(deletion.deletedAt),
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // 삭제 사유
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 14.sp, color: Colors.orange[700]),
                              SizedBox(width: 4.w),
                              Text(
                                '삭제 사유',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            deletion.deletionReason,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _acknowledgeDeletion(deletion),
                        icon: Icon(Icons.check_circle, size: 18.sp),
                        label: Text('확인 및 삭제', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
          },
        );
      },
    );
  }

  /// 삭제 확인 및 영구 삭제
  Future<void> _acknowledgeDeletion(MissionDeletionModel deletion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text('삭제 확인', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 미션을 영구적으로 삭제하시겠습니까?',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Text(
              '미션: ${deletion.missionTitle}',
              style: TextStyle(fontSize: 13.sp),
            ),
            Text(
              '테스터: ${deletion.testerName}',
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16.sp, color: Colors.red),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      '이 작업은 되돌릴 수 없습니다',
                      style: TextStyle(fontSize: 12.sp, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _missionService.acknowledgeDeletion(
          deletionId: deletion.deletionId,
          workflowId: deletion.workflowId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 미션이 영구 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 삭제 처리 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 날짜 포맷팅
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}