import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewHelper {
  static bool _isInitialized = false;

  /// Initialize WebView platform if not already done
  static void ensureInitialized() {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // For web, we need to register the web platform
        // This is handled automatically by webview_flutter_web when imported
        DebugLogger.success('WebView platform initialized for web');
      } else {
        // For mobile platforms (iOS/Android), initialization is automatic
        DebugLogger.success('WebView platform initialized for mobile');
      }
      _isInitialized = true;
    } catch (e) {
      DebugLogger.warning('WebView platform initialization failed', e);
    }
  }

  /// Create a WebView controller with proper error handling
  static WebViewController createController({
    required String url,
    Function(String)? onPageStarted,
    Function(String)? onPageFinished,
    Function(WebResourceError)? onWebResourceError,
  }) {
    ensureInitialized();

    final controller = WebViewController();

    try {
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: onPageStarted,
            onPageFinished: onPageFinished,
            onWebResourceError:
                onWebResourceError ??
                (WebResourceError error) {
                  DebugLogger.warning('WebView error: ${error.description}');
                },
          ),
        )
        ..loadRequest(Uri.parse(url));

      return controller;
    } catch (e) {
      DebugLogger.error('Error creating WebView controller', e);
      rethrow;
    }
  }

  /// Create a safe WebView widget with error handling
  static Widget createSafeWebView({
    required BuildContext context,
    required String url,
    double? width,
    double? height,
    Function(String)? onPageStarted,
    Function(String)? onPageFinished,
    Widget? errorWidget,
  }) {
    try {
      ensureInitialized();

      final controller = createController(
        url: url,
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
        onWebResourceError: (error) {
          DebugLogger.warning('WebView resource error: ${error.description}');
        },
      );

      return SizedBox(
        width: width,
        height: height,
        child: WebViewWidget(controller: controller),
      );
    } catch (e) {
      DebugLogger.error('Error creating safe WebView', e);
      return errorWidget ?? _buildErrorWidget(context, width, height, url);
    }
  }

  /// Build error widget when WebView fails
  static Widget _buildErrorWidget(BuildContext context, double? width, double? height, String url) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'tour_unavailable_title'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'tour_unavailable_body'.tr,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (kIsWeb)
            TextButton(
              onPressed: () {
                // Try to open in new tab for web
                try {
                  // This would need url_launcher for proper implementation
                  DebugLogger.debug('Opening URL in new tab: $url');
                } catch (e) {
                  DebugLogger.warning('Could not open URL', e);
                }
              },
              child: Text('open_in_new_tab'.tr),
            ),
        ],
      ),
    );
  }

  /// Check if WebView is supported on current platform
  static bool get isSupported {
    ensureInitialized();
    return _isInitialized;
  }
}
