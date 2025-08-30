import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickActionsState = ref.watch(quickActionsProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '빠른 작업',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildQuickActionGrid(context, ref, quickActionsState),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<void> quickActionsState,
  ) {
    final isLoading = quickActionsState.isLoading;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 2.5,
      children: [
        _buildQuickActionButton(
          context: context,
          icon: Icons.upload,
          label: '새 앱 등록',
          color: Colors.blue,
          isLoading: isLoading,
          onTap: () => _navigateToAppRegistration(context),
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.assignment_add,
          label: '새 미션 생성',
          color: Colors.green,
          isLoading: isLoading,
          onTap: () => _showCreateMissionDialog(context),
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.analytics,
          label: '통계 보기',
          color: Colors.orange,
          isLoading: isLoading,
          onTap: () => _navigateToAnalytics(context),
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.bug_report,
          label: '버그 리포트',
          color: Colors.red,
          isLoading: isLoading,
          onTap: () => _navigateToBugReports(context),
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.people,
          label: '테스터 관리',
          color: Colors.purple,
          isLoading: isLoading,
          onTap: () => _navigateToTesterManagement(context),
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.settings,
          label: '설정',
          color: Colors.grey,
          isLoading: isLoading,
          onTap: () => _navigateToSettings(context),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToAppRegistration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('앱 등록 페이지로 이동합니다.')),
    );
  }

  void _showCreateMissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 미션 생성'),
        content: const Text('새 미션 생성 기능이 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('통계 페이지로 이동합니다.')),
    );
  }

  void _navigateToBugReports(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('버그 리포트 페이지로 이동합니다.')),
    );
  }

  void _navigateToTesterManagement(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('테스터 관리 페이지로 이동합니다.')),
    );
  }

  void _navigateToSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정 페이지로 이동합니다.')),
    );
  }
}