import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/connection_status_widget.dart';
import '../../../../core/presentation/widgets/sync_management_widget.dart';
import '../../../missions/presentation/providers/offline_mission_provider.dart';
import '../../../missions/presentation/providers/realtime_mission_provider.dart';

class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const ConnectionStatusAppBar(
        title: 'Sync Settings',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Section
            _buildConnectionStatusSection(context, ref),
            
            const SizedBox(height: 20),
            
            // Sync Management Section
            const SyncManagementWidget(),
            
            const SizedBox(height: 20),
            
            // Auto-sync Settings
            _buildAutoSyncSettings(context, ref),
            
            const SizedBox(height: 20),
            
            // Data Usage Settings
            _buildDataUsageSettings(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusSection(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusNotifierProvider);
    final isConnected = connectionStatus['isConnected'] ?? false;
    final connectionType = connectionStatus['connectionType'] ?? 'unknown';
    final lastConnectedAt = connectionStatus['lastConnectedAt'];
    final reconnectAttempts = connectionStatus['reconnectAttempts'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.signal_wifi_4_bar, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Connection Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const ConnectionStatusWidget(),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusDetailRow(
              'Status',
              isConnected ? 'Connected' : 'Disconnected',
              isConnected ? Colors.green : Colors.red,
            ),
            _buildStatusDetailRow(
              'Connection Type',
              connectionType.toUpperCase(),
              Colors.blue,
            ),
            if (reconnectAttempts > 0)
              _buildStatusDetailRow(
                'Reconnect Attempts',
                reconnectAttempts.toString(),
                Colors.orange,
              ),
            if (lastConnectedAt != null)
              _buildStatusDetailRow(
                'Last Connected',
                _formatDateTime(lastConnectedAt),
                Colors.grey,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? null : () => _testConnection(ref),
                    icon: const Icon(Icons.network_check),
                    label: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 8),
                const NetworkQualityIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSyncSettings(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.autorenew, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Auto-sync Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-sync when connected'),
              subtitle: const Text('Automatically sync data when online'),
              value: true, // This would come from settings provider
              onChanged: (value) {
                // Handle auto-sync toggle
              },
            ),
            SwitchListTile(
              title: const Text('Sync on Wi-Fi only'),
              subtitle: const Text('Avoid mobile data usage for syncing'),
              value: false, // This would come from settings provider
              onChanged: (value) {
                // Handle Wi-Fi only toggle
              },
            ),
            SwitchListTile(
              title: const Text('Background sync'),
              subtitle: const Text('Sync data even when app is in background'),
              value: true, // This would come from settings provider
              onChanged: (value) {
                // Handle background sync toggle
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataUsageSettings(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.data_usage, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Cache Duration'),
              subtitle: const Text('How long to keep cached data'),
              trailing: DropdownButton<String>(
                value: '1 hour',
                items: const [
                  DropdownMenuItem(value: '30 minutes', child: Text('30 minutes')),
                  DropdownMenuItem(value: '1 hour', child: Text('1 hour')),
                  DropdownMenuItem(value: '6 hours', child: Text('6 hours')),
                  DropdownMenuItem(value: '1 day', child: Text('1 day')),
                ],
                onChanged: (value) {
                  // Handle cache duration change
                },
              ),
            ),
            ListTile(
              title: const Text('Max Cache Size'),
              subtitle: const Text('Maximum storage for cached data'),
              trailing: DropdownButton<String>(
                value: '50 MB',
                items: const [
                  DropdownMenuItem(value: '10 MB', child: Text('10 MB')),
                  DropdownMenuItem(value: '50 MB', child: Text('50 MB')),
                  DropdownMenuItem(value: '100 MB', child: Text('100 MB')),
                  DropdownMenuItem(value: '200 MB', child: Text('200 MB')),
                ],
                onChanged: (value) {
                  // Handle max cache size change
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cleanExpiredCache(ref),
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Clean Expired Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCacheInfo(context, ref),
                    icon: const Icon(Icons.info),
                    label: const Text('Cache Info'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testConnection(WidgetRef ref) {
    final connectionNotifier = ref.read(connectionStatusNotifierProvider.notifier);
    connectionNotifier.checkConnection();
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('Testing connection...')),
    );
  }

  void _cleanExpiredCache(WidgetRef ref) {
    final cache = ref.read(offlineDataCacheProvider);
    cache.cleanExpiredCache();
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('Expired cache cleaned')),
    );
  }

  void _showCacheInfo(BuildContext context, WidgetRef ref) {
    final cacheInfoAsync = ref.watch(cacheInfoProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Information'),
        content: cacheInfoAsync.when(
          data: (cacheInfo) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Total Items', cacheInfo['totalItems']?.toString() ?? '0'),
              _buildInfoRow('Valid Items', cacheInfo['validItems']?.toString() ?? '0'),
              _buildInfoRow('Expired Items', cacheInfo['expiredItems']?.toString() ?? '0'),
              _buildInfoRow('Memory Items', cacheInfo['memoryItems']?.toString() ?? '0'),
              _buildInfoRow('Total Size', '${cacheInfo['estimatedSizeKB'] ?? 0} KB'),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load cache info'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}';
  }
}