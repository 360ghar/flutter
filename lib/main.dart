import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ghar360/core/bindings/initial_binding.dart';
import 'package:ghar360/core/controllers/localization_controller.dart';
import 'package:ghar360/core/design/app_design_theme.dart';
import 'package:ghar360/core/firebase/analytics_service.dart';
import 'package:ghar360/core/firebase/firebase_initializer.dart';
import 'package:ghar360/core/firebase/push_notifications_service.dart';
import 'package:ghar360/core/routes/app_pages.dart';
import 'package:ghar360/core/translations/app_translations.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/null_check_trap.dart';
import 'package:ghar360/core/utils/webview_helper.dart';
import 'package:ghar360/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:ghar360/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:ghar360/root.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  runZonedGuarded(
    () async {
      // CRITICAL PATH ONLY - Do absolute minimum before first frame
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize GetStorage (needed for theme/locale persistence)
      await GetStorage.init();

      // Load environment variables (small file I/O, acceptable on critical path)
      try {
        final envFile = kReleaseMode ? '.env.production' : '.env.development';
        await dotenv.load(fileName: envFile);
      } catch (e) {
        // Continue without .env file - will use defaults
      }

      // Initialize Supabase (REQUIRED for app authentication/session handling)
      final supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
      final supabaseClientKey =
          (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
      if (supabaseUrl.isEmpty || supabaseClientKey.isEmpty) {
        throw StateError(
          'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. '
          'Set these values in your environment before launching the app.',
        );
      }
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseClientKey,
        authOptions: const FlutterAuthClientOptions(
          detectSessionInUri: false,
          autoRefreshToken: true,
        ),
      );

      // Setup global error handlers (lightweight, no I/O)
      FlutterError.onError = (FlutterErrorDetails details) {
        NullCheckTrap.captureFlutterError(details);
        if (FirebaseInitializer.isFirebaseReady) {
          try {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          } catch (_) {
            // Crashlytics may not be initialized yet
          }
        }
        FlutterError.presentError(details);
      };

      // START THE APP NOW - Everything else can wait
      runApp(const MyApp());

      // === DEFER NON-CRITICAL INIT TO POST-FRAME ===
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final launchStart = DateTime.now();

        // Initialize DebugLogger (deferred)
        DebugLogger.initialize();

        // System UI setup (deferred)
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        WebViewHelper.ensureInitialized();

        // Log environment status (deferred)
        try {
          DebugLogger.success('Environment variables loaded successfully');
          DebugLogger.info(
            'API Base URL: ${dotenv.env['API_BASE_URL'] ?? 'https://api.360ghar.com'}',
          );
          DebugLogger.success('Supabase initialized successfully');
        } catch (e) {
          DebugLogger.warning('Failed to load .env file', e);
          DebugLogger.info('Using default configuration');
        }

        // Initialize Firebase (deferred - not critical for startup)
        try {
          await FirebaseInitializer.init();
          DebugLogger.success('Firebase initialized');
        } catch (e, st) {
          DebugLogger.warning('Failed to initialize Firebase', e, st);
        }

        // Track app launch duration (deferred)
        final launchDuration = DateTime.now().difference(launchStart);
        AnalyticsService.appLaunchComplete(durationMs: launchDuration.inMilliseconds);

        // Setup notifications (already deferred, keep as-is)
        _setupNotifications();
      });

      // Defer notifications setup and prompts until after first frame
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            if (!FirebaseInitializer.isFirebaseReady) {
              DebugLogger.info('🔔 Skipping deferred notifications setup (Firebase disabled)');
              return;
            }

            DebugLogger.info('🔔 Starting deferred notifications setup...');

            // Configure token registration callback to send token to backend
            PushNotificationsService.onTokenRegistration = (token) async {
              try {
                final auth = Supabase.instance.client.auth;
                final session = auth.currentSession;

                if (session == null || session.accessToken.isEmpty) {
                  DebugLogger.info(
                    '🔔 Skipping token registration until authenticated session exists',
                  );
                  return;
                }

                final userId = auth.currentUser?.id;
                if (userId == null || userId.isEmpty) {
                  DebugLogger.info(
                    '🔔 Skipping token registration until authenticated user exists',
                  );
                  return;
                }

                if (Get.isRegistered<NotificationsRemoteDatasource>()) {
                  final datasource = Get.find<NotificationsRemoteDatasource>();
                  await datasource.registerDeviceToken(token: token, userId: userId);
                } else {
                  DebugLogger.warning('🔔 NotificationsRemoteDatasource not registered yet');
                }
              } catch (e, st) {
                DebugLogger.warning('🔔 Failed to register token with backend', e, st);
              }
            };

            // Initialize FCM handling (foreground, background, terminated states)
            await PushNotificationsService.initializeForegroundHandling();

            // Request notification permissions
            final settings = await PushNotificationsService.requestUserPermission(
              provisional: false,
            );
            if (settings == null) {
              DebugLogger.info('🔔 Notification permission flow skipped');
              return;
            }
            final authorizationStatus = settings.authorizationStatus;
            DebugLogger.info('🔔 Permission status: $authorizationStatus');

            final canRequestToken =
                authorizationStatus == AuthorizationStatus.authorized ||
                authorizationStatus == AuthorizationStatus.provisional;
            if (!canRequestToken) {
              DebugLogger.warning(
                '🔔 Notifications permission not granted yet; skipping token retrieval.',
              );
              return;
            }

            final isApplePlatform =
                !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS);

            // Get and log FCM token (this will also trigger registration with backend)
            String? token = await PushNotificationsService.getToken();
            if (token == null && !isApplePlatform) {
              DebugLogger.info('🔔 FCM token not available yet; retrying once shortly...');
              await Future<void>.delayed(const Duration(seconds: 2));
              token = await PushNotificationsService.getToken();
            }

            if (token != null) {
              DebugLogger.success('🔔 Notifications setup complete. Token available.');
              // Check if notifications are actually enabled on the device
              final enabled = await PushNotificationsService.areNotificationsEnabled();
              DebugLogger.info('🔔 Notifications enabled on device: $enabled');
            } else if (isApplePlatform) {
              DebugLogger.warning(
                '🔔 Notifications setup incomplete - no FCM token. On iOS simulator this can be expected; on a real device verify APNS entitlements/provisioning.',
              );
            } else {
              DebugLogger.warning('🔔 Notifications setup incomplete - no FCM token!');
            }
          } catch (e, st) {
            DebugLogger.error('🔔 Deferred notifications setup failed', e, st);
          }
        });
      } catch (e) {
        DebugLogger.warning('Failed to schedule notifications setup: $e');
      }
    },
    (error, stack) {
      // One-time first null-check trap capture for unhandled async errors
      if (error.toString().contains('Null check operator used on a null value')) {
        NullCheckTrap.capture(error, stack, source: 'zone');
      }
      // Logger may not be initialized yet, so skip logging here
      // Report to Crashlytics if available
      if (FirebaseInitializer.isFirebaseReady) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {
          // Crashlytics may not be initialized yet
        }
      }
    },
  );
}

