import 'package:get/get.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:uni_links/uni_links.dart';

class DeepLinkService {
  Future<void> initDeepLinks() async {
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
    final host = uri.host;
    if (host == 'ghar.sale' || host == 'www.ghar.sale') {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'p') {
        final id = uri.pathSegments[1];
        Get.toNamed(AppRoutes.propertyDetails, arguments: id);
      }
    }
  }
}
