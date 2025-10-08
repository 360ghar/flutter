import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import 'package:ghar360/core/data/providers/api_service.dart';
import 'package:ghar360/core/firebase/analytics_service.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Deep Linking Service using App Links
/// Replaces deprecated Firebase Dynamic Links
class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;

  /// Initialize deep link listener for App Links
  static Future<void> initializeListener() async {
    try {
      // Handle initial deep link when app is launched
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        DebugLogger.info('🔗 Initial app link: $initialLink');
        _handleDeepLink(initialLink);
      }

      // Listen for deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          DebugLogger.info('🔗 App link received: $uri');
          _handleDeepLink(uri);
        },
        onError: (Object err, StackTrace stackTrace) {
          DebugLogger.warning('App links listener error', err, stackTrace);
        },
      );

      DebugLogger.startup('Deep linking initialized (App Links)');
    } catch (e, st) {
      DebugLogger.warning('Deep links init failed', e, st);
    }
  }

  /// Handle incoming deep link
  static void _handleDeepLink(Uri uri) {
    try {
      DebugLogger.info('🔗 Processing deep link: $uri');

      // Parse the URI and extract relevant information
      final String path = uri.path;
      final Map<String, String> queryParams = uri.queryParameters;

      DebugLogger.debug('Deep link path: $path');
      DebugLogger.debug('Deep link query params: $queryParams');

      // Routing logic for supported patterns
      if (path.startsWith('/property/')) {
        final propertyId = path.replaceFirst('/property/', '').split('/').first;
        if (propertyId.isNotEmpty) {
          DebugLogger.info('🔗 Navigating to property-details for id=$propertyId');
          // Analytics: deep link opened for property
          AnalyticsService.deepLinkOpenProperty(propertyId);
          Get.toNamed(AppRoutes.propertyDetails, arguments: propertyId);
          return;
        }
      }
      if (path.startsWith('/tour/')) {
        final raw = path.replaceFirst('/tour/', '');
        final firstSeg = raw.split('/').first;
        if (firstSeg.isEmpty) return;

        // If looks like a URL, navigate directly (decode first)
        final decoded = Uri.decodeComponent(firstSeg);
        if (decoded.startsWith('http://') || decoded.startsWith('https://')) {
          DebugLogger.info('🔗 Navigating to tour by URL');
          // Analytics: deep link opened for tour via URL
          AnalyticsService.deepLinkOpenTour(url: decoded);
          Get.toNamed(AppRoutes.tour, arguments: decoded);
          return;
        }

        // Otherwise, try interpreting as property id and fetch tour URL
        final id = int.tryParse(firstSeg);
        if (id != null) {
          DebugLogger.info('🔗 Resolving tour via property id=$id');
          // Fetch asynchronously and route once resolved
          Future.microtask(() async {
            try {
              final api = Get.find<ApiService>();
              final p = await api.getPropertyDetails(id);
              if (p.virtualTourUrl != null && p.virtualTourUrl!.isNotEmpty) {
                // Analytics: deep link opened for tour resolved via property id
                AnalyticsService.deepLinkOpenTour(propertyId: id.toString(), url: p.virtualTourUrl);
                Get.toNamed(AppRoutes.tour, arguments: p.virtualTourUrl);
              } else {
                DebugLogger.warning('No virtual tour URL for property id=$id');
              }
            } catch (e, st) {
              DebugLogger.warning('Failed to resolve tour URL from property id', e, st);
            }
          });
          return;
        }
      }
    } catch (e, st) {
      DebugLogger.error('Error handling deep link', e, st);
    }
  }

  /// Dispose of deep link listener
  static Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    DebugLogger.info('Deep link listener disposed');
  }
}
