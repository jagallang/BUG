import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/provider_model.dart';
import '../../../../core/utils/logger.dart';

class AppsListWidget extends StatelessWidget {
  final List<AppModel> apps;
  final Function(AppModel)? onAppTap;
  final ScrollController? scrollController;

  const AppsListWidget({
    super.key,
    required this.apps,
    this.onAppTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return _buildAppItem(context, app);
      },
    );
  }

  Widget _buildAppItem(BuildContext context, AppModel app) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: _buildAppIcon(context, app),
        title: Text(
          app.appName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '버전 ${app.version ?? '1.0.0'} • ${app.category.name}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        trailing: _buildStatusChip(context, app.status),
        onTap: () {
          AppLogger.info('App tapped: ${app.appName}', 'AppsListWidget');
          onAppTap?.call(app);
        },
      ),
    );
  }

  Widget _buildAppIcon(BuildContext context, AppModel app) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: app.iconUrl != null && app.iconUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                app.iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.phone_android,
                  color: Colors.blue,
                  size: 24.sp,
                ),
              ),
            )
          : Icon(
              Icons.phone_android,
              color: Colors.blue,
              size: 24.sp,
            ),
    );
  }

  Widget _buildStatusChip(BuildContext context, AppStatus status) {
    final statusInfo = _getStatusInfo(status);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: statusInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: statusInfo['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusInfo['text'],
        style: TextStyle(
          color: statusInfo['color'],
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(AppStatus status) {
    switch (status) {
      case AppStatus.active:
        return {'color': Colors.green, 'text': '활성'};
      case AppStatus.review:
        return {'color': Colors.orange, 'text': '검토중'};
      case AppStatus.paused:
        return {'color': Colors.grey, 'text': '일시정지'};
      case AppStatus.draft:
        return {'color': Colors.blue, 'text': '초안'};
      case AppStatus.completed:
        return {'color': Colors.blue, 'text': '완료'};
      case AppStatus.cancelled:
        return {'color': Colors.red, 'text': '취소됨'};
    }
  }
}