import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'test_data_page.dart';

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
        ],
      ),
      body: Row(
        children: [
          // 사이드바 네비게이션
          Container(
            width: 240.w,
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
      padding: EdgeInsets.all(24.w),
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
      padding: EdgeInsets.all(24.w),
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
                TabBar(
                  labelColor: Colors.deepPurple,
                  tabs: const [
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
      padding: EdgeInsets.all(24.w),
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
      padding: EdgeInsets.all(24.w),
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

          // 거래 내역 테이블
          _buildTransactionsTable(),
        ],
      ),
    );
  }

  // 5. Reports Tab - 신고 처리
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
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
      padding: EdgeInsets.all(24.w),
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
            color: Colors.grey.withOpacity(0.1),
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
                  color: color.withOpacity(0.1),
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
          return const Center(child: CircularProgressIndicator());
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
    final rewards = data['rewards'] as Map<String, dynamic>? ?? {};
    final baseReward = rewards['baseReward'] ?? 0;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
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
                        color: statusColor.withOpacity(0.1),
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
                      '₩${NumberFormat('#,###').format(baseReward)}',
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
                  '최대 테스터: ${maxTesters}명',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8.w,
                  children: [
                    if (status == 'pending') ...[
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
            color: Colors.grey.withOpacity(0.1),
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
                  return const Center(child: CircularProgressIndicator());
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
            color: Colors.grey.withOpacity(0.1),
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
          Text('빠른 작업 버튼들이 여기에 표시됩니다.'),
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
            color: Colors.grey.withOpacity(0.1),
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
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
                  return const Center(child: CircularProgressIndicator());
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
                      DataColumn(label: Text('가입일')),
                      DataColumn(label: Text('상태')),
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final createdAt = data['createdAt'] as Timestamp?;
                      final dateString = createdAt != null
                          ? DateFormat('yyyy-MM-dd').format(createdAt.toDate())
                          : '미상';

                      return DataRow(
                        cells: [
                          DataCell(Text(data['name'] ?? 'N/A')),
                          DataCell(Text(data['email'] ?? 'N/A')),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(data['role'] ?? 'tester'),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                _getRoleText(data['role'] ?? 'tester'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(dateString)),
                          DataCell(
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16.sp,
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
            color: Colors.grey.withOpacity(0.1),
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '거래 내역',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Text('거래 내역 테이블이 여기에 표시됩니다.'),
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
            color: Colors.grey.withOpacity(0.1),
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '신고 목록',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Text('신고 목록이 여기에 표시됩니다.'),
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
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
      case 'pending': return '승인 대기';
      case 'open': return '승인됨';
      case 'rejected': return '거부됨';
      case 'closed': return '종료됨';
      default: return '알 수 없음';
    }
  }

  void _approveProject(String projectId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'status': 'open',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'admin', // 실제로는 현재 관리자 ID
      });

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
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': 'admin',
        'rejectionReason': reason,
      });

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['appName'] ?? '프로젝트 상세'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('프로젝트 ID: $projectId'),
              SizedBox(height: 8.h),
              Text('공급자: ${data['providerId'] ?? 'N/A'}'),
              SizedBox(height: 8.h),
              Text('상태: ${_getStatusText(data['status'] ?? 'pending')}'),
              SizedBox(height: 8.h),
              Text('설명: ${data['description'] ?? 'N/A'}'),
              SizedBox(height: 8.h),
              Text('최대 테스터: ${data['maxTesters'] ?? 0}명'),
              SizedBox(height: 8.h),
              Text('기본 리워드: ₩${NumberFormat('#,###').format(data['rewards']?['baseReward'] ?? 0)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 기능 (개발 중)')),
    );
  }

  void _showProjectFilters() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('필터 기능 (개발 중)')),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildDefaultSummaryCards();
        }

        final payments = snapshot.data![0];
        final projects = snapshot.data![1];
        final users = snapshot.data![2];
        final applications = snapshot.data![3];

        // 실제 데이터 계산
        int totalCharged = 0;
        int totalPaid = 0;
        int platformRevenue = 0;
        int newUsersThisMonth = 0;

        // 결제 데이터 계산
        for (var doc in payments.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = data['amount'] ?? 0;
          final type = data['type'] ?? '';

          if (type == 'charge') {
            totalCharged += (amount as num).toInt();
          } else if (type == 'payout') {
            totalPaid += (amount as num).toInt();
          }
        }

        platformRevenue = (totalCharged * 0.1).toInt(); // 10% 수수료

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
                '${newUsersThisMonth}명',
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
}