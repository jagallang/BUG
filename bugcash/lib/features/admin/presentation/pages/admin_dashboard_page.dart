import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/loading_widgets.dart';
import '../../../../core/constants/app_colors.dart'; // v2.89.0: 관리자 색상 사용
import 'test_data_page.dart';
import 'project_detail_page.dart';
import '../../../../utils/migration_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/presentation/pages/admin_withdrawal_page.dart';
import 'platform_settings_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // v2.68.0: Finance 탭 - 거래 내역 필터 상태
  int _transactionsTabIndex = 0;
  String _transactionsFilterType = 'all';
  String _transactionsFilterStatus = 'all'; // all, pending, completed, failed

  // v2.70.0: 빠른 날짜 필터
  String _quickDateFilter = 'thisMonth'; // today, thisWeek, thisMonth, lastMonth, last3Months, all
  DateTime _transactionsStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1); // 이번 달 1일
  DateTime _transactionsEndDate = DateTime.now();

  // v2.89.0: 프로젝트 검수 필터 상태
  String _projectKeyword = ''; // 키워드 검색
  String _projectProviderEmail = ''; // 공급자 이메일 검색
  DateTime? _projectStartDate; // 시작일
  DateTime? _projectEndDate; // 종료일
  bool _showProjectFilters = false; // 필터 섹션 표시 여부

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
    final hasAdminRole = user.roles.contains(UserType.admin) || user.primaryRole == UserType.admin;

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
            width: 240, // 고정 사이드바 너비
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
          // 메인 컨텐츠 - 전체 화면 활용
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
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple : null,
        borderRadius: BorderRadius.circular(8),
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
            fontSize: 12,
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
      padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard - 플랫폼 현황',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),

          // 실시간 요약 카드들
          _buildRealTimeSummaryCards(),

          SizedBox(height: 24),

          // 최근 활동 & 그래프 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRecentActivityPanel(),
              ),
              SizedBox(width: 16),
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
      padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects - 프로젝트 검수',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // v2.89.0: 향상된 필터 UI
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showProjectFilters = !_showProjectFilters),
                    icon: Icon(_showProjectFilters ? Icons.filter_list_off : Icons.filter_list),
                    label: Text(_showProjectFilters ? '필터 숨기기' : '필터 표시'),
                  ),
                  SizedBox(width: 12),
                  if (_hasActiveProjectFilters()) ...[
                    OutlinedButton.icon(
                      onPressed: _resetProjectFilters,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('초기화'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('새로고침'),
                  ),
                ],
              ),
              // v2.89.0: 필터 섹션 (접기/펼치기)
              if (_showProjectFilters) ...[
                SizedBox(height: 16),
                _buildProjectFilterSection(),
              ],
            ],
          ),
          SizedBox(height: 24),

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
                SizedBox(height: 16),
                SizedBox(
                  height: 600,
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

  // v2.89.0: 프로젝트 필터 섹션
  Widget _buildProjectFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 키워드 검색
          TextField(
            decoration: InputDecoration(
              labelText: '키워드 검색',
              hintText: '앱 이름, 프로젝트 제목, 설명으로 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _projectKeyword = value),
          ),
          const SizedBox(height: 12),

          // 공급자 이메일 검색
          TextField(
            decoration: InputDecoration(
              labelText: '공급자 이메일 검색',
              hintText: '공급자 이메일 주소',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _projectProviderEmail = value),
          ),
          const SizedBox(height: 12),

          // 날짜 범위 선택
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectProjectStartDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _projectStartDate == null
                        ? '시작일 선택'
                        : '${_projectStartDate!.year}-${_projectStartDate!.month.toString().padLeft(2, '0')}-${_projectStartDate!.day.toString().padLeft(2, '0')}',
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectProjectEndDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _projectEndDate == null
                        ? '종료일 선택'
                        : '${_projectEndDate!.year}-${_projectEndDate!.month.toString().padLeft(2, '0')}-${_projectEndDate!.day.toString().padLeft(2, '0')}',
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // v2.89.0: 활성 필터 확인
  bool _hasActiveProjectFilters() {
    return _projectKeyword.isNotEmpty ||
        _projectProviderEmail.isNotEmpty ||
        _projectStartDate != null ||
        _projectEndDate != null;
  }

  // v2.89.0: 필터 초기화
  void _resetProjectFilters() {
    setState(() {
      _projectKeyword = '';
      _projectProviderEmail = '';
      _projectStartDate = null;
      _projectEndDate = null;
    });
  }

  // v2.89.0: 시작일 선택
  Future<void> _selectProjectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _projectStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.adminPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _projectStartDate) {
      setState(() => _projectStartDate = picked);
    }
  }

  // v2.89.0: 종료일 선택
  Future<void> _selectProjectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _projectEndDate ?? DateTime.now(),
      firstDate: _projectStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.adminPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _projectEndDate) {
      setState(() => _projectEndDate = picked);
    }
  }

  // v2.90.0: 액션 버튼 헬퍼 위젯
  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 80,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11), // v2.90.1: 텍스트 크기 60% 축소
        ),
      ),
    );
  }

  // v2.90.0: 프로젝트 게시 (status → 'open')
  Future<void> _publishProject(String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로젝트 게시'),
        content: const Text('이 프로젝트를 게시하시겠습니까?\n테스터들이 미션을 볼 수 있게 됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('게시'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .update({'status': 'open'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 프로젝트가 게시되었습니다'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 게시 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // v2.90.0: 프로젝트 숨김 (status → 'closed')
  Future<void> _hideProject(String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로젝트 숨김'),
        content: const Text('이 프로젝트를 숨기시겠습니까?\n테스터들이 더 이상 볼 수 없게 됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('숨김'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .update({'status': 'closed'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 프로젝트가 숨겨졌습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 숨김 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // v2.90.0: 프로젝트 삭제
  Future<void> _deleteProject(String projectId, String appName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로젝트 삭제'),
        content: Text(
          '정말로 "$appName" 프로젝트를 삭제하시겠습니까?\n\n'
          '⚠️ 이 작업은 되돌릴 수 없습니다!\n'
          '- 프로젝트 데이터 영구 삭제\n'
          '- 관련 미션 데이터 삭제\n'
          '- 테스터 진행 기록 삭제',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showLoadingDialog('프로젝트 삭제 중...');

      try {
        // Firestore 프로젝트 문서 삭제
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .delete();

        // TODO: 관련 서브컬렉션 삭제 (missions, tester progress 등)
        // 필요시 Cloud Function으로 처리

        if (mounted) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 프로젝트가 삭제되었습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 3. Users Tab - 사용자 관리
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users - 사용자 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),

          // 실시간 사용자 통계
          _buildRealTimeUserStats(),

          SizedBox(height: 24),

          // 사용자 목록
          _buildUsersTable(),
        ],
      ),
    );
  }

  // 4. Finance Tab - 포인트/수익 관리 (v2.68.0: 서브탭 추가)
  Widget _buildFinanceTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance - 포인트 & 수익 관리',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),

                // v2.69.0: 금융 요약 (실시간 데이터)
                _buildFinanceSummaryCards(),

                SizedBox(height: 24),

                // 출금 관리 바로가기 버튼
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToWithdrawalManagement,
                    icon: const Icon(Icons.arrow_circle_up),
                    label: const Text('출금 신청 관리'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // 서브탭 (전체/충전/지급)
                TabBar(
                  onTap: (index) {
                    setState(() {
                      _transactionsTabIndex = index;
                      // 탭에 따라 필터 타입 자동 설정
                      if (index == 0) {
                        _transactionsFilterType = 'all';
                      } else if (index == 1) {
                        _transactionsFilterType = 'charge';
                      } else {
                        _transactionsFilterType = 'earn'; // 지급 탭은 earn, withdraw 포함
                      }
                    });
                  },
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: '전체 내역'),
                    Tab(text: '충전 내역'),
                    Tab(text: '지급 내역'),
                  ],
                ),
              ],
            ),
          ),

          // 서브탭 콘텐츠
          Expanded(
            child: TabBarView(
              children: [
                _buildTransactionContent('all'),
                _buildTransactionContent('charge'),
                _buildTransactionContent('disbursement'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // v2.68.0: 거래 내역 콘텐츠 (탭별)
  Widget _buildTransactionContent(String tabType) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 필터 UI
          _buildTransactionFilters(tabType),
          SizedBox(height: 16),
          // 거래 내역 테이블
          _buildTransactionsTable(tabType),
        ],
      ),
    );
  }

  // v2.68.0: 거래 내역 필터 UI
  Widget _buildTransactionFilters(String tabType) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            '필터',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          // v2.70.0: 빠른 날짜 필터 버튼
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip('오늘', 'today'),
              _buildQuickFilterChip('이번 주', 'thisWeek'),
              _buildQuickFilterChip('이번 달', 'thisMonth'),
              _buildQuickFilterChip('지난 달', 'lastMonth'),
              _buildQuickFilterChip('최근 3개월', 'last3Months'),
              _buildQuickFilterChip('전체', 'all'),
            ],
          ),
          SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 상태 드롭다운 - 크기 축소
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  value: _transactionsFilterStatus,
                  decoration: InputDecoration(
                    labelText: '상태',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('전체')),
                    DropdownMenuItem(value: 'pending', child: Text('대기중')),
                    DropdownMenuItem(value: 'completed', child: Text('완료')),
                    DropdownMenuItem(value: 'failed', child: Text('실패')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _transactionsFilterStatus = value;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: 12),
              // 날짜 범위 - 더 컴팩트하게
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _transactionsStartDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _transactionsStartDate = picked;
                      _quickDateFilter = ''; // 커스텀 날짜 선택 시 빠른 필터 해제
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text(
                        '${_transactionsStartDate.year}-${_transactionsStartDate.month.toString().padLeft(2, '0')}-${_transactionsStartDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('~', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _transactionsEndDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _transactionsEndDate = picked;
                      _quickDateFilter = ''; // 커스텀 날짜 선택 시 빠른 필터 해제
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text(
                        '${_transactionsEndDate.year}-${_transactionsEndDate.month.toString().padLeft(2, '0')}-${_transactionsEndDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              // 필터 초기화 버튼 - 아이콘만
              IconButton(
                onPressed: () {
                  setState(() {
                    _transactionsFilterStatus = 'all';
                    _quickDateFilter = 'thisMonth';
                    _applyQuickDateFilter('thisMonth');
                  });
                },
                icon: const Icon(Icons.refresh),
                tooltip: '초기화',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Reports Tab - 신고 처리
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports - 신고 처리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),

          // 신고 요약
          Row(
            children: [
              Expanded(child: _buildReportStatsCard('대기중', '12건', Colors.orange)),
              SizedBox(width: 16),
              Expanded(child: _buildReportStatsCard('처리완료', '156건', Colors.green)),
              SizedBox(width: 16),
              Expanded(child: _buildReportStatsCard('이번 달', '23건', Colors.blue)),
            ],
          ),

          SizedBox(height: 24),

          // 신고 목록
          _buildReportsTable(),
        ],
      ),
    );
  }

  // 6. Settings Tab - 플랫폼 설정
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings - 플랫폼 설정',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),

          // 플랫폼 설정 관리 버튼
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune, color: Colors.white, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '플랫폼 설정 관리',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '보상, 출금, 수수료, 어뷰징 방지 등 모든 설정을 관리합니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlatformSettingsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('설정 열기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // 설정 카테고리들
          _buildSettingsSection('수수료 설정', [
            _buildSettingItem('플랫폼 수수료율', '18%', _editCommissionRate),
            _buildSettingItem('최소 충전 금액', '₩10,000', _editMinCharge),
            _buildSettingItem('최대 충전 금액', '₩1,000,000', _editMaxCharge),
          ]),

          SizedBox(height: 24),

          _buildSettingsSection('앱 카테고리 관리', [
            _buildSettingItem('카테고리 수', '32개', _manageCategories),
            _buildSettingItem('신규 카테고리 요청', '3건', _reviewCategoryRequests),
          ]),

          SizedBox(height: 24),

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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
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
                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  '프로젝트가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // v2.89.0: 클라이언트 사이드 필터링
        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // 키워드 검색 (appName, title, description)
          if (_projectKeyword.isNotEmpty) {
            final keyword = _projectKeyword.toLowerCase();
            final appName = (data['appName'] ?? '').toString().toLowerCase();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();

            if (!appName.contains(keyword) &&
                !title.contains(keyword) &&
                !description.contains(keyword)) {
              return false;
            }
          }

          // 공급자 이메일 검색
          if (_projectProviderEmail.isNotEmpty) {
            final providerId = data['providerId'] ?? '';
            // providerId로 사용자 이메일 조회가 필요하므로,
            // 여기서는 providerId 자체로 검색 (이메일은 별도 StreamBuilder로 조회 필요)
            // 간단한 구현을 위해 providerId로 검색
            if (!providerId.toLowerCase().contains(_projectProviderEmail.toLowerCase())) {
              return false;
            }
          }

          // 날짜 범위 검색
          if (_projectStartDate != null || _projectEndDate != null) {
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt == null) return false;

            if (_projectStartDate != null && createdAt.isBefore(_projectStartDate!)) {
              return false;
            }
            if (_projectEndDate != null && createdAt.isAfter(_projectEndDate!.add(Duration(days: 1)))) {
              return false;
            }
          }

          return true;
        }).toList();

        // v2.89.0: 필터링 결과 없음
        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  '검색 결과가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '필터 조건을 변경해보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildProjectCard(doc.id, data, currentTab: status);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(
    String projectId,
    Map<String, dynamic> data, {
    required String currentTab, // v2.90.0: 현재 탭 정보
  }) {
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
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '공급자: $providerId',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '등록일: ${DateFormat('yyyy.MM.dd').format(createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          SizedBox(width: 4),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '₩${NumberFormat('#,###').format(totalReward)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '최대 테스터: $maxTesters명',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // v2.90.0: 전체 탭에서는 모든 관리 액션 표시
                    if (currentTab == 'all') ...[
                      // 승인/거절 버튼 (pending, draft 상태만)
                      if (status == 'pending' || status == 'draft') ...[
                        _buildActionButton(
                          label: '승인',
                          color: Colors.green,
                          onPressed: () => _approveProject(projectId),
                        ),
                        _buildActionButton(
                          label: '거절',
                          color: Colors.red,
                          onPressed: () => _rejectProject(projectId),
                        ),
                      ],
                      // 게시 버튼 (approved 상태만)
                      if (status == 'approved') ...[
                        _buildActionButton(
                          label: '게시',
                          color: Colors.blue,
                          onPressed: () => _publishProject(projectId),
                        ),
                      ],
                      // 숨김 버튼 (open 상태만)
                      if (status == 'open') ...[
                        _buildActionButton(
                          label: '숨김',
                          color: Colors.orange,
                          onPressed: () => _hideProject(projectId),
                        ),
                      ],
                      // 삭제 버튼 (모든 상태)
                      _buildActionButton(
                        label: '삭제',
                        color: Colors.red[700]!,
                        onPressed: () => _deleteProject(projectId, appName),
                      ),
                    ] else ...[
                      // 다른 탭에서는 기존 로직 유지
                      if (status == 'pending' || status == 'draft') ...[
                        _buildActionButton(
                          label: '승인',
                          color: Colors.green,
                          onPressed: () => _approveProject(projectId),
                        ),
                        _buildActionButton(
                          label: '거절',
                          color: Colors.red,
                          onPressed: () => _rejectProject(projectId),
                        ),
                      ],
                    ],
                    // 상세보기 버튼 (모든 탭)
                    SizedBox(
                      width: 80,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _viewProjectDetails(projectId, data),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          '상세보기',
                          style: TextStyle(fontSize: 11), // v2.90.1: 텍스트 크기 60% 축소
                        ),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 300,
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
                  separatorBuilder: (context, index) => Divider(height: 16),
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
                          size: 16,
                          color: _getStatusColor(data['status'] ?? 'pending'),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['appName'] ?? '프로젝트',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getStatusText(data['status'] ?? 'pending'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          const Text('빠른 작업 버튼들이 여기에 표시됩니다.'),
        ],
      ),
    );
  }

  Widget _buildUserStatsCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
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
        borderRadius: BorderRadius.circular(12),
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
        padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '사용자 목록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로고침'),
                ),
              ],
            ),
            SizedBox(height: 16),
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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(data['role'] ?? data['primaryRole'] ?? 'tester'),
                                borderRadius: BorderRadius.circular(12),
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
                                ? Icon(Icons.block, color: Colors.red, size: 16)
                                : Icon(Icons.check_circle, color: Colors.green, size: 16),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icon, size: 32, color: color),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // v2.68.0: 거래 내역 테이블 (Firestore 실시간 연동)
  Widget _buildTransactionsTable(String tabType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTransactionsStream(tabType),
      builder: (context, snapshot) {
        // 로딩 상태
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: const CircularProgressIndicator(),
            ),
          );
        }

        // 에러 상태
        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  '데이터를 불러오는 중 오류가 발생했습니다',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // 데이터가 없는 경우
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  '거래 내역이 없습니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // 클라이언트 측 필터링
        final filteredDocs = _applyTransactionFilters(snapshot.data!.docs, tabType);

        if (filteredDocs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  '필터 조건에 맞는 거래 내역이 없습니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // 거래 내역 테이블
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
              columns: [
                DataColumn(label: Text('날짜/시간', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('사용자', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('유형', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('금액', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('설명', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('상세', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final type = data['type'] ?? '';
                final amount = data['amount'] as int? ?? 0;
                final status = data['status'] ?? '';
                final description = data['description'] ?? '';
                final userId = data['userId'] ?? '';

                return DataRow(
                  cells: [
                    DataCell(Text(
                      createdAt != null
                          ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                          : '-',
                    )),
                    DataCell(Text(userId.length > 20 ? '${userId.substring(0, 20)}...' : userId)),
                    DataCell(Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTransactionTypeColor(type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTransactionTypeText(type),
                        style: TextStyle(
                          color: _getTransactionTypeColor(type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
                    DataCell(Text(
                      '${_getSignForType(type)}₩${NumberFormat('#,###').format(amount)}',
                      style: TextStyle(
                        color: _getSignForType(type) == '+' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    DataCell(Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTransactionStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTransactionStatusText(status),
                        style: TextStyle(
                          color: _getTransactionStatusColor(status),
                        ),
                      ),
                    )),
                    DataCell(SizedBox(
                      width: 200,
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.info_outline, size: 20),
                        onPressed: () => _showTransactionDetailDialog(doc.id, data),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // v2.68.0: Firestore 거래 내역 스트림
  Stream<QuerySnapshot> _getTransactionsStream(String tabType) {
    Query query = FirebaseFirestore.instance.collection('transactions');

    // 기본 정렬만 적용 (클라이언트 측 필터링 사용)
    return query.orderBy('createdAt', descending: true).limit(100).snapshots();
  }

  // v2.68.0: 클라이언트 측 필터링
  List<QueryDocumentSnapshot> _applyTransactionFilters(List<QueryDocumentSnapshot> docs, String tabType) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] ?? '';
      final status = data['status'] ?? '';
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      // 날짜 필터링
      if (createdAt != null) {
        if (createdAt.isBefore(_transactionsStartDate) || createdAt.isAfter(_transactionsEndDate.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // 탭별 필터
      if (tabType == 'charge') {
        if (type != 'charge') return false;
      } else if (tabType == 'disbursement') {
        if (type != 'earn' && type != 'withdraw') return false;
      }

      // 상태 필터
      if (_transactionsFilterStatus != 'all' && status != _transactionsFilterStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  // v2.68.0: 거래 유형별 색상
  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'charge':
        return Colors.blue;
      case 'earn':
        return Colors.green;
      case 'withdraw':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // v2.68.0: 거래 유형별 텍스트
  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'charge':
        return '충전';
      case 'earn':
        return '적립';
      case 'withdraw':
        return '출금';
      default:
        return type;
    }
  }

  // v2.68.0: 거래 유형별 부호
  String _getSignForType(String type) {
    if (type == 'charge' || type == 'earn') {
      return '+';
    }
    return '-';
  }

  // v2.68.0: 거래 상태별 색상
  Color _getTransactionStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // v2.68.0: 거래 상태별 텍스트
  String _getTransactionStatusText(String status) {
    switch (status) {
      case 'completed':
        return '완료';
      case 'pending':
        return '대기중';
      case 'failed':
        return '실패';
      default:
        return status;
    }
  }

  // v2.68.0: 거래 상세 정보 다이얼로그
  void _showTransactionDetailDialog(String transactionId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거래 상세 정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('거래 ID', transactionId),
              _buildDetailRow('사용자 ID', data['userId'] ?? '-'),
              _buildDetailRow('유형', _getTransactionTypeText(data['type'] ?? '')),
              _buildDetailRow('금액', '₩${NumberFormat('#,###').format(data['amount'] ?? 0)}'),
              _buildDetailRow('상태', _getTransactionStatusText(data['status'] ?? '')),
              _buildDetailRow('설명', data['description'] ?? '-'),
              _buildDetailRow('생성일', (data['createdAt'] as Timestamp?)?.toDate().toString() ?? '-'),
              if (data['metadata'] != null) ...[
                const Divider(),
                Text('메타데이터', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                Text(data['metadata'].toString()),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatsCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // v2.69.0: Finance 요약 카드 (실시간 데이터)
  Widget _buildFinanceSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTransactionsStream('all'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 로딩 중 스켈레톤 UI
          return Row(
            children: [
              Expanded(child: _buildSkeletonCard()),
              SizedBox(width: 16),
              Expanded(child: _buildSkeletonCard()),
              SizedBox(width: 16),
              Expanded(child: _buildSkeletonCard()),
            ],
          );
        }

        if (snapshot.hasError) {
          // 에러 발생 시 기본값
          return Row(
            children: [
              Expanded(child: _buildFinanceCard('이번 달 충전', '₩-', Colors.blue, Icons.add_circle)),
              SizedBox(width: 16),
              Expanded(child: _buildFinanceCard('이번 달 지급', '₩-', Colors.red, Icons.remove_circle)),
              SizedBox(width: 16),
              Expanded(child: _buildFinanceCard('수수료 수익', '₩-', Colors.green, Icons.monetization_on)),
            ],
          );
        }

        // 이번 달 집계
        final stats = _calculateMonthlyStats(snapshot.data?.docs ?? []);

        return Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                '이번 달 충전',
                '₩${NumberFormat('#,###').format(stats['charge'] ?? 0)}',
                Colors.blue,
                Icons.add_circle,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildFinanceCard(
                '이번 달 지급',
                '₩${NumberFormat('#,###').format(stats['disbursement'] ?? 0)}',
                Colors.red,
                Icons.remove_circle,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildFinanceCard(
                '수수료 수익',
                '₩${NumberFormat('#,###').format(stats['fee'] ?? 0)}',
                Colors.green,
                Icons.monetization_on,
              ),
            ),
          ],
        );
      },
    );
  }

  // v2.69.0: 이번 달 통계 집계
  Map<String, int> _calculateMonthlyStats(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));

    int chargeTotal = 0;
    int disbursementTotal = 0;
    int feeTotal = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] ?? '';
      final status = data['status'] ?? '';
      final amount = (data['amount'] ?? 0) as int;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      // 완료된 거래만 집계
      if (status != 'completed') continue;

      // 이번 달 거래만 집계
      if (createdAt == null || createdAt.isBefore(monthStart) || createdAt.isAfter(monthEnd)) {
        continue;
      }

      // 타입별 집계
      if (type == 'charge') {
        chargeTotal += amount;
      } else if (type == 'earn' || type == 'withdraw') {
        disbursementTotal += amount;
        // 수수료는 지급액의 10% (또는 별도 fee 필드 사용)
        final fee = (data['fee'] ?? (amount * 0.1).round()) as int;
        feeTotal += fee;
      }
    }

    return {
      'charge': chargeTotal,
      'disbursement': disbursementTotal,
      'fee': feeTotal,
    };
  }

  // v2.69.0: 로딩 중 스켈레톤 카드
  Widget _buildSkeletonCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // v2.70.0: 빠른 필터 칩 위젯
  Widget _buildQuickFilterChip(String label, String value) {
    final isSelected = _quickDateFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _quickDateFilter = value;
          _applyQuickDateFilter(value);
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        fontSize: 14,
        color: isSelected ? Colors.blue[900] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // v2.70.0: 빠른 필터 날짜 범위 적용
  void _applyQuickDateFilter(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'today':
        _transactionsStartDate = DateTime(now.year, now.month, now.day);
        _transactionsEndDate = now;
        break;
      case 'thisWeek':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        _transactionsStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        _transactionsEndDate = now;
        break;
      case 'thisMonth':
        _transactionsStartDate = DateTime(now.year, now.month, 1);
        _transactionsEndDate = now;
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _transactionsStartDate = lastMonth;
        _transactionsEndDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        break;
      case 'last3Months':
        _transactionsStartDate = DateTime(now.year, now.month - 3, 1);
        _transactionsEndDate = now;
        break;
      case 'all':
        _transactionsStartDate = DateTime(2020, 1, 1);
        _transactionsEndDate = now.add(const Duration(days: 1));
        break;
    }
  }

  Widget _buildReportsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '신고 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(12),
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
        padding: EdgeInsets.all(24), // 관리자 대시보드 전용 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
              fontSize: 14,
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
            SizedBox(height: 16),
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
            SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                '총 신청',
                '${applications.docs.length}건',
                Colors.green,
                Icons.assignment,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                '활성 사용자',
                '${users.docs.length}명',
                Colors.purple,
                Icons.people,
              ),
            ),
            SizedBox(width: 16),
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
        SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('총 신청', '로딩...', Colors.green, Icons.assignment)),
        SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('활성 사용자', '로딩...', Colors.purple, Icons.people)),
        SizedBox(width: 16),
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
              SizedBox(width: 16),
              Expanded(child: _buildUserStatsCard('테스터', '로딩...', Colors.green)),
              SizedBox(width: 16),
              Expanded(child: _buildUserStatsCard('공급자', '로딩...', Colors.orange)),
            ],
          );
        }

        if (!snapshot.hasData) {
          return Row(
            children: [
              Expanded(child: _buildUserStatsCard('전체 사용자', '0명', Colors.blue)),
              SizedBox(width: 16),
              Expanded(child: _buildUserStatsCard('테스터', '0명', Colors.green)),
              SizedBox(width: 16),
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
            SizedBox(width: 16),
            Expanded(child: _buildUserStatsCard('테스터', '${testers.docs.length}명', Colors.green)),
            SizedBox(width: 16),
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