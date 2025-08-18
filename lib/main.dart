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

void main() async {
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
    DebugLogger.info('API Base URL: ${dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000'}');
  } catch (e) {
    DebugLogger.warning('Failed to load .env.development', e);
    DebugLogger.info('Using default configuration');
  }
  
  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    DebugLogger.success('Supabase initialized successfully');
  } catch (e) {
    DebugLogger.warning('Failed to initialize Supabase', e);
    DebugLogger.info('Continuing without Supabase');
  }
  
  runApp(const MyApp());
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
              },
            );
          },
        );
      },
    );
  }
} 