/// Deferred notifications setup - runs after first frame
void _setupNotifications() {
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!FirebaseInitializer.isFirebaseReady) {
          DebugLogger.info('🔔 Skipping deferred notifications setup (Firebase disabled)');
          return;
        }

        DebugLogger.info('🔔 Starting deferred notifications setup...');

        // Configure token registration callback to send token to backend
        PushNotificationsService.onTokenRegistration = (token) async {
          try {
            final auth = Supabase.instance.client.auth;
            final session = auth.currentSession;

            if (session == null || session.accessToken.isEmpty) {
              DebugLogger.info('🔔 Skipping token registration until authenticated session exists');
              return;
            }

            final userId = auth.currentUser?.id;
            if (userId == null || userId.isEmpty) {
              DebugLogger.info('🔔 Skipping token registration until authenticated user exists');
              return;
            }

            if (Get.isRegistered<NotificationsRemoteDatasource>()) {
              final datasource = Get.find<NotificationsRemoteDatasource>();
              await datasource.registerDeviceToken(token: token, userId: userId);
            } else {
              DebugLogger.warning('🔔 NotificationsRemoteDatasource not registered yet');
            }
          } catch (e, st) {
            DebugLogger.warning('🔔 Failed to register token with backend', e, st);
          }
        };

        // Initialize FCM handling (foreground, background, terminated states)
        await PushNotificationsService.initializeForegroundHandling();

        // Request notification permissions
        final settings = await PushNotificationsService.requestUserPermission(provisional: false);
        if (settings == null) {
          DebugLogger.info('🔔 Notification permission flow skipped');
          return;
        }
        final authorizationStatus = settings.authorizationStatus;
        DebugLogger.info('🔔 Permission status: $authorizationStatus');

        final canRequestToken =
            authorizationStatus == AuthorizationStatus.authorized ||
            authorizationStatus == AuthorizationStatus.provisional;
        if (!canRequestToken) {
          DebugLogger.warning(
            '🔔 Notifications permission not granted yet; skipping token retrieval.',
          );
          return;
        }

        final isApplePlatform =
            !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS);

        // Get and log FCM token (this will also trigger registration with backend)
        String? token = await PushNotificationsService.getToken();
        if (token == null && !isApplePlatform) {
          DebugLogger.info('🔔 FCM token not available yet; retrying once shortly...');
          await Future<void>.delayed(const Duration(seconds: 2));
          token = await PushNotificationsService.getToken();
        }

        if (token != null) {
          DebugLogger.success('🔔 Notifications setup complete. Token available.');
          // Check if notifications are actually enabled on the device
          final enabled = await PushNotificationsService.areNotificationsEnabled();
          DebugLogger.info('🔔 Notifications enabled on device: $enabled');
        } else if (isApplePlatform) {
          DebugLogger.warning(
            '🔔 Notifications setup incomplete - no FCM token. On iOS simulator this can be expected; on a real device verify APNS entitlements/provisioning.',
          );
        } else {
          DebugLogger.warning('🔔 Notifications setup incomplete - no FCM token!');
        }
      } catch (e, st) {
        DebugLogger.error('🔔 Deferred notifications setup failed', e, st);
      }
    });
  } catch (e) {
    // Fallback if DebugLogger not ready
    // Ignore silently - notifications will be setup on next launch
  }
}

