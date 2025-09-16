import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/provider_dashboard_provider.dart';
import '../../../../models/mission_model.dart';

class MissionsOverviewWidget extends ConsumerWidget {
  final String providerId;
  final bool isFullView;

  const MissionsOverviewWidget({
    super.key,
    required this.providerId,
    this.isFullView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(providerMissionsProvider(providerId));
    final missionFilter = ref.watch(missionFilterProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            SizedBox(height: 16.h),
            if (isFullView) _buildFilterChips(context, ref, missionFilter),
            if (isFullView) SizedBox(height: 16.h),
            _buildMissionsList(context, missionsAsync, isFullView),
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
          isFullView ? '미션 관리' : '미션 개요',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!isFullView)
          TextButton(
            onPressed: () {
              // Navigate to full view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('미션 관리 페이지로 이동합니다.')),
              );
            },
            child: const Text('더보기'),
          ),
        if (isFullView)
          ElevatedButton.icon(
            onPressed: () => _showCreateMissionDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('새 미션'),
          ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, String? currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '전체',
            isSelected: currentFilter == null,
            onTap: () => ref.read(missionFilterProvider.notifier).state = null,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '활성',
            isSelected: currentFilter == 'active',
            onTap: () => ref.read(missionFilterProvider.notifier).state = 'active',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '완료',
            isSelected: currentFilter == 'completed',
            onTap: () => ref.read(missionFilterProvider.notifier).state = 'completed',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '일시정지',
            isSelected: currentFilter == 'paused',
            onTap: () => ref.read(missionFilterProvider.notifier).state = 'paused',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '만료',
            isSelected: currentFilter == 'expired',
            onTap: () => ref.read(missionFilterProvider.notifier).state = 'expired',
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

  Widget _buildMissionsList(BuildContext context, AsyncValue<List<MissionModel>> missionsAsync, bool showAll) {
    return missionsAsync.when(
      data: (missions) {
        final displayMissions = showAll ? missions : missions.take(3).toList();
        
        if (displayMissions.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: displayMissions.map((mission) => _buildMissionItem(context, mission)).toList(),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(context, error),
    );
  }

  Widget _buildMissionItem(BuildContext context, MissionModel mission) {
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
              // Mission Type Icon
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.assignment,
                  color: Colors.blue,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      mission.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildMissionStatusChip(context, mission.status),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildStatItem(
                context: context,
                icon: Icons.monetization_on,
                label: '포인트',
                value: '100',
                color: Colors.green,
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                context: context,
                icon: Icons.people,
                label: '참여자',
                value: '10',
                color: Colors.blue,
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                context: context,
                icon: Icons.schedule,
                label: '기한',
                value: _formatDeadline(mission.createdAt?.add(const Duration(days: 30)) ?? DateTime.now().add(const Duration(days: 30))),
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
                  onPressed: () => _viewMissionDetails(context, mission),
                  icon: const Icon(Icons.visibility),
                  label: const Text('상세보기'),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => _editMission(context, mission),
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

  Widget _buildMissionStatusChip(BuildContext context, String status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case 'active':
        chipColor = Colors.green;
        statusText = '활성';
        break;
      case 'completed':
        chipColor = Colors.blue;
        statusText = '완료';
        break;
      case 'paused':
        chipColor = Colors.orange;
        statusText = '일시정지';
        break;
      case 'expired':
        chipColor = Colors.red;
        statusText = '만료';
        break;
      case 'draft':
        chipColor = Colors.grey;
        statusText = '초안';
        break;
      default:
        chipColor = Colors.grey;
        statusText = '알 수 없음';
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

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    
    if (difference < 0) {
      return '만료됨';
    } else if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '내일';
    } else if (difference < 7) {
      return '$difference일 남음';
    } else {
      return '${difference ~/ 7}주 남음';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 32.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              '미션이 없습니다',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade500,
              ),
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
              '미션 목록을 불러올 수 없습니다',
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

  void _viewMissionDetails(BuildContext context, MissionModel mission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mission.title} 상세정보를 확인합니다.')),
    );
  }

  void _editMission(BuildContext context, MissionModel mission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mission.title} 편집 페이지로 이동합니다.')),
    );
  }
}