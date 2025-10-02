import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/widgets/loading_widgets.dart';
import '../../../../shared/widgets/responsive_wrapper.dart';
import '../../../../shared/extensions/responsive_extensions.dart';
import '../../../../core/constants/app_colors.dart';
// import '../widgets/earnings_summary_widget.dart';
// import '../widgets/community_board_widget.dart';
// import '../widgets/expandable_mission_card.dart';
// import '../widgets/active_test_session_card.dart';
import '../providers/tester_dashboard_provider.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
// 채팅 기능 제거됨
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_wrapper.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'mission_detail_page.dart';
import 'daily_mission_submission_page.dart';
import 'mission_tracking_page.dart';
import '../../../../core/services/mission_management_service.dart';
import '../../../shared/widgets/daily_mission_card.dart';
import '../../../shared/models/mission_management_model.dart';
import '../../../../core/services/screenshot_service.dart';
import '../widgets/mission_timer_floating_button.dart';

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
  int? _navigateToMissionSubTab; // 미션 서브탭 네비게이션 신호

  // [MVP] 타이머 UI 제거 - 백그라운드에서만 작동
  // bool _showStartOverlay = false;
  // DateTime? _missionStartTime;
  // String? _currentMissionWorkflowId;

  // 스크린샷 서비스
  final ScreenshotService _screenshotService = ScreenshotService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 미션, 게시판
    _scrollController = ScrollController();

    // TabController 초기화 완료

    // 초기 데이터 로드 및 타이머 상태 복원
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);
      _restoreTimerState();
    });
  }

  /// 브라우저 재시작 시 타이머 상태 복원
  Future<void> _restoreTimerState() async {
    try {
      // 진행 중인 미션 찾기
      final snapshot = await FirebaseFirestore.instance
          .collection('mission_workflows')
          .where('testerId', isEqualTo: widget.testerId)
          .where('currentState', whereIn: ['in_progress', 'testing_completed'])
          .where('startedAt', isNull: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      // 가장 최근 시작된 미션 찾기
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aStarted = (a.data()['startedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bStarted = (b.data()['startedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bStarted.compareTo(aStarted); // 최신순
        });

      final latestDoc = docs.first;
      final data = latestDoc.data();
      final startedAt = (data['startedAt'] as Timestamp?)?.toDate();
      final completedAt = data['completedAt'] as Timestamp?;
      final currentState = data['currentState'] as String?;

      if (startedAt == null) return;

      // 이미 완료된 미션은 복원하지 않음
      if (completedAt != null) return;

      // 경과 시간 계산
      final elapsed = DateTime.now().difference(startedAt);

      // 10분 이상 경과했는지 확인
      if (elapsed >= const Duration(minutes: 10)) {
        // [MVP] 자동 완료 처리 - 백그라운드에서만
        await FirebaseFirestore.instance
            .collection('mission_workflows')
            .doc(latestDoc.id)
            .update({
          'completedAt': FieldValue.serverTimestamp(),
          'currentState': 'testing_completed',
        });

        if (mounted) {
          // UI 새로고침
          ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 10분 테스트가 완료되었습니다! 완료 버튼을 눌러 결과를 제출해주세요.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
      // [MVP] else 블록 제거 - 타이머 UI 복원 불필요
    } catch (e) {
      debugPrint('❌ 타이머 상태 복원 실패: $e');
    }
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

    return Stack(
      children: [
        Scaffold(
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
                        padding: ResponsiveWrapper.getResponsivePadding(context),
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
                    ? const BugCashLoadingWidget(
                        message: '미션 데이터를 불러오는 중...',
                      )
                    : dashboardState.error != null
                        ? _buildErrorWidget(dashboardState.error!)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              // 미션 (미션 찾기 + 진행 중인 미션 통합)
                              _buildMissionTab(),

                              // 게시판 (커뮤니티)
                              Card(
                                child: Padding(
                                  padding: ResponsiveWrapper.getResponsivePadding(context),
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
        ),

        // [MVP] 타이머 UI 제거 - 백그라운드에서만 작동
        // // 미션 시작 전체 화면 오버레이
        // if (_showStartOverlay)
        //   MissionStartTimerOverlay(
        //     displayDuration: const Duration(seconds: 3),
        //     onComplete: () {
        //       setState(() {
        //         _showStartOverlay = false;
        //       });
        //     },
        //   ),

        // // 미션 타이머 플로팅 버튼
        // if (_missionStartTime != null && !_showStartOverlay)
        //   MissionTimerFloatingButton(
        //     startedAt: _missionStartTime!,
        //     onScreenshot: () async {
        //       await _screenshotService.showScreenshotGuide(context);
        //     },
        //     onComplete: () async {
        //       if (_currentMissionWorkflowId != null) {
        //         try {
        //           await FirebaseFirestore.instance
        //               .collection('mission_workflows')
        //               .doc(_currentMissionWorkflowId)
        //               .update({
        //             'completedAt': FieldValue.serverTimestamp(),
        //             'currentState': 'testing_completed',
        //           });

        //           setState(() {
        //             _missionStartTime = null;
        //             _currentMissionWorkflowId = null;
        //           });

        //           if (mounted) {
        //             ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);
        //             ScaffoldMessenger.of(context).showSnackBar(
        //               const SnackBar(
        //                 content: Text('✅ 테스트가 완료되었습니다! 완료 버튼을 눌러 결과를 제출해주세요.'),
        //                 backgroundColor: Colors.green,
        //                 duration: Duration(seconds: 4),
        //               ),
        //             );
        //           }
        //         } catch (e) {
        //           if (mounted) {
        //             ScaffoldMessenger.of(context).showSnackBar(
        //               SnackBar(
        //                 content: Text('❌ 완료 처리 중 오류가 발생했습니다: $e'),
        //                 backgroundColor: Colors.red,
        //                 duration: Duration(seconds: 3),
        //               ),
        //             );
        //           }
        //         }
        //       }
        //     },
        //   ),
      ],
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
                padding: ResponsiveWrapper.getResponsivePadding(context),
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


  Widget _buildMissionTab() {
    return DefaultTabController(
      length: 4,
      animationDuration: const Duration(milliseconds: 350), // 부드러운 애니메이션
      initialIndex: _navigateToMissionSubTab ?? 0, // 탭 전환 신호가 있으면 해당 탭으로 시작
      child: Builder(
        builder: (context) {
          // 탭 전환 신호 처리 (개선된 애니메이션)
          if (_navigateToMissionSubTab != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                DefaultTabController.of(context).animateTo(
                  _navigateToMissionSubTab!,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                );
                setState(() {
                  _navigateToMissionSubTab = null; // 신호 초기화
                });
              }
            });
          }

          return Column(
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
                  // 정산 탭
                  _buildSettlementTab(),
                ],
              ),
            ),
          ),
          Container(
            height: 60.h + MediaQuery.of(context).padding.bottom, // 시스템 내비게이션 바 높이 추가
            decoration: BoxDecoration(
              color: Colors.white, // 배경 중립화
              border: Border(
                top: BorderSide(
                  color: AppColors.neutral200,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom), // 하단 세이프 에리어 패딩
              child: TabBar(
                labelColor: AppColors.neutral800,
                unselectedLabelColor: AppColors.neutral500,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 8.w),
                splashFactory: InkRipple.splashFactory,
                overlayColor: WidgetStateProperty.all(AppColors.neutral100),
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
                  Tab(text: '정산', icon: Icon(Icons.monetization_on, size: 16.w)),
                ],
              ),
            ),
          ),
            ],
          );
        },
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
      padding: ResponsiveWrapper.getResponsivePadding(context),
      itemCount: dashboardState.availableMissions.length,
      itemBuilder: (context, index) {
        final mission = dashboardState.availableMissions[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildMissionCard(
            mission: mission,
            title: mission.title.isNotEmpty ? mission.title : '미션 ${mission.id}',
            description: mission.description.isNotEmpty ? mission.description : '새로운 테스트 미션에 참여해보세요!',
            reward: '${mission.rewardPoints}P',
            deadline: '바로 진행',
            participants: '대기 중',
          ),
        );
      },
    );
  }

  Widget _buildActiveMissionsTab() {
    // 기존 MissionManagementService를 사용해서 실제 데이터 로드
    final missionService = MissionManagementService();

    return StreamBuilder<List<DailyMissionModel>>(
      stream: missionService.watchTesterTodayMissions(widget.testerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BugCashLoadingWidget(
            message: '미션 목록을 불러오는 중...',
          );
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
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    // 새로고침을 위해 setState 호출
                    setState(() {});
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // 삭제 요청된 미션 필터링 (deleted_by_tester 상태 제외)
        final dailyMissions = (snapshot.data ?? [])
            .where((mission) => mission.currentState != 'deleted_by_tester')
            .toList();

        if (dailyMissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 64.w, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  '진행 중인 일일 미션이 없습니다',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '미션을 신청하고 일일 미션을 시작하세요!',
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
          padding: ResponsiveWrapper.getResponsivePadding(context),
          itemCount: dailyMissions.length,
          itemBuilder: (context, index) {
            final mission = dailyMissions[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: DailyMissionCard(
                mission: mission,
                onTap: () {
                  // 미션 진행 상황 페이지로 이동
                  if (mission.workflowId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MissionTrackingPage(
                          workflowId: mission.workflowId!,
                        ),
                      ),
                    );
                  } else {
                    _showMissionDetail(mission);
                  }
                },
                // 삭제 버튼 (승인 완료 전까지 모든 상태에서 가능)
                onDelete: mission.status != DailyMissionStatus.approved
                    ? () => _deleteMissionEnhanced(mission)
                    : null,
                // 시작 버튼 (application_approved + startedAt 없음)
                onStart: mission.currentState == 'application_approved' && mission.startedAt == null
                    ? () => _startMission(mission)
                    : null,
                // 완료 버튼 (타이머 완료 후: completedAt 있음 + status != completed/approved)
                onComplete: mission.completedAt != null &&
                            mission.status != DailyMissionStatus.completed &&
                            mission.status != DailyMissionStatus.approved
                    ? () => _completeMission(mission)
                    : null,
                // 제출 버튼 (현재는 사용하지 않음 - 완료 버튼에서 직접 제출)
                onSubmit: null,
                // 재제출 버튼
                onResubmit: mission.status == DailyMissionStatus.rejected
                    ? () => _resubmitMission(mission)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // 일일 미션 상호작용 함수들
  void _showMissionDetail(DailyMissionModel mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mission.missionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '미션 설명:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(mission.missionDescription),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 20.w),
                SizedBox(width: 8.w),
                Text(
                  '보상: ${mission.baseReward}원',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.grey, size: 20.w),
                SizedBox(width: 8.w),
                Text('미션 날짜: ${_formatDate(mission.missionDate)}'),
              ],
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

  // 미션 삭제 (비밀번호 재인증 필요)
  Future<void> _deleteMission(DailyMissionModel mission) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text('미션 삭제', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '미션을 삭제하려면 비밀번호를 입력하세요.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '⚠️ 이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(fontSize: 12.sp, color: Colors.red[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(context, false);
            },
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 비밀번호 재인증
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.email == null) {
          throw Exception('로그인된 사용자를 찾을 수 없습니다');
        }

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text,
        );
        await user.reauthenticateWithCredential(credential);

        // mission_workflows 삭제
        if (mission.workflowId != null) {
          await FirebaseFirestore.instance
              .collection('mission_workflows')
              .doc(mission.workflowId)
              .delete();
        }

        passwordController.dispose();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 미션이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // UI 새로고침
        }
      } on FirebaseAuthException catch (e) {
        passwordController.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.code == 'wrong-password' || e.code == 'invalid-credential'
                    ? '❌ 비밀번호가 올바르지 않습니다'
                    : '❌ 인증 실패: ${e.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        passwordController.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 미션 삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      passwordController.dispose();
    }
  }

  // 미션 삭제 강화 버전 (삭제 사유 + 서버 기록)
  Future<void> _deleteMissionEnhanced(DailyMissionModel mission) async {
    final passwordController = TextEditingController();
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text('미션 삭제', style: TextStyle(color: Colors.red, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 메시지
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16.sp, color: Colors.orange[700]),
                        SizedBox(width: 4.w),
                        Text(
                          '삭제 요청 절차',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.orange[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '• 공급자에게 삭제 요청이 전송됩니다\n• 공급자 확인 후 영구 삭제됩니다\n• 삭제 사유는 공급자에게 공유됩니다',
                      style: TextStyle(fontSize: 12.sp, color: Colors.orange[900], height: 1.4),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // 비밀번호 입력
              Text('비밀번호 확인', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  hintText: '계정 비밀번호를 입력하세요',
                ),
              ),
              SizedBox(height: 16.h),

              // 삭제 사유 입력
              Text('삭제 사유 *', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: '삭제 사유 (최소 10자)',
                  border: OutlineInputBorder(),
                  hintText: '미션을 삭제하는 이유를 구체적으로 작성해주세요',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              SizedBox(height: 8.h),

              // 경고 메시지
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
                        '이 작업은 공급자 확인 후 취소할 수 없습니다',
                        style: TextStyle(fontSize: 11.sp, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              reasonController.dispose();
              Navigator.pop(context, false);
            },
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // 삭제 사유 최소 길이 검증
              if (reasonController.text.trim().length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ 삭제 사유는 최소 10자 이상 입력해주세요')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('삭제 요청', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 1. 비밀번호 재인증
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.email == null) {
          throw Exception('로그인된 사용자를 찾을 수 없습니다');
        }

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text,
        );
        await user.reauthenticateWithCredential(credential);

        // 2. 앱 및 공급자 정보 가져오기
        final workflowDoc = await FirebaseFirestore.instance
            .collection('mission_workflows')
            .doc(mission.workflowId)
            .get();

        final workflowData = workflowDoc.data();
        final providerId = workflowData?['providerId'] as String?;
        final appId = workflowData?['appId'] as String?;

        if (providerId == null || appId == null) {
          throw Exception('미션 정보를 찾을 수 없습니다');
        }

        // 앱 이름 가져오기
        final appDoc = await FirebaseFirestore.instance.collection('projects').doc(appId).get();
        final appName = appDoc.data()?['title'] as String? ?? '알 수 없는 앱';

        // 테스터 이름 가져오기
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final testerName = userDoc.data()?['displayName'] as String? ?? user.email!;

        // 3. mission_deletions 컬렉션에 삭제 요청 기록
        await FirebaseFirestore.instance.collection('mission_deletions').add({
          'workflowId': mission.workflowId,
          'testerId': user.uid,
          'testerName': testerName,
          'providerId': providerId,
          'appId': appId,
          'appName': appName,
          'missionTitle': mission.missionTitle,
          'dayNumber': mission.dayNumber ?? 0,
          'deletionReason': reasonController.text.trim(),
          'deletedAt': FieldValue.serverTimestamp(),
          'providerAcknowledged': false,
        });

        // 4. mission_workflows 업데이트 (currentState 변경)
        await FirebaseFirestore.instance
            .collection('mission_workflows')
            .doc(mission.workflowId)
            .update({
          'currentState': 'deleted_by_tester',
          'deletionReason': reasonController.text.trim(),
          'deletedAt': FieldValue.serverTimestamp(),
          'deletionAcknowledged': false,
        });

        passwordController.dispose();
        reasonController.dispose();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 삭제 요청이 공급자에게 전송되었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {}); // UI 새로고침
        }
      } on FirebaseAuthException catch (e) {
        passwordController.dispose();
        reasonController.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.code == 'wrong-password' || e.code == 'invalid-credential'
                    ? '❌ 비밀번호가 올바르지 않습니다'
                    : '❌ 인증 실패: ${e.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        passwordController.dispose();
        reasonController.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 삭제 요청 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      passwordController.dispose();
      reasonController.dispose();
    }
  }

  // 미션 시작 (가이드 대화상자 + 앱 열기)
  Future<void> _startMission(DailyMissionModel mission) async {
    try {
      // 1. 앱 URL 먼저 가져오기
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(mission.appId)
          .get();

      final appUrl = projectDoc.data()?['appUrl'] as String?;
      final appTestUrl = projectDoc.data()?['appTestUrl'] as String?;

      // appTestUrl 우선, 없으면 appUrl 사용
      final testUrl = appTestUrl ?? appUrl;
      final isWebApp = appTestUrl != null;

      if (testUrl == null || testUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 앱 URL이 설정되지 않았습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2. 가이드 대화상자 표시
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.blue, size: 28.sp),
              SizedBox(width: 8.w),
              Text(
                '🚀 미션 시작',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 앱 링크 섹션
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, size: 16.sp, color: Colors.blue),
                          SizedBox(width: 4.w),
                          Text(
                            '🔗 앱 링크',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      SelectableText(
                        testUrl,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: testUrl));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('📋 링크가 복사되었습니다'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.copy, size: 14.sp),
                              label: Text('복사', style: TextStyle(fontSize: 12.sp)),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                html.window.open(testUrl, '_blank');
                              },
                              icon: Icon(Icons.open_in_new, size: 14.sp),
                              label: Text('바로가기', style: TextStyle(fontSize: 12.sp)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // 미션 가이드 섹션
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 미션 가이드',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isWebApp
                            ? '✅ 10분 동안 웹 앱을 테스트해주세요\n'
                              '🌐 브라우저에서 앱을 사용해주세요\n'
                              '📸 스크린샷을 캡처해주세요\n'
                              '⏱️ 10분 후 완료 버튼이 활성화됩니다'
                            : '✅ 10분 동안 앱을 테스트해주세요\n'
                              '📱 버그나 개선사항을 찾아주세요\n'
                              '📸 스크린샷을 캡처해주세요\n'
                              '⏱️ 10분 후 완료 버튼이 활성화됩니다',
                        style: TextStyle(fontSize: 13.sp, height: 1.6),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                Text(
                  '아래 버튼을 눌러 앱 테스트를 시작하세요!',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                html.window.open(testUrl, '_blank');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isWebApp
                          ? '🌐 웹 앱이 새 탭에서 열렸습니다'
                          : '📱 앱을 설치한 후 "미션시작" 버튼을 눌러주세요'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: Icon(isWebApp ? Icons.open_in_browser : Icons.download, size: 16.sp),
              label: Text(isWebApp ? '웹에서 열기' : '설치하기'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // 설치 확인 다이얼로그
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('미션 시작 확인'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isWebApp
                              ? '웹 앱이 실행 가능한가요?'
                              : '앱이 설치되고 실행 가능한가요?',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16.sp, color: Colors.blue),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '확인을 누르면 10분 타이머가 시작됩니다.',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.blue[700]),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('확인'),
                      ),
                    ],
                  ),
                );

                // 미션 시작 - 타이머 모달창 표시
                if (confirmed == true && mounted) {
                  if (mission.workflowId != null) {
                    debugPrint('🔵 [Dashboard] 미션 시작 - startedAt 업데이트');

                    // startedAt 업데이트
                    await FirebaseFirestore.instance
                        .collection('mission_workflows')
                        .doc(mission.workflowId)
                        .update({
                      'startedAt': FieldValue.serverTimestamp(),
                      'currentState': 'in_progress',
                    });

                    debugPrint('🔵 [Dashboard] Firestore 업데이트 완료, 테스트 앱 열기');

                    // 테스트용 앱을 새 창에서 열기
                    html.window.open(testUrl, '_blank');

                    // UI 새로고침
                    debugPrint('🔵 [Dashboard] Provider 리로드 (미션 시작 후)');
                    ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);

                    // 타이머 모달창 표시
                    if (mounted) {
                      debugPrint('🔵 [Dashboard] 타이머 모달창 표시');
                      final result = await _showTimerModal(context, mission.workflowId!);
                      debugPrint('🔵 [Dashboard] 타이머 모달창 종료, result=$result');

                      // 타이머 종료 후 UI 새로고침
                      if (result != null && mounted) {
                        debugPrint('🔵 [Dashboard] Provider 리로드 (타이머 종료 후, 300ms delay)');
                        await Future.delayed(Duration(milliseconds: 300));
                        if (mounted) {
                          ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);
                          debugPrint('🔵 [Dashboard] Provider 리로드 완료');
                        }
                      }
                    }
                  }
                }
              },
              icon: Icon(Icons.play_arrow, size: 16.sp),
              label: Text('미션시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 미션 시작 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 미션 완료 (스크린샷 + 피드백 입력 → 즉시 제출)
  Future<void> _completeMission(DailyMissionModel mission) async {
    // [MVP] 10분 체크 - 남은 시간 표시
    if (mission.startedAt != null) {
      final elapsed = DateTime.now().difference(mission.startedAt!);
      final remaining = const Duration(minutes: 10) - elapsed;

      if (remaining.inSeconds > 0) {
        // 10분이 안 된 경우 - 경고 다이얼로그
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8.w),
                Text('10분 미만 테스트'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '아직 10분이 지나지 않았습니다.',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.orange, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '남은 시간: ${remaining.inMinutes}분 ${remaining.inSeconds % 60}초',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  '그래도 완료하시겠습니까?',
                  style: TextStyle(fontSize: 13.sp),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('완료하기'),
              ),
            ],
          ),
        );

        if (confirmed != true) return; // 취소 시 종료
      }
    }

    // DailyMissionSubmissionPage로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyMissionSubmissionPage(
          workflowId: mission.workflowId!,
          dayNumber: mission.dayNumber!,
          missionTitle: mission.missionTitle,
        ),
      ),
    );

    // 제출 완료 시 상태 업데이트
    if (result == true && mounted) {
      try {
        // mission_workflows 업데이트
        await FirebaseFirestore.instance
            .collection('mission_workflows')
            .doc(mission.workflowId)
            .update({
          'currentState': 'submission_completed',
          'submittedAt': FieldValue.serverTimestamp(),
        });

        // mission_management 업데이트
        await FirebaseFirestore.instance
            .collection('mission_management')
            .doc(mission.id)
            .update({
          'status': 'completed',
          'currentState': 'submission_completed',
        });

        if (mounted) {
          // UI 새로고침
          ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 미션이 제출되었습니다! 공급자 검토를 기다려주세요.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 미션 제출 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 타이머 모달창 표시
  Future<String?> _showTimerModal(BuildContext context, String workflowId) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TimerDialog(
        workflowId: workflowId,
        testerId: widget.testerId,
        providerRef: ref,
      ),
    );
  }

  // 미션 제출 (공급자에게 최종 제출)
  Future<void> _submitMission(DailyMissionModel mission) async {
    // 제출 데이터 확인 (attachments가 있어야 함)
    if (mission.attachments.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 스크린샷이 업로드되지 않았습니다. 미션 완료 버튼을 먼저 눌러주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('미션 제출'),
        content: Text('미션을 제출하시겠습니까?\n제출 후에는 수정할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('제출', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // status를 'completed'로 변경 (공급자 검토 대기)
        await MissionManagementService().updateMissionStatus(
          missionId: mission.id,
          status: DailyMissionStatus.completed,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 미션이 제출되었습니다! 공급자 검토를 기다려주세요.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {}); // UI 새로고침
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 미션 제출 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resubmitMission(DailyMissionModel mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미션 재제출'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${mission.missionTitle} 미션을 재제출하시겠습니까?'),
            if (mission.reviewNote != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이전 거절 사유:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      mission.reviewNote!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // MissionManagementService를 사용해서 미션을 다시 completed 상태로 변경 (재제출)
                await MissionManagementService().updateMissionStatus(
                  missionId: mission.id,
                  status: DailyMissionStatus.completed,
                  note: '미션 재제출 - 수정사항 반영',
                );

                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 미션이 재제출되었습니다!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ 미션 재제출 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('재제출'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required dynamic mission,
    required String title,
    required String description,
    required String reward,
    required String deadline,
    required String participants,
  }) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissionDetailPage(mission: mission),
          ),
        );

        // 미션 신청 결과 처리
        if (result != null) {
          if (result is Map<String, dynamic> && result['success'] == true) {
            // 미션 신청 성공 - 탭 전환 및 데이터 새로고침
            ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);

            // 진행중 탭으로 자동 전환 (navigateToTab이 있는 경우)
            if (result['navigateToTab'] != null) {
              final tabIndex = result['navigateToTab'] as int;
              if (tabIndex >= 0 && tabIndex < 4) {
                // 하위 TabController에 접근하기 위해 GlobalKey 사용 예정
                // 현재는 기본 진행중 탭(인덱스 1)으로 전환
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    // 메인 탭바에서 미션 탭이 이미 선택되어 있으므로
                    // 하위 탭 컨트롤러에만 영향을 줌
                    setState(() {
                      // 미션 서브탭에서 진행중 탭으로 전환하도록 신호 전송
                      _navigateToMissionSubTab = tabIndex;
                    });
                  }
                });
              }
            }
          } else if (result == true) {
            // 기존 호환성을 위한 단순 성공 처리
            ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);
          }
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: ResponsiveWrapper.getResponsivePadding(context),
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
                    color: AppColors.accentGoldBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    reward,
                    style: TextStyle(
                      color: AppColors.accentGold,
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
    ).withUserTypeCard(
      userType: 'tester',
      borderRadius: 12.r,
      withHover: true,
    );
  }


  Widget _buildCompletedMissionsTab() {
    final dashboardState = ref.watch(testerDashboardProvider);
    
    if (dashboardState.completedMissions.isEmpty) {
      return _buildEmptyCompletedMissions();
    }

    return ListView.builder(
      padding: ResponsiveWrapper.getResponsivePadding(context),
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
        padding: ResponsiveWrapper.getResponsivePadding(context),
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

  Widget _buildSettlementTab() {
    final missionService = MissionManagementService();

    return StreamBuilder<List<MissionSettlementModel>>(
      stream: missionService.watchTesterSettlements(widget.testerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BugCashLoadingWidget(
            message: '미션 목록을 불러오는 중...',
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.w,
                  color: Colors.red[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  '정산 정보를 불러올 수 없습니다',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '오류: ${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.red[500],
                  ),
                ),
              ],
            ),
          );
        }

        final settlements = snapshot.data ?? [];

        if (settlements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 64.w,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  '정산 가능한 미션이 없습니다',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '14일 미션을 완료하면 정산이 가능합니다!',
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
          padding: ResponsiveWrapper.getResponsivePadding(context),
          itemCount: settlements.length,
          itemBuilder: (context, index) {
            final settlement = settlements[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: ResponsiveWrapper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '정산 #${settlement.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: settlement.isPaid ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            settlement.isPaid ? '지급완료' : '지급대기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '완료 미션: ${settlement.completedMissions}/${settlement.totalDays}일',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '기본 보상: ${settlement.totalBaseReward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (settlement.bonusReward > 0)
                          Text(
                            '보너스: ${settlement.bonusReward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.blue[600],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    const Divider(),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '총 지급액',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${settlement.finalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (settlement.paidAt != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        '지급일: ${settlement.paidAt!.year}.${settlement.paidAt!.month.toString().padLeft(2, '0')}.${settlement.paidAt!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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

/// 타이머 다이얼로그 Widget
class TimerDialog extends StatefulWidget {
  final String workflowId;
  final String testerId;
  final WidgetRef providerRef;

  const TimerDialog({
    Key? key,
    required this.workflowId,
    required this.testerId,
    required this.providerRef,
  }) : super(key: key);

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  late Timer _timer;
  late DateTime _startTime;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // 1초마다 타이머 업데이트
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
      });

      // 10분 체크 (600초)
      if (_elapsedSeconds >= 600) {
        _autoComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // 자동 완료
  Future<void> _autoComplete() async {
    _timer.cancel();

    debugPrint('🟢 [TimerDialog] _autoComplete 시작');

    await FirebaseFirestore.instance
        .collection('mission_workflows')
        .doc(widget.workflowId)
        .update({
      'completedAt': FieldValue.serverTimestamp(),
      'currentState': 'testing_completed',
    });

    debugPrint('🟢 [TimerDialog] Firestore 업데이트 완료');

    if (mounted) {
      debugPrint('🟢 [TimerDialog] Navigator.pop 실행 (rootNavigator: false)');
      Navigator.of(context, rootNavigator: false).pop('completed');
      debugPrint('🟢 [TimerDialog] Navigator.pop 완료');
    }
  }

  // 수동 중지
  Future<void> _manualStop() async {
    debugPrint('🟡 [TimerDialog] _manualStop 시작');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('테스트 중지'),
        content: Text('테스트를 중지하시겠습니까?\n진행 시간이 기록됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('중지'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _timer.cancel();
      debugPrint('🟡 [TimerDialog] Navigator.pop 실행 (rootNavigator: false)');
      Navigator.of(context, rootNavigator: false).pop('stopped');
      debugPrint('🟡 [TimerDialog] Navigator.pop 완료');
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;

    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer, color: Colors.green),
            SizedBox(width: 8.w),
            Text('앱 테스트 중입니다'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이머 표시
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // 안내 문구
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  '10분 후 자동 종료',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _manualStop,
            child: Text('중지', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}