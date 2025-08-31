import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/logger.dart';

enum SyncOperation {
  create,
  update,
  delete,
}

enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
  conflict,
}

class PendingSyncItem {
  final String id;
  final String collection;
  final String? documentId;
  final Map<String, dynamic> data;
  final SyncOperation operation;
  final DateTime timestamp;
  final int retryCount;
  final SyncStatus status;
  final String? error;

  PendingSyncItem({
    required this.id,
    required this.collection,
    this.documentId,
    required this.data,
    required this.operation,
    required this.timestamp,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection': collection,
      'documentId': documentId,
      'data': data,
      'operation': operation.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'status': status.name,
      'error': error,
    };
  }

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) {
    return PendingSyncItem(
      id: json['id'],
      collection: json['collection'],
      documentId: json['documentId'],
      data: Map<String, dynamic>.from(json['data']),
      operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
      error: json['error'],
    );
  }

  PendingSyncItem copyWith({
    String? id,
    String? collection,
    String? documentId,
    Map<String, dynamic>? data,
    SyncOperation? operation,
    DateTime? timestamp,
    int? retryCount,
    SyncStatus? status,
    String? error,
  }) {
    return PendingSyncItem(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      documentId: documentId ?? this.documentId,
      data: data ?? this.data,
      operation: operation ?? this.operation,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

class OfflineSyncService {
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final String _syncQueueKey = 'offline_sync_queue';
  final String _lastSyncKey = 'last_sync_timestamp';
  final int _maxRetries = 5;
  final Duration _retryDelay = const Duration(seconds: 30);

  static OfflineSyncService? _instance;
  static OfflineSyncService get instance => _instance ??= OfflineSyncService._internal();

  OfflineSyncService._internal()
      : _firestore = FirebaseFirestore.instance,
        _connectivity = Connectivity();

  Timer? _syncTimer;
  final StreamController<List<PendingSyncItem>> _syncQueueController =
      StreamController<List<PendingSyncItem>>.broadcast();
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  Stream<List<PendingSyncItem>> get syncQueueStream => _syncQueueController.stream;
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Initialize offline sync service
  Future<void> initialize() async {
    await _loadPendingSyncItems();
    _startPeriodicSync();
    _listenToConnectivityChanges();
    AppLogger.info('Offline sync service initialized', 'OfflineSyncService');
  }

  // Add item to sync queue
  Future<void> addToSyncQueue({
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  }) async {
    final item = PendingSyncItem(
      id: _generateSyncId(),
      collection: collection,
      documentId: documentId,
      data: data,
      operation: operation,
      timestamp: DateTime.now(),
    );

    final items = await _getPendingSyncItems();
    items.add(item);
    await _savePendingSyncItems(items);

    _syncQueueController.add(items);
    AppLogger.info('Added item to sync queue: ${item.id}', 'OfflineSyncService');

    // Try immediate sync if online
    if (await _isConnected()) {
      _processSyncQueue();
    }
  }

  // Process sync queue
  Future<void> _processSyncQueue() async {
    if (!await _isConnected()) {
      AppLogger.warning('Device offline, skipping sync', 'OfflineSyncService');
      return;
    }

    _syncStatusController.add(SyncStatus.syncing);
    final items = await _getPendingSyncItems();
    final pendingItems = items.where((item) => 
        item.status == SyncStatus.pending || 
        (item.status == SyncStatus.failed && item.retryCount < _maxRetries)
    ).toList();

    if (pendingItems.isEmpty) {
      _syncStatusController.add(SyncStatus.completed);
      return;
    }

    AppLogger.info('Processing ${pendingItems.length} pending sync items', 'OfflineSyncService');

    for (final item in pendingItems) {
      try {
        await _syncItem(item);
        
        // Update item status
        final updatedItem = item.copyWith(
          status: SyncStatus.completed,
        );
        await _updateSyncItem(updatedItem);

        AppLogger.info('Successfully synced item: ${item.id}', 'OfflineSyncService');
      } catch (e) {
        AppLogger.error('Failed to sync item ${item.id}', 'OfflineSyncService', e);
        
        // Update retry count and status
        final updatedItem = item.copyWith(
          status: item.retryCount >= _maxRetries ? SyncStatus.failed : SyncStatus.pending,
          retryCount: item.retryCount + 1,
          error: e.toString(),
        );
        await _updateSyncItem(updatedItem);
      }
    }

    // Clean up completed items
    await _cleanupCompletedItems();
    _syncStatusController.add(SyncStatus.completed);
    
    // Update last sync timestamp
    await _updateLastSyncTimestamp();
  }

  // Sync individual item
  Future<void> _syncItem(PendingSyncItem item) async {
    final collectionRef = _firestore.collection(item.collection);

    switch (item.operation) {
      case SyncOperation.create:
        if (item.documentId != null) {
          await collectionRef.doc(item.documentId).set(item.data);
        } else {
          await collectionRef.add(item.data);
        }
        break;

      case SyncOperation.update:
        if (item.documentId == null) {
          throw Exception('Document ID required for update operation');
        }
        await collectionRef.doc(item.documentId).update(item.data);
        break;

      case SyncOperation.delete:
        if (item.documentId == null) {
          throw Exception('Document ID required for delete operation');
        }
        await collectionRef.doc(item.documentId).delete();
        break;
    }
  }

  // Update sync item
  Future<void> _updateSyncItem(PendingSyncItem updatedItem) async {
    final items = await _getPendingSyncItems();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      items[index] = updatedItem;
      await _savePendingSyncItems(items);
      _syncQueueController.add(items);
    }
  }

  // Clean up completed sync items
  Future<void> _cleanupCompletedItems() async {
    final items = await _getPendingSyncItems();
    final activeItems = items.where((item) => 
        item.status != SyncStatus.completed
    ).toList();
    
    if (activeItems.length != items.length) {
      await _savePendingSyncItems(activeItems);
      _syncQueueController.add(activeItems);
      AppLogger.info('Cleaned up ${items.length - activeItems.length} completed sync items', 'OfflineSyncService');
    }
  }

  // Get pending sync items from storage
  Future<List<PendingSyncItem>> _getPendingSyncItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_syncQueueKey);
      
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => PendingSyncItem.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to load pending sync items', 'OfflineSyncService', e);
      return [];
    }
  }

  // Save pending sync items to storage
  Future<void> _savePendingSyncItems(List<PendingSyncItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(items.map((item) => item.toJson()).toList());
      await prefs.setString(_syncQueueKey, jsonString);
    } catch (e) {
      AppLogger.error('Failed to save pending sync items', 'OfflineSyncService', e);
    }
  }

  // Load pending sync items on initialization
  Future<void> _loadPendingSyncItems() async {
    final items = await _getPendingSyncItems();
    _syncQueueController.add(items);
  }

  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _processSyncQueue();
    });
  }

  // Listen to connectivity changes
  void _listenToConnectivityChanges() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final isConnected = result != ConnectivityResult.none;
      
      if (isConnected) {
        AppLogger.info('Connection restored, processing sync queue', 'OfflineSyncService');
        _processSyncQueue();
      } else {
        AppLogger.info('Connection lost, sync will resume when online', 'OfflineSyncService');
      }
    });
  }

  // Check connection status
  Future<bool> _isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  // Generate unique sync ID
  String _generateSyncId() {
    return 'sync_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Get sync queue status
  Future<Map<String, int>> getSyncQueueStatus() async {
    final items = await _getPendingSyncItems();
    final status = <String, int>{};
    
    for (final syncStatus in SyncStatus.values) {
      status[syncStatus.name] = items.where((item) => item.status == syncStatus).length;
    }
    
    return status;
  }

  // Force sync now
  Future<void> forceSyncNow() async {
    AppLogger.info('Force sync requested', 'OfflineSyncService');
    await _processSyncQueue();
  }

  // Clear failed items
  Future<void> clearFailedItems() async {
    final items = await _getPendingSyncItems();
    final activeItems = items.where((item) => item.status != SyncStatus.failed).toList();
    
    if (activeItems.length != items.length) {
      await _savePendingSyncItems(activeItems);
      _syncQueueController.add(activeItems);
      AppLogger.info('Cleared ${items.length - activeItems.length} failed sync items', 'OfflineSyncService');
    }
  }

  // Retry failed items
  Future<void> retryFailedItems() async {
    final items = await _getPendingSyncItems();
    final retryItems = items.map((item) {
      if (item.status == SyncStatus.failed) {
        return item.copyWith(
          status: SyncStatus.pending,
          retryCount: 0,
          error: null,
        );
      }
      return item;
    }).toList();

    await _savePendingSyncItems(retryItems);
    _syncQueueController.add(retryItems);
    
    // Process sync queue
    await _processSyncQueue();
    
    AppLogger.info('Retrying failed sync items', 'OfflineSyncService');
  }

  // Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncQueueController.close();
    _syncStatusController.close();
    AppLogger.info('Offline sync service disposed', 'OfflineSyncService');
  }
}