import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ghar360/core/bindings/initial_binding.dart';
import 'package:ghar360/core/controllers/localization_controller.dart';
import 'package:ghar360/core/controllers/theme_controller.dart';
import 'package:ghar360/core/firebase/firebase_initializer.dart';
import 'package:ghar360/core/firebase/push_notifications_service.dart';
import 'package:ghar360/core/routes/app_pages.dart';
import 'package:ghar360/core/translations/app_translations.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/null_check_trap.dart';
import 'package:ghar360/core/utils/theme.dart';
import 'package:ghar360/core/utils/webview_helper.dart';
import 'package:ghar360/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ghar360/root.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  runZonedGuarded(
    () async {
      // Ensure Flutter bindings are initialized in the same zone as runApp
      WidgetsFlutterBinding.ensureInitialized();
      // Initialize GetStorage before any controllers that depend on it
      await GetStorage.init();

      // Load environment variables first (before DebugLogger initialization)
      try {
        // Choose env file based on build mode
        final envFile = kReleaseMode ? '.env.production' : '.env.development';
        await dotenv.load(fileName: envFile);
      } catch (e) {
        // Continue without .env file - will use defaults
      }

      // Initialize DebugLogger after dotenv is loaded
      DebugLogger.initialize();

      // Initialize WebView platform
      WebViewHelper.ensureInitialized();

      // Enable edge-to-edge system UI on Android 10+ and iOS
      // This avoids deprecated status/navigation bar color APIs on Android 15+
      // and ensures our content can draw behind system bars with insets.
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Log environment status after DebugLogger is ready
      try {
        DebugLogger.success('Environment variables loaded successfully');
        DebugLogger.info(
          'API Base URL: ${dotenv.env['API_BASE_URL'] ?? 'https://api.360ghar.com'}',
        );
      } catch (e) {
        DebugLogger.warning('Failed to load .env file', e);
        DebugLogger.info('Using default configuration');
      }

      // Initialize Supabase with error handling
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
          authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
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
        // Report to Crashlytics if available
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        } catch (_) {}
        // Still show the error in debug mode
        FlutterError.presentError(details);
      };

      // Initialize Firebase (minimal, privacy-first)
      try {
        await FirebaseInitializer.init();
      } catch (e, st) {
        DebugLogger.warning('Failed to initialize Firebase', e, st);
      }

      // Deep link service is now initialized in InitialBinding (onReady)

      runApp(const MyApp());

      // Defer notifications setup and prompts until after first frame
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await PushNotificationsService.initializeForegroundHandling();
            await PushNotificationsService.requestUserPermission(provisional: false);
            await PushNotificationsService.getToken();
          } catch (e, st) {
            DebugLogger.warning('Deferred notifications setup failed', e, st);
          }
        });
      } catch (_) {}
    },
    (error, stack) {
      // One-time first null-check trap capture for unhandled async errors
      if (error.toString().contains('Null check operator used on a null value')) {
        NullCheckTrap.capture(error, stack, source: 'zone');
      }
      DebugLogger.error('🚨 [GLOBAL_ERROR] Unhandled zone error', error, stack);
      // Report to Crashlytics if available
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
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
        title: '360 Ghar',
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
