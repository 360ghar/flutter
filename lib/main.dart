import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/utils/webview_helper.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/utils/theme.dart';
import 'app/bindings/initial_binding.dart';
import 'app/controllers/theme_controller.dart';
import 'app/controllers/localization_controller.dart';
import 'app/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize GetStorage before any controllers that depend on it
  await GetStorage.init();
  
  // Initialize WebView platform
  WebViewHelper.ensureInitialized();
  
  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env.development");
    print('✅ Environment variables loaded successfully');
    print('🌐 API Base URL: ${dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1'}');
  } catch (e) {
    print('⚠️ Failed to load .env.development: $e');
    print('💡 Using default configuration');
  }
  
  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('⚠️ Failed to initialize Supabase: $e');
    print('💡 Continuing without Supabase');
  }
  
  // Initialize dependencies before running the app
  InitialBinding().dependencies();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access pre-initialized controllers from InitialBinding
    final ThemeController themeController = Get.find<ThemeController>();
    final LocalizationController localizationController = Get.find<LocalizationController>();
    
    return Obx(() => GetMaterialApp(
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
      debugShowCheckedModeBanner: false,
      // Add proper lifecycle management
      routingCallback: (routing) {
        print('🧭 Routing to: ${routing?.current}');
      },
    ));
  }
} 