/// Reads the persisted theme mode from GetStorage synchronously.
/// GetStorage.init() is already awaited in main() before runApp().
ThemeMode _readInitialThemeMode() {
  final stored = GetStorage().read<String>('themeMode');
  switch (stored) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Reads the persisted locale from GetStorage synchronously.
/// After init, LocalizationController manages via Get.updateLocale().
Locale _readInitialLocale() {
  final storage = GetStorage();
  final langCode = storage.read<String>('language_code');
  final countryCode = storage.read<String>('country_code');
  if (langCode != null && countryCode != null) {
    return Locale(langCode, countryCode);
  }
  return const Locale('en', 'US');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '360 Ghar',
      theme: AppDesignTheme.light(),
      darkTheme: AppDesignTheme.dark(),
      themeMode: _readInitialThemeMode(),
      locale: _readInitialLocale(),
      defaultTransition: Transition.native,
      transitionDuration: AppDesignTheme.defaultTransitionDuration,
      popGesture: true,
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
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
      routingCallback: (routing) {
        DebugLogger.debug('Routing to: ${routing?.current}');

        if (Get.isRegistered<DashboardController>()) {
          final currentRoute = routing?.current ?? '';
          Get.find<DashboardController>().syncTabWithRoute(currentRoute);
        }
      },
    );
  }
}
