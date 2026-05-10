import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/analytics/analytics_service.dart';
import 'core/api/api_client.dart';
import 'core/notifications/fcm_notification_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/ai_provider.dart';
import 'core/providers/food_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/nutrition_provider.dart';
import 'core/providers/reminder_provider.dart';
import 'core/router.dart';
import 'core/storage/secure_storage.dart';
import 'theme.dart';
import 'firebase_options.dart';

const _enableDevicePreview = bool.fromEnvironment('ENABLE_DEVICE_PREVIEW');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics: collect Dart errors in release; mirror to console in debug.
  // Must run after Firebase.initializeApp.
  FlutterError.onError = (details) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    kReleaseMode,
  );

  await AnalyticsService.instance.initialize();

  // Initialize timezone data early so notification scheduling can use tz.local
  tz.initializeTimeZones();
  final localTz = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(localTz.identifier));

  const storage = SecureTokenStorage();
  final api = ApiClient(tokenStorage: storage);
  final authProvider = AuthProvider(api: api, storage: storage);
  await authProvider.initialize();
  AnalyticsService.instance.bindAuth(authProvider);

  final notificationProvider = NotificationProvider(api: api);
  authProvider.addListener(() {
    // Defer notification sync so it doesn't compete with the heavy
    // login route transition on the Android main thread.
    Future.delayed(const Duration(seconds: 2), () {
      notificationProvider.handleAuthChanged(
        isAuthenticated: authProvider.isAuthenticated,
      );
    });
  });

  final app = NutrimateApp(
    authProvider: authProvider,
    aiProvider: AiProvider(api: api),
    foodProvider: FoodProvider(api: api),
    nutritionProvider: NutritionProvider(api: api),
    reminderProvider: ReminderProvider(api: api),
    notificationProvider: notificationProvider,
  );

  runApp(
    kDebugMode && _enableDevicePreview
        ? DevicePreview(builder: (_) => app)
        : app,
  );

  unawaited(
    _initializeNotificationsAfterFirstFrame(
      notificationProvider,
      isAuthenticated: authProvider.isAuthenticated,
    ),
  );
}

Future<void> _initializeNotificationsAfterFirstFrame(
  NotificationProvider notificationProvider, {
  required bool isAuthenticated,
}) async {
  // Wait well past the critical first-render window. On first install,
  // Impeller shader compilation + the HomeScreen data load can block the
  // main thread for several seconds. Running notification channel creation
  // (platform channel calls) during that window pushes the device over
  // the ANR threshold on MIUI.
  await Future.delayed(const Duration(seconds: 5));
  await NotificationService.instance.initialize();
  await notificationProvider.initialize();
  await notificationProvider.handleAuthChanged(
    isAuthenticated: isAuthenticated,
  );
}

class NutrimateApp extends StatefulWidget {
  const NutrimateApp({
    super.key,
    required this.authProvider,
    this.aiProvider,
    required this.foodProvider,
    required this.nutritionProvider,
    required this.reminderProvider,
    required this.notificationProvider,
  });

  final AuthProvider authProvider;
  final AiProvider? aiProvider;
  final FoodProvider foodProvider;
  final NutritionProvider nutritionProvider;
  final ReminderProvider reminderProvider;
  final NotificationProvider notificationProvider;

  @override
  State<NutrimateApp> createState() => _NutrimateAppState();
}

class _NutrimateAppState extends State<NutrimateApp> {
  late final GoRouter _router;
  StreamSubscription<String?>? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(widget.authProvider);
    _notificationTapSub = notificationTapStream.stream.listen((route) {
      if (route == null || route.trim().isEmpty) return;
      _router.go(route);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = FcmNotificationService.instance.takePendingRoute();
      if (route != null && route.trim().isNotEmpty) {
        _router.go(route);
      }
    });
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: widget.authProvider),
        if (widget.aiProvider != null)
          ChangeNotifierProvider<AiProvider>.value(value: widget.aiProvider!),
        ChangeNotifierProvider<FoodProvider>.value(value: widget.foodProvider),
        ChangeNotifierProvider<NutritionProvider>.value(
          value: widget.nutritionProvider,
        ),
        ChangeNotifierProvider<ReminderProvider>.value(
          value: widget.reminderProvider,
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: widget.notificationProvider,
        ),
      ],
      child: Builder(
        builder: (context) {
          final appearance = context.select<AuthProvider, String>(
            (provider) => provider.user?.appearance ?? 'light',
          );
          return MaterialApp.router(
            locale: kDebugMode && _enableDevicePreview
                ? DevicePreview.locale(context)
                : null,
            builder: kDebugMode && _enableDevicePreview
                ? DevicePreview.appBuilder
                : null,
            title: 'Nutrimate',
            debugShowCheckedModeBanner: false,
            theme: NVTheme.light(),
            darkTheme: NVTheme.dark(),
            themeMode: switch (appearance) {
              'dark' => ThemeMode.dark,
              'system' => ThemeMode.system,
              _ => ThemeMode.light,
            },
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
