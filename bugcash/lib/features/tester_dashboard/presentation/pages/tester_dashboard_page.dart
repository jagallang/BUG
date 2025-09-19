import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../widgets/earnings_summary_widget.dart';
// import '../widgets/community_board_widget.dart';
// import '../widgets/expandable_mission_card.dart';
// import '../widgets/active_test_session_card.dart';
import '../providers/tester_dashboard_provider.dart';
import '../../../../models/test_session_model.dart';
import '../../../../services/test_session_service.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
// 채팅 기능 제거됨
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_wrapper.dart';
import '../../../settings/presentation/pages/settings_page.dart';
// import 'mission_detail_page.dart';

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
    
    // TabController 초기화 완료
    
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

  void _showProviderApplicationDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.orange),
            SizedBox(width: 12),
            Text('공급자 모드 신청'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공급자 모드로 전환하여 앱 테스팅 미션을 생성하고 관리할 수 있습니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '신분 확인을 위해 비밀번호를 입력해주세요:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '비밀번호 입력',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // 비밀번호 확인 후 공급자 모드로 전환
              _verifyPasswordAndSwitchToProvider(passwordController.text);
              passwordController.dispose();
              Navigator.pop(context);
            },
            child: const Text('신청'),
          ),
        ],
      ),
    );
  }

  void _verifyPasswordAndSwitchToProvider(String password) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 비밀번호를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 현재 사용자 정보 가져오기
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      // 비밀번호 검증을 위해 재인증 시도
      final credential = EmailAuthProvider.credential(
        email: currentUser.email,
        password: password,
      );

      // 비밀번호 검증
      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);

      // mounted 체크 후 네비게이션
      if (!mounted) return;

      // 공급자 대시보드로 전환 (실제 사용자 ID 사용)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProviderDashboardPage(
            providerId: currentUser.uid,
          ),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 공급자 모드로 전환되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = '❌ 인증에 실패했습니다';

      if (e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) {
        errorMessage = '❌ 비밀번호가 올바르지 않습니다';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = '❌ 너무 많은 시도로 인해 일시적으로 차단되었습니다';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = '❌ 네트워크 연결을 확인해주세요';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    debugPrint('🟡 _showLogoutConfirmation 호출됨');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('로그아웃'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정말로 로그아웃 하시겠습니까?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '다시 로그인하려면 이메일과 비밀번호를 입력해야 합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🟡 로그아웃 취소 버튼 클릭');
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('🟡 로그아웃 확인 버튼 클릭');
              Navigator.pop(context);
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    debugPrint('🔴 _performLogout 시작');
    try {
      // 로그아웃 중 로딩 표시
      debugPrint('🔴 로그아웃 스낵바 표시');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('로그아웃 중...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      // Firebase Auth 직접 로그아웃
      debugPrint('🔴 Firebase Auth 직접 signOut 호출');
      await FirebaseAuth.instance.signOut();
      debugPrint('🔴 Firebase Auth 직접 signOut 완료');

      // AuthProvider 상태 초기화
      debugPrint('🔴 AuthProvider 상태 초기화');
      ref.invalidate(authProvider);

      // 즉시 로그인 페이지로 이동 - Navigator 스택 모두 제거
      if (mounted && context.mounted) {
        debugPrint('🔴 Navigator를 통한 강제 이동');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
            settings: const RouteSettings(name: '/'),
          ),
          (route) => false,
        );
        debugPrint('🔴 Navigator 이동 완료');
      }

    } catch (e) {
      debugPrint('🔴 로그아웃 오류: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  debugPrint('🔵 PopupMenu 선택됨: $value');
                  switch (value) {
                    case 'provider':
                      debugPrint('🔵 공급자 신청 메뉴 선택');
                      _showProviderApplicationDialog(context);
                      break;
                    case 'settings':
                      debugPrint('🔵 설정 메뉴 선택');
                      _navigateToSettings(context);
                      break;
                    case 'logout':
                      debugPrint('🔵 로그아웃 메뉴 선택 - _showLogoutConfirmation 호출');
                      _showLogoutConfirmation(context);
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
                        const Text('공급자 신청'),
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
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red[600]),
                        SizedBox(width: 12.w),
                        const Text('로그아웃', style: TextStyle(color: Colors.red)),
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
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                children: [
                                  Text('수익 요약', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8.h),
                                  Text('테스터 ID: ${widget.testerId}'),
                                ],
                              ),
                            ),
                          ),
                          
                          // 게시판 (커뮤니티)
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                children: [
                                  Text('커뮤니티 게시판', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8.h),
                                  Text('테스터 커뮤니티 준비 중'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      
      // Floating Action Button for chat
      floatingActionButton: _buildChatFAB(),
      floatingActionButtonLocation: _CustomFabLocation(), // 모든 탭에서 동일한 중간 위치로 고정
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
            profile.averageRating.toStringAsFixed(1),
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
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('알림이 없습니다', style: TextStyle(color: Colors.grey)),
                    ],
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
        color: isUnread ? Colors.green.shade50 : Colors.transparent,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _showProfileSettings(BuildContext context) {
    // Navigate to profile settings page
  }

  // Chat FAB with unread message badge
  Widget _buildChatFAB() {
    final dashboardState = ref.watch(testerDashboardProvider);
    final int unreadCount = dashboardState.unreadNotifications;
    
    return Stack(
      children: [
        FloatingActionButton(
          heroTag: "tester_dashboard_chat_fab",
          onPressed: () {
            Navigator.push(
              context,
              // 채팅 기능 제거됨
              MaterialPageRoute(builder: (context) => Container()),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.chat),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: BoxConstraints(
                minWidth: 20.w,
                minHeight: 20.w,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
      length: 4,
      child: Column(
        children: [
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
                  // 신청 현황 탭
                  _buildApplicationStatusTab(),
                ],
              ),
            ),
          ),
          Container(
            height: 60.h + MediaQuery.of(context).padding.bottom, // 시스템 내비게이션 바 높이 추가
            decoration: BoxDecoration(
              color: Colors.green.shade50, // 연한 녹색 배경
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom), // 하단 세이프 에리어 패딩
              child: TabBar(
                labelColor: Colors.green.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.green.shade700,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontSize: 11.sp, // 폰트 크기 약간 줄임 (4개 탭을 위해)
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  Tab(text: '미션 찾기', icon: Icon(Icons.search, size: 16.w)),
                  Tab(text: '진행 중', icon: Icon(Icons.play_circle, size: 16.w)),
                  Tab(text: '완료', icon: Icon(Icons.check_circle, size: 16.w)),
                  Tab(text: '신청 현황', icon: Icon(Icons.pending_actions, size: 16.w)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDiscoveryTab() {
    final dashboardState = ref.watch(testerDashboardProvider);
    
    if (dashboardState.availableMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              '사용 가능한 미션이 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '새로운 미션이 등록되면 알려드릴게요!',
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
      itemCount: dashboardState.availableMissions.length,
      itemBuilder: (context, index) {
        final mission = dashboardState.availableMissions[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Card(
            child: ListTile(
              title: Text('미션: ${mission.id}'),
              subtitle: Text('테스터 ID: ${widget.testerId}'),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveMissionsTab() {
    // 실제 테스트 세션 데이터를 사용
    final testSessionsAsync = ref.watch(testerTestSessionsProvider(widget.testerId));

    return testSessionsAsync.when(
      data: (testSessions) {
        // 활성 상태(승인됨, 진행중)인 세션만 필터링
        final activeSessions = testSessions.where((session) =>
          session.status == TestSessionStatus.approved ||
          session.status == TestSessionStatus.active
        ).toList();

        if (activeSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 64.w, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  '진행 중인 미션이 없습니다',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '미션을 신청하고 승인을 기다리세요!',
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
          itemCount: activeSessions.length,
          itemBuilder: (context, index) {
            final session = activeSessions[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Card(
                child: ListTile(
                  title: Text('활성 세션: ${session.id}'),
                  subtitle: Text('진행 중'),
                  trailing: const Icon(Icons.play_arrow),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
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
              error.toString(),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                  Flexible(
                    child: Text(
                      deadline,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(Icons.people, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      participants,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
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
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(title)),
                body: const Center(
                  child: Text('미션 상세 페이지 준비 중'),
                ),
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
    final dashboardState = ref.watch(testerDashboardProvider);
    
    if (dashboardState.completedMissions.isEmpty) {
      return _buildEmptyCompletedMissions();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: dashboardState.completedMissions.length,
      itemBuilder: (context, index) {
        final mission = dashboardState.completedMissions[index];
        // Convert MissionCard to CompletedMission for display
        final completedMission = CompletedMission(
          id: mission.id,
          title: mission.title,
          description: mission.description,
          points: mission.rewardPoints,
          rating: 4.5, // Default rating
          completedDate: DateTime.now().toString().substring(0, 10),
          settlementStatus: SettlementStatus.settled,
        );
        return _buildCompletedMissionCard(completedMission);
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
                      backgroundColor: Colors.green,
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

  // Removed hardcoded dummy data - using real data from provider

  Color _getSettlementStatusColor(SettlementStatus status) {
    switch (status) {
      case SettlementStatus.pending:
        return Colors.orange;
      case SettlementStatus.processing:
        return Colors.green;
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  Widget _buildApplicationStatusTab() {
    // 실제 테스트 세션 데이터에서 pending, rejected 상태만 필터링
    final testSessionsAsync = ref.watch(testerTestSessionsProvider(widget.testerId));

    return testSessionsAsync.when(
      data: (testSessions) {
        final pendingSessions = testSessions.where((session) =>
          session.status == TestSessionStatus.pending ||
          session.status == TestSessionStatus.rejected
        ).toList();

        if (pendingSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pending_actions_outlined,
                  size: 64.w,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  '신청한 미션이 없습니다',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '관심있는 미션에 신청해보세요!',
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
          itemCount: pendingSessions.length,
          itemBuilder: (context, index) {
            final session = pendingSessions[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildTestSessionStatusCard(session),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.w, color: Colors.red[300]),
            SizedBox(height: 16.h),
            Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSessionStatusCard(TestSession session) {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.schedule;
    String statusText = '대기 중';

    switch (session.status) {
      case TestSessionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = '승인 대기';
        break;
      case TestSessionStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '승인됨';
        break;
      case TestSessionStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = '거부됨';
        break;
      case TestSessionStatus.active:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        statusText = '진행 중';
        break;
      default:
        break;
    }

    return Card(
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14.w, color: statusColor),
                      SizedBox(width: 4.w),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(session.createdAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              '미션: ${session.appId}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '미션 ID: ${session.missionId}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.star, size: 16.w, color: Colors.orange),
                SizedBox(width: 4.w),
                Text(
                  '${session.totalRewardPoints} 포인트',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (session.status == TestSessionStatus.rejected) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16.w, color: Colors.red),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '거부 사유를 확인하고 다시 신청해보세요.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationStatusCard(MissionApplicationStatus application) {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.schedule;
    String statusText = '대기 중';

    switch (application.status) {
      case ApplicationStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = '검토 대기';
        break;
      case ApplicationStatus.reviewing:
        statusColor = Colors.blue;
        statusIcon = Icons.visibility;
        statusText = '검토 중';
        break;
      case ApplicationStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '승인됨';
        break;
      case ApplicationStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = '거절됨';
        break;
      case ApplicationStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusText = '취소됨';
        break;
    }

    return Card(
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16.w),
                      SizedBox(width: 4.w),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimeAgo(application.appliedAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Mission ID: ${application.missionId}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            if (application.message.isNotEmpty)
              Container(
                width: double.infinity,
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
                      '신청 메시지:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      application.message,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            if (application.responseMessage != null && application.responseMessage!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공급자 응답:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      application.responseMessage!,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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

// Custom FAB Location to avoid overlap with bottom tabs
class _CustomFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 기본 endFloat 위치를 기준으로 Y 좌표만 조정
    final double x = scaffoldGeometry.scaffoldSize.width - 
                     scaffoldGeometry.floatingActionButtonSize.width - 16.0;
    final double y = scaffoldGeometry.scaffoldSize.height - 
                     scaffoldGeometry.floatingActionButtonSize.height - 
                     120.0; // 하단 탭바와 기본 위치의 중간 지점으로 고정
    
    return Offset(x, y);
  }
}