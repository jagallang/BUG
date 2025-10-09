import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/widgets/loading_widgets.dart';
import '../../../../shared/widgets/responsive_wrapper.dart';
import '../../../../core/constants/app_colors.dart';
// import '../widgets/earnings_summary_widget.dart';
// import '../widgets/community_board_widget.dart';
// import '../widgets/expandable_mission_card.dart';
// import '../widgets/active_test_session_card.dart';
import '../providers/tester_dashboard_provider.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
// 채팅 기능 제거됨
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mission/presentation/providers/mission_providers.dart';
import '../../../auth/presentation/widgets/auth_wrapper.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'mission_detail_page.dart';
import 'mission_tracking_page.dart';
import '../../../../core/services/mission_management_service.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../shared/widgets/daily_mission_card.dart';
import '../../../shared/models/mission_management_model.dart';
import '../../../../core/services/screenshot_service.dart';
import '../../../mission/presentation/providers/mission_providers.dart';
import '../../../mission/domain/entities/mission_workflow_entity.dart';
import '../../../../core/utils/logger.dart';
// v2.52.0: 지갑 기능 추가
import '../../../wallet/presentation/widgets/tester_wallet_card.dart';
// v2.74.0: 통합 지갑 페이지 추가
import '../../../wallet/presentation/pages/unified_wallet_page.dart';
// v2.80.0: 역할 전환 다이얼로그
import '../../../shared/widgets/role_switch_dialog.dart';

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
    _tabController = TabController(length: 3, vsync: this); // 미션 서브탭: 미션 찾기, 진행 중, 완료
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
      // 진행 중인 미션 찾기 (단순 쿼리로 변경 - 인덱스 불필요)
      final snapshot = await FirebaseFirestore.instance
          .collection('mission_workflows')
          .where('testerId', isEqualTo: widget.testerId)
          .get();

      if (snapshot.docs.isEmpty) return;

      // 클라이언트 측 필터링: in_progress 또는 testing_completed & startedAt이 있는 것만
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final currentState = data['currentState'] as String?;
        final startedAt = data['startedAt'] as Timestamp?;
        return startedAt != null &&
               (currentState == 'in_progress' || currentState == 'testing_completed');
      }).toList();

      if (filteredDocs.isEmpty) return;

      // 가장 최근 시작된 미션 찾기
      final docs = filteredDocs
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

  // v2.73.0: 프로필 페이지로 이동
  void _navigateToProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필 페이지 (개발 중)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // v2.74.0: 통합 지갑 페이지로 이동
  void _navigateToWallet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnifiedWalletPage(
          userId: widget.testerId,
          userType: 'tester',
        ),
      ),
    );
  }

  // v2.80.0: 역할 전환 다이얼로그 표시
  void _showRoleSwitchDialog(BuildContext context) {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    showDialog(
      context: context,
      builder: (context) => RoleSwitchDialog(user: authState.user!),
    );
  }

  // v2.80.1: 공급자 신청 메뉴 제거됨 (역할 전환 기능으로 통합)

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
      // v2.38.0: 로그아웃 전 모든 Provider 정리
      debugPrint('🔴 Riverpod Provider 정리');
      // AutoDispose provider들이 자동으로 정리됨
      ref.invalidate(authProvider);

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
              // App Bar - v2.77.0: 오렌지 테마 적용 및 로고 변경
              SliverAppBar(
                pinned: true,
                elevation: 2,
                backgroundColor: AppColors.testerOrangePrimary,
                automaticallyImplyLeading: false,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BUGS 텍스트 로고 (이미지 준비 전까지 임시)
                    Text(
                      'BUGS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  // 0. 역할 전환 아이콘 (v2.80.0)
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    tooltip: '역할 전환',
                    onPressed: () => _showRoleSwitchDialog(context),
                  ),
                  // 1. 프로필 아이콘
                  IconButton(
                    icon: const Icon(Icons.account_circle, color: Colors.white),
                    tooltip: '프로필',
                    onPressed: () => _navigateToProfile(context),
                  ),
                  // 2. 지갑 아이콘
                  IconButton(
                    icon: const Icon(Icons.wallet, color: Colors.white),
                    tooltip: '거래 내역',
                    onPressed: () => _navigateToWallet(context),
                  ),
                  // 3. 알림 아이콘 (Badge 포함)
                  IconButton(
                    icon: Badge(
                      label: Text('${dashboardState.unreadNotifications}'),
                      isLabelVisible: dashboardState.unreadNotifications > 0,
                      child: const Icon(Icons.notifications, color: Colors.white),
                    ),
                    tooltip: '알림',
                    onPressed: () => _showNotifications(context),
                  ),
                  // 4. 햄버거 메뉴
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    tooltip: '메뉴',
                    offset: Offset(0, 50.h),
                    onSelected: (String value) {
                      debugPrint('🔵 PopupMenu 선택됨: $value');
                      switch (value) {
                        // v2.80.1: 공급자 신청 메뉴 제거 (역할 전환 아이콘으로 대체)
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
                      // v2.80.1: 공급자 신청 메뉴 제거 (역할 전환 아이콘으로 대체)
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

              // 미션 콘텐츠 (게시판 탭 제거)
              SliverFillRemaining(
                child: dashboardState.isLoading
                    ? const BugCashLoadingWidget(
                        message: '미션 데이터를 불러오는 중...',
                      )
                    : dashboardState.error != null
                        ? _buildErrorWidget(dashboardState.error!)
                        : _buildMissionTab(),
              ),
            ],
          ),

          // v2.39.0: 채팅 FAB 제거
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

  // v2.39.0: 채팅 FAB 제거됨
  // Widget _buildChatFAB() { ... }


  Widget _buildMissionTab() {
    return DefaultTabController(
      length: 3, // v2.74.0: 정산 탭 제거로 3개로 변경
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
                ],
              ),
            ),
          ),
          Container(
            height: 50.h + MediaQuery.of(context).padding.bottom, // v2.75.1: 높이 감소 (60→50)
            decoration: BoxDecoration(
              color: AppColors.testerOrangePrimary, // v2.77.0: 오렌지 테마
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom), // 하단 세이프 에리어 패딩
              child: TabBar(
                labelColor: Colors.white, // v2.75.1: 흰색 텍스트
                unselectedLabelColor: Colors.white70, // v2.75.1: 반투명 흰색
                indicatorColor: AppColors.testerYellowLight, // v2.77.0: 옐로우 인디케이터
                indicatorWeight: 3,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 8.w),
                splashFactory: InkRipple.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  Tab(text: '미션 찾기', icon: Icon(Icons.search, size: 24.w)), // v2.75.1: 아이콘 크기 증가 (18→24)
                  Tab(text: '진행 중', icon: Icon(Icons.play_circle, size: 24.w)),
                  Tab(text: '완료', icon: Icon(Icons.check_circle, size: 24.w)),
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
            reward: '${mission.rewardPoints}P',  // v2.19.0: 동적 총 리워드
            deadline: mission.deadlineText,      // v2.19.0: '바로 진행' 또는 '모집 마감'
            participants: mission.participantsText,  // v2.19.0: '3/5' 형식
          ),
        );
      },
    );
  }

  Widget _buildActiveMissionsTab() {
    // v2.28.0: Clean Architecture 상태관리 (독립 인스턴스 Provider)
    // Legacy StreamBuilder 제거 → cleanArchTesterMissionProvider 사용
    final missionState = ref.watch(cleanArchTesterMissionProvider(widget.testerId));

    return missionState.when(
      initial: () => const BugCashLoadingWidget(
        message: '초기화 중...',
      ),
      loading: () => const BugCashLoadingWidget(
        message: '미션 목록을 불러오는 중...',
      ),
      error: (message, exception) => Center(
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
              message,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                // v2.28.0: 수동 새로고침 (30초 폴링 대신 즉시 갱신)
                ref.read(cleanArchTesterMissionProvider(widget.testerId).notifier).refreshMissions();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      loaded: (missions, isRefreshing) {
        // v2.27.0: MissionWorkflowEntity → DailyMissionModel 변환 및 필터링
        // v2.24.1: in_progress 상태 미션만 표시 (approved 상태 제외)
        // v2.24.8: 일일 미션 진행 상태 추가 (제출 후에도 계속 보여야 함)
        // approved: 공급자가 승인했지만 아직 미션만들기를 하지 않은 상태 (제외)
        // inProgress: 미션 수행 중
        // dailyMissionCompleted: 일일 미션 제출 후 검토 대기
        // dailyMissionApproved: 일일 미션 승인됨 (다음 날 제출 가능)
        final activeMissionEntities = missions.where((mission) {
          return mission.status == MissionWorkflowStatus.inProgress ||
              mission.status == MissionWorkflowStatus.dailyMissionCompleted ||
              mission.status == MissionWorkflowStatus.dailyMissionApproved;
        }).toList();

        // Convert to DailyMissionModel
        final dailyMissions = activeMissionEntities.map((entity) {
          return DailyMissionModel(
            id: entity.id,
            appId: entity.appId,
            testerId: entity.testerId,
            missionDate: entity.appliedAt,  // Use appliedAt as missionDate
            missionTitle: entity.appName,
            missionDescription: '${entity.totalDays}일 일일 미션 테스트',
            baseReward: entity.dailyReward,
            status: _mapWorkflowStatusToDailyMissionStatus(entity.status),
            currentState: entity.status.name.toString(),
            startedAt: entity.startedAt,
            completedAt: entity.completedAt,
            approvedAt: entity.approvedAt,
            workflowId: entity.id,
            dayNumber: entity.completedDays + 1,
          );
        }).toList();

        AppLogger.info(
          '🎨 [v2.27.0] ACTIVE_TAB: total=${missions.length}, filtered=${dailyMissions.length}',
          'TesterDashboard'
        );
        if (dailyMissions.isNotEmpty) {
          AppLogger.info(
            '   └─ First mission: ${dailyMissions.first.missionTitle} (${dailyMissions.first.currentState})',
            'TesterDashboard'
          );
        }

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
                SizedBox(height: 16.h),
                // v2.28.0: 수동 새로고침 버튼
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(cleanArchTesterMissionProvider(widget.testerId).notifier).refreshMissions();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로고침'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.testerOrangePrimary, // v2.77.0: 오렌지 테마
                    foregroundColor: Colors.white,
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
                          appId: mission.appId, // v2.9.0
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
                // v2.24.1: 시작 버튼 (in_progress 상태에서만 시작 가능)
                // approved 상태에서는 공급자가 "미션만들기"를 해야 함
                onStart: (mission.currentState == 'in_progress') &&
                         mission.startedAt == null
                    ? () => _startMission(mission)
                    : null,
                // v2.8.9: 완료 버튼 (시간 기반 체크 - 10분 경과 여부)
                onComplete: _canCompleteMission(mission)
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

  /// v2.27.0: MissionWorkflowStatus → DailyMissionStatus 변환
  DailyMissionStatus _mapWorkflowStatusToDailyMissionStatus(MissionWorkflowStatus status) {
    switch (status) {
      case MissionWorkflowStatus.applicationSubmitted:
        return DailyMissionStatus.pending;
      case MissionWorkflowStatus.approved:
        return DailyMissionStatus.approved;
      case MissionWorkflowStatus.inProgress:
      case MissionWorkflowStatus.dailyMissionCompleted:
      case MissionWorkflowStatus.dailyMissionApproved:
        return DailyMissionStatus.inProgress; // 진행중으로 표시
      case MissionWorkflowStatus.submissionCompleted:
      case MissionWorkflowStatus.testingCompleted:
        return DailyMissionStatus.completed;
      case MissionWorkflowStatus.rejected:
      case MissionWorkflowStatus.cancelled:
        return DailyMissionStatus.rejected;
    }
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

  // v2.21.01: 미션 시작 (단순 가이드 메시지만 표시)
  Future<void> _startMission(DailyMissionModel mission) async {
    // 가이드 대화상자 표시
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 28.sp),
            SizedBox(width: 8.w),
            Text(
              '미션 진행 안내',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        content: Text(
          '앱 테스트가 진행중입니다.\n앱을 누르고 날짜별로 미션을 제출하세요',
          style: TextStyle(fontSize: 14.sp, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // v2.13.0: 미션 완료 (완료 시간만 기록, 제출은 미션진행현황 페이지에서)
  Future<void> _completeMission(DailyMissionModel mission) async {
    // workflowId 유효성 검증
    if (mission.workflowId == null || mission.workflowId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 미션 워크플로우 ID가 없습니다. 관리자에게 문의하세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // dayNumber 유효성 검증
    if (mission.dayNumber == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 미션 일자 정보가 없습니다. 관리자에게 문의하세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // v2.13.0: 완료 시간만 기록 (제출 없음)
      await ref.read(missionWorkflowServiceProvider).markDailyMissionCompleted(
        workflowId: mission.workflowId!,
        testerId: widget.testerId,
        dayNumber: mission.dayNumber!,
      );

      if (mounted) {
        // UI 새로고침
        ref.read(testerDashboardProvider.notifier).loadTesterData(widget.testerId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 테스트가 완료되었습니다!\n📝 "미션진행현황" 페이지에서 제출해주세요.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 완료 처리 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // v2.8.9: 미션 완료 가능 여부 체크 (순수 시간 기반)
  bool _canCompleteMission(DailyMissionModel mission) {
    // v2.11.4: testing_completed 상태면 완료 불가 (중복 제출 방지)
    if (mission.currentState == 'testing_completed') {
      return false;
    }

    // 이미 완료되었거나 승인된 미션은 완료 불가
    if (mission.status == DailyMissionStatus.completed ||
        mission.status == DailyMissionStatus.approved) {
      return false;
    }

    // 시작하지 않은 미션은 완료 불가
    if (mission.startedAt == null) {
      return false;
    }

    // 시작 시간으로부터 10분 경과 여부 확인
    final elapsed = DateTime.now().difference(mission.startedAt!);
    final canComplete = elapsed.inMinutes >= 10;

    if (kDebugMode) {
      debugPrint('🔍 [Complete Check] mission=${mission.id}, startedAt=${mission.startedAt}, elapsed=${elapsed.inMinutes}분, canComplete=$canComplete');
    }

    return canComplete;
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
    // v2.20.01: 신청 여부 확인
    final bool isApplied = mission.isApplied ?? false;

    return Opacity(
      opacity: isApplied ? 0.6 : 1.0,  // v2.20.01: 신청한 미션은 투명도 낮춤
      child: InkWell(
        onTap: isApplied ? null : () async {  // v2.20.01: 신청한 미션은 클릭 비활성화
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
        child: Container(
          decoration: BoxDecoration(
            color: isApplied ? Colors.grey[100] : Colors.white,  // v2.20.01: 배경색 변경
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isApplied ? [] : AppColors.cardShadowMedium,  // v2.20.01: 그림자 제거
            border: isApplied
                ? Border.all(color: Colors.grey[300]!, width: 1)  // v2.20.01: 테두리 추가
                : null,
          ),
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
                          color: isApplied ? Colors.grey[700] : Colors.black,  // v2.20.01: 텍스트 색상 조정
                        ),
                      ),
                    ),
                    // v2.20.01: 신청완료 배지 또는 리워드 표시
                    if (isApplied)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14.sp, color: Colors.green),
                            SizedBox(width: 4.w),
                            Text(
                              '신청완료',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
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
                    color: isApplied ? Colors.grey[500] : Colors.grey[600],  // v2.20.01: 텍스트 색상 조정
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
      ),
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

  // v2.52.0: 실시간 지갑 UI 적용
  Widget _buildSettlementTab() {
    final missionService = MissionManagementService();

    return StreamBuilder<List<MissionSettlementModel>>(
      stream: missionService.watchTesterSettlements(widget.testerId),
      builder: (context, snapshot) {
        // v2.55.0: 로딩 상태를 더 엄격하게 체크 (waiting이면서 data가 null일 때만 로딩)
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const BugCashLoadingWidget(
            message: '정산 정보를 불러오는 중...',
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

        // v2.52.0: 지갑 카드를 ListView의 첫 항목으로 추가
        return ListView.builder(
          padding: ResponsiveWrapper.getResponsivePadding(context),
          itemCount: 1 + settlements.length, // 지갑 카드 + 정산 항목들
          itemBuilder: (context, index) {
            // 첫 번째 항목: 지갑 카드
            if (index == 0) {
              return Column(
                children: [
                  TesterWalletCard(testerId: widget.testerId),
                  SizedBox(height: 16.h),
                  if (settlements.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Column(
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
                    ),
                ],
              );
            }

            // 나머지 항목: 정산 목록
            final settlement = settlements[index - 1];
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

// v2.39.0: 채팅 FAB 제거로 _CustomFabLocation 제거됨
// class _CustomFabLocation extends FloatingActionButtonLocation { ... }

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

    // v2.8.9: 타이머는 UI 표시 전용 (자동완료 로직 제거)
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
      });

      // ❌ 자동완료 제거 - 백그라운드 throttle 이슈 방지
      // 완료 버튼 활성화는 _canCompleteMission()에서 순수 시간 계산으로 처리
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // 수동 중지
  Future<void> _manualStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('테스트 중지'),
        content: Text('테스트를 중지하시겠습니까?'),
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
      Navigator.of(context, rootNavigator: false).pop('stopped');
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
            // v2.8.9: 안내 문구 - 완료 버튼 활성화로 변경
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  '10분 후 자동으로 완료 버튼 활성화',
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