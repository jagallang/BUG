import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/auth_service.dart';
import 'app_management_page.dart' hide ProviderAppModel;
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
// 채팅 기능 제거됨
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/payment_management_tab.dart';

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
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildAppsTab();
      case 2:
        return _buildPaymentTab();
      default:
        return _buildDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '대시보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: '앱 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: '결제',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final providerInfoAsync = ref.watch(providerInfoStateProvider(widget.providerId));
    final recentActivitiesAsync = ref.watch(recentActivitiesProvider(widget.providerId));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Info Section
          providerInfoAsync.when(
            data: (providerInfo) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, ${providerInfo?.companyName ?? 'Provider'}님!',
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
            loading: () => Column(
              children: [
                Container(
                  height: 30.h,
                  width: 200.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 20.h,
                  width: 150.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
            error: (error, stack) => Text(
              '정보를 불러올 수 없습니다',
              style: TextStyle(color: Colors.red, fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 24.h),
          
          SizedBox(height: 24.h),
          
          // Recent Activities Section
          recentActivitiesAsync.when(
            data: (activities) => _buildRecentActivities(activities),
            loading: () => _buildRecentActivitiesLoading(),
            error: (error, stack) => _buildRecentActivitiesError(),
          ),
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
    return PaymentManagementTab(providerId: widget.providerId);
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



  Widget _buildChatFAB() {
    final currentUser = ref.watch(currentUserProvider);
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
}