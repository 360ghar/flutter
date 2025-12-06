import 'package:get/get.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:uni_links/uni_links.dart';

class DeepLinkService extends GetxService {
  @override
  void onReady() {
    super.onReady();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      uriLinkStream.listen((Uri? uri) {
        if (uri != null) _handleUri(uri);
      });
    } catch (e, st) {
      DebugLogger.warning('Deep link init failed', e, st);
    }
  }

  void _handleUri(Uri uri) {
    DebugLogger.info('🔗 Deep link received: $uri');
    final host = uri.host;
    if (host == 'ghar.sale' || host == 'www.ghar.sale') {
      if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments[0] == 'p' &&
          uri.pathSegments.length == 2) {
        final id = uri.pathSegments[1];
        DebugLogger.info('🔗 Navigating to property: $id');
        // Small delay to ensure UI is ready/transition has settled if coming from cold start
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed(AppRoutes.propertyDetails, arguments: id);
        });
      } else {
        DebugLogger.warning('Invalid property deep link format: ${uri.path}');
      }
    }
  }
}
