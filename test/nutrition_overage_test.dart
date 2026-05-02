import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/models/food.dart';
import 'package:myapplication/core/models/nutrition.dart';
import 'package:myapplication/core/nutrition/overage_warning.dart';

void main() {
  test('projectedOverages returns nutrients that cross 100 percent', () {
    final current = DayNutrientTotals(
      date: '2026-05-02',
      nutrients: const [
        NutrientTotal(
          code: 'Protein',
          name: 'Protein',
          unit: 'g',
          amount: 45,
          driAmount: 50,
          driPercent: 90,
        ),
        NutrientTotal(
          code: 'D',
          name: 'Vitamin D',
          unit: 'mcg',
          amount: 8,
          driAmount: 20,
          driPercent: 40,
        ),
      ],
    );
    const food = FoodDetail(
      id: 'food-1',
      name: 'Protein bowl',
      category: 'general',
      servingSizeG: 100,
      verified: true,
      nutrients: ['Protein', 'D'],
      source: 'test',
      breakdown: [
        FoodNutrient(
          code: 'Protein',
          name: 'Protein',
          unit: 'g',
          amountPer100G: 10,
          driAmount: 50,
          driPercent: 20,
        ),
        FoodNutrient(
          code: 'D',
          name: 'Vitamin D',
          unit: 'mcg',
          amountPer100G: 2,
          driAmount: 20,
          driPercent: 10,
        ),
      ],
    );

    final warnings = projectedOverages(
      currentTotals: current,
      food: food,
      servingG: 100,
    );

    expect(warnings.map((w) => w.code), ['Protein']);
    expect(warnings.single.currentPercent, 90);
    expect(warnings.single.projectedPercent, closeTo(110, 0.001));
  });

  test(
    'projectedOverages uses percent Daily Value when raw amount is absent',
    () {
      final current = DayNutrientTotals(
        date: '2026-05-02',
        nutrients: const [
          NutrientTotal(
            code: 'B12',
            name: 'Vitamin B12',
            unit: 'mcg',
            amount: 2.2,
            driAmount: 2.4,
            driPercent: 92,
          ),
        ],
      );
      const food = FoodDetail(
        id: 'food-2',
        name: 'Imported cereal',
        category: 'general',
        servingSizeG: 100,
        verified: true,
        nutrients: ['B12'],
        source: 'percent Daily Value',
        breakdown: [
          FoodNutrient(
            code: 'B12',
            name: 'Vitamin B12',
            unit: 'mcg',
            amountPer100G: 0,
            driAmount: 2.4,
            driPercent: 20,
          ),
        ],
      );

      final warnings = projectedOverages(
        currentTotals: current,
        food: food,
        servingG: 100,
      );

      expect(warnings.map((w) => w.code), ['B12']);
      expect(warnings.single.projectedPercent.round(), 112);
    },
  );
}
