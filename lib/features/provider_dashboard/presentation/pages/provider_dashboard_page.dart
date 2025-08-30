import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';
import '../widgets/dashboard_stats_cards.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/apps_overview_widget.dart';
import '../widgets/missions_overview_widget.dart';
import '../widgets/bug_reports_overview_widget.dart';
import '../widgets/recent_activities_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../../../../core/presentation/widgets/connection_status_widget.dart';

class ProviderDashboardPage extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderDashboardPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Set current provider ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentProviderIdProvider.notifier).state = widget.providerId;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConnectionStatusAppBar(
        title: '앱 공급자 대시보드',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
            tooltip: '설정',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: '대시보드'),
                Tab(icon: Icon(Icons.apps), text: '앱 관리'),
                Tab(icon: Icon(Icons.assignment), text: '미션 관리'),
                Tab(icon: Icon(Icons.bug_report), text: '버그 리포트'),
                Tab(icon: Icon(Icons.analytics), text: '분석'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildAppsTab(),
                _buildMissionsTab(),
                _buildBugReportsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDashboardTab() {
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider(widget.providerId));
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            
            SizedBox(height: 24.h),
            
            // Quick Actions
            const QuickActionsWidget(),
            
            SizedBox(height: 24.h),
            
            // Stats Cards
            dashboardStatsAsync.when(
              data: (stats) => DashboardStatsCards(stats: stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorWidget('통계 로딩 실패', error),
            ),
            
            SizedBox(height: 24.h),
            
            // Charts
            dashboardStatsAsync.when(
              data: (stats) => DashboardCharts(stats: stats),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            SizedBox(height: 24.h),
            
            // Overview Widgets
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      AppsOverviewWidget(providerId: widget.providerId),
                      SizedBox(height: 16.h),
                      MissionsOverviewWidget(providerId: widget.providerId),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 1,
                  child: RecentActivitiesWidget(providerId: widget.providerId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsTab() {
    return AppsOverviewWidget(providerId: widget.providerId, isFullView: true);
  }

  Widget _buildMissionsTab() {
    return MissionsOverviewWidget(providerId: widget.providerId, isFullView: true);
  }

  Widget _buildBugReportsTab() {
    return BugReportsOverviewWidget(providerId: widget.providerId, isFullView: true);
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 분석',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Performance Metrics
          _buildPerformanceMetrics(),
          
          SizedBox(height: 24.h),
          
          // App Analytics
          _buildAppAnalytics(),
          
          SizedBox(height: 24.h),
          
          // Tester Analytics
          _buildTesterAnalytics(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final providerInfoAsync = ref.watch(providerInfoProvider(widget.providerId));
    
    return providerInfoAsync.when(
      data: (provider) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, ${provider?.companyName ?? '공급자'}님!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '오늘도 훌륭한 앱 테스트를 진행해보세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildProviderStatusChip(provider?.status),
                ],
              ),
            ),
            Icon(
              Icons.dashboard,
              size: 64.w,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildProviderStatusChip(status) {
    Color chipColor;
    String statusText;
    IconData statusIcon;
    
    switch (status?.name) {
      case 'approved':
        chipColor = Colors.green;
        statusText = '승인됨';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        chipColor = Colors.orange;
        statusText = '승인 대기';
        statusIcon = Icons.pending;
        break;
      case 'suspended':
        chipColor = Colors.red;
        statusText = '일시정지';
        statusIcon = Icons.pause_circle;
        break;
      default:
        chipColor = Colors.grey;
        statusText = '알 수 없음';
        statusIcon = Icons.help;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: chipColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16.w, color: chipColor),
          SizedBox(width: 6.w),
          Text(
            statusText,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider(widget.providerId));
    
    return dashboardStatsAsync.when(
      data: (stats) => Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '성과 지표',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ...stats.performanceMetrics.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatMetricName(entry.key)),
                      Text(
                        '${entry.value.toStringAsFixed(1)}${_getMetricUnit(entry.key)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      loading: () => const Card(child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAppAnalytics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱별 분석',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text('상세 앱 분석 차트가 여기에 표시됩니다.'),
            // TODO: Implement detailed app analytics charts
          ],
        ),
      ),
    );
  }

  Widget _buildTesterAnalytics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '테스터 분석',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text('테스터 활동 분석이 여기에 표시됩니다.'),
            // TODO: Implement tester analytics
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final currentTab = ref.watch(dashboardTabProvider);
    
    switch (currentTab) {
      case 1: // Apps tab
        return FloatingActionButton.extended(
          onPressed: () => _showCreateAppDialog(),
          icon: const Icon(Icons.add),
          label: const Text('새 앱'),
        );
      case 2: // Missions tab
        return FloatingActionButton.extended(
          onPressed: () => _showCreateMissionDialog(),
          icon: const Icon(Icons.add),
          label: const Text('새 미션'),
        );
      default:
        return FloatingActionButton(
          onPressed: () => _refreshData(),
          child: const Icon(Icons.refresh),
        );
    }
  }

  Widget _buildErrorWidget(String title, dynamic error) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMetricName(String key) {
    switch (key) {
      case 'missionCompletionRate':
        return '미션 완료율';
      case 'averageResponseTime':
        return '평균 응답 시간';
      case 'bugResolutionRate':
        return '버그 해결율';
      case 'recentActivityScore':
        return '활동 점수';
      default:
        return key;
    }
  }

  String _getMetricUnit(String key) {
    switch (key) {
      case 'missionCompletionRate':
      case 'bugResolutionRate':
        return '%';
      case 'averageResponseTime':
        return '시간';
      default:
        return '';
    }
  }

  Future<void> _refreshData() async {
    // Refresh all data
    ref.invalidate(dashboardStatsProvider(widget.providerId));
    ref.invalidate(providerAppsProvider(widget.providerId));
    ref.invalidate(providerMissionsProvider(widget.providerId));
    ref.invalidate(recentActivitiesProvider(widget.providerId));
  }

  void _showSettings() {
    // TODO: Navigate to settings page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정 페이지 준비 중입니다.')),
    );
  }

  void _showCreateAppDialog() {
    // TODO: Show create app dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('앱 생성 기능 준비 중입니다.')),
    );
  }

  void _showCreateMissionDialog() {
    // TODO: Show create mission dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('미션 생성 기능 준비 중입니다.')),
    );
  }
}