import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'debug_logger.dart';

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
    } catch (e, stackTrace) {
      DebugLogger.warning('WebView platform initialization failed', e, stackTrace);
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
            onWebResourceError: onWebResourceError ?? (WebResourceError error) {
              DebugLogger.warning('WebView error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
        
      return controller;
    } catch (e, stackTrace) {
      DebugLogger.error('Error creating WebView controller', e, stackTrace);
      rethrow;
    }
  }
  
  /// Create a safe WebView widget with error handling
  static Widget createSafeWebView({
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
    } catch (e, stackTrace) {
      DebugLogger.error('Error creating safe WebView', e, stackTrace);
      return errorWidget ?? _buildErrorWidget(width, height, url);
    }
  }
  
  /// Build error widget when WebView fails
  static Widget _buildErrorWidget(double? width, double? height, String url) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '360° Tour Unavailable',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Virtual tour could not be loaded',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          if (kIsWeb)
            TextButton(
              onPressed: () {
                // Try to open in new tab for web
                try {
                  // This would need url_launcher for proper implementation
                  DebugLogger.debug('Opening URL in new tab: $url');
                } catch (e, stackTrace) {
                  DebugLogger.warning('Could not open URL', e);
                }
              },
              child: const Text('Open in New Tab'),
            ),
        ],
      ),
    );
  }
  
  /// Check if WebView is supported on current platform
  static bool get isSupported {
    try {
      ensureInitialized();
      return true;
    } catch (e, stackTrace) {
      return false;
    }
  }
}