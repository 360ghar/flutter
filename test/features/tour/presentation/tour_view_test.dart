import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:ghar360/core/translations/app_translations.dart';
import 'package:ghar360/features/tour/presentation/views/tour_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('shows invalid fallback state when route arguments are missing', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const TourView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('qa.tour.screen')), findsOneWidget);
    expect(find.byIcon(Icons.link_off), findsOneWidget);
  });
}
