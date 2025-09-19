import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../shared/providers/unified_mission_provider.dart';
import '../../../shared/models/unified_mission_model.dart';
import '../providers/tester_management_provider.dart';
import 'app_management_page.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    AppLogger.info('Tester Management Page initialized for app: ${widget.app.appName}', 'TesterManagement');

    // 🚀 CRITICAL DEBUG: Page initialization
    debugPrint('🚀 TESTER_MANAGEMENT_PAGE_DEBUG:');
    debugPrint('🚀 initState() called for app: ${widget.app.appName}');
    debugPrint('🚀 App ID: ${widget.app.id}');
    debugPrint('🚀 Provider ID: ${widget.app.providerId}');

    // Tab controller listener for tracking tab changes
    _tabController.addListener(() {
      debugPrint('🚀 TAB_CHANGE_DEBUG:');
      debugPrint('🚀 Tab changed to index: ${_tabController.index}');
      if (_tabController.index == 1) {
        debugPrint('🚀 미션관리 탭이 선택됨 - Providers가 실행되어야 함');
      }
    });
  }

  // appId prefix 정리 헬퍼 함수
  String _getCleanAppId() {
    final appId = widget.app.id;
    final cleanAppId = appId.startsWith('provider_app_')
        ? appId.replaceFirst('provider_app_', '')
        : appId;

    // 디버그 로그 추가
    debugPrint('🟠 PROVIDER_DEBUG:');
    debugPrint('🟠 Original widget.app.id: $appId');
    debugPrint('🟠 Clean appId for query: $cleanAppId');

    return cleanAppId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 CRITICAL DEBUG: Build method
    debugPrint('🚀 TESTER_MANAGEMENT_BUILD_DEBUG:');
    debugPrint('🚀 build() called for app: ${widget.app.appName}');
    debugPrint('🚀 Current tab index: ${_tabController.index}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.app.appName} 관리',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '테스터 관리'),
            Tab(text: '미션 관리'),
            Tab(text: '통계'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTesterManagementTab(),
          _buildMissionManagementTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  // 테스터 관리 탭
  Widget _buildTesterManagementTab() {
    final cleanAppId = _getCleanAppId();
    final testersAsync = ref.watch(appTestersStreamProvider(cleanAppId));

    return testersAsync.when(
      data: (testers) => _buildTestersList(testers),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('테스터 목록을 불러올 수 없습니다'),
    );
  }

  Widget _buildTestersList(List<UnifiedMissionModel> testers) {
    final pendingTesters = testers.where((t) => t.status == 'pending').toList();
    final approvedTesters = testers.where((t) => t.status == 'approved').toList();
    final rejectedTesters = testers.where((t) => t.status == 'rejected').toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('신청', pendingTesters.length, Colors.orange),
                _buildStatCard('승인', approvedTesters.length, Colors.green),
                _buildStatCard('거부', rejectedTesters.length, Colors.red),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // 신청 대기 중인 테스터
          if (pendingTesters.isNotEmpty) ...[
            Text(
              '신청 대기 중인 테스터',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            ...pendingTesters.map((tester) => _buildTesterCard(tester)),
            SizedBox(height: 24.h),
          ],

          // 승인된 테스터
          if (approvedTesters.isNotEmpty) ...[
            Text(
              '승인된 테스터',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            ...approvedTesters.map((tester) => _buildTesterCard(tester)),
            SizedBox(height: 24.h),
          ],

          // 거부된 테스터 (접힌 상태로)
          if (rejectedTesters.isNotEmpty)
            ExpansionTile(
              title: Text(
                '거부된 테스터 (${rejectedTesters.length}명)',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: rejectedTesters.map((tester) => _buildTesterCard(tester)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTesterBasedMissionCard(List<UnifiedMissionModel> pendingTesters, List<UnifiedMissionModel> approvedTesters) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${widget.app.appName} 테스터 미션',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '자동 생성',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '이 앱에 신청한 테스터들의 미션 상태입니다. 테스터를 승인하여 테스트를 시작하세요.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16.h),

          // 미션 상태 통계
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMissionStatItem('신청 대기', pendingTesters.length, Colors.orange),
                _buildMissionStatItem('진행 중', approvedTesters.length, Colors.green),
                _buildMissionStatItem('완료', 0, Colors.blue),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 액션 버튼들
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // 테스터 관리 탭으로 이동
                    DefaultTabController.of(context)?.animateTo(0);
                  },
                  icon: Icon(Icons.people_outline, size: 16.sp),
                  label: const Text('테스터 관리'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: approvedTesters.isNotEmpty
                    ? () => _sendDailyMissionToApprovedTesters(approvedTesters)
                    : null,
                  icon: Icon(Icons.send, size: 16.sp),
                  label: const Text('일일 미션 전송'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18.sp,
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

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTesterCard(UnifiedMissionModel tester) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tester.testerName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      tester.testerEmail,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(tester.status),
            ],
          ),

          if (tester.experience.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              '경험: ${tester.experience}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ],

          if (tester.motivation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              '지원 동기: ${tester.motivation}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ],

          SizedBox(height: 8.h),
          Text(
            '신청일: ${_formatDate(tester.appliedAt)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),

          // 액션 버튼 (신청 대기 상태일 때만)
          if (tester.status == 'pending') ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleTesterApplication(tester.id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('거부'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleTesterApplication(tester.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('승인'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'approved':
        color = Colors.green;
        text = '승인';
        break;
      case 'rejected':
        color = Colors.red;
        text = '거부';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = '대기';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // 미션 관리 탭
  Widget _buildMissionManagementTab() {
    // 🚀 CRITICAL DEBUG: Mission Management Tab
    debugPrint('🚀 MISSION_MANAGEMENT_TAB_DEBUG:');
    debugPrint('🚀 _buildMissionManagementTab() called');

    final cleanAppId = _getCleanAppId();
    debugPrint('🚀 Clean App ID for queries: $cleanAppId');

    // 🚀 Provider 호출 시작 (통합 Provider 사용 - 단순화)
    debugPrint('🚀 Calling ref.watch(appTestersStreamProvider($cleanAppId))');
    final testersAsync = ref.watch(appTestersStreamProvider(cleanAppId));

    return testersAsync.when(
      data: (testers) {
        debugPrint('🚀 TESTERS_DATA_DEBUG:');
        debugPrint('🚀 testersAsync.data received: ${testers.length} testers found');
        for (var tester in testers) {
          debugPrint('🚀 Tester: ${tester.testerName}, appId: ${tester.appId}, status: ${tester.status}');
        }

        debugPrint('🚀 Building missions list with ${testers.length} testers');
        return _buildMissionsList([], testers);
      },
      loading: () {
        debugPrint('🚀 TESTERS_LOADING_DEBUG: testersAsync is loading');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        debugPrint('🚀 TESTERS_ERROR_DEBUG: $error');
        return _buildErrorWidget('데이터를 불러올 수 없습니다');
      },
    );
  }

  Widget _buildMissionsList(List<TestMissionModel> missions, List<UnifiedMissionModel> testers) {
    // 승인된 테스터들의 미션 신청을 기반으로 가상 미션 목록 생성
    final approvedTesters = testers.where((t) => t.status == 'approved').toList();
    final pendingTesters = testers.where((t) => t.status == 'pending').toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 미션 생성 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateMissionDialog,
              icon: const Icon(Icons.add),
              label: const Text('새 미션 생성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // 테스터 신청 기반 미션 상태
          if (pendingTesters.isNotEmpty || approvedTesters.isNotEmpty) ...[
            Text(
              '테스터 신청 기반 미션',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            _buildTesterBasedMissionCard(pendingTesters, approvedTesters),
            SizedBox(height: 24.h),
          ],

          // 정식 미션 목록
          if (missions.isNotEmpty) ...[
            Text(
              '생성된 미션',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            ...missions.map((mission) => _buildMissionCard(mission)),
          ] else if (pendingTesters.isEmpty && approvedTesters.isEmpty)
            _buildEmptyMissionsState(),
        ],
      ),
    );
  }

  Widget _buildEmptyMissionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            '등록된 미션이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '새 미션을 생성하여 테스터들에게 과제를 할당하세요',
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

  Widget _buildMissionCard(TestMissionModel mission) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildMissionStatusBadge(mission.status),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            mission.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey[600]),
              SizedBox(width: 4.w),
              Text(
                '기한: ${_formatDate(mission.dueDate)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 16.w),
              Icon(Icons.people, size: 14.sp, color: Colors.grey[600]),
              SizedBox(width: 4.w),
              Text(
                '참여: ${mission.completedCount}/${mission.assignedCount}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewMissionDetails(mission),
                  child: const Text('상세보기'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: mission.status == 'active'
                    ? () => _pauseMission(mission.id)
                    : () => _activateMission(mission.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mission.status == 'active'
                      ? Colors.orange
                      : AppColors.primary,
                  ),
                  child: Text(mission.status == 'active' ? '일시정지' : '활성화'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'active':
        color = Colors.green;
        text = '진행중';
        break;
      case 'paused':
        color = Colors.orange;
        text = '일시정지';
        break;
      case 'completed':
        color = Colors.blue;
        text = '완료';
        break;
      default:
        color = Colors.grey;
        text = '대기';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // 통계 탭
  Widget _buildStatisticsTab() {
    final cleanAppId = _getCleanAppId();
    final statisticsAsync = ref.watch(appStatisticsProvider(cleanAppId));

    return statisticsAsync.when(
      data: (stats) => _buildStatistics(stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('통계를 불러올 수 없습니다'),
    );
  }

  Widget _buildStatistics(AppStatisticsModel stats) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 통계 카드
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전체 통계',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _buildStatItem('총 테스터', stats.totalTesters.toString())),
                    Expanded(child: _buildStatItem('활성 테스터', stats.activeTesters.toString())),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _buildStatItem('총 미션', stats.totalMissions.toString())),
                    Expanded(child: _buildStatItem('완료 미션', stats.completedMissions.toString())),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _buildStatItem('발견 버그', stats.bugsFound.toString())),
                    Expanded(child: _buildStatItem('해결 버그', stats.bugsResolved.toString())),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // 최근 활동
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 활동',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                if (stats.recentActivities.isEmpty)
                  Center(
                    child: Text(
                      '최근 활동이 없습니다',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  ...stats.recentActivities.map((activity) => _buildActivityItem(activity)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              activity['description'] ?? '',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            _formatDate(activity['timestamp']),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Action methods
  Future<void> _handleTesterApplication(String applicationId, String action) async {
    try {
      await ref.read(testerManagementProvider.notifier)
          .updateTesterApplication(applicationId, action);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approved' ? '테스터를 승인했습니다' : '테스터를 거부했습니다'),
            backgroundColor: action == 'approved' ? Colors.green : Colors.red,
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

  void _showCreateMissionDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateMissionDialog(appId: widget.app.id),
    );
  }

  void _viewMissionDetails(TestMissionModel mission) {
    // 미션 상세보기 구현
    showDialog(
      context: context,
      builder: (context) => MissionDetailsDialog(mission: mission),
    );
  }

  Future<void> _pauseMission(String missionId) async {
    await ref.read(testerManagementProvider.notifier)
        .updateMissionStatus(missionId, 'paused');
  }

  Future<void> _activateMission(String missionId) async {
    await ref.read(testerManagementProvider.notifier)
        .updateMissionStatus(missionId, 'active');
  }

  Future<void> _sendDailyMissionToApprovedTesters(List<UnifiedMissionModel> approvedTesters) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('일일 미션 전송'),
          content: Text('승인된 테스터 ${approvedTesters.length}명에게 일일 미션을 전송하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('전송'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // 일일 미션 생성 및 전송
        final dailyMissionTitle = '${widget.app.appName} 일일 테스트 (${DateTime.now().month}/${DateTime.now().day})';
        const dailyMissionDescription = '''
앱을 사용하면서 다음 사항들을 확인해주세요:
• 앱의 주요 기능들이 정상적으로 작동하는지 확인
• 사용자 인터페이스에 문제가 없는지 확인
• 앱 사용 중 발생하는 버그나 오류 신고
• 사용성 개선 사항 제안

테스트 완료 후 리포트를 작성해주세요.
        ''';

        await ref.read(testerManagementProvider.notifier).createMission(
          appId: widget.app.id,
          title: dailyMissionTitle,
          description: dailyMissionDescription,
          dueDate: DateTime.now().add(const Duration(days: 1)),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${approvedTesters.length}명의 테스터에게 일일 미션을 전송했습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 전송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// 미션 생성 다이얼로그
class CreateMissionDialog extends ConsumerStatefulWidget {
  final String appId;

  const CreateMissionDialog({super.key, required this.appId});

  @override
  ConsumerState<CreateMissionDialog> createState() => _CreateMissionDialogState();
}

class _CreateMissionDialogState extends ConsumerState<CreateMissionDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 미션 생성'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '미션 제목',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '미션 설명',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              title: const Text('마감일'),
              subtitle: Text(_formatDate(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _createMission,
          child: const Text('생성'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _createMission() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 설명을 입력해주세요')),
      );
      return;
    }

    try {
      await ref.read(testerManagementProvider.notifier).createMission(
        appId: widget.appId,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// 미션 상세보기 다이얼로그
class MissionDetailsDialog extends StatelessWidget {
  final TestMissionModel mission;

  const MissionDetailsDialog({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(mission.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('설명: ${mission.description}'),
            SizedBox(height: 8.h),
            Text('마감일: ${_formatDate(mission.dueDate)}'),
            SizedBox(height: 8.h),
            Text('상태: ${mission.status}'),
            SizedBox(height: 8.h),
            Text('참여자: ${mission.assignedCount}명'),
            SizedBox(height: 8.h),
            Text('완료자: ${mission.completedCount}명'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}