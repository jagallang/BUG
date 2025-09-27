import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mission_management_service.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../features/shared/models/mission_management_model.dart';
import '../../../provider_dashboard/presentation/pages/app_management_page.dart';

/// 새로운 미션관리 페이지
/// 4개 탭: 앱테스터 → 오늘미션 → 완료미션 → 정산
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
    _tabController = TabController(length: 4, vsync: this);

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
            Tab(text: '앱테스터'),
            Tab(text: '오늘미션'),
            Tab(text: '완료미션'),
            Tab(text: '정산'),
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
        ],
      ),
    );
  }

  /// 앱테스터 탭 - 테스터 모집 및 관리
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

  /// 오늘미션 탭 - 오늘의 미션 관리
  Widget _buildTodayMissionsTab() {
    return StreamBuilder<List<DailyMissionModel>>(
      stream: _missionService.watchTodayMissions(widget.app.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }

        final missions = snapshot.data ?? [];

        if (missions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 48.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  '오늘 생성된 미션이 없습니다',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _generateTodayMissions,
                  child: const Text('오늘 미션 생성'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: missions.length,
          itemBuilder: (context, index) {
            final mission = missions[index];
            return _buildDailyMissionCard(mission);
          },
        );
      },
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

  /// 정산 탭 - 14일 완료 후 정산
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
}