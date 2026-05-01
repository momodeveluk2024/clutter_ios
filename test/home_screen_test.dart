import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/models/nutrition.dart';
import 'package:myapplication/core/models/user.dart';
import 'package:myapplication/core/providers/auth_provider.dart';
import 'package:myapplication/core/providers/nutrition_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/screens/home.dart';
import 'package:myapplication/theme.dart';
import 'package:provider/provider.dart';

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider(this.fakeUser)
    : super(
        api: ApiClient(tokenStorage: const SecureTokenStorage()),
        storage: const SecureTokenStorage(),
      );

  final AppUser fakeUser;

  @override
  AppUser? get user => fakeUser;
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient() : super(tokenStorage: const SecureTokenStorage());

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = switch (path) {
      '/me/streak' => {'streak': 12},
      _ => const <String, dynamic>{},
    };
    return Response<dynamic>(
      data: data,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  testWidgets('Home empty state remains a useful command center', (
    tester,
  ) async {
    final nutrition = NutritionProvider(api: _NoopApiClient())
      ..todayTotals = const DayNutrientTotals(date: '2026-04-28', nutrients: [])
      ..recommendations = const []
      ..logs = const []
      ..streak = 12;
    final auth = _FakeAuthProvider(
      const AppUser(
        id: 'user-1',
        email: 'ahmed@gmail.com',
        displayName: 'ahmed',
        units: 'metric',
        locale: 'en',
        timezone: 'Asia/Baghdad',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
        ],
        child: MaterialApp(
          theme: NVTheme.light(),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Daily command'), findsOneWidget);
    expect(find.text('STARTER · RECOMMENDATIONS'), findsOneWidget);
    expect(find.text('TOP · NUTRIENT GAPS'), findsOneWidget);
    expect(find.text('12-day streak'), findsOneWidget);
  });
}
