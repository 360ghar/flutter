import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/bindings/initial_binding.dart';
import 'core/controllers/localization_controller.dart';
import 'core/controllers/theme_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/translations/app_translations.dart';
import 'core/utils/debug_logger.dart';
import 'core/utils/null_check_trap.dart';
import 'core/utils/theme.dart';
import 'core/utils/webview_helper.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';
import 'root.dart';

void main() async {
  runZonedGuarded(
    () async {
      // Ensure Flutter bindings are initialized in the same zone as runApp
      WidgetsFlutterBinding.ensureInitialized();
      // Initialize GetStorage before any controllers that depend on it
      await GetStorage.init();

      // Load environment variables first (before DebugLogger initialization)
      try {
        await dotenv.load(fileName: ".env.development");
      } catch (e) {
        // Continue without .env file - will use defaults
      }

      // Initialize DebugLogger after dotenv is loaded
      DebugLogger.initialize();

      // Initialize WebView platform
      WebViewHelper.ensureInitialized();

      // Log environment status after DebugLogger is ready
      try {
        DebugLogger.success('Environment variables loaded successfully');
        DebugLogger.info(
          'API Base URL: ${dotenv.env['API_BASE_URL'] ?? 'https://360ghar.up.railway.app'}',
        );
      } catch (e) {
        DebugLogger.warning('Failed to load .env.development', e);
        DebugLogger.info('Using default configuration');
      }

      // Initialize Supabase with error handling
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
          authOptions: FlutterAuthClientOptions(detectSessionInUri: false),
        );
        DebugLogger.success('Supabase initialized successfully');
      } catch (e) {
        DebugLogger.warning('Failed to initialize Supabase', e);
        DebugLogger.info('Continuing without Supabase');
      }

      // Set up global error handlers
      FlutterError.onError = (FlutterErrorDetails details) {
        DebugLogger.error('🚨 [GLOBAL_ERROR] Flutter Error: ${details.exception}');
        DebugLogger.error('🚨 [GLOBAL_ERROR] Stack trace: ${details.stack}');

        // One-time first null-check trap capture
        NullCheckTrap.captureFlutterError(details);

        // Still show the error in debug mode
        FlutterError.presentError(details);
      };

      runApp(const MyApp());
    },
    (error, stack) {
      // One-time first null-check trap capture for unhandled async errors
      if (error.toString().contains('Null check operator used on a null value')) {
        NullCheckTrap.capture(error, stack, source: 'zone');
      }
      DebugLogger.error('🚨 [GLOBAL_ERROR] Unhandled zone error', error, stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = _ensureThemeController();

    // Rebuild GetMaterialApp whenever theme mode changes
    return Obx(
      () => GetMaterialApp(
        title: 'app_name'.tr,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        supportedLocales: LocalizationController.supportedLocales,
        translations: AppTranslations(),
        fallbackLocale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Root(),
        getPages: AppPages.routes,
        initialBinding: InitialBinding(), // Correctly use bindings
        debugShowCheckedModeBanner: false,
        routingCallback: (routing) {
          DebugLogger.debug('Routing to: ${routing?.current}');

          // Update dashboard tab when DashboardController is registered
          if (Get.isRegistered<DashboardController>()) {
            final currentRoute = routing?.current ?? '';
            Get.find<DashboardController>().syncTabWithRoute(currentRoute);
          }
        },
      ),
    );
  }

  ThemeController _ensureThemeController() {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(ThemeController(), permanent: true);
    }
    return Get.find<ThemeController>();
  }
}
