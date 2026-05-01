import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myapplication/core/models/visual_catalog.dart';
import 'package:myapplication/screens/splash.dart';

GoRouter _welcomeRouter() {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Onboarding route'))),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Sign in route'))),
      ),
    ],
  );
}

void main() {
  testWidgets('welcome hero advances through food photos automatically', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.byKey(ValueKey(categoryVisualFor('fruit').imageUrl)), findsOne);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey(categoryVisualFor('vegetables').imageUrl)),
      findsOne,
    );
  });

  testWidgets('welcome Get started opens onboarding route', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _welcomeRouter()));
    await tester.pump();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Onboarding route'), findsOne);
  });

  testWidgets('welcome Sign in opens login route', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _welcomeRouter()));
    await tester.pump();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sign in route'), findsOne);
  });
}
