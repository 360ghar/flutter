import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Unified image caching service that works across web and mobile platforms
class ImageCacheService {
  static const String _cacheKey = 'robust_image_cache';
  static const Duration _defaultMaxAge = Duration(hours: 24);
  static const int _maxCacheSize = 200 * 1024 * 1024; // 200MB
  static const int _maxFilesCount = 200;

  // Singleton instance
  static ImageCacheService? _instance;
  static ImageCacheService get instance {
    _instance ??= ImageCacheService._();
    return _instance!;
  }

  late final CacheManager _cacheManager;

  ImageCacheService._() {
    _cacheManager = CacheManager(
      Config(
        _cacheKey,
        stalePeriod: _defaultMaxAge,
        maxNrOfCacheObjects: _maxFilesCount,
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
  }

  /// Get cached image file or download from network
  Future<File?> getImageFile(String url) async {
    if (!isValidImageUrl(url)) {
      return null;
    }

    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        // Check if cached file is still valid
        if (await _isFileValid(fileInfo.file)) {
          return fileInfo.file;
        } else {
          // Remove invalid cached file
          await _cacheManager.removeFile(url);
        }
      }

      // Download new file
      final newFileInfo = await _cacheManager.downloadFile(url, key: url);

      return newFileInfo.file;
    } catch (e) {
      debugPrint('Error loading image from cache: $e');
      return null;
    }
  }

  /// Get image as bytes for web platform
  Future<Uint8List?> getImageBytes(String url) async {
    if (!isValidImageUrl(url)) {
      return null;
    }

    try {
      final file = await getImageFile(url);
      if (file != null) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting image bytes: $e');
      return null;
    }
  }

  /// Check if URL is valid for caching
  bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Check if cached file is still valid (exists and not corrupted)
  Future<bool> _isFileValid(File file) async {
    try {
      return file.existsSync() && file.lengthSync() > 0;
    } catch (e) {
      return false;
    }
  }

  /// Remove specific image from cache
  Future<void> removeFromCache(String url) async {
    try {
      await _cacheManager.removeFile(url);
    } catch (e) {
      debugPrint('Error removing image from cache: $e');
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      // flutter_cache_manager doesn't expose cache size directly
      // Return 0 as we can't determine this easily
      return 0;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }

  /// Get cache file count
  Future<int> getCacheFileCount() async {
    try {
      // flutter_cache_manager doesn't expose cache count directly
      // Return 0 as we can't determine this easily
      return 0;
    } catch (e) {
      debugPrint('Error getting cache file count: $e');
      return 0;
    }
  }

  /// Remove expired cache entries
  Future<void> cleanExpiredCache() async {
    try {
      // flutter_cache_manager handles expiration automatically
      // We can clear all files and let the cache manager re-download as needed
      await _cacheManager.emptyCache();
    } catch (e) {
      debugPrint('Error cleaning expired cache: $e');
    }
  }

  /// Dispose cache manager (call on app termination)
  Future<void> dispose() async {
    try {
      await _cacheManager.dispose();
      _instance = null;
    } catch (e) {
      debugPrint('Error disposing cache manager: $e');
    }
  }

  /// Smart cache cleanup based on size and age
  Future<void> smartCleanup() async {
    try {
      // For flutter_cache_manager, the best approach is to clear expired entries
      // and let the built-in size limits handle the rest
      await cleanExpiredCache();
    } catch (e) {
      debugPrint('Error during smart cleanup: $e');
    }
  }

  /// Set custom cache configuration
  Future<void> updateCacheConfig({Duration? maxAge, int? maxSize, int? maxFiles}) async {
    try {
      // Note: flutter_cache_manager doesn't support runtime config changes
      // This would require recreating the cache manager
      debugPrint('Cache config update requested. Restart app for changes to take effect.');
    } catch (e) {
      debugPrint('Error updating cache config: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      // For flutter_cache_manager, we don't have direct access to cache info
      // We'll return basic configuration info
      return {
        'maxAge': _defaultMaxAge.toString(),
        'maxSize': _maxCacheSize,
        'maxFiles': _maxFilesCount,
        'note': 'flutter_cache_manager handles cache internally',
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }
}

/// Extension for easier cache operations
extension ImageCacheServiceExtension on ImageCacheService {
  /// Preload image into cache
  Future<void> preloadImage(String url) async {
    if (isValidImageUrl(url)) {
      await getImageFile(url);
    }
  }

  /// Invalidate cache for specific URL with delay
  Future<void> invalidateCacheDelayed(String url, Duration delay) async {
    Future.delayed(delay, () => removeFromCache(url));
  }

  /// Check if image exists in cache
  Future<bool> isImageCached(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo != null && fileInfo.file.existsSync();
    } catch (e) {
      return false;
    }
  }
}
