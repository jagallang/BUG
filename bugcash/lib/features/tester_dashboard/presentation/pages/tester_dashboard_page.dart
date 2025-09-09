import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/earnings_summary_widget.dart';
import '../widgets/community_board_widget.dart';
import '../providers/tester_dashboard_provider.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
import 'mission_detail_page.dart';

class TesterDashboardPage extends ConsumerStatefulWidget {
  final String testerId;

  const TesterDashboardPage({
    super.key,
    required this.testerId,
  });

  @override
  ConsumerState<TesterDashboardPage> createState() => _TesterDashboardPageState();
}

class _TesterDashboardPageState extends ConsumerState<TesterDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isAppBarExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _isAppBarExpanded = !_isAppBarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(testerDashboardProvider);
    
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with Profile
          SliverAppBar(
            expandedHeight: _isAppBarExpanded ? 200.h : kToolbarHeight,
            collapsedHeight: kToolbarHeight,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            snap: false,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              tooltip: 'Provider 모드로 전환',
              onPressed: () {
                // Provider Dashboard로 이동
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const ProviderDashboardPage(
                      providerId: 'test_provider_001',
                    ),
                  ),
                );
              },
            ),
            flexibleSpace: _isAppBarExpanded ? FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Top spacing to avoid overlap with title
                        SizedBox(height: 60.h),
                        
                        // Greeting and notifications
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '안녕하세요! 👋',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  Text(
                                    '오늘도 화이팅!',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification and settings
                            IconButton(
                              onPressed: () => _showNotifications(context),
                              icon: Badge(
                                label: Text('${dashboardState.unreadNotifications}'),
                                isLabelVisible: dashboardState.unreadNotifications > 0,
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showProfileSettings(context),
                              icon: const Icon(
                                Icons.account_circle,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Quick stats
                        if (dashboardState.testerProfile != null)
                          _buildQuickStats(context, dashboardState.testerProfile!),
                      ],
                    ),
                  ),
                ),
              ),
            ) : null,
            title: GestureDetector(
              onTap: _toggleAppBar,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16.w,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18.w,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      dashboardState.testerProfile?.name ?? '테스터',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isAppBarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            actions: [
              // Hamburger menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu, color: Colors.white),
                offset: Offset(0, 50.h),
                onSelected: (String value) {
                  switch (value) {
                    case 'provider':
                      _navigateToProviderDashboard(context);
                      break;
                    case 'settings':
                      _navigateToSettings(context);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'provider',
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 12.w),
                        const Text('공급자 기능'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 12.w),
                        const Text('설정'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Tab Bar
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '미션', icon: Icon(Icons.assignment)),
                  Tab(text: '수익', icon: Icon(Icons.account_balance_wallet)),
                  Tab(text: '게시판', icon: Icon(Icons.forum)),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            pinned: true,
          ),
          
          // Tab Content
          SliverFillRemaining(
            child: dashboardState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : dashboardState.error != null
                    ? _buildErrorWidget(dashboardState.error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // 미션 (미션 찾기 + 진행 중인 미션 통합)
                          _buildMissionTab(),
                          
                          // 수익 관리
                          EarningsSummaryWidget(testerId: widget.testerId),
                          
                          // 게시판 (커뮤니티)
                          CommunityBoardWidget(testerId: widget.testerId),
                        ],
                      ),
          ),
        ],
      ),
      
      // Floating Action Button for quick mission creation
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "tester_dashboard_fab",
        onPressed: () => _showQuickActions(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('빠른 참여'),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, TesterProfile profile) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '완료 미션',
            '${profile.completedMissions}',
            Icons.check_circle,
          ),
          _buildStatDivider(),
          _buildStatItem(
            '성공률',
            '${(profile.successRate * 100).toStringAsFixed(0)}%',
            Icons.trending_up,
          ),
          _buildStatDivider(),
          _buildStatItem(
            '평균 평점',
            '${profile.averageRating.toStringAsFixed(1)}',
            Icons.star,
          ),
          _buildStatDivider(),
          _buildStatItem(
            '이번 달',
            '${profile.monthlyPoints}P',
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20.w),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1.w,
      height: 40.h,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.w,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),
          Text(
            '데이터를 불러올 수 없습니다',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '알림',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref.read(testerDashboardProvider.notifier).markAllNotificationsRead();
                        Navigator.of(context).pop();
                      },
                      child: const Text('모두 읽음'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 5, // Mock notifications
                  itemBuilder: (context, index) => _buildNotificationItem(
                    '새로운 미션이 있습니다',
                    '${['UI 테스트', '성능 테스트', '버그 찾기', '사용성 테스트', '피드백 수집'][index]} 미션에 참여해보세요!',
                    DateTime.now().subtract(Duration(hours: index)),
                    index < 2, // First 2 are unread
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message, DateTime time, bool isUnread) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: isUnread 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notification_important,
            color: isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
            size: 20.w,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 2.h),
            Text(
              _formatNotificationTime(time),
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: isUnread 
            ? Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  void _navigateToProviderDashboard(BuildContext context) {
    // Provider Dashboard로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderDashboardPage(
          providerId: widget.testerId, // 테스터 ID를 임시로 사용
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    // Settings 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정 페이지로 이동하는 기능을 구현 예정입니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showProfileSettings(BuildContext context) {
    // Navigate to profile settings page
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '빠른 액션',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionItem(
                  '미션 보기',
                  Icons.assignment,
                  Colors.blue,
                  () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(0);
                  },
                ),
                _buildQuickActionItem(
                  '수익 확인',
                  Icons.account_balance_wallet,
                  Colors.green,
                  () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(1);
                  },
                ),
                _buildQuickActionItem(
                  '게시판',
                  Icons.forum,
                  Colors.purple,
                  () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(2);
                  },
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 28.w),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Widget _buildMissionTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            height: 60.h, // 높이 줄임 (기본 72.h에서 60.h로)
            decoration: BoxDecoration(
              color: Colors.blue.shade50, // 연한 파란색 배경
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: 13.sp, // 폰트 크기 조정
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(text: '미션 찾기', icon: Icon(Icons.search, size: 18.w)),
                Tab(text: '진행 중', icon: Icon(Icons.play_circle, size: 18.w)),
                Tab(text: '완료', icon: Icon(Icons.check_circle, size: 18.w)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade50, // 본문 배경색을 연한 회색으로
              child: TabBarView(
                children: [
                  // 미션 찾기 간단 버전
                  _buildMissionDiscoveryTab(),
                  // 진행 중인 미션 간단 버전  
                  _buildActiveMissionsTab(),
                  // 완료된 미션 탭
                  _buildCompletedMissionsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDiscoveryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 미션',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildMissionCard(
            title: '인스타그램 클론 앱 테스트',
            description: 'UI/UX 테스트 및 기능 검증',
            reward: '5,000P',
            deadline: '5일 남음',
            participants: '8/15',
          ),
          SizedBox(height: 12.h),
          _buildMissionCard(
            title: '배달앱 주문 플로우 테스트',
            description: '주문부터 결제까지 전체 프로세스 테스트',
            reward: '3,000P',
            deadline: '3일 남음',
            participants: '12/20',
          ),
          SizedBox(height: 12.h),
          _buildMissionCard(
            title: '온라인 쇼핑몰 결제 테스트',
            description: '다양한 결제 수단 테스트 및 검증',
            reward: '7,000P',
            deadline: '7일 남음',
            participants: '5/10',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissionsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '진행 중인 미션',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildActiveMissionCard(
            title: '채팅앱 알림 기능 테스트',
            progress: 0.7,
            status: '테스트 진행 중',
            deadline: '2일 남음',
          ),
          SizedBox(height: 12.h),
          _buildActiveMissionCard(
            title: '게임 앱 성능 테스트',
            progress: 0.3,
            status: '준비 단계',
            deadline: '5일 남음',
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required String title,
    required String description,
    required String reward,
    required String deadline,
    required String participants,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title 미션 상세보기')),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      reward,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    deadline,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16.w),
                  Icon(Icons.people, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    participants,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMissionCard({
    required String title,
    required double progress,
    required String status,
    required String deadline,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MissionDetailPage(
                missionId: 'mission_${title.hashCode}',
                missionTitle: title,
                missionDescription: '앱 테스트를 통해 품질을 검증하고 개선점을 찾아주세요.',
                appName: title.contains('채팅') ? '채팅메신저 앱' : '모바일 게임 앱',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    deadline,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedMissionsTab() {
    final completedMissions = _getCompletedMissions();
    
    if (completedMissions.isEmpty) {
      return _buildEmptyCompletedMissions();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: completedMissions.length,
      itemBuilder: (context, index) {
        final mission = completedMissions[index];
        return _buildCompletedMissionCard(mission);
      },
    );
  }

  Widget _buildEmptyCompletedMissions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            '완료된 미션이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '미션을 완료하고 포인트를 획득하세요!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedMissionCard(CompletedMission mission) {
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getSettlementStatusColor(mission.settlementStatus),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _getSettlementStatusText(mission.settlementStatus),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  mission.completedDate,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              mission.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              mission.description,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 16.w,
                  color: Colors.amber,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${mission.points}P',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(
                  Icons.star,
                  size: 16.w,
                  color: Colors.orange,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${mission.rating}/5.0',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (mission.settlementStatus == SettlementStatus.pending)
                  ElevatedButton(
                    onPressed: () => _showSettlementInfo(mission),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(80.w, 32.h),
                    ),
                    child: Text(
                      '정산 대기',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<CompletedMission> _getCompletedMissions() {
    return [
      CompletedMission(
        id: 'completed_1',
        title: '쇼핑몰 앱 버그 테스트',
        description: '결제 시스템 및 상품 검색 기능 테스트 완료',
        points: 8000,
        rating: 4.8,
        completedDate: '2024-01-15',
        settlementStatus: SettlementStatus.settled,
      ),
      CompletedMission(
        id: 'completed_2', 
        title: '금융 앱 보안 테스트',
        description: '로그인 및 본인인증 프로세스 테스트 완료',
        points: 12000,
        rating: 4.9,
        completedDate: '2024-01-10',
        settlementStatus: SettlementStatus.processing,
      ),
      CompletedMission(
        id: 'completed_3',
        title: 'SNS 앱 UI/UX 테스트',
        description: '게시글 작성 및 댓글 기능 사용성 테스트 완료',
        points: 6000,
        rating: 4.5,
        completedDate: '2024-01-08',
        settlementStatus: SettlementStatus.pending,
      ),
    ];
  }

  Color _getSettlementStatusColor(SettlementStatus status) {
    switch (status) {
      case SettlementStatus.pending:
        return Colors.orange;
      case SettlementStatus.processing:
        return Colors.blue;
      case SettlementStatus.settled:
        return Colors.green;
    }
  }

  String _getSettlementStatusText(SettlementStatus status) {
    switch (status) {
      case SettlementStatus.pending:
        return '정산 대기';
      case SettlementStatus.processing:
        return '정산 처리중';
      case SettlementStatus.settled:
        return '정산 완료';
    }
  }

  void _showSettlementInfo(CompletedMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '정산 정보',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('미션: ${mission.title}'),
            SizedBox(height: 8.h),
            Text('획득 포인트: ${mission.points}P'),
            SizedBox(height: 8.h),
            Text('평가 점수: ${mission.rating}/5.0'),
            SizedBox(height: 8.h),
            Text('완료일: ${mission.completedDate}'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 16.w),
                      SizedBox(width: 8.w),
                      Text(
                        '정산 대기 중',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '공급자가 포인트 정산을 완료하면 자동으로 사라집니다.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

enum SettlementStatus {
  pending,    // 정산 대기
  processing, // 정산 처리중  
  settled,    // 정산 완료
}

class CompletedMission {
  final String id;
  final String title;
  final String description;
  final int points;
  final double rating;
  final String completedDate;
  final SettlementStatus settlementStatus;

  CompletedMission({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.rating,
    required this.completedDate,
    required this.settlementStatus,
  });
}

// Custom SliverPersistentHeaderDelegate for TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}