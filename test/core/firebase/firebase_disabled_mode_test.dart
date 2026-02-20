import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/firebase/analytics_service.dart';
import 'package:ghar360/core/firebase/firebase_runtime_state.dart';
import 'package:ghar360/core/firebase/remote_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase disabled mode guards', () {
    late bool prevEnabled;
    late bool prevReady;

    setUp(() {
      prevEnabled = FirebaseRuntimeState.isEnabled;
      prevReady = FirebaseRuntimeState.isReady;
      FirebaseRuntimeState.isEnabled = false;
      FirebaseRuntimeState.isReady = false;
    });

    tearDown(() {
      FirebaseRuntimeState.isEnabled = prevEnabled;
      FirebaseRuntimeState.isReady = prevReady;
    });

    test('RemoteConfig forceFetch and getters are safe defaults when Firebase not ready', () async {
      final fetched = await RemoteConfigService.forceFetch();

      expect(fetched, isFalse);
      expect(RemoteConfigService.analyticsEnabled, isFalse);
      expect(RemoteConfigService.androidLatestVersion, '1.0.0');
      expect(RemoteConfigService.iosForceUpdate, isFalse);
    });

    test('Analytics logVital is a no-op when Firebase not ready', () async {
      await expectLater(
        AnalyticsService.logVital('unit_test_event', params: {'value': 1}),
        completes,
      );
      await expectLater(AnalyticsService.setUserId('user-1'), completes);
    });
  });
}
