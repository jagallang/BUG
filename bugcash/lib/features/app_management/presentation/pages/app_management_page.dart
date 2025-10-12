import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../providers/app_management_provider.dart';
import '../widgets/app_card_widget.dart';
import '../widgets/app_deletion_dialog.dart';
import '../../domain/entities/provider_app_entity.dart';

class AppManagementPage extends ConsumerStatefulWidget {
  final String providerId;

  const AppManagementPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<AppManagementPage> createState() => _AppManagementPageState();
}

class _AppManagementPageState extends ConsumerState<AppManagementPage> {
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final appsAsyncValue = ref.watch(providerAppsStreamProvider(widget.providerId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '앱 관리',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateAppDialog,
            icon: Icon(
              Icons.add,
              color: Colors.white,
              size: 24.sp,
            ),
            tooltip: '새 앱 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: appsAsyncValue.when(
              data: (apps) => _buildAppsList(apps),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: '카테고리',
                  value: _selectedCategory,
                  items: [
                    {'value': 'all', 'label': '전체'},
                    {'value': 'productivity', 'label': '생산성'},
                    {'value': 'entertainment', 'label': '엔터테인먼트'},
                    {'value': 'education', 'label': '교육'},
                    {'value': 'lifestyle', 'label': '라이프스타일'},
                    {'value': 'business', 'label': '비즈니스'},
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildFilterDropdown(
                  label: '상태',
                  value: _selectedStatus,
                  items: [
                    {'value': 'all', 'label': '전체'},
                    {'value': 'draft', 'label': '초안'},
                    {'value': 'pending', 'label': '검토중'},
                    {'value': 'open', 'label': '활성'},
                    {'value': 'closed', 'label': '종료'},
                    {'value': 'rejected', 'label': '거부됨'},
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(
                    item['label']!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppsList(List<ProviderAppEntity> apps) {
    final filteredApps = _filterApps(apps);

    if (filteredApps.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final app = filteredApps[index];
        return AppCardWidget(
          app: app,
          onTap: () => _navigateToAppDetail(app),
          onEdit: () => _showEditAppDialog(app),
          onDelete: () => _showDeleteConfirmation(app),
        );
      },
    );
  }

  List<ProviderAppEntity> _filterApps(List<ProviderAppEntity> apps) {
    return apps.where((app) {
      final categoryMatch = _selectedCategory == 'all' || app.category == _selectedCategory;
      final statusMatch = _selectedStatus == 'all' || app.status == _selectedStatus;
      return categoryMatch && statusMatch;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            '등록된 앱이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '첫 번째 앱을 추가해보세요!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _showCreateAppDialog,
            icon: Icon(Icons.add, size: 20.sp),
            label: Text(
              '앱 추가',
              style: TextStyle(fontSize: 14.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            '데이터를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              '다시 시도',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAppDetail(ProviderAppEntity app) {
    AppLogger.info('Navigating to app detail: ${app.appName}', 'AppManagementPage');
    // TODO: Navigate to app detail page
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => AppDetailPage(app: app),
    //   ),
    // );
  }

  void _showCreateAppDialog() {
    AppLogger.info('Opening create app dialog', 'AppManagementPage');
    // TODO: Implement create app dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('앱 추가 기능을 준비 중입니다'),
      ),
    );
  }

  void _showEditAppDialog(ProviderAppEntity app) {
    AppLogger.info('Opening edit app dialog for: ${app.appName}', 'AppManagementPage');
    // TODO: Implement edit app dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${app.appName} 편집 기능을 준비 중입니다'),
      ),
    );
  }

  void _showDeleteConfirmation(ProviderAppEntity app) {
    showDialog(
      context: context,
      builder: (context) => AppDeletionDialog(
        appName: app.appName,
        onConfirm: () => _deleteApp(app),
      ),
    );
  }

  Future<void> _deleteApp(ProviderAppEntity app) async {
    AppLogger.info('Deleting app: ${app.appName}', 'AppManagementPage');

    final success = await ref.read(appManagementProvider.notifier).deleteApp(app.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${app.appName}이(가) 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(appManagementProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: ${error ?? "알 수 없는 오류"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}