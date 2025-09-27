import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/auth_service.dart';
import 'app_management_page.dart' hide ProviderAppModel;
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
// 채팅 기능 제거됨
// import '../widgets/payment_management_tab.dart';

class ProviderDashboardPage extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderDashboardPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('Initializing Provider Dashboard for: ${widget.providerId}', 'ProviderDashboard');
    });
  }

  Widget _buildCurrentTab() {
    // 현재 사용자의 권한 확인
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final hasAdminRole = user?.roles.contains(UserType.admin) == true ||
                        user?.primaryRole == UserType.admin;

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildAppsTab();
      case 2:
        return _buildPaymentTab();
      case 3:
        // 관리자 권한이 있는 경우에만 관리자 탭 표시
        if (hasAdminRole) {
          return _buildAdminTab();
        } else {
          // 권한이 없는 경우 대시보드로 리디렉션
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedIndex = 0);
          });
          return _buildDashboardTab();
        }
      default:
        return _buildDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 사용자의 권한 확인
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final hasAdminRole = user?.roles.contains(UserType.admin) == true ||
                        user?.primaryRole == UserType.admin;

    // 디버그 로그
    debugPrint('ProviderDashboard - User roles: ${user?.roles}');
    debugPrint('ProviderDashboard - Primary role: ${user?.primaryRole}');
    debugPrint('ProviderDashboard - Has admin role: $hasAdminRole');

    // 관리자 권한에 따라 네비게이션 아이템 구성
    final List<BottomNavigationBarItem> navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: '대시보드',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.apps),
        label: '앱 관리',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.payment),
        label: '결제',
      ),
      // 관리자 권한이 있을 때만 관리자 탭 표시
      if (hasAdminRole)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: '관리자',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: '테스터 모드로 전환',
          onPressed: () {
            // 테스터 대시보드로 이동
            final userId = CurrentUserService.getCurrentUserIdOrDefault();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TesterDashboardPage(
                  testerId: userId,
                ),
              ),
            );
          },
        ),
        title: Text(
          '공급자 대시보드',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 기능 (개발 중)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 기능 (개발 중)')),
              );
            },
          ),
        ],
      ),
      body: _buildCurrentTab(),
      floatingActionButton: _buildChatFAB(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.indigo[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.indigo[300],
        currentIndex: _selectedIndex,
        onTap: (index) {
          debugPrint('BottomNavigationBar tapped: $index');

          // 관리자 권한이 없는데 관리자 탭(3번)을 클릭한 경우 방지
          if (!hasAdminRole && index >= 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ 관리자 권한이 필요합니다'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          setState(() => _selectedIndex = index);
        },
        items: navigationItems,
      ),
    );
  }

  Widget _buildDashboardTab() {
    // Provider 정보 대신 간단한 환영 메시지 사용 - Firebase 에러 방지
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 간단한 환영 메시지 - Firebase provider 컬렉션 에러 방지
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안녕하세요, Provider님!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '오늘도 품질 높은 앱을 만들어 보세요.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 간단한 통계 카드들
          _buildSimpleStatsCards(),

          SizedBox(height: 24.h),

          // Recent Activities Section - 에러 방지를 위해 간단한 메시지로 대체
          _buildSimpleRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildAppsTab() {
    AppLogger.info('🔧🔧🔧 Building Apps Tab', 'ProviderDashboard');
    AppLogger.info('Provider ID: ${widget.providerId}', 'ProviderDashboard');
    
    // 앱 관리 페이지 import 및 사용
    return AppManagementPage(providerId: widget.providerId);
  }



  Widget _buildPaymentTab() {
    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Icon(Icons.payment, size: 48.sp, color: Colors.indigo),
            SizedBox(height: 16.h),
            Text(
              '결제 관리',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              '결제 시스템 (개발 중)',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }





  // Recent Activities Methods
  Widget _buildRecentActivities(List<Map<String, dynamic>> activities) {
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
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  '최근 활동이 없습니다',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                ),
              ),
            )
          else
            ...activities.take(3).map((activity) => _buildActivityItem(
              title: activity['title'] ?? '활동',
              subtitle: activity['description'] ?? '',
              time: _formatTime(activity['timestamp']),
              icon: _getActivityIcon(activity['type']),
              color: _getActivityColor(activity['priority']),
            )),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesLoading() {
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
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          ...List.generate(3, (index) => _buildActivityItemLoading()),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesError() {
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
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            '최근 활동을 불러올 수 없습니다',
            style: TextStyle(fontSize: 16.sp, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItemLoading() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  height: 12.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '방금 전';
    try {
      final DateTime time = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      final Duration diff = DateTime.now().difference(time);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}분 전';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}시간 전';
      } else {
        return '${diff.inDays}일 전';
      }
    } catch (e) {
      return '방금 전';
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'bug_report':
        return Icons.bug_report;
      case 'mission_completed':
        return Icons.check_circle;
      case 'tester_joined':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }



  Widget _buildSimpleStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Icon(Icons.apps, size: 32.sp, color: Colors.blue),
                  SizedBox(height: 8.h),
                  Text(
                    '0',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '등록된 앱',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Icon(Icons.people, size: 32.sp, color: Colors.green),
                  SizedBox(height: 8.h),
                  Text(
                    '0',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '테스터',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRecentActivities() {
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
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    '아직 활동 내역이 없습니다',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '앱을 등록하고 테스터를 모집해보세요!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatFAB() {
    // currentUserProvider 대신 직접 Firebase Auth 사용
    final currentUser = FirebaseAuth.instance.currentUser;
    final unreadCount = currentUser != null
        ? 0 // 채팅 기능 제거됨
        : 0;

    return Stack(
      children: [
        FloatingActionButton(
          heroTag: "provider_dashboard_chat_fab",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // 채팅 기능 제거됨
                builder: (context) => Container(),
              ),
            );
          },
          backgroundColor: Colors.indigo[700],
          child: const Icon(
            Icons.chat,
            color: Colors.white,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10.r),
              ),
              constraints: BoxConstraints(
                minWidth: 16.w,
                minHeight: 16.w,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
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

  // 관리자 탭 - 프로젝트 검수 기능
  Widget _buildAdminTab() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AdminDashboardPage(),
        );
      },
    );
  }
}