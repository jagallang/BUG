import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/mission_discovery_widget.dart';
import '../widgets/active_missions_widget.dart';
import '../widgets/earnings_summary_widget.dart';
import '../widgets/tester_profile_widget.dart';
import '../providers/tester_dashboard_provider.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
                  Tab(text: '미션 찾기', icon: Icon(Icons.search)),
                  Tab(text: '진행 중', icon: Icon(Icons.play_circle)),
                  Tab(text: '수익', icon: Icon(Icons.account_balance_wallet)),
                  Tab(text: '프로필', icon: Icon(Icons.person)),
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
                          // 미션 찾기
                          MissionDiscoveryWidget(testerId: widget.testerId),
                          
                          // 진행 중인 미션
                          ActiveMissionsWidget(testerId: widget.testerId),
                          
                          // 수익 관리
                          EarningsSummaryWidget(testerId: widget.testerId),
                          
                          // 프로필
                          TesterProfileWidget(testerId: widget.testerId),
                        ],
                      ),
          ),
        ],
      ),
      
      // Floating Action Button for quick mission creation
      floatingActionButton: FloatingActionButton.extended(
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
                  '새 미션 찾기',
                  Icons.search,
                  Colors.blue,
                  () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(0);
                  },
                ),
                _buildQuickActionItem(
                  '진행 중 보기',
                  Icons.play_circle,
                  Colors.green,
                  () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(1);
                  },
                ),
                _buildQuickActionItem(
                  '수익 확인',
                  Icons.account_balance_wallet,
                  Colors.orange,
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