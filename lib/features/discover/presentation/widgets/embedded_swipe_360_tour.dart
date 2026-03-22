import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/webview_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Embeds a 360° virtual tour WebView for the swipe card.
class EmbeddedSwipe360Tour extends StatefulWidget {
  final String tourUrl;

  const EmbeddedSwipe360Tour({super.key, required this.tourUrl});

  @override
  State<EmbeddedSwipe360Tour> createState() => _EmbeddedSwipe360TourState();
}

class _EmbeddedSwipe360TourState extends State<EmbeddedSwipe360Tour> {
  WebViewController? controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      WebViewHelper.ensureInitialized();
      const consoleSilencer = '''
        if (window && window.console) {
          window.console.log = function() {};
          window.console.warn = function() {};
          window.console.error = function() {};
          window.console.info = function() {};
          window.console.debug = function() {};
        }
      ''';

      controller = WebViewHelper.createBaseController();
      controller!
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() => isLoading = true);
              }
              controller!.runJavaScript(consoleSilencer);
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() => isLoading = false);
              }
              controller!.runJavaScript(consoleSilencer);
            },
            onWebResourceError: (WebResourceError error) {
              DebugLogger.warning('WebView error in 360° tour: ${error.description}');
              if (mounted) {
                setState(() {
                  isLoading = false;
                  hasError = true;
                });
              }
            },
          ),
        );

      final htmlContent =
          '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            margin: 0;
            padding: 0;
            background: #f0f0f0;
            overflow: hidden;
          }
          iframe {
            width: 100vw;
            height: 100vh;
            border: none;
            display: block;
          }
        </style>
        <script type="text/javascript">
          $consoleSilencer
        </script>
      </head>
      <body>
        <iframe class="ku-embed"
                frameborder="0"
                allow="xr-spatial-tracking; gyroscope; accelerometer"
                allowfullscreen
                scrolling="no"
                src="${widget.tourUrl}">
        </iframe>
      </body>
      </html>
    ''';

      controller!.loadHtmlString(htmlContent);
    } catch (e, stackTrace) {
      DebugLogger.error('Error initializing WebView for 360° tour', e, stackTrace);
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasError || controller == null) {
      return _buildErrorState(context);
    }

    return Stack(
      children: [
        WebViewWidget(
          controller: controller!,
          gestureRecognizers: WebViewHelper.createInteractiveGestureRecognizers(),
        ),
        if (isLoading) _buildLoadingState(context),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_off, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'tour_unavailable_title'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'tour_unavailable_body'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppDesign.primaryYellow, strokeWidth: 2),
            const SizedBox(height: 8),
            Text(
              'loading_virtual_tour'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
