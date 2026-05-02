import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/providers/auth_provider.dart';
import 'package:myapplication/core/providers/food_provider.dart';
import 'package:myapplication/core/providers/notification_provider.dart';
import 'package:myapplication/core/providers/nutrition_provider.dart';
import 'package:myapplication/core/providers/reminder_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/main.dart';
import 'package:myapplication/screens/sign_up.dart';
import 'package:provider/provider.dart';

class _InitializedAuthProvider extends AuthProvider {
  _InitializedAuthProvider({required super.api, required super.storage});

  @override
  bool get initialized => true;

  @override
  bool get isAuthenticated => false;
}

void main() {
  testWidgets('Nutrimate boots to splash', (WidgetTester tester) async {
    const storage = SecureTokenStorage();
    final api = ApiClient(tokenStorage: storage);
    await tester.pumpWidget(
      NutrimateApp(
        authProvider: _InitializedAuthProvider(api: api, storage: storage),
        foodProvider: FoodProvider(api: api),
        nutritionProvider: NutritionProvider(api: api),
        reminderProvider: ReminderProvider(api: api),
        notificationProvider: NotificationProvider(),
      ),
    );
    await tester.pump();

    expect(find.text('Nutrimate'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Get started opens onboarding without layout exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const storage = SecureTokenStorage();
    final api = ApiClient(tokenStorage: storage);
    await tester.pumpWidget(
      NutrimateApp(
        authProvider: _InitializedAuthProvider(api: api, storage: storage),
        foodProvider: FoodProvider(api: api),
        nutritionProvider: NutritionProvider(api: api),
        reminderProvider: ReminderProvider(api: api),
        notificationProvider: NotificationProvider(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('STEP'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/branding/logo.png',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('See the full vitamin'), findsOneWidget);
  });

  testWidgets('Sign in link opens login without layout exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const storage = SecureTokenStorage();
    final api = ApiClient(tokenStorage: storage);
    await tester.pumpWidget(
      NutrimateApp(
        authProvider: _InitializedAuthProvider(api: api, storage: storage),
        foodProvider: FoodProvider(api: api),
        nutritionProvider: NutritionProvider(api: api),
        reminderProvider: ReminderProvider(api: api),
        notificationProvider: NotificationProvider(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/branding/logo.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('Login back button returns to welcome', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const storage = SecureTokenStorage();
    final api = ApiClient(tokenStorage: storage);
    await tester.pumpWidget(
      NutrimateApp(
        authProvider: _InitializedAuthProvider(api: api, storage: storage),
        foodProvider: FoodProvider(api: api),
        nutritionProvider: NutritionProvider(api: api),
        reminderProvider: ReminderProvider(api: api),
        notificationProvider: NotificationProvider(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Create account screen uses the brand logo asset', (
    WidgetTester tester,
  ) async {
    const storage = SecureTokenStorage();
    final api = ApiClient(tokenStorage: storage);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _InitializedAuthProvider(api: api, storage: storage),
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/branding/logo.png',
      ),
      findsOneWidget,
    );
  });
}
