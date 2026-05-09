import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/providers/food_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/screens/search.dart';
import 'package:provider/provider.dart';

class _SearchApiClient extends ApiClient {
  _SearchApiClient() : super(tokenStorage: const SecureTokenStorage());

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return Response<dynamic>(
      data: {
        'foods': [
          {
            'id': '018f0000-0000-7000-8002-000000000201',
            'name': 'Apple Juice',
            'category': 'drinks',
            'serving_size_g': 100,
            'verified': true,
            'nutrients': ['A', 'C'],
          },
        ],
      },
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  testWidgets('food search results use a green plus affordance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => FoodProvider(api: _SearchApiClient()),
            child: const SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/app/food/:id',
          builder: (context, state) =>
              Scaffold(body: Text('food=${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Apple Juice'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    final plus = tester.widget<Icon>(find.byIcon(Icons.add_rounded));
    expect(plus.color, const Color(0xFF2F7D4A));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(
      find.text('food=018f0000-0000-7000-8002-000000000201'),
      findsOneWidget,
    );
  });
}
