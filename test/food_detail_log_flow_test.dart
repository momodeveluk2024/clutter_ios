import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/models/food.dart';
import 'package:myapplication/core/providers/food_provider.dart';
import 'package:myapplication/core/providers/nutrition_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/screens/food_detail.dart';
import 'package:myapplication/theme.dart';
import 'package:provider/provider.dart';

class _FakeFoodProvider extends FoodProvider {
  _FakeFoodProvider()
    : super(api: ApiClient(tokenStorage: const SecureTokenStorage()));

  static const food = FoodDetail(
    id: 'food-1',
    name: 'Apple Cider Vinegar',
    category: 'drinks',
    servingSizeG: 100,
    verified: true,
    nutrients: ['Kp'],
    source: 'seed',
    breakdown: [
      FoodNutrient(
        code: 'Kp',
        name: 'Potassium',
        unit: 'mg',
        amountPer100G: 73,
        driAmount: 4700,
        driPercent: 2,
      ),
    ],
  );

  @override
  Future<List<FoodSummary>> loadFavorites() async => const [];

  @override
  Future<FoodDetail> getFood(String id) async => food;

  @override
  bool isFavorite(String foodId) => false;
}

class _FakeNutritionProvider extends NutritionProvider {
  _FakeNutritionProvider()
    : super(api: ApiClient(tokenStorage: const SecureTokenStorage()));

  var createLogCalls = 0;

  @override
  Future<void> createLog({
    required String foodId,
    required double servingG,
    required String mealType,
    DateTime? date,
    String? pairedDrink,
    String? notes,
  }) async {
    createLogCalls += 1;
  }
}

void main() {
  testWidgets('successful food log closes the sheet before showing success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final nutrition = _FakeNutritionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FoodProvider>.value(value: _FakeFoodProvider()),
          ChangeNotifierProvider<NutritionProvider>.value(
            value: nutrition,
          ),
        ],
        child: MaterialApp(
          theme: NVTheme.light(),
          home: const FoodDetailScreen(foodId: 'food-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log this food'));
    await tester.tap(find.text('Log this food'));
    await tester.pumpAndSettle();

    expect(find.text('ADD TO YOUR LOG'), findsOneWidget);

    await tester.ensureVisible(find.text('Save to log'));
    await tester.tap(find.text('Save to log'));
    expect(nutrition.createLogCalls, 1);

    for (var i = 0; i < 200; i += 1) {
      await tester.pump(const Duration(milliseconds: 10));
      if (find.textContaining('Logged').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Logged'), findsOneWidget);
    expect(find.text('ADD TO YOUR LOG'), findsNothing);
    expect(find.text('Save to log'), findsNothing);
  });
}
