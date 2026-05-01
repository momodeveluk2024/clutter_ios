class NutrientTotal {
  const NutrientTotal({
    required this.code,
    required this.name,
    required this.unit,
    required this.amount,
    this.driAmount,
    this.driPercent,
  });

  final String code;
  final String name;
  final String unit;
  final double amount;
  final double? driAmount;
  final double? driPercent;

  factory NutrientTotal.fromJson(Map<String, dynamic> json) {
    return NutrientTotal(
      code: json['code'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      driAmount: (json['dri_amount'] as num?)?.toDouble(),
      driPercent: (json['dri_percent'] as num?)?.toDouble(),
    );
  }
}

class DayNutrientTotals {
  const DayNutrientTotals({required this.date, required this.nutrients});

  final String date;
  final List<NutrientTotal> nutrients;

  factory DayNutrientTotals.fromJson(Map<String, dynamic> json) {
    return DayNutrientTotals(
      date: json['date'] as String? ?? '',
      nutrients: (json['nutrients'] as List? ?? const [])
          .map((v) => NutrientTotal.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
    );
  }

  double get averagePercent {
    final percents = nutrients.map((n) => n.driPercent).whereType<double>().toList();
    if (percents.isEmpty) return 0;
    return percents.reduce((a, b) => a + b) / percents.length;
  }
}

class Recommendation {
  const Recommendation({
    required this.code,
    required this.name,
    required this.message,
    this.percent,
    required this.foodId,
    required this.foodName,
    this.foodImageUrl,
  });

  final String code;
  final String name;
  final String message;
  final double? percent;
  final String foodId;
  final String foodName;
  final String? foodImageUrl;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      code: json['code'] as String,
      name: json['name'] as String,
      message: json['message'] as String,
      percent: (json['percent'] as num?)?.toDouble(),
      foodId: json['food_id'] as String,
      foodName: json['food_name'] as String,
      foodImageUrl: json['food_image_url'] as String?,
    );
  }
}
