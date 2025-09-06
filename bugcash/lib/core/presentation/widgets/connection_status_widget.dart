import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/missions/presentation/providers/realtime_mission_provider.dart';
import '../../../features/missions/presentation/providers/offline_mission_provider.dart';

class ConnectionStatusWidget extends ConsumerWidget {
  final bool showLabel;
  final Color? onlineColor;
  final Color? offlineColor;
  final Color? reconnectingColor;

  const ConnectionStatusWidget({
    Key? key,
    this.showLabel = true,
    this.onlineColor,
    this.offlineColor,
    this.reconnectingColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusNotifierProvider);
    
    final isConnected = connectionStatus['isConnected'] ?? false;
    final reconnectAttempts = connectionStatus['reconnectAttempts'] ?? 0;
    
    final isReconnecting = !isConnected && reconnectAttempts > 0;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isConnected) {
      statusColor = onlineColor ?? Colors.green;
      statusIcon = Icons.wifi;
      statusText = 'Online';
    } else if (isReconnecting) {
      statusColor = reconnectingColor ?? Colors.orange;
      statusIcon = Icons.wifi_off;
      statusText = 'Reconnecting...';
    } else {
      statusColor = offlineColor ?? Colors.red;
      statusIcon = Icons.wifi_off;
      statusText = 'Offline';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isReconnecting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ConnectionStatusBanner extends ConsumerWidget {
  const ConnectionStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusNotifierProvider);
    final isConnected = connectionStatus['isConnected'] ?? false;
    final reconnectAttempts = connectionStatus['reconnectAttempts'] ?? 0;
    
    // Only show banner when offline or reconnecting
    if (isConnected) {
      return const SizedBox.shrink();
    }
    
    final isReconnecting = reconnectAttempts > 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: isReconnecting ? Colors.orange : Colors.red,
      child: Row(
        children: [
          if (isReconnecting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReconnecting ? 'Reconnecting...' : 'You are offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (reconnectAttempts > 0)
                  Text(
                    'Attempt ${reconnectAttempts}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'Data will sync when connection is restored',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncQueueAsync = ref.watch(syncQueueStatusProvider);
    final syncStatusAsync = ref.watch(syncStatusProvider);
    
    return syncQueueAsync.when(
      data: (syncQueue) {
        final pendingCount = syncQueue.length;
        
        if (pendingCount == 0) {
          return const SizedBox.shrink();
        }
        
        return syncStatusAsync.when(
          data: (syncStatus) {
            Color statusColor;
            IconData statusIcon;
            String statusText;
            bool isAnimated = false;
            
            switch (syncStatus.name) {
              case 'syncing':
                statusColor = Colors.blue;
                statusIcon = Icons.sync;
                statusText = 'Syncing $pendingCount items...';
                isAnimated = true;
                break;
              case 'failed':
                statusColor = Colors.red;
                statusIcon = Icons.sync_problem;
                statusText = '$pendingCount items failed to sync';
                break;
              default:
                statusColor = Colors.orange;
                statusIcon = Icons.sync_disabled;
                statusText = '$pendingCount items pending sync';
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAnimated)
                    AnimatedRotation(
                      turns: 1.0,
                      duration: const Duration(seconds: 2),
                      child: Icon(
                        statusIcon,
                        size: 14,
                        color: statusColor,
                      ),
                    )
                  else
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class NetworkQualityIndicator extends ConsumerStatefulWidget {
  const NetworkQualityIndicator({Key? key}) : super(key: key);

  @override
  ConsumerState<NetworkQualityIndicator> createState() => _NetworkQualityIndicatorState();
}

class _NetworkQualityIndicatorState extends ConsumerState<NetworkQualityIndicator> {
  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusNotifierProvider);
    final isConnected = connectionStatus['isConnected'] ?? false;
    
    if (!isConnected) {
      return const SizedBox.shrink();
    }
    
    return Tooltip(
      message: 'Connected via Network',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.wifi,
          size: 16,
          color: Colors.green,
        ),
      ),
    );
  }
}

// Connection status app bar widget
class ConnectionStatusAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;

  const ConnectionStatusAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: Text(title),
          centerTitle: centerTitle,
          backgroundColor: backgroundColor,
          leading: leading,
          actions: [
            const ConnectionStatusWidget(showLabel: false),
            const SizedBox(width: 8),
            const NetworkQualityIndicator(),
            const SizedBox(width: 8),
            ...?actions,
          ],
        ),
        const ConnectionStatusBanner(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60); // Extra height for banner
}