import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/providers/food_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/screens/explore.dart';
import 'package:provider/provider.dart';

class _ExploreApiClient extends ApiClient {
  _ExploreApiClient() : super(tokenStorage: const SecureTokenStorage());

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return Response<dynamic>(
      data: {
        'foods': [
          {
            'id': '018f0000-0000-7000-8002-000000000101',
            'name': 'Spinach',
            'category': 'vegetables',
            'serving_size_g': 100,
            'verified': true,
            'nutrients': ['A', 'C'],
          },
          {
            'id': '018f0000-0000-7000-8002-000000000102',
            'name': 'Broccoli',
            'category': 'vegetables',
            'serving_size_g': 100,
            'verified': true,
            'nutrients': ['C', 'K'],
          },
          {
            'id': '018f0000-0000-7000-8002-000000000103',
            'name': 'Orange',
            'category': 'fruit',
            'serving_size_g': 100,
            'verified': true,
            'nutrients': ['C'],
          },
        ],
      },
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  testWidgets('Explore opens premium nutrient suites from three pickers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final visitedVitamins = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => FoodProvider(api: _ExploreApiClient()),
            child: const Scaffold(body: ExploreScreen()),
          ),
        ),
        GoRoute(
          path: '/app/search',
          builder: (context, state) => Scaffold(
            body: Text('category=${state.uri.queryParameters['category']}'),
          ),
        ),
        GoRoute(
          path: '/app/vitamin/:code',
          builder: (context, state) {
            visitedVitamins.add(state.pathParameters['code']!);
            return Scaffold(
              body: Text('vitamin=${state.pathParameters['code']}'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Vitamins'), findsOneWidget);
    expect(find.text('Minerals'), findsOneWidget);
    expect(find.text('Macros'), findsOneWidget);
    expect(find.text('13 essentials'), findsOneWidget);
    expect(find.text('Browse nutrients'), findsNothing);
    expect(find.text('Vegetables'), findsOneWidget);
    expect(find.text('Fruit'), findsOneWidget);
    expect(find.text('VITAMINS'), findsNothing);
    expect(find.text('MINERALS'), findsNothing);
    expect(find.text('MACROS'), findsNothing);
    expect(find.text('Vitamin A'), findsNothing);

    await tester.tap(find.text('Vitamins'));
    await tester.pumpAndSettle();

    expect(find.text('Vitamin Suite'), findsOneWidget);
    expect(
      find.text('Curated essentials for everyday vitality'),
      findsOneWidget,
    );
    expect(find.text('VITAMINS'), findsWidgets);
    expect(
      find.byKey(const ValueKey('luxury-nutrient-chip-A')),
      findsOneWidget,
    );

    await tester.tap(find.text('Vitamin A').last);
    await tester.pumpAndSettle();

    expect(visitedVitamins, contains('A'));
    expect(find.text('vitamin=A'), findsOneWidget);
  });
}
