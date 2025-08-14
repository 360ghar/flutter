import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_network/image_network.dart';
import '../../core/utils/app_colors.dart';

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
    return url.contains('placeholder.com') || url.contains('picsum.photos') || url.contains('via.placeholder');
  }
  
  static String? getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (!isValidUrl(url)) return null;
    if (isPlaceholderUrl(url)) return null; // Skip problematic placeholder services
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
    
    // If no valid URL, show error widget immediately
    if (validUrl == null) {
      final errorFallback = errorWidget ?? _buildDefaultErrorWidget();
      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: errorFallback,
        );
      }
      return errorFallback;
    }

    Widget imageWidget;

    if (kIsWeb) {
      // Web-specific implementation with better error handling
      imageWidget = _buildWebImage(validUrl);
    } else {
      // Mobile implementation using CachedNetworkImage
      imageWidget = CachedNetworkImage(
        imageUrl: validUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth ?? width?.toInt(),
        memCacheHeight: memCacheHeight ?? height?.toInt(),
        placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        filterQuality: FilterQuality.medium,
      );
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
  
  Widget _buildWebImage(String url) {
    return FutureBuilder<bool>(
      future: _testImageUrl(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? _buildDefaultPlaceholder();
        }
        
        if (snapshot.hasError || snapshot.data == false) {
          return errorWidget ?? _buildDefaultErrorWidget();
        }
        
        // If image URL is accessible, use ImageNetwork
        return ImageNetwork(
          image: url,
          width: width ?? 200,
          height: height ?? 200,
          duration: 300,
          curve: Curves.easeIn,
          onPointer: false,
          debugPrint: false,
          fitAndroidIos: BoxFit.cover,
          fitWeb: _convertToWebFit(fit),
          onLoading: placeholder ?? _buildDefaultPlaceholder(),
          onError: errorWidget ?? _buildDefaultErrorWidget(),
        );
      },
    );
  }
  
  Future<bool> _testImageUrl(String url) async {
    try {
      // Quick test if we can resolve the domain
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return false;
      
      // For now, we'll assume the URL is good if it's a valid URI
      // In a real app, you might want to do a HEAD request to test
      return true;
    } catch (e) {
      return false;
    }
  }

  BoxFitWeb _convertToWebFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return BoxFitWeb.cover;
      case BoxFit.contain:
        return BoxFitWeb.contain;
      case BoxFit.fill:
        return BoxFitWeb.fill;
      case BoxFit.fitWidth:
        return BoxFitWeb.cover; // Fallback to cover
      case BoxFit.fitHeight:
        return BoxFitWeb.cover; // Fallback to cover
      case BoxFit.none:
        return BoxFitWeb.cover; // Fallback to cover
      case BoxFit.scaleDown:
        return BoxFitWeb.scaleDown;
    }
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
          child: CircularProgressIndicator(
            color: AppColors.loadingIndicator,
            strokeWidth: 2,
          ),
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
            AppColors.primaryYellow.withOpacity(0.1),
            AppColors.primaryYellow.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.2),
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
                'Property Image',
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
        placeholder: placeholder ?? Container(
          width: size,
          height: size,
          color: AppColors.inputBackground,
          child: const Icon(Icons.person, color: Colors.grey),
        ),
        errorWidget: errorWidget ?? Container(
          width: size,
          height: size,
          color: AppColors.inputBackground,
          child: const Icon(Icons.person, color: Colors.grey),
        ),
      ),
    );
  }
}