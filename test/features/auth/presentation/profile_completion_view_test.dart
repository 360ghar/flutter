import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:ghar360/core/translations/app_translations.dart';
import 'package:ghar360/features/auth/presentation/controllers/profile_completion_controller.dart';
import 'package:ghar360/features/auth/presentation/views/profile_completion_view.dart';

class _TestProfileCompletionController extends ProfileCompletionController {
  @override
  // ignore: must_call_super
  void onInit() {
    // Skip production dependency lookups (AuthController/PageStateService)
    // for isolated widget testing.
  }

  @override
  Future<void> completeProfile() async {}

  @override
  void skipToHome() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('blocks progression on step 1 when required fields are missing', (tester) async {
    final controller = Get.put<ProfileCompletionController>(_TestProfileCompletionController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const ProfileCompletionView(),
      ),
    );
    await tester.pumpAndSettle();

    final nextButton = find.byKey(const ValueKey('qa.auth.profile_completion.next_or_complete'));
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(controller.currentStep.value, 0);
  });

  testWidgets('advances to purpose step when step 1 fields are valid', (tester) async {
    final controller = Get.put<ProfileCompletionController>(_TestProfileCompletionController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const ProfileCompletionView(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('qa.auth.profile_completion.full_name_input')),
      'Test User',
    );
    await tester.enterText(
      find.byKey(const ValueKey('qa.auth.profile_completion.email_input')),
      'test@example.com',
    );

    controller.selectedDateOfBirth = DateTime(2000, 1, 1);
    controller.dateOfBirthController.text = '01/01/2000';
    controller.update();
    await tester.pump();

    final nextButton = find.byKey(const ValueKey('qa.auth.profile_completion.next_or_complete'));
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(controller.currentStep.value, 1);
    expect(find.byKey(const ValueKey('qa.auth.profile_completion.purpose.rent')), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.auth.profile_completion.purpose.buy')), findsOneWidget);
  });
}
