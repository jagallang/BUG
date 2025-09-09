import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';
import '../../domain/models/provider_model.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';
import 'app_registration_page.dart';
import 'app_management_page.dart' hide ProviderAppModel;
import '../widgets/apps_header_widget.dart';
import '../widgets/apps_list_widget.dart';
import '../widgets/apps_empty_state_widget.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import 'apps_tab_test.dart';
import 'missions_tab_test.dart';
import '../widgets/tester_management_tab.dart';
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
        return _buildTesterManagementTab();
      case 3:
        return _buildReportsTab();
      case 4:
        return _buildPaymentTab();
      default:
        return _buildDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          tooltip: '테스터 모드로 전환',
          onPressed: () {
            // 테스터 대시보드로 이동
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const TesterDashboardPage(
                  testerId: 'test_tester_001',
                ),
              ),
            );
          },
        ),
        title: Text(
          '공급자 대시보드',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 기능 (개발 중)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 기능 (개발 중)')),
              );
            },
          ),
        ],
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.people),
            label: '테스터 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report),
            label: '버그 리포트',
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

  Widget _buildTesterManagementTab() {
    return TesterManagementTab(providerId: widget.providerId);
  }

  Widget _buildReportsTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '버그 리포트',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ref.watch(providerBugReportsProvider(widget.providerId)).when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 48.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '버그 리포트가 없습니다',
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
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportCard(report);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.sp,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '리포트를 불러올 수 없습니다',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        ref.refresh(providerBugReportsProvider(widget.providerId));
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  // App Card Widget
  Widget _buildAppCard(AppModel app) {
    final statusColor = _getAppStatusColor(app.status);
    final statusText = _getAppStatusText(app.status);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.phone_android,
            color: Colors.blue,
            size: 24.sp,
          ),
        ),
        title: Text(
          app.appName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Text('버전 ${app.version ?? '1.0.0'} • 미션 ${app.totalMissions}개'),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          debugPrint('앱 카드 클릭됨: ${app.appName}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${app.appName} 상세 정보 (개발 중)')),
          );
        },
      ),
    );
  }

  Color _getAppStatusColor(AppStatus status) {
    switch (status) {
      case AppStatus.active:
        return Colors.green;
      case AppStatus.review:
        return Colors.orange;
      case AppStatus.paused:
        return Colors.grey;
      case AppStatus.draft:
        return Colors.blue;
      case AppStatus.completed:
        return Colors.blue;
      case AppStatus.cancelled:
        return Colors.red;
    }
  }

  String _getAppStatusText(AppStatus status) {
    switch (status) {
      case AppStatus.active:
        return '활성';
      case AppStatus.review:
        return '검토중';
      case AppStatus.paused:
        return '일시정지';
      case AppStatus.draft:
        return '초안';
      case AppStatus.completed:
        return '완료';
      case AppStatus.cancelled:
        return '취소됨';
    }
  }

  Widget _buildMissionCard(MissionModel mission) {
    final statusColor = _getMissionStatusColor(mission.status);
    final statusText = _getMissionStatusText(mission.status);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
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
                    mission.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              mission.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '참여자: ${mission.testers}/${mission.maxTesters}',
                  style: TextStyle(fontSize: 12.sp),
                ),
                Text(
                  '보상: ${mission.reward}P',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
                Text(
                  mission.createdAt != null 
                      ? _formatReportTime(mission.createdAt!)
                      : '날짜 없음',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMissionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMissionStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return '활성';
      case 'draft':
        return '초안';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소됨';
      default:
        return '알 수 없음';
    }
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
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
                    report['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(report['severity'] as String).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    report['severity'] as String,
                    style: TextStyle(
                      color: _getSeverityColor(report['severity'] as String),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '${report['appName'] ?? 'Unknown App'} • ${report['testerName'] ?? 'Unknown Tester'}님',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    report['status'] as String? ?? '확인중',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  _formatReportTime(report['createdAt']),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatReportTime(dynamic createdAt) {
    if (createdAt is DateTime) {
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      
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
    return createdAt?.toString() ?? '알 수 없음';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 남음';
    } else if (difference.inDays == 0) {
      return '오늘 마감';
    } else {
      return '${(-difference.inDays)}일 지남';
    }
  }
}