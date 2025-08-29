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
                  'Sync Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showSyncManagementDialog(context, ref),
                  icon: const Icon(Icons.settings),
                  tooltip: 'Sync Settings',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sync Queue Status
            syncQueueAsync.when(
              data: (syncQueue) => _buildSyncQueueStatus(context, syncQueue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load sync status'),
            ),
            
            const SizedBox(height: 16),
            
            // Cache Info
            cacheInfoAsync.when(
              data: (cacheInfo) => _buildCacheInfo(context, cacheInfo),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load cache info'),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _forceSyncNow(ref),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _clearCache(context, ref),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Cache'),
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
          Text('All data synced', style: TextStyle(color: Colors.green)),
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
            text: '$pendingCount items pending',
          ),
        if (syncingCount > 0)
          _buildStatusRow(
            icon: Icons.sync,
            color: Colors.blue,
            text: '$syncingCount items syncing',
          ),
        if (failedCount > 0)
          _buildStatusRow(
            icon: Icons.error,
            color: Colors.red,
            text: '$failedCount items failed',
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
          'Cache Status',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCacheStatItem('Total Items', totalItems.toString()),
            _buildCacheStatItem('Valid', validItems.toString()),
            _buildCacheStatItem('Expired', expiredItems.toString()),
            _buildCacheStatItem('Size', '${sizeKB}KB'),
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
      const SnackBar(content: Text('Sync started...')),
    );
  }

  void _clearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached data. You may experience slower loading times until data is cached again. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final cache = ref.read(offlineDataCacheProvider);
              await cache.clearAllCache();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
            child: const Text('Clear'),
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
      title: const Text('Sync Management'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            syncQueueAsync.when(
              data: (syncQueue) => _buildSyncItemsList(context, ref, syncQueue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load sync items'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (syncQueueAsync.hasValue && syncQueueAsync.value!.any((item) => item.status == SyncStatus.failed))
          ElevatedButton(
            onPressed: () => _retryFailedItems(ref),
            child: const Text('Retry Failed'),
          ),
      ],
    );
  }

  Widget _buildSyncItemsList(BuildContext context, WidgetRef ref, List<PendingSyncItem> syncQueue) {
    if (syncQueue.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No pending sync items'),
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
            item.documentId ?? 'New document',
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
              tooltip: 'Retry',
            )
          : null,
    );
  }

  void _retryFailedItems(WidgetRef ref) {
    final syncService = ref.read(offlineMissionSyncProvider);
    syncService.retryFailedItems();
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('Retrying failed items...')),
    );
  }

  void _retrySingleItem(WidgetRef ref, String itemId) {
    // Implementation for retrying single item would need to be added to the service
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('Retry functionality coming soon')),
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
            tooltip: '$failedCount sync failures',
          );
        } else if (pendingCount > 0) {
          return IconButton(
            icon: Badge(
              label: Text(pendingCount.toString()),
              child: const Icon(Icons.sync_disabled, color: Colors.orange),
            ),
            onPressed: () => _showQuickSyncDialog(context, ref),
            tooltip: '$pendingCount pending sync items',
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