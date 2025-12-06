import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:uni_links/uni_links.dart';

class DeepLinkService extends GetxService {
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    // Handle initial link (Cold Start)
    _initInitialLink();
    // Handle incoming links (Background/Warm Start)
    _initIncomingLinks();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Handles the link that opened the app (Cold Start)
  Future<void> _initInitialLink() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        // Wait for app routes and controllers to be ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialUri);
        });
      }
    } on PlatformException catch (e) {
      DebugLogger.warning('Failed to get initial deep link: $e');
    } on FormatException catch (e) {
      DebugLogger.warning('Bad parse of initial deep link: $e');
    }
  }

  /// Listens for new links while app is running (Warm Start)
  void _initIncomingLinks() {
    if (!kIsWeb) {
      _sub = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            _handleDeepLink(uri);
          }
        },
        onError: (Object err) {
          DebugLogger.error('Deep link stream error: $err');
        },
      );
    }
  }

  void _handleDeepLink(Uri uri) {
    DebugLogger.info('🔗 Received Deep Link: $uri');

    // Parse path segments to find property ID
    // Supports:
    // 1. https://ghar.sale/p/123 (short link from _redirects)
    // 2. https://ghar.sale/property/123

    String? propertyId;

    if (uri.pathSegments.length >= 2) {
      final firstSegment = uri.pathSegments[0];
      if (firstSegment == 'p' || firstSegment == 'property') {
        propertyId = uri.pathSegments[1];
      }
    }

    if (propertyId != null && propertyId.isNotEmpty) {
      DebugLogger.info('🔗 Navigating to Property ID: $propertyId');
      _navigateToProperty(propertyId);
    } else {
      DebugLogger.warning('🔗 Could not parse Property ID from: $uri');
    }
  }

  void _navigateToProperty(String propertyId) {
    // Small delay to ensure UI is ready/transition has settled if coming from cold start
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.toNamed(AppRoutes.propertyDetails, arguments: propertyId);
    });
  }
}
