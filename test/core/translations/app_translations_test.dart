import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/translations/app_translations.dart';

void main() {
  test('contains required translation keys in supported locales', () {
    final keys = AppTranslations().keys;
    const required = <String>[
      'Call',
      'WhatsApp',
      'profile_picture',
      'unavailable',
      'agent_contact_unavailable',
      'could_not_open_phone_dialer',
      'could_not_open_whatsapp',
      'auth_phone_title',
      'auth_phone_subtitle',
      'auth_login_subtitle',
      'auth_signup_personal_subtitle',
      'auth_signup_security_title',
      'auth_signup_security_subtitle',
      'auth_chip_verified',
      'auth_chip_transparent',
      'auth_chip_support',
      'auth_chip_private',
      'auth_chip_secure',
      'onboarding_slide_1_title',
      'onboarding_slide_1_desc',
      'onboarding_slide_2_title',
      'onboarding_slide_2_desc',
      'onboarding_slide_3_title',
      'onboarding_slide_3_desc',
      'skip',
    ];

    for (final locale in ['en_US', 'hi_IN']) {
      final localeMap = keys[locale];
      expect(localeMap, isNotNull, reason: 'Missing locale map for $locale');
      for (final key in required) {
        expect(localeMap!.containsKey(key), isTrue, reason: 'Missing "$key" in $locale');
      }
    }
  });
}
