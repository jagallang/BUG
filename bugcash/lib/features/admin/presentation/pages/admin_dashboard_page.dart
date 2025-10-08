import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/loading_widgets.dart';
import '../../../../shared/widgets/responsive_wrapper.dart';
import 'test_data_page.dart';
import 'project_detail_page.dart';
import '../../../../utils/migration_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/presentation/pages/admin_withdrawal_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 관리자 권한 확인
    final authState = ref.watch(authProvider);

    // 로그인되지 않은 경우 로그인 페이지로 리디렉션
    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(
        body: const BugCashLoadingWidget(
          message: '관리자 대시보드를 불러오는 중...',
        ),
      );
    }

    // 관리자 권한이 없는 경우 접근 거부
    final user = authState.user!;
    final hasAdminRole = user.roles.contains(UserType.admin.name) || user.primaryRole == UserType.admin;

    if (!hasAdminRole) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('접근 거부'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ 관리자 권한이 필요합니다',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '현재 역할: ${user.primaryRole.toString().split('.').last}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    // 마이그레이션 실행 완료됨

    return Scaffold(
      appBar: AppBar(
        title: const Text('BUGS 관리자 대시보드'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.data_usage),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TestDataPage()),
            ),
            tooltip: '테스트 데이터 관리',
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.account_tree, color: Colors.white),
              onPressed: () => _showMigrationDialog(),
              tooltip: '🔄 사용자 데이터 마이그레이션 (필요함)',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(),
            tooltip: '알림',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Row(
        children: [
          // 사이드바 네비게이션
          Container(
            width: ResponsiveWrapper.isDesktop(context) ? 240.w : 200.w,
            color: Colors.grey[100],
            child: Column(
              children: [
                _buildNavItem(0, Icons.dashboard, 'Dashboard', '요약'),
                _buildNavItem(1, Icons.folder_open, 'Projects', '프로젝트 검수'),
                _buildNavItem(2, Icons.people, 'Users', '사용자 관리'),
                _buildNavItem(3, Icons.account_balance_wallet, 'Finance', '포인트/수익'),
                _buildNavItem(4, Icons.report_problem, 'Reports', '신고 처리'),
                _buildNavItem(5, Icons.settings, 'Settings', '플랫폼 설정'),
              ],
            ),
          ),
          // 메인 컨텐츠
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: [
                _buildDashboardTab(),
                _buildProjectsTab(),
                _buildUsersTab(),
                _buildFinanceTab(),
                _buildReportsTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title, String subtitle) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple : null,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? Colors.white70 : Colors.grey[600],
            fontSize: 12.sp,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  // 1. Dashboard Tab - 요약 통계
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard - 플랫폼 현황',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),

          // 실시간 요약 카드들
          _buildRealTimeSummaryCards(),

          SizedBox(height: 24.h),

          // 최근 활동 & 그래프 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRecentActivityPanel(),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildQuickActions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Projects Tab - 프로젝트 검수/관리
  Widget _buildProjectsTab() {
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects - 프로젝트 검수',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('새로고침'),
                  ),
                  SizedBox(width: 12.w),
                  OutlinedButton.icon(
                    onPressed: _showProjectFilters,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('필터'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 프로젝트 상태별 탭
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.deepPurple,
                  tabs: [
                    Tab(text: '승인 대기'),
                    Tab(text: '승인됨'),
                    Tab(text: '거부됨'),
                    Tab(text: '전체'),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 600.h,
                  child: TabBarView(
                    children: [
                      _buildProjectsList('pending'),
                      _buildProjectsList('open'),
                      _buildProjectsList('rejected'),
                      _buildProjectsList('all'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Users Tab - 사용자 관리
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users - 사용자 관리',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),

          // 실시간 사용자 통계
          _buildRealTimeUserStats(),

          SizedBox(height: 24.h),

          // 사용자 목록
          _buildUsersTable(),
        ],
      ),
    );
  }

  // 4. Finance Tab - 포인트/수익 관리
  Widget _buildFinanceTab() {
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finance - 포인트 & 수익 관리',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),

          // 금융 요약
          Row(
            children: [
              Expanded(child: _buildFinanceCard('이번 달 충전', '₩2,500,000', Colors.blue, Icons.add_circle)),
              SizedBox(width: 16.w),
              Expanded(child: _buildFinanceCard('이번 달 지급', '₩1,800,000', Colors.red, Icons.remove_circle)),
              SizedBox(width: 16.w),
              Expanded(child: _buildFinanceCard('수수료 수익', '₩700,000', Colors.green, Icons.monetization_on)),
            ],
          ),

          SizedBox(height: 24.h),

          // 출금 관리 바로가기 버튼
          ElevatedButton.icon(
            onPressed: _navigateToWithdrawalManagement,
            icon: const Icon(Icons.arrow_circle_up),
            label: const Text('출금 신청 관리'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            ),
          ),

          SizedBox(height: 24.h),

          // 거래 내역 테이블
          _buildTransactionsTable(),
        ],
      ),
    );
  }

  // 5. Reports Tab - 신고 처리
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports - 신고 처리',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),

          // 신고 요약
          Row(
            children: [
              Expanded(child: _buildReportStatsCard('대기중', '12건', Colors.orange)),
              SizedBox(width: 16.w),
              Expanded(child: _buildReportStatsCard('처리완료', '156건', Colors.green)),
              SizedBox(width: 16.w),
              Expanded(child: _buildReportStatsCard('이번 달', '23건', Colors.blue)),
            ],
          ),

          SizedBox(height: 24.h),

          // 신고 목록
          _buildReportsTable(),
        ],
      ),
    );
  }

  // 6. Settings Tab - 플랫폼 설정
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings - 플랫폼 설정',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),

          // 설정 카테고리들
          _buildSettingsSection('수수료 설정', [
            _buildSettingItem('플랫폼 수수료율', '18%', _editCommissionRate),
            _buildSettingItem('최소 충전 금액', '₩10,000', _editMinCharge),
            _buildSettingItem('최대 충전 금액', '₩1,000,000', _editMaxCharge),
          ]),

          SizedBox(height: 24.h),

          _buildSettingsSection('앱 카테고리 관리', [
            _buildSettingItem('카테고리 수', '32개', _manageCategories),
            _buildSettingItem('신규 카테고리 요청', '3건', _reviewCategoryRequests),
          ]),

          SizedBox(height: 24.h),

          _buildSettingsSection('시스템 설정', [
            _buildSettingItem('미션 기본 기간', '14일', _editDefaultPeriod),
            _buildSettingItem('최대 테스터 수', '50명', _editMaxTesters),
            _buildSettingItem('포인트 정산 주기', '월 2회', _editPayoutSchedule),
          ]),
        ],
      ),
    );
  }

  // 헬퍼 위젯들
  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
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
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16.sp),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: status == 'all'
          ? FirebaseFirestore.instance.collection('projects').snapshots()
          : status == 'pending'
              ? FirebaseFirestore.instance
                  .collection('projects')
                  .where('status', whereIn: ['pending', 'draft'])
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('projects')
                  .where('status', isEqualTo: status)
                  .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BugCashLoadingWidget(
            message: '데이터를 불러오는 중...',
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64.sp, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  '프로젝트가 없습니다',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildProjectCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(String projectId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final appName = data['appName'] ?? '알 수 없는 앱';
    final providerId = data['providerId'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final description = data['description'] ?? '';
    final maxTesters = data['maxTesters'] ?? 0;
    // 보상 정보 읽기 - metadata 우선, rewards 폴백
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
    final rewards = data['rewards'] as Map<String, dynamic>? ?? {};
    final dailyMissionPoints = metadata['dailyMissionPoints'] ??
                              rewards['dailyMissionPoints'] ?? 0;
    final finalCompletionPoints = metadata['finalCompletionPoints'] ??
                                 rewards['finalCompletionPoints'] ?? 0;
    final bonusPoints = metadata['bonusPoints'] ??
                       rewards['bonusPoints'] ?? 0;
    final estimatedMinutes = metadata['estimatedMinutes'] ??
                            rewards['estimatedMinutes'] ?? 60;

    // 총보상 계산 (심플화된 3단계 보상)
    final totalReward = _calculateTotalReward(
      dailyMissionPoints: dailyMissionPoints,
      finalCompletionPoints: finalCompletionPoints,
      bonusPoints: bonusPoints,
      estimatedMinutes: estimatedMinutes,
    );

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'draft':
        statusColor = Colors.blue;
        statusIcon = Icons.edit;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'open':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusIcon = Icons.archive;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '공급자: $providerId',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '등록일: ${DateFormat('yyyy.MM.dd').format(createdAt)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16.sp, color: statusColor),
                          SizedBox(width: 4.w),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '₩${NumberFormat('#,###').format(totalReward)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.people, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  '최대 테스터: $maxTesters명',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8.w,
                  children: [
                    if (status == 'pending' || status == 'draft') ...[
                      SizedBox(
                        width: 80.w,
                        height: 32.h,
                        child: ElevatedButton(
                          onPressed: () => _approveProject(projectId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('승인'),
                        ),
                      ),
                      SizedBox(
                        width: 80.w,
                        height: 32.h,
                        child: ElevatedButton(
                          onPressed: () => _rejectProject(projectId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('거부'),
                        ),
                      ),
                    ],
                    SizedBox(
                      width: 80.w,
                      height: 32.h,
                      child: ElevatedButton(
                        onPressed: () => _viewProjectDetails(projectId, data),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('상세보기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 실제 데이터와 연동된 최근 활동 패널
  Widget _buildRecentActivityPanel() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
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
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 300.h,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const BugCashLoadingWidget(
            message: '데이터를 불러오는 중...',
          );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('최근 활동이 없습니다.'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => Divider(height: 16.h),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final createdAt = data['createdAt'] as Timestamp?;
                    final timeAgo = createdAt != null
                        ? _getTimeAgo(createdAt.toDate())
                        : '방금';

                    return Row(
                      children: [
                        Icon(
                          _getStatusIcon(data['status'] ?? 'pending'),
                          size: 16.sp,
                          color: _getStatusColor(data['status'] ?? 'pending'),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['appName'] ?? '프로젝트',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getStatusText(data['status'] ?? 'pending'),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'pending':
        return Icons.schedule;
      case 'open':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'closed':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.blue[600]!;
      case 'pending':
        return Colors.orange[600]!;
      case 'open':
        return Colors.green[600]!;
      case 'rejected':
        return Colors.red[600]!;
      case 'closed':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '빠른 작업',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          const Text('빠른 작업 버튼들이 여기에 표시됩니다.'),
        ],
      ),
    );
  }

  Widget _buildUserStatsCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveWrapper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '사용자 목록',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로고침'),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const BugCashLoadingWidget(
            message: '데이터를 불러오는 중...',
          );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('등록된 사용자가 없습니다.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('이름')),
                      DataColumn(label: Text('이메일')),
                      DataColumn(label: Text('역할')),
                      DataColumn(label: Text('포인트')),
                      DataColumn(label: Text('가입일')),
                      DataColumn(label: Text('상태')),
                      DataColumn(label: Text('액션')),
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = doc.id;
                      final createdAt = data['createdAt'] as Timestamp?;
                      final dateString = createdAt != null
                          ? DateFormat('yyyy-MM-dd').format(createdAt.toDate())
                          : '미상';
                      final points = data['points'] ?? 0;
                      final isSuspended = data['isSuspended'] ?? false;

                      return DataRow(
                        cells: [
                          DataCell(Text(data['displayName'] ?? data['name'] ?? 'N/A')),
                          DataCell(Text(data['email'] ?? 'N/A')),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(data['role'] ?? data['primaryRole'] ?? 'tester'),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                _getRoleText(data['role'] ?? data['primaryRole'] ?? 'tester'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text('${NumberFormat('#,###').format(points)}P')),
                          DataCell(Text(dateString)),
                          DataCell(
                            isSuspended
                                ? Icon(Icons.block, color: Colors.red, size: 16.sp)
                                : Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 포인트 조정 버튼
                                IconButton(
                                  icon: const Icon(Icons.monetization_on, size: 18),
                                  color: Colors.blue,
                                  onPressed: () => _showAdjustPointsDialog(userId, data),
                                  tooltip: '포인트 조정',
                                ),
                                // 계정 정지/해제 버튼
                                IconButton(
                                  icon: Icon(
                                    isSuspended ? Icons.lock_open : Icons.block,
                                    size: 18,
                                  ),
                                  color: isSuspended ? Colors.green : Colors.red,
                                  onPressed: () => _showSuspendDialog(userId, data),
                                  tooltip: isSuspended ? '정지 해제' : '계정 정지',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red[600]!;
      case 'provider':
        return Colors.orange[600]!;
      case 'tester':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'provider':
        return '공급자';
      case 'tester':
        return '테스터';
      default:
        return '알 수 없음';
    }
  }

  Widget _buildFinanceCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveWrapper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '거래 내역',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            const Text('거래 내역 테이블이 여기에 표시됩니다.'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStatsCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveWrapper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '신고 목록',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            const Text('신고 목록이 여기에 표시됩니다.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveWrapper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }

  // 액션 메서드들
  String _getStatusText(String status) {
    switch (status) {
      case 'draft': return '초안';
      case 'pending': return '승인 대기';
      case 'open': return '승인됨';
      case 'rejected': return '거부됨';
      case 'closed': return '종료됨';
      default: return '알 수 없음';
    }
  }


  void _approveProject(String projectId) async {
    try {
      // Try Cloud Functions first, fallback to direct Firestore update if needed
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
        final callable = functions.httpsCallable('reviewProject');

        await callable.call({
          'projectId': projectId,
          'approve': true,
        });
      } catch (cloudError) {
        debugPrint('Cloud Functions not available, using direct Firestore update: $cloudError');
        // Fallback to direct Firestore update
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .update({
          'status': 'open',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 프로젝트가 승인되었습니다'),
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

  void _rejectProject(String projectId) async {
    // 거부 이유 입력 다이얼로그
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      // Try Cloud Functions first, fallback to direct Firestore update if needed
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
        final callable = functions.httpsCallable('reviewProject');

        await callable.call({
          'projectId': projectId,
          'approve': false,
          'rejectionReason': reason,
        });
      } catch (cloudError) {
        debugPrint('Cloud Functions not available, using direct Firestore update: $cloudError');
        // Fallback to direct Firestore update
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': 'admin',
          'rejectionReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 프로젝트가 거부되었습니다'),
            backgroundColor: Colors.red,
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

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로젝트 거부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('거부 이유를 입력해주세요:'),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '거부 이유를 입력하세요...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _viewProjectDetails(String projectId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailPage(
          projectId: projectId,
          projectData: data,
        ),
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 기능 (개발 중)')),
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  void _showProjectFilters() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('필터 기능 (개발 중)')),
    );
  }

  // Finance 액션들
  void _navigateToWithdrawalManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminWithdrawalPage(),
      ),
    );
  }

  // Settings 액션들
  void _editCommissionRate() => _showNotImplemented('수수료율 변경');
  void _editMinCharge() => _showNotImplemented('최소 충전 금액 변경');
  void _editMaxCharge() => _showNotImplemented('최대 충전 금액 변경');
  void _manageCategories() => _showNotImplemented('카테고리 관리');
  void _reviewCategoryRequests() => _showNotImplemented('카테고리 요청 검토');
  void _editDefaultPeriod() => _showNotImplemented('기본 기간 변경');
  void _editMaxTesters() => _showNotImplemented('최대 테스터 수 변경');
  void _editPayoutSchedule() => _showNotImplemented('정산 주기 변경');

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature 기능 (개발 중)')),
    );
  }

  // 실시간 Firebase 데이터와 연동된 요약 카드들
  Widget _buildRealTimeSummaryCards() {
    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('payments').get(),
        FirebaseFirestore.instance.collection('projects').get(),
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance.collection('applications').get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BugCashLoadingWidget(
            message: '데이터를 불러오는 중...',
          );
        }

        if (!snapshot.hasData) {
          return _buildDefaultSummaryCards();
        }

        final payments = snapshot.data![0];
        final projects = snapshot.data![1];
        final users = snapshot.data![2];
        final applications = snapshot.data![3];

        // 실제 데이터 계산
        int newUsersThisMonth = 0;

        // 이번 달 신규 사용자 계산
        final thisMonth = DateTime.now();
        final startOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);

        for (var doc in users.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['createdAt'];
          if (createdAt != null) {
            DateTime userCreatedAt;
            if (createdAt is Timestamp) {
              userCreatedAt = createdAt.toDate();
            } else {
              continue;
            }

            if (userCreatedAt.isAfter(startOfMonth)) {
              newUsersThisMonth++;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                '총 프로젝트',
                '${projects.docs.length}개',
                Colors.blue,
                Icons.folder_open,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildSummaryCard(
                '총 신청',
                '${applications.docs.length}건',
                Colors.green,
                Icons.assignment,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildSummaryCard(
                '활성 사용자',
                '${users.docs.length}명',
                Colors.purple,
                Icons.people,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildSummaryCard(
                '이번 달 신규',
                '$newUsersThisMonth명',
                Colors.orange,
                Icons.person_add,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('총 프로젝트', '로딩...', Colors.blue, Icons.folder_open)),
        SizedBox(width: 16.w),
        Expanded(child: _buildSummaryCard('총 신청', '로딩...', Colors.green, Icons.assignment)),
        SizedBox(width: 16.w),
        Expanded(child: _buildSummaryCard('활성 사용자', '로딩...', Colors.purple, Icons.people)),
        SizedBox(width: 16.w),
        Expanded(child: _buildSummaryCard('이번 달 신규', '로딩...', Colors.orange, Icons.person_add)),
      ],
    );
  }

  // 실시간 사용자 통계
  Widget _buildRealTimeUserStats() {
    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'tester').get(),
        FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'provider').get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(child: _buildUserStatsCard('전체 사용자', '로딩...', Colors.blue)),
              SizedBox(width: 16.w),
              Expanded(child: _buildUserStatsCard('테스터', '로딩...', Colors.green)),
              SizedBox(width: 16.w),
              Expanded(child: _buildUserStatsCard('공급자', '로딩...', Colors.orange)),
            ],
          );
        }

        if (!snapshot.hasData) {
          return Row(
            children: [
              Expanded(child: _buildUserStatsCard('전체 사용자', '0명', Colors.blue)),
              SizedBox(width: 16.w),
              Expanded(child: _buildUserStatsCard('테스터', '0명', Colors.green)),
              SizedBox(width: 16.w),
              Expanded(child: _buildUserStatsCard('공급자', '0명', Colors.orange)),
            ],
          );
        }

        final allUsers = snapshot.data![0];
        final testers = snapshot.data![1];
        final providers = snapshot.data![2];

        return Row(
          children: [
            Expanded(child: _buildUserStatsCard('전체 사용자', '${allUsers.docs.length}명', Colors.blue)),
            SizedBox(width: 16.w),
            Expanded(child: _buildUserStatsCard('테스터', '${testers.docs.length}명', Colors.green)),
            SizedBox(width: 16.w),
            Expanded(child: _buildUserStatsCard('공급자', '${providers.docs.length}명', Colors.orange)),
          ],
        );
      },
    );
  }

  // 마이그레이션 다이얼로그 표시
  void _showMigrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 데이터 마이그레이션'),
        content: const Text(
          '기존 사용자 데이터를 새로운 다중 역할 시스템으로 마이그레이션합니다.\n\n'
          '이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _analyzeUserData();
            },
            child: const Text('분석'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performMigration();
            },
            child: const Text('마이그레이션 실행'),
          ),
        ],
      ),
    );
  }

  // 사용자 데이터 구조 분석
  void _analyzeUserData() async {
    _showLoadingDialog('사용자 데이터 분석 중...');

    try {
      final analysis = await MigrationHelper.analyzeCurrentUsers();

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showAnalysisResult(analysis);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('분석 실패: $e');
      }
    }
  }

  // 실제 마이그레이션 실행
  void _performMigration() async {
    _showLoadingDialog('마이그레이션 실행 중...');

    try {
      // 1. 시뮬레이션 실행
      final simulation = await MigrationHelper.migrateUsers(dryRun: true);

      if (simulation.containsKey('error')) {
        throw Exception(simulation['error']);
      }

      // 2. 실제 마이그레이션 실행
      final result = await MigrationHelper.migrateUsers(dryRun: false);

      if (result.containsKey('error')) {
        throw Exception(result['error']);
      }

      // 3. 검증
      final isValid = await MigrationHelper.verifyMigration();

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showMigrationResult(result, isValid);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('마이그레이션 실패: $e');
      }
    }
  }

  // 분석 결과 표시
  void _showAnalysisResult(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 분석 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('총 사용자: ${analysis['totalUsers']}명'),
              Text('새 형식: ${analysis['newFormat']}명'),
              Text('기존 형식: ${analysis['oldFormat']}명'),
              const SizedBox(height: 16),
              const Text('역할별 통계:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((analysis['userTypes'] as Map<String, int>).entries.map(
                (entry) => Text('${entry.key}: ${entry.value}명'),
              )),
              if (analysis['samples'] != null) ...[
                const SizedBox(height: 16),
                const Text('샘플 데이터:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...((analysis['samples'] as List).take(3).map(
                  (sample) => Text('${sample['email']}: ${sample['userType'] ?? sample['roles']}'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 마이그레이션 결과 표시
  void _showMigrationResult(Map<String, dynamic> result, bool isValid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isValid ? '✅ 마이그레이션 완료' : '⚠️ 마이그레이션 주의',
          style: TextStyle(
            color: isValid ? Colors.green : Colors.orange,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('총 사용자: ${result['totalUsers']}명'),
            Text('마이그레이션: ${result['migrated']}명'),
            Text('건너뛴 사용자: ${result['skipped']}명'),
            if (result['errors'] != null && (result['errors'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('오류: ${(result['errors'] as List).length}건',
                   style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            Text(
              isValid
                ? '모든 사용자 데이터가 성공적으로 마이그레이션되었습니다.'
                : '일부 사용자 데이터에 문제가 있을 수 있습니다. 확인이 필요합니다.',
              style: TextStyle(
                color: isValid ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
          if (!isValid)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // 페이지 새로고침
              },
              child: const Text('새로고침'),
            ),
        ],
      ),
    );
  }

  // 로딩 다이얼로그 표시
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const BugCashLoadingWidget(
              message: '처리 중...',
              size: 24.0,
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // 총보상 계산 헬퍼 메서드 (심플화된 3단계 보상)
  int _calculateTotalReward({
    required int dailyMissionPoints,
    required int finalCompletionPoints,
    required int bonusPoints,
    required int estimatedMinutes,
  }) {
    // 심플화된 계산 로직: 진행 중 보상 + 완료 시 보상
    final estimatedDays = (estimatedMinutes / (24 * 60)).ceil().clamp(1, 30);
    final progressReward = dailyMissionPoints * estimatedDays;
    final completionReward = finalCompletionPoints + bonusPoints;

    return progressReward + completionReward;
  }

  // 오류 다이얼로그 표시
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // v2.58.0: 사용자 계정 정지/해제 다이얼로그
  void _showSuspendDialog(String userId, Map<String, dynamic> userData) {
    final isSuspended = userData['isSuspended'] ?? false;
    final displayName = userData['displayName'] ?? userData['name'] ?? 'Unknown';
    final email = userData['email'] ?? '';

    if (isSuspended) {
      // 정지 해제 확인
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('계정 정지 해제'),
          content: Text('$displayName ($email)\n\n계정 정지를 해제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _suspendUser(userId, suspend: false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('정지 해제'),
            ),
          ],
        ),
      );
    } else {
      // 정지 설정
      final reasonController = TextEditingController();
      int durationDays = 7; // 기본 7일

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('계정 정지'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$displayName ($email)\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('정지 기간:'),
                DropdownButton<int>(
                  value: durationDays,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1일')),
                    DropdownMenuItem(value: 7, child: Text('7일')),
                    DropdownMenuItem(value: 30, child: Text('30일')),
                    DropdownMenuItem(value: 0, child: Text('영구')),
                  ],
                  onChanged: (value) => setState(() => durationDays = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '정지 사유',
                    hintText: '계정 정지 사유를 입력하세요...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _suspendUser(
                    userId,
                    suspend: true,
                    reason: reasonController.text,
                    durationDays: durationDays,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('계정 정지'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // v2.58.0: 사용자 포인트 조정 다이얼로그
  void _showAdjustPointsDialog(String userId, Map<String, dynamic> userData) {
    final displayName = userData['displayName'] ?? userData['name'] ?? 'Unknown';
    final email = userData['email'] ?? '';
    final currentPoints = userData['points'] ?? 0;

    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    String adjustmentType = 'grant'; // grant, deduct, reset

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('포인트 조정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$displayName ($email)', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('현재 포인트: ${NumberFormat('#,###').format(currentPoints)}P\n'),
              const SizedBox(height: 16),
              const Text('조정 유형:'),
              DropdownButton<String>(
                value: adjustmentType,
                items: const [
                  DropdownMenuItem(value: 'grant', child: Text('💰 포인트 지급')),
                  DropdownMenuItem(value: 'deduct', child: Text('➖ 포인트 차감')),
                  DropdownMenuItem(value: 'reset', child: Text('🔄 포인트 리셋 (0으로)')),
                ],
                onChanged: (value) => setState(() => adjustmentType = value!),
              ),
              const SizedBox(height: 16),
              if (adjustmentType != 'reset')
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '포인트',
                    hintText: '금액을 입력하세요',
                    border: OutlineInputBorder(),
                    suffixText: 'P',
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '사유',
                  hintText: '조정 사유를 입력하세요...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = adjustmentType == 'reset'
                    ? 0
                    : int.tryParse(amountController.text) ?? 0;

                if (adjustmentType != 'reset' && amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('올바른 금액을 입력하세요')),
                  );
                  return;
                }

                Navigator.of(context).pop();
                _adjustUserPoints(
                  userId,
                  adjustmentType: adjustmentType,
                  amount: amount,
                  reason: reasonController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: adjustmentType == 'grant'
                    ? Colors.green
                    : adjustmentType == 'deduct'
                        ? Colors.orange
                        : Colors.grey,
              ),
              child: const Text('조정 실행'),
            ),
          ],
        ),
      ),
    );
  }

  // v2.58.0: Cloud Function - suspendUser 호출
  Future<void> _suspendUser(
    String userId, {
    required bool suspend,
    String? reason,
    int? durationDays,
  }) async {
    _showLoadingDialog('처리 중...');

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable('suspendUser');

      final result = await callable.call({
        'userId': userId,
        'suspend': suspend,
        if (reason != null) 'reason': reason,
        if (durationDays != null && durationDays > 0) 'durationDays': durationDays,
      });

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(suspend ? '✅ 계정이 정지되었습니다' : '✅ 계정 정지가 해제되었습니다'),
            backgroundColor: suspend ? Colors.red : Colors.green,
          ),
        );
        setState(() {}); // 목록 새로고침
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('계정 정지 처리 실패: $e');
      }
    }
  }

  // v2.58.0: Cloud Function - adjustUserPoints 호출
  Future<void> _adjustUserPoints(
    String userId, {
    required String adjustmentType,
    required int amount,
    String? reason,
  }) async {
    _showLoadingDialog('포인트 조정 중...');

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable('adjustUserPoints');

      final result = await callable.call({
        'userId': userId,
        'adjustmentType': adjustmentType,
        if (adjustmentType != 'reset') 'amount': amount,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 포인트가 ${adjustmentType == 'grant' ? '지급' : adjustmentType == 'deduct' ? '차감' : '리셋'}되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // 목록 새로고침
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('포인트 조정 실패: $e');
      }
    }
  }
}