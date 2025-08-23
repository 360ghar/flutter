import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/webview_helper.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/utils/theme.dart';
import 'core/bindings/initial_binding.dart';
import 'core/controllers/theme_controller.dart';
import 'core/controllers/localization_controller.dart';
import 'core/translations/app_translations.dart';
import 'core/utils/debug_logger.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';


// Use a separate async function for initialization to ensure proper order.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // It's critical that these initializations succeed before running the app.
  // The original code had try-catch blocks that hid the root cause of the crash.
  try {
    // 1. Initialize GetStorage first.
    await GetStorage.init();

    // 2. Load environment variables. This is essential.
    await dotenv.load(fileName: ".env.development");

    // 3. Initialize the logger now that dotenv is loaded.
    DebugLogger.initialize();
    DebugLogger.success('Environment variables loaded successfully.');

    // 4. Initialize Supabase. This is also essential.
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      // If credentials are not in .env, the app cannot function.
      // This provides a clear error instead of crashing later.
      throw Exception('Supabase URL/Key not found in .env file. Please check your setup.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    DebugLogger.success('Supabase initialized successfully.');

    // 5. Initialize other services.
    WebViewHelper.ensureInitialized();

  } catch (e) {
    // If any critical initialization fails, show an error screen.
    runApp(InitializationErrorApp(error: e));
    return; // Stop execution
  }

  // If all initializations are successful, run the main app.
  runApp(const MyApp());
}

// A simple widget to display a critical error during initialization.
class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Fatal Error during App Initialization:\n\n$error\n\nPlease check your .env configuration and restart the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Let GetX manage the controllers through bindings
    return GetBuilder<ThemeController>(
      init: ThemeController(),
      builder: (themeController) {
        return GetBuilder<LocalizationController>(
          init: LocalizationController(),
          builder: (localizationController) {
            return GetMaterialApp(
              title: 'app_name'.tr,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeController.themeMode,
              locale: localizationController.currentLocale,
              supportedLocales: LocalizationController.supportedLocales,
              translations: AppTranslations(),
              fallbackLocale: const Locale('en', 'US'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: AppRoutes.splash,
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
            );
          },
        );
      },
    );
  }
} 