import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/api/api_endpoints.dart';
import 'package:myapplication/core/providers/auth_provider.dart';
import 'package:myapplication/core/providers/nutrition_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/screens/home.dart';
import 'package:myapplication/screens/onboarding.dart';
import 'package:myapplication/screens/tracker.dart';
import 'package:provider/provider.dart';

class _DocxApiClient extends ApiClient {
  _DocxApiClient({List<Map<String, Object?>>? logItems})
    : _logItems = logItems,
      super(tokenStorage: const SecureTokenStorage());

  final todayDates = <String>[];
  final List<Map<String, Object?>>? _logItems;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (path == ApiEndpoints.todayIntake) {
      todayDates.add(query?['date'] as String? ?? '');
      return _response(path, {'date': query?['date'], 'nutrients': []});
    }
    if (path == ApiEndpoints.logs) {
      final items =
          _logItems ??
          [
            {
              'id': '019dc4da-c114-7b3a-a060-3215bd064c36',
              'food_id': '018f0000-0000-7000-8002-000000000106',
              'food_name': 'Almonds, dry roasted',
              'image_url': 'https://example.com/almonds.jpg',
              'serving_g': 100,
            },
          ];
      return _response(path, {
        'logs': [
          {
            'id': '019dc4da-c100-7b35-bc50-8bbac34a366f',
            'logged_on': query?['from'] ?? '2026-04-25',
            'meal_type': 'breakfast',
            'items': items,
          },
        ],
      });
    }
    if (path == ApiEndpoints.recommendations) {
      return _response(path, {'recommendations': []});
    }
    if (path == ApiEndpoints.streak) {
      return _response(path, {'streak': 1});
    }
    if (path == ApiEndpoints.weekIntake) {
      return _response(path, {'days': []});
    }
    return _response(path, <String, dynamic>{});
  }

  Response<dynamic> _response(String path, Object data) {
    return Response<dynamic>(
      data: data,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  testWidgets('Home recent meal opens the eaten-food details sheet', (
    tester,
  ) async {
    final api = _DocxApiClient();
    await tester.pumpWidget(
      _Providers(
        api: api,
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final recentMeal = find.byKey(
      const ValueKey('recent-meal-019dc4da-c100-7b35-bc50-8bbac34a366f'),
    );
    await tester.ensureVisible(recentMeal);
    await tester.pumpAndSettle();
    await tester.tap(recentMeal);
    await tester.pumpAndSettle();

    expect(find.text('FOODS EATEN'), findsOneWidget);
    expect(find.text('Almonds, dry roasted'), findsWidgets);
    expect(find.text('100g'), findsOneWidget);
  });

  testWidgets('Onboarding can be swiped between slides', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(
      find.textContaining('Know what', findRichText: true),
      findsOneWidget,
    );
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Built around', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Tracker horizontal strip selects an older date by hand', (
    tester,
  ) async {
    final api = _DocxApiClient();
    final older = DateTime.now().subtract(const Duration(days: 1));
    final olderKey = _dateString(older);
    await tester.pumpWidget(
      _Providers(
        api: api,
        child: const MaterialApp(home: Scaffold(body: TrackerScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('track-day-$olderKey')));
    await tester.pumpAndSettle();

    expect(api.todayDates, contains(olderKey));
  });

  testWidgets('Tracker meal card shows four-item mosaic with overflow count', (
    tester,
  ) async {
    final api = _DocxApiClient(logItems: _fiveMealItems());
    await tester.pumpWidget(
      _Providers(
        api: api,
        child: const MaterialApp(home: Scaffold(body: TrackerScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('meal-image-mosaic')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-image-mosaic-tile-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-image-mosaic-tile-3')),
      findsOneWidget,
    );
    expect(find.text('+1'), findsOneWidget);
    expect(find.textContaining('5 foods'), findsOneWidget);
  });

  testWidgets('Meal detail item rows navigate to the food detail route', (
    tester,
  ) async {
    final api = _DocxApiClient(logItems: _fiveMealItems());
    final visitedFoodIds = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: TrackerScreen()),
        ),
        GoRoute(
          path: '/app/food/:id',
          builder: (context, state) {
            visitedFoodIds.add(state.pathParameters['id']!);
            return const Scaffold(body: Text('Food detail opened'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      _Providers(
        api: api,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('meal-log-019dc4da-c100-7b35-bc50-8bbac34a366f'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('meal-food-018f0000-0000-7000-8002-000000000203'),
      ),
    );
    await tester.pumpAndSettle();

    expect(visitedFoodIds, contains('018f0000-0000-7000-8002-000000000203'));
    expect(find.text('Food detail opened'), findsOneWidget);
  });
}

class _Providers extends StatelessWidget {
  const _Providers({required this.api, required this.child});

  final ApiClient api;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const storage = SecureTokenStorage();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(api: api, storage: storage),
        ),
        ChangeNotifierProvider(create: (_) => NutritionProvider(api: api)),
      ],
      child: child,
    );
  }
}

String _dateString(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

List<Map<String, Object?>> _fiveMealItems() {
  return [
    {
      'id': '019dc4da-c114-7b3a-a060-3215bd064c31',
      'food_id': '018f0000-0000-7000-8002-000000000201',
      'food_name': 'Salmon, cooked',
      'image_url': 'https://example.com/salmon.jpg',
      'serving_g': 120,
    },
    {
      'id': '019dc4da-c114-7b3a-a060-3215bd064c32',
      'food_id': '018f0000-0000-7000-8002-000000000202',
      'food_name': 'Spinach',
      'image_url': 'https://example.com/spinach.jpg',
      'serving_g': 80,
    },
    {
      'id': '019dc4da-c114-7b3a-a060-3215bd064c33',
      'food_id': '018f0000-0000-7000-8002-000000000203',
      'food_name': 'Greek yogurt',
      'image_url': 'https://example.com/yogurt.jpg',
      'serving_g': 150,
    },
    {
      'id': '019dc4da-c114-7b3a-a060-3215bd064c34',
      'food_id': '018f0000-0000-7000-8002-000000000204',
      'food_name': 'Blueberries',
      'image_url': 'https://example.com/blueberries.jpg',
      'serving_g': 60,
    },
    {
      'id': '019dc4da-c114-7b3a-a060-3215bd064c35',
      'food_id': '018f0000-0000-7000-8002-000000000205',
      'food_name': 'Almonds',
      'image_url': 'https://example.com/almonds.jpg',
      'serving_g': 30,
    },
  ];
}
