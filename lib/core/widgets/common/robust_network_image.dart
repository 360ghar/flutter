import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/image_cache_service.dart';

class ImageLoadingService {
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  static bool isPlaceholderUrl(String url) {
    return url.contains('placeholder.com') ||
        url.contains('picsum.photos') ||
        url.contains('via.placeholder');
  }

  static String? getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (!ImageCacheService.instance.isValidImageUrl(url)) return null;
    if (isPlaceholderUrl(url)) {
      return null; // Skip problematic placeholder services
    }
    return url;
  }
}

class RobustNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const RobustNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Validate image URL first
    final validUrl = ImageLoadingService.getValidImageUrl(imageUrl);

    // If no valid URL, show placeholder immediately
    if (validUrl == null || validUrl.isEmpty) {
      final placeholderFallback = placeholder ?? _buildDefaultPlaceholder();
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: placeholderFallback);
      }
      return placeholderFallback;
    }

    // Use unified image builder with SVG support
    final imageWidget = _buildUnifiedImage(validUrl);

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildUnifiedImage(String url) {
    if (_isSvgUrl(url)) {
      return _buildSvgImage(url);
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, placeholderUrl) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, error, stackTrace) => errorWidget ?? _buildDefaultErrorWidget(),
    );
  }

  bool _isSvgUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.svg') || lower.contains('/svg?') || lower.contains('format=svg');
  }

  Widget _buildSvgImage(String url) {
    return SvgPicture.network(
      url,
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: (context) => placeholder ?? _buildDefaultPlaceholder(),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.inputBackground,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: AppColors.loadingIndicator, strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryYellow.withValues(alpha: 0.1),
            AppColors.primaryYellow.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_outlined,
                color: AppColors.primaryYellow,
                size: width != null && width! < 100 ? 20 : 32,
              ),
            ),
            if (width != null && width! > 100) ...[
              const SizedBox(height: 8),
              Text(
                'property_image'.tr,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Extension for easier usage with different configurations
extension RobustNetworkImageExtension on RobustNetworkImage {
  static Widget circular({
    required String imageUrl,
    required double radius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipOval(
      child: RobustNetworkImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }

  static Widget avatar({
    required String imageUrl,
    double size = 40,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipOval(
      child: RobustNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder:
            placeholder ??
            Container(
              width: size,
              height: size,
              color: AppColors.inputBackground,
              child: Icon(Icons.person, color: AppColors.textSecondary),
            ),
        errorWidget:
            errorWidget ??
            Container(
              width: size,
              height: size,
              color: AppColors.inputBackground,
              child: Icon(Icons.person, color: AppColors.textSecondary),
            ),
      ),
    );
  }

  /// Cache management utilities
  static Future<void> clearImageCache() async {
    await ImageCacheService.instance.clearCache();
  }

  static Future<void> cleanExpiredCache() async {
    await ImageCacheService.instance.cleanExpiredCache();
  }

  static Future<void> smartCacheCleanup() async {
    await ImageCacheService.instance.smartCleanup();
  }

  static Future<void> removeImageFromCache(String imageUrl) async {
    await ImageCacheService.instance.removeFromCache(imageUrl);
  }

  static Future<bool> isImageCached(String imageUrl) async {
    return ImageCacheService.instance.isImageCached(imageUrl);
  }

  static Future<void> preloadImage(String imageUrl) async {
    await ImageCacheService.instance.preloadImage(imageUrl);
  }

  static Future<Map<String, dynamic>> getCacheStats() async {
    return ImageCacheService.instance.getCacheStats();
  }
}
