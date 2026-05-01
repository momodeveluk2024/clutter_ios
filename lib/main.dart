import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/ai_provider.dart';
import 'core/providers/food_provider.dart';
import 'core/providers/nutrition_provider.dart';
import 'core/providers/reminder_provider.dart';
import 'core/router.dart';
import 'core/storage/secure_storage.dart';
import 'theme.dart';

const _enableDevicePreview = bool.fromEnvironment('ENABLE_DEVICE_PREVIEW');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = SecureTokenStorage();
  final api = ApiClient(tokenStorage: storage);
  final authProvider = AuthProvider(api: api, storage: storage);
  await authProvider.initialize();

  final app = NutrimateApp(
    authProvider: authProvider,
    aiProvider: AiProvider(api: api),
    foodProvider: FoodProvider(api: api),
    nutritionProvider: NutritionProvider(api: api),
    reminderProvider: ReminderProvider(api: api),
  );

  runApp(
    kDebugMode && _enableDevicePreview
        ? DevicePreview(builder: (_) => app)
        : app,
  );
}

class NutrimateApp extends StatelessWidget {
  const NutrimateApp({
    super.key,
    required this.authProvider,
    this.aiProvider,
    required this.foodProvider,
    required this.nutritionProvider,
    required this.reminderProvider,
  });

  final AuthProvider authProvider;
  final AiProvider? aiProvider;
  final FoodProvider foodProvider;
  final NutritionProvider nutritionProvider;
  final ReminderProvider reminderProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        if (aiProvider != null)
          ChangeNotifierProvider<AiProvider>.value(value: aiProvider!),
        ChangeNotifierProvider<FoodProvider>.value(value: foodProvider),
        ChangeNotifierProvider<NutritionProvider>.value(
          value: nutritionProvider,
        ),
        ChangeNotifierProvider<ReminderProvider>.value(value: reminderProvider),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(authProvider);
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
            routerConfig: router,
          );
        },
      ),
    );
  }
}
