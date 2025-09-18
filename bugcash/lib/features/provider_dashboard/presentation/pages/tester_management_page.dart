import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final testersAsync = ref.watch(appTestersProvider(widget.app.id));

    return testersAsync.when(
      data: (testers) => _buildTestersList(testers),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('테스터 목록을 불러올 수 없습니다'),
    );
  }

  Widget _buildTestersList(List<TesterApplicationModel> testers) {
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

  Widget _buildTesterCard(TesterApplicationModel tester) {
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
    final missionsAsync = ref.watch(appMissionsProvider(widget.app.id));

    return missionsAsync.when(
      data: (missions) => _buildMissionsList(missions),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('미션 목록을 불러올 수 없습니다'),
    );
  }

  Widget _buildMissionsList(List<TestMissionModel> missions) {
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

          // 미션 목록
          if (missions.isEmpty)
            _buildEmptyMissionsState()
          else
            ...missions.map((mission) => _buildMissionCard(mission)),
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
    final statisticsAsync = ref.watch(appStatisticsProvider(widget.app.id));

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