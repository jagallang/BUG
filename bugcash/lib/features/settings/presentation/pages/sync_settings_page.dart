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
        title: '동기화 설정',
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
            const Row(
              children: [
                Icon(Icons.signal_wifi_4_bar, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '연결 상태',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                ConnectionStatusWidget(),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusDetailRow(
              '상태',
              isConnected ? '연결됨' : '연결 안됨',
              isConnected ? Colors.green : Colors.red,
            ),
            _buildStatusDetailRow(
              '연결 타입',
              connectionType.toUpperCase(),
              Colors.blue,
            ),
            if (reconnectAttempts > 0)
              _buildStatusDetailRow(
                '재연결 시도',
                reconnectAttempts.toString(),
                Colors.orange,
              ),
            if (lastConnectedAt != null)
              _buildStatusDetailRow(
                '마지막 연결',
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
                    label: const Text('연결 테스트'),
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
                  '자동 동기화 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('연결 시 자동 동기화'),
              subtitle: const Text('온라인 상태일 때 자동으로 데이터 동기화'),
              value: true, // This would come from settings provider
              onChanged: (value) {
                // Handle auto-sync toggle
              },
            ),
            SwitchListTile(
              title: const Text('Wi-Fi에서만 동기화'),
              subtitle: const Text('동기화 시 모바일 데이터 사용 방지'),
              value: false, // This would come from settings provider
              onChanged: (value) {
                // Handle Wi-Fi only toggle
              },
            ),
            SwitchListTile(
              title: const Text('백그라운드 동기화'),
              subtitle: const Text('앱이 백그라운드에서도 데이터 동기화'),
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
                  '데이터 관리',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('캐시 유지 기간'),
              subtitle: const Text('캐시된 데이터를 보관하는 기간'),
              trailing: DropdownButton<String>(
                value: '1시간',
                items: const [
                  DropdownMenuItem(value: '30분', child: Text('30분')),
                  DropdownMenuItem(value: '1시간', child: Text('1시간')),
                  DropdownMenuItem(value: '6시간', child: Text('6시간')),
                  DropdownMenuItem(value: '1일', child: Text('1일')),
                ],
                onChanged: (value) {
                  // Handle cache duration change
                },
              ),
            ),
            ListTile(
              title: const Text('최대 캐시 크기'),
              subtitle: const Text('캐시된 데이터의 최대 저장 용량'),
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
                    label: const Text('만료된 캐시 정리'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCacheInfo(context, ref),
                    icon: const Icon(Icons.info),
                    label: const Text('캐시 정보'),
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
      const SnackBar(content: Text('연결을 테스트 중입니다...')),
    );
  }

  void _cleanExpiredCache(WidgetRef ref) {
    final cache = ref.read(offlineDataCacheProvider);
    cache.cleanExpiredCache();
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('만료된 캐시가 정리되었습니다')),
    );
  }

  void _showCacheInfo(BuildContext context, WidgetRef ref) {
    final cacheInfoAsync = ref.watch(cacheInfoProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐시 정보'),
        content: cacheInfoAsync.when(
          data: (cacheInfo) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('전체 항목', cacheInfo['totalItems']?.toString() ?? '0'),
              _buildInfoRow('유효 항목', cacheInfo['validItems']?.toString() ?? '0'),
              _buildInfoRow('만료 항목', cacheInfo['expiredItems']?.toString() ?? '0'),
              _buildInfoRow('메모리 항목', cacheInfo['memoryItems']?.toString() ?? '0'),
              _buildInfoRow('전체 크기', '${cacheInfo['estimatedSizeKB'] ?? 0} KB'),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('캐시 정보를 불러올 수 없습니다'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
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