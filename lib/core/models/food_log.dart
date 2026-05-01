class MealLogItem {
  const MealLogItem({
    required this.id,
    required this.foodId,
    required this.foodName,
    this.imageUrl,
    required this.servingG,
  });

  final String id;
  final String foodId;
  final String foodName;
  final String? imageUrl;
  final double servingG;

  factory MealLogItem.fromJson(Map<String, dynamic> json) {
    return MealLogItem(
      id: json['id'] as String,
      foodId: json['food_id'] as String,
      foodName: json['food_name'] as String? ?? 'Food',
      imageUrl: json['image_url'] as String?,
      servingG: (json['serving_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MealLog {
  const MealLog({
    required this.id,
    required this.loggedOn,
    required this.mealType,
    this.notes,
    required this.items,
  });

  final String id;
  final String loggedOn;
  final String mealType;
  final String? notes;
  final List<MealLogItem> items;

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String,
      loggedOn: json['logged_on'] as String,
      mealType: json['meal_type'] as String,
      notes: json['notes'] as String?,
      items: (json['items'] as List? ?? const [])
          .map((v) => MealLogItem.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
    );
  }
}
