import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import 'package:ghar360/core/utils/debug_logger.dart';

class DynamicLinksService {
  static Future<void> initializeListener() async {
    try {
      final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
      if (data?.link != null) {
        DebugLogger.info('🔗 Initial dynamic link: ${data!.link}');
      }

      FirebaseDynamicLinks.instance.onLink.listen(
        (pendingLink) {
          DebugLogger.info('🔗 Dynamic link received: ${pendingLink.link}');
          // TODO: route handling later (post-approval)
        },
        onError: (e, st) {
          DebugLogger.warning('Dynamic links onLink error', e);
          DebugLogger.debug('Dynamic links stack', st);
        },
      );
    } catch (e, st) {
      DebugLogger.warning('Dynamic links init failed', e);
      DebugLogger.debug('Dynamic links init stack', st);
    }
  }
}
