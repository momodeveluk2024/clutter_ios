import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/models/nutrient_reference.dart';
import 'package:myapplication/theme.dart';
import 'package:myapplication/widgets.dart';

void main() {
  testWidgets('NutrientCard presents nutrient metadata and action affordance', (
    tester,
  ) async {
    final nutrient = nutrientReferencesByCode['B12']!;

    await tester.pumpWidget(
      MaterialApp(
        theme: NVTheme.light(),
        home: Scaffold(
          body: NutrientCard(nutrient: nutrient, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Vitamin B12'), findsOneWidget);
    expect(find.text('vitamin'), findsOneWidget);
    expect(find.text('2.4 mcg'), findsOneWidget);
    expect(find.textContaining('nerves'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
