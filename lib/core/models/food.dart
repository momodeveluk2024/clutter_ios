class FoodSummary {
  const FoodSummary({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.servingSizeG,
    required this.verified,
    required this.nutrients,
    this.imageUrl,
    this.backgroundColor,
    this.ownerUserId,
    this.driPercent,
  });

  final String id;
  final String name;
  final String? brand;
  final String category;
  final double servingSizeG;
  final bool verified;
  final List<String> nutrients;
  final String? imageUrl;
  final String? backgroundColor;
  final String? ownerUserId;
  final double? driPercent;

  factory FoodSummary.fromJson(Map<String, dynamic> json) {
    return FoodSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: json['category'] as String? ?? 'general',
      servingSizeG: (json['serving_size_g'] as num?)?.toDouble() ?? 100,
      verified: json['verified'] as bool? ?? false,
      nutrients: (json['nutrients'] as List? ?? const [])
          .map((v) => v.toString())
          .toList(),
      imageUrl: json['image_url'] as String?,
      backgroundColor: json['background_color'] as String?,
      ownerUserId: json['owner_user_id'] as String?,
      driPercent: (json['dri_percent'] as num?)?.toDouble(),
    );
  }
}

class FoodNutrient {
  const FoodNutrient({
    required this.code,
    required this.name,
    required this.unit,
    required this.amountPer100G,
    this.driAmount,
    this.driPercent,
  });

  final String code;
  final String name;
  final String unit;
  final double amountPer100G;
  final double? driAmount;
  final double? driPercent;

  factory FoodNutrient.fromJson(Map<String, dynamic> json) {
    return FoodNutrient(
      code: json['code'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      amountPer100G: (json['amount_per_100g'] as num?)?.toDouble() ?? 0,
      driAmount: (json['dri_amount'] as num?)?.toDouble(),
      driPercent: (json['dri_percent'] as num?)?.toDouble(),
    );
  }
}

class FoodDetail extends FoodSummary {
  const FoodDetail({
    required super.id,
    required super.name,
    super.brand,
    required super.category,
    required super.servingSizeG,
    required super.verified,
    required super.nutrients,
    super.imageUrl,
    super.backgroundColor,
    super.ownerUserId,
    super.driPercent,
    required this.source,
    required this.breakdown,
  });

  final String source;
  final List<FoodNutrient> breakdown;

  factory FoodDetail.fromJson(Map<String, dynamic> json) {
    final breakdown = (json['nutrients'] as List? ?? const [])
        .map((v) => FoodNutrient.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    return FoodDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: json['category'] as String? ?? 'general',
      servingSizeG: (json['serving_size_g'] as num?)?.toDouble() ?? 100,
      verified: json['verified'] as bool? ?? false,
      nutrients: breakdown.map((n) => n.code).toList(),
      imageUrl: json['image_url'] as String?,
      backgroundColor: json['background_color'] as String?,
      ownerUserId: json['owner_user_id'] as String?,
      driPercent: (json['dri_percent'] as num?)?.toDouble(),
      source: json['source'] as String? ?? 'seed',
      breakdown: breakdown,
    );
  }
}
