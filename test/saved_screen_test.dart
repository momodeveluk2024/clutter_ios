import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/models/food.dart';
import 'package:myapplication/core/providers/food_provider.dart';
import 'package:myapplication/core/providers/nutrition_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/screens/favorites.dart';
import 'package:myapplication/theme.dart';
import 'package:provider/provider.dart';

class _EmptyFoodProvider extends FoodProvider {
  _EmptyFoodProvider()
    : super(api: ApiClient(tokenStorage: const SecureTokenStorage()));

  @override
  Future<List<FoodSummary>> loadFavorites() async {
    favorites = const [];
    notifyListeners();
    return favorites;
  }
}

class _EmptyNutritionProvider extends NutritionProvider {
  _EmptyNutritionProvider()
    : super(api: ApiClient(tokenStorage: const SecureTokenStorage()));

  @override
  Future<void> refreshDashboard({DateTime? date}) async {
    logs = const [];
    notifyListeners();
  }
}

void main() {
  testWidgets('Saved screen does not show default vitamins as saved items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FoodProvider>(
            create: (_) => _EmptyFoodProvider(),
          ),
          ChangeNotifierProvider<NutritionProvider>(
            create: (_) => _EmptyNutritionProvider(),
          ),
        ],
        child: MaterialApp(
          theme: NVTheme.light(),
          home: const Scaffold(body: FavoritesScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Foods'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Vitamins'), findsNothing);
    expect(find.text('Vitamin A'), findsNothing);
  });
}
