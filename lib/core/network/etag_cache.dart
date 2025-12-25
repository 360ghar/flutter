import 'dart:convert';

import 'package:get/get.dart' as getx;
import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/utils/debug_logger.dart';

/// Simple ETag-based response cache.
class ETagCache {
  final GetStorage _storage = GetStorage();
  static const String _cachePrefix = 'etag_cache_';
  static const int _maxCacheAge = 5 * 60 * 1000; // 5 minutes in ms

  /// Gets the cached ETag for a given key.
  String? getETag(String key) {
    try {
      final cached = _storage.read('$_cachePrefix$key');
      if (cached == null) return null;

      final entry = cached as Map<String, dynamic>;
      final timestamp = entry['timestamp'] as int?;
      if (timestamp != null && DateTime.now().millisecondsSinceEpoch - timestamp > _maxCacheAge) {
        _storage.remove('$_cachePrefix$key');
        return null;
      }

      return entry['etag'] as String?;
    } catch (e) {
      DebugLogger.warning('Failed to get ETag: $e');
      return null;
    }
  }

  /// Gets the cached response body for a given key.
  String? getCachedBody(String key) {
    try {
      final cached = _storage.read('$_cachePrefix$key');
      if (cached == null) return null;

      final entry = cached as Map<String, dynamic>;
      final timestamp = entry['timestamp'] as int?;
      if (timestamp != null && DateTime.now().millisecondsSinceEpoch - timestamp > _maxCacheAge) {
        _storage.remove('$_cachePrefix$key');
        return null;
      }

      return entry['body'] as String?;
    } catch (e) {
      DebugLogger.warning('Failed to get cached body: $e');
      return null;
    }
  }

  /// Caches a response with its ETag.
  void cacheResponse(String key, getx.Response response) {
    try {
      final etag = _getHeaderValue(response.headers, 'etag');
      if (etag == null || etag.isEmpty) {
        DebugLogger.debug('🗂️ No ETag present; skipping cache for $key');
        return;
      }

      final bodyStr = response.bodyString ?? jsonEncode(response.body);
      if (bodyStr.isEmpty || bodyStr.trim() == 'null') {
        DebugLogger.debug('🗂️ Empty body; skipping cache for $key');
        return;
      }

      _storage.write('$_cachePrefix$key', {
        'etag': etag,
        'body': bodyStr,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      DebugLogger.debug('✅ Cached response (etag=$etag) for $key');
    } catch (e) {
      DebugLogger.warning('Failed to cache response for $key', e);
    }
  }

  /// Clears all cached entries.
  void clear() {
    try {
      final keys = _storage.getKeys().where((k) => k.startsWith(_cachePrefix));
      for (final key in keys) {
        _storage.remove(key);
      }
      DebugLogger.info('🗑️ Cleared ETag cache');
    } catch (e) {
      DebugLogger.warning('Failed to clear cache: $e');
    }
  }

  String? _getHeaderValue(Map<String, String>? headers, String key) {
    if (headers == null) return null;
    final lowerKey = key.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        return entry.value;
      }
    }
    return null;
  }
}
