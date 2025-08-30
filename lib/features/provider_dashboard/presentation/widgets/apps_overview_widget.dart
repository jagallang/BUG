import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';
import '../../domain/models/provider_model.dart';

class AppsOverviewWidget extends ConsumerWidget {
  final String providerId;
  final bool isFullView;

  const AppsOverviewWidget({
    super.key,
    required this.providerId,
    this.isFullView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(providerAppsProvider(providerId));
    final appFilter = ref.watch(appFilterProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            SizedBox(height: 16.h),
            if (isFullView) _buildFilterChips(context, ref, appFilter),
            if (isFullView) SizedBox(height: 16.h),
            _buildAppsList(context, appsAsync, isFullView),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isFullView ? '앱 관리' : '앱 개요',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!isFullView)
          TextButton(
            onPressed: () {
              // Navigate to full view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('앱 관리 페이지로 이동합니다.')),
              );
            },
            child: const Text('더보기'),
          ),
        if (isFullView)
          ElevatedButton.icon(
            onPressed: () => _showCreateAppDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('새 앱'),
          ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, AppStatus? currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '전체',
            isSelected: currentFilter == null,
            onTap: () => ref.read(appFilterProvider.notifier).state = null,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '활성',
            isSelected: currentFilter == AppStatus.active,
            onTap: () => ref.read(appFilterProvider.notifier).state = AppStatus.active,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '일시정지',
            isSelected: currentFilter == AppStatus.paused,
            onTap: () => ref.read(appFilterProvider.notifier).state = AppStatus.paused,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '검토중',
            isSelected: currentFilter == AppStatus.review,
            onTap: () => ref.read(appFilterProvider.notifier).state = AppStatus.review,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '완료',
            isSelected: currentFilter == AppStatus.completed,
            onTap: () => ref.read(appFilterProvider.notifier).state = AppStatus.completed,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildAppsList(BuildContext context, AsyncValue<List<AppModel>> appsAsync, bool showAll) {
    return appsAsync.when(
      data: (apps) {
        final displayApps = showAll ? apps : apps.take(3).toList();
        
        if (displayApps.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: displayApps.map((app) => _buildAppItem(context, app)).toList(),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(context, error),
    );
  }

  Widget _buildAppItem(BuildContext context, AppModel app) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // App Icon
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: app.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          app.iconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.apps,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24.w,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.apps,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24.w,
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      app.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildAppStatusChip(context, app.status),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildStatItem(
                context: context,
                icon: Icons.assignment,
                label: '미션',
                value: '${app.totalMissions}',
                color: Colors.blue,
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                context: context,
                icon: Icons.people,
                label: '테스터',
                value: '${app.totalTesters}',
                color: Colors.green,
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                context: context,
                icon: Icons.star,
                label: '평점',
                value: app.averageRating.toStringAsFixed(1),
                color: Colors.orange,
              ),
            ],
          ),
          if (isFullView) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewAppDetails(context, app),
                  icon: const Icon(Icons.visibility),
                  label: const Text('상세보기'),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => _editApp(context, app),
                  icon: const Icon(Icons.edit),
                  label: const Text('편집'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppStatusChip(BuildContext context, AppStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case AppStatus.active:
        chipColor = Colors.green;
        statusText = '활성';
        break;
      case AppStatus.paused:
        chipColor = Colors.orange;
        statusText = '일시정지';
        break;
      case AppStatus.review:
        chipColor = Colors.blue;
        statusText = '검토중';
        break;
      case AppStatus.completed:
        chipColor = Colors.purple;
        statusText = '완료';
        break;
      case AppStatus.cancelled:
        chipColor = Colors.red;
        statusText = '취소';
        break;
      case AppStatus.draft:
        chipColor = Colors.grey;
        statusText = '초안';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: color),
        SizedBox(width: 4.w),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(
              Icons.apps,
              size: 48.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              '등록된 앱이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '새로운 앱을 등록해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _showCreateAppDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('새 앱 등록'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              '앱 목록을 불러올 수 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터를 새로고침합니다.')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 앱 등록'),
        content: const Text('새 앱 등록 기능이 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _viewAppDetails(BuildContext context, AppModel app) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${app.appName} 상세정보를 확인합니다.')),
    );
  }

  void _editApp(BuildContext context, AppModel app) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${app.appName} 편집 페이지로 이동합니다.')),
    );
  }
}