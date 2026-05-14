class MealLogItem {
  const MealLogItem({
    required this.id,
    required this.foodId,
    required this.foodName,
    this.imageUrl,
    required this.servingG,
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
  });

  final String id;
  final String foodId;
  final String foodName;
  final String? imageUrl;
  final double servingG;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  /// True when the backend has no usable nutrition data for the underlying food.
  bool get hasNutrition =>
      caloriesKcal > 0 || proteinG > 0 || carbsG > 0 || fatG > 0 || fiberG > 0;

  /// Kcal as the backend sent it, or — when stored kcal is missing — an
  /// Atwater estimate from the macros (P*4 + C*4 + F*9). Lets the UI show a
  /// number when only macros are available.
  double get displayKcal {
    if (caloriesKcal > 0) return caloriesKcal;
    final estimate = proteinG * 4 + carbsG * 4 + fatG * 9;
    return estimate > 0 ? estimate : 0;
  }

  factory MealLogItem.fromJson(Map<String, dynamic> json) {
    return MealLogItem(
      id: json['id'] as String,
      foodId: json['food_id'] as String,
      foodName: json['food_name'] as String? ?? 'Food',
      imageUrl: json['image_url'] as String?,
      servingG: (json['serving_g'] as num?)?.toDouble() ?? 0,
      caloriesKcal: (json['calories_kcal'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MealLog {
  const MealLog({
    required this.id,
    required this.loggedOn,
    required this.mealType,
    this.notes,
    this.pairedDrink,
    required this.items,
  });

  final String id;
  final String loggedOn;
  final String mealType;
  final String? notes;
  final String? pairedDrink;
  final List<MealLogItem> items;

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String,
      loggedOn: json['logged_on'] as String,
      mealType: json['meal_type'] as String,
      notes: json['notes'] as String?,
      pairedDrink: json['paired_drink'] as String?,
      items: (json['items'] as List? ?? const [])
          .map((v) => MealLogItem.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
    );
  }
}
