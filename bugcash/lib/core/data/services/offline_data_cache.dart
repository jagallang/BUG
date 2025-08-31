import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';
import '../../../models/mission_model.dart';

class CacheItem<T> {
  final String key;
  final T data;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final String? etag;

  CacheItem({
    required this.key,
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
    this.etag,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': _serializeData(data),
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'etag': etag,
    };
  }

  factory CacheItem.fromJson(Map<String, dynamic> json, T Function(dynamic) deserializer) {
    return CacheItem<T>(
      key: json['key'],
      data: deserializer(json['data']),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt']),
      etag: json['etag'],
    );
  }

  dynamic _serializeData(T data) {
    if (data is MissionModel) {
      return data.toFirestore();
    } else if (data is List) {
      return data.map((item) => item is MissionModel ? item.toFirestore() : item).toList();
    } else if (data is Map) {
      return data;
    }
    return data;
  }
}

class OfflineDataCache {
  static const String _cachePrefix = 'offline_cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  static const int _maxCacheSize = 100; // Maximum number of cache items
  
  static OfflineDataCache? _instance;
  static OfflineDataCache get instance => _instance ??= OfflineDataCache._internal();
  
  OfflineDataCache._internal();

  final Map<String, dynamic> _memoryCache = {};
  final StreamController<String> _cacheUpdateController = 
      StreamController<String>.broadcast();

  Stream<String> get cacheUpdateStream => _cacheUpdateController.stream;

  // Cache missions data
  Future<void> cacheMissions(String key, List<MissionModel> missions, {Duration? duration}) async {
    await _cacheData(
      key,
      missions,
      duration ?? _defaultCacheDuration,
      _serializeMissions,
    );
  }

