import '../models/food.dart';
import '../models/nutrition.dart';

class NutrientOverage {
  const NutrientOverage({
    required this.code,
    required this.name,
    required this.currentPercent,
    required this.projectedPercent,
  });

  final String code;
  final String name;
  final double currentPercent;
  final double projectedPercent;
}

List<NutrientOverage> projectedOverages({
  required DayNutrientTotals? currentTotals,
  required FoodDetail food,
  required double servingG,
}) {
  if (currentTotals == null) return const [];
  final totalsByCode = {
    for (final nutrient in currentTotals.nutrients) nutrient.code: nutrient,
  };
  final warnings = <NutrientOverage>[];
  for (final nutrient in food.breakdown) {
    final current = totalsByCode[nutrient.code];
    final target = current?.driAmount ?? nutrient.driAmount;
    if (target == null || target <= 0) continue;

    final currentAmount = current?.amount ?? 0;
    final rawAddedAmount = nutrient.amountPer100G * (servingG / 100);
    final percentDailyValueAmount =
        target * ((nutrient.driPercent ?? 0) / 100) * (servingG / 100);
    final addedAmount = rawAddedAmount > 0
        ? rawAddedAmount
        : percentDailyValueAmount;
    if (addedAmount <= 0) continue;

    final currentPercent =
        current?.driPercent ?? ((currentAmount / target) * 100);
    final projectedPercent = ((currentAmount + addedAmount) / target) * 100;
    if (currentPercent <= 100 && projectedPercent > 100) {
      warnings.add(
        NutrientOverage(
          code: nutrient.code,
          name: nutrient.name,
          currentPercent: currentPercent,
          projectedPercent: projectedPercent,
        ),
      );
    }
  }
  warnings.sort((a, b) => b.projectedPercent.compareTo(a.projectedPercent));
  return warnings;
}
