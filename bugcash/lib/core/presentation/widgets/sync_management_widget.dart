import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/missions/presentation/providers/offline_mission_provider.dart';
import '../../../core/data/services/offline_sync_service.dart';

class SyncManagementWidget extends ConsumerWidget {
  const SyncManagementWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncQueueAsync = ref.watch(syncQueueStatusProvider);
    final cacheInfoAsync = ref.watch(cacheInfoProvider);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '동기화 관리',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showSyncManagementDialog(context, ref),
                  icon: const Icon(Icons.settings),
                  tooltip: '동기화 설정',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sync Queue Status
            syncQueueAsync.when(
              data: (syncQueue) => _buildSyncQueueStatus(context, syncQueue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('동기화 상태를 불러올 수 없습니다'),
            ),
            
            const SizedBox(height: 16),
            
            // Cache Info
            cacheInfoAsync.when(
              data: (cacheInfo) => _buildCacheInfo(context, cacheInfo),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('캐시 정보를 불러올 수 없습니다'),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _forceSyncNow(ref),
                    icon: const Icon(Icons.sync),
                    label: const Text('지금 동기화'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _clearCache(context, ref),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('캐시 삭제'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncQueueStatus(BuildContext context, List<PendingSyncItem> syncQueue) {
    if (syncQueue.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text('모든 데이터가 동기화되었습니다', style: TextStyle(color: Colors.green)),
        ],
      );
    }

    final pendingCount = syncQueue.where((item) => item.status == SyncStatus.pending).length;
    final failedCount = syncQueue.where((item) => item.status == SyncStatus.failed).length;
    final syncingCount = syncQueue.where((item) => item.status == SyncStatus.syncing).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingCount > 0)
          _buildStatusRow(
            icon: Icons.schedule,
            color: Colors.orange,
            text: '$pendingCount개 항목 대기중',
          ),
        if (syncingCount > 0)
          _buildStatusRow(
            icon: Icons.sync,
            color: Colors.blue,
            text: '$syncingCount개 항목 동기화중',
          ),
        if (failedCount > 0)
          _buildStatusRow(
            icon: Icons.error,
            color: Colors.red,
            text: '$failedCount개 항목 실패',
          ),
      ],
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCacheInfo(BuildContext context, Map<String, dynamic> cacheInfo) {
    final totalItems = cacheInfo['totalItems'] ?? 0;
    final validItems = cacheInfo['validItems'] ?? 0;
    final expiredItems = cacheInfo['expiredItems'] ?? 0;
    final sizeKB = cacheInfo['estimatedSizeKB'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '캐시 상태',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCacheStatItem('전체 항목', totalItems.toString()),
            _buildCacheStatItem('유효', validItems.toString()),
            _buildCacheStatItem('만료', expiredItems.toString()),
            _buildCacheStatItem('크기', '${sizeKB}KB'),
          ],
        ),
      ],
    );
  }

  Widget _buildCacheStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _forceSyncNow(WidgetRef ref) {
    final syncService = ref.read(offlineMissionSyncProvider);
    syncService.forceSyncNow();
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('동기화를 시작합니다...')),
    );
  }

  void _clearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text(
          '모든 캐시된 데이터가 삭제됩니다. 데이터가 다시 캐시될 때까지 로딩 시간이 길어질 수 있습니다. 계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final cache = ref.read(offlineDataCacheProvider);
              await cache.clearAllCache();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('캐시가 삭제되었습니다')),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showSyncManagementDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const SyncManagementDialog(),
    );
  }
}

class SyncManagementDialog extends ConsumerWidget {
  const SyncManagementDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncQueueAsync = ref.watch(syncQueueStatusProvider);
    
    return AlertDialog(
      title: const Text('동기화 관리'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            syncQueueAsync.when(
              data: (syncQueue) => _buildSyncItemsList(context, ref, syncQueue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('동기화 항목을 불러올 수 없습니다'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        if (syncQueueAsync.hasValue && syncQueueAsync.value!.any((item) => item.status == SyncStatus.failed))
          ElevatedButton(
            onPressed: () => _retryFailedItems(ref),
            child: const Text('실패한 항목 재시도'),
          ),
      ],
    );
  }

  Widget _buildSyncItemsList(BuildContext context, WidgetRef ref, List<PendingSyncItem> syncQueue) {
    if (syncQueue.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('대기 중인 동기화 항목이 없습니다'),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: syncQueue.length,
        itemBuilder: (context, index) {
          final item = syncQueue[index];
          return _buildSyncItemTile(context, ref, item);
        },
      ),
    );
  }

  Widget _buildSyncItemTile(BuildContext context, WidgetRef ref, PendingSyncItem item) {
    IconData statusIcon;
    Color statusColor;
    
    switch (item.status) {
      case SyncStatus.pending:
        statusIcon = Icons.schedule;
        statusColor = Colors.orange;
        break;
      case SyncStatus.syncing:
        statusIcon = Icons.sync;
        statusColor = Colors.blue;
        break;
      case SyncStatus.completed:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case SyncStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
      case SyncStatus.conflict:
        statusIcon = Icons.warning;
        statusColor = Colors.purple;
        break;
    }

    return ListTile(
      dense: true,
      leading: Icon(statusIcon, color: statusColor, size: 20),
      title: Text(
        '${item.operation.name.toUpperCase()} ${item.collection}',
        style: const TextStyle(fontSize: 12),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.documentId ?? '새 문서',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          if (item.error != null)
            Text(
              item.error!,
              style: const TextStyle(fontSize: 10, color: Colors.red),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: item.status == SyncStatus.failed
          ? IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: () => _retrySingleItem(ref, item.id),
              tooltip: '재시도',
            )
          : null,
    );
  }

  void _retryFailedItems(WidgetRef ref) {
    final syncService = ref.read(offlineMissionSyncProvider);
    syncService.retryFailedItems();
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('실패한 항목을 재시도합니다...')),
    );
  }

  void _retrySingleItem(WidgetRef ref, String itemId) {
    // Implementation for retrying single item would need to be added to the service
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('재시도 기능이 곧 제공됩니다')),
    );
  }
}

// Quick sync status widget for app bars
class QuickSyncStatus extends ConsumerWidget {
  const QuickSyncStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncQueueAsync = ref.watch(syncQueueStatusProvider);
    
    return syncQueueAsync.when(
      data: (syncQueue) {
        if (syncQueue.isEmpty) return const SizedBox.shrink();
        
        final failedCount = syncQueue.where((item) => item.status == SyncStatus.failed).length;
        final pendingCount = syncQueue.where((item) => item.status == SyncStatus.pending).length;
        
        if (failedCount > 0) {
          return IconButton(
            icon: Badge(
              label: Text(failedCount.toString()),
              child: const Icon(Icons.sync_problem, color: Colors.red),
            ),
            onPressed: () => _showQuickSyncDialog(context, ref),
            tooltip: '동기화 실패 $failedCount개',
          );
        } else if (pendingCount > 0) {
          return IconButton(
            icon: Badge(
              label: Text(pendingCount.toString()),
              child: const Icon(Icons.sync_disabled, color: Colors.orange),
            ),
            onPressed: () => _showQuickSyncDialog(context, ref),
            tooltip: '대기 중인 동기화 항목 $pendingCount개',
          );
        }
        
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showQuickSyncDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const SyncManagementDialog(),
    );
  }
}