  // Get cached missions
  Future<List<MissionModel>?> getCachedMissions(String key) async {
    final data = await _getCachedData<List<dynamic>>(key, _deserializeToList);
    if (data == null) return null;
    
    try {
      return data.map((json) => _missionFromCachedData(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to deserialize cached missions', 'OfflineDataCache', e);
      await clearCache(key);
      return null;
    }
  }

  // Cache generic data
  Future<void> cacheData<T>(String key, T data, {Duration? duration}) async {
    await _cacheData(key, data, duration ?? _defaultCacheDuration, (data) => data);
  }

  // Get cached generic data
  Future<T?> getCachedData<T>(String key) async {
    return await _getCachedData<T>(key, (data) => data as T);
  }

  // Cache user data
  Future<void> cacheUserData(String userId, Map<String, dynamic> userData, {Duration? duration}) async {
    await cacheData('user_$userId', userData, duration: duration);
  }

  // Get cached user data
  Future<Map<String, dynamic>?> getCachedUserData(String userId) async {
    return await getCachedData<Map<String, dynamic>>('user_$userId');
  }

  // Cache mission progress
  Future<void> cacheMissionProgress(String userId, String missionId, Map<String, dynamic> progress, {Duration? duration}) async {
    await cacheData('progress_${userId}_$missionId', progress, duration: duration);
  }

  // Get cached mission progress
  Future<Map<String, dynamic>?> getCachedMissionProgress(String userId, String missionId) async {
    return await getCachedData<Map<String, dynamic>>('progress_${userId}_$missionId');
  }

  // Cache notifications
  Future<void> cacheNotifications(String userId, List<Map<String, dynamic>> notifications, {Duration? duration}) async {
    await cacheData('notifications_$userId', notifications, duration: duration);
  }

  // Get cached notifications
  Future<List<Map<String, dynamic>>?> getCachedNotifications(String userId) async {
    final data = await getCachedData<List<dynamic>>('notifications_$userId');
    return data?.cast<Map<String, dynamic>>();
  }

  // Cache search results
  Future<void> cacheSearchResults(String query, List<MissionModel> results, {Duration? duration}) async {
    await cacheMissions('search_${_sanitizeKey(query)}', results, duration: duration ?? const Duration(minutes: 30));
  }

  // Get cached search results
  Future<List<MissionModel>?> getCachedSearchResults(String query) async {
    return await getCachedMissions('search_${_sanitizeKey(query)}');
  }

  // Internal cache data method
  Future<void> _cacheData<T>(String key, T data, Duration duration, dynamic Function(T) serializer) async {
    try {
      final cacheItem = CacheItem<T>(
        key: key,
        data: data,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(duration),
      );

      // Store in memory cache
      _memoryCache[key] = cacheItem;

      // Store in persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final serializedData = json.encode(cacheItem.toJson());
      await prefs.setString(cacheKey, serializedData);

      // Manage cache size
      await _manageCacheSize();

      _cacheUpdateController.add(key);
      AppLogger.info('Cached data for key: $key', 'OfflineDataCache');
    } catch (e) {
      AppLogger.error('Failed to cache data for key: $key', 'OfflineDataCache', e);
    }
  }

  // Internal get cached data method
  Future<T?> _getCachedData<T>(String key, T Function(dynamic) deserializer) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final cacheItem = _memoryCache[key] as CacheItem;
        if (cacheItem.isValid) {
          return deserializer(cacheItem.data);
        } else {
          _memoryCache.remove(key);
        }
      }

      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final serializedData = prefs.getString(cacheKey);
      
      if (serializedData == null) return null;

      final json = jsonDecode(serializedData) as Map<String, dynamic>;
      final cacheItem = CacheItem.fromJson(json, deserializer);

      if (cacheItem.isExpired) {
        await clearCache(key);
        return null;
      }

      // Update memory cache
      _memoryCache[key] = cacheItem;
      return cacheItem.data;
    } catch (e) {
      AppLogger.error('Failed to get cached data for key: $key', 'OfflineDataCache', e);
      await clearCache(key);
      return null;
    }
  }

  // Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      _memoryCache.remove(key);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      AppLogger.info('Cleared cache for key: $key', 'OfflineDataCache');
    } catch (e) {
      AppLogger.error('Failed to clear cache for key: $key', 'OfflineDataCache', e);
    }
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      AppLogger.info('Cleared all cache data', 'OfflineDataCache');
    } catch (e) {
      AppLogger.error('Failed to clear all cache', 'OfflineDataCache', e);
    }
  }

  // Get cache info
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      int totalSize = 0;
      int validCount = 0;
      int expiredCount = 0;
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
          
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final expiresAt = DateTime.fromMillisecondsSinceEpoch(json['expiresAt']);
            if (DateTime.now().isBefore(expiresAt)) {
              validCount++;
            } else {
              expiredCount++;
            }
          } catch (e) {
            expiredCount++;
          }
        }
      }
      
      return {
        'totalItems': keys.length,
        'validItems': validCount,
        'expiredItems': expiredCount,
        'memoryItems': _memoryCache.length,
        'totalSize': totalSize,
        'estimatedSizeKB': (totalSize / 1024).round(),
      };
    } catch (e) {
      AppLogger.error('Failed to get cache info', 'OfflineDataCache', e);
      return {};
    }
  }

  // Clean expired cache
  Future<void> cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      int cleanedCount = 0;
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final expiresAt = DateTime.fromMillisecondsSinceEpoch(json['expiresAt']);
            
            if (DateTime.now().isAfter(expiresAt)) {
              await prefs.remove(key);
              cleanedCount++;
            }
          } catch (e) {
            await prefs.remove(key);
            cleanedCount++;
          }
        }
      }
      
      // Clean memory cache
      final expiredKeys = _memoryCache.keys.where((key) {
        final cacheItem = _memoryCache[key] as CacheItem?;
        return cacheItem?.isExpired ?? true;
      }).toList();
      
      for (final key in expiredKeys) {
        _memoryCache.remove(key);
      }
      
      AppLogger.info('Cleaned $cleanedCount expired cache items', 'OfflineDataCache');
    } catch (e) {
      AppLogger.error('Failed to clean expired cache', 'OfflineDataCache', e);
    }
  }

  // Manage cache size
  Future<void> _manageCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
      
      if (keys.length <= _maxCacheSize) return;

      // Get cache items with timestamps
      final cacheItems = <String, DateTime>{};
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final cachedAt = DateTime.fromMillisecondsSinceEpoch(json['cachedAt']);
            cacheItems[key] = cachedAt;
          } catch (e) {
            // Remove invalid cache items
            await prefs.remove(key);
          }
        }
      }

      // Sort by oldest first
      final sortedKeys = cacheItems.keys.toList()
        ..sort((a, b) => cacheItems[a]!.compareTo(cacheItems[b]!));

      // Remove oldest items
      final itemsToRemove = keys.length - _maxCacheSize;
      for (int i = 0; i < itemsToRemove; i++) {
        await prefs.remove(sortedKeys[i]);
        final cacheKey = sortedKeys[i].replaceFirst(_cachePrefix, '');
        _memoryCache.remove(cacheKey);
      }

      AppLogger.info('Removed $itemsToRemove old cache items', 'OfflineDataCache');
    } catch (e) {
      AppLogger.error('Failed to manage cache size', 'OfflineDataCache', e);
    }
  }

  // Helper methods
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w\-_]'), '_').toLowerCase();
  }

  dynamic _serializeMissions(List<MissionModel> missions) {
    return missions.map((mission) => mission.toFirestore()).toList();
  }

  List<dynamic> _deserializeToList(dynamic data) {
    return data as List<dynamic>;
  }

  // Create MissionModel from cached data without DocumentSnapshot
  MissionModel _missionFromCachedData(Map<String, dynamic> data) {
    return MissionModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      appName: data['appName'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'draft',
      testers: data['testers'] ?? 0,
      maxTesters: data['maxTesters'] ?? 0,
      reward: data['reward'] ?? 0,
      description: data['description'] ?? '',
      requirements: List<String>.from(data['requirements'] ?? []),
      duration: data['duration'] ?? 7,
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : null,
      createdBy: data['createdBy'] ?? '',
      bugs: data['bugs'] ?? 0,
      isHot: data['isHot'] ?? false,
      isNew: data['isNew'] ?? false,
    );
  }
}