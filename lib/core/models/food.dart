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
    this.isUnhealthy = false,
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
  final bool isUnhealthy;

  /// Reformats USDA-style names like "chicken breast, cooked, roasted"
  /// into "Chicken breast (cooked and roasted)".
  static String prettifyName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    // Only reformat if there are commas (USDA style)
    if (!trimmed.contains(',')) {
      // Just capitalize first letter
      return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
    }

    final parts = trimmed.split(',').map((p) => p.trim()).toList();
    final mainName = parts.first;
    final capitalized =
        '${mainName[0].toUpperCase()}${mainName.substring(1)}';

    if (parts.length == 1) return capitalized;

    // Join preparation methods with " and " for 2, or ", " + " and " for 3+
    final methods = parts.sublist(1).where((m) => m.isNotEmpty).toList();
    if (methods.isEmpty) return capitalized;

    final String methodStr;
    if (methods.length == 1) {
      methodStr = methods.first;
    } else {
      methodStr =
          '${methods.sublist(0, methods.length - 1).join(', ')} and ${methods.last}';
    }

    return '$capitalized ($methodStr)';
  }

  factory FoodSummary.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as String? ?? 'general';
    // Backend sends is_unhealthy; fallback to category-based check
    final unhealthy = json['is_unhealthy'] as bool? ??
        const {'fast-food', 'sweets', 'sugary-drinks'}.contains(cat.toLowerCase());
    return FoodSummary(
      id: json['id'] as String,
      name: prettifyName(json['name'] as String),
      brand: json['brand'] as String?,
      category: cat,
      servingSizeG: (json['serving_size_g'] as num?)?.toDouble() ?? 100,
      verified: json['verified'] as bool? ?? false,
      nutrients: (json['nutrients'] as List? ?? const [])
          .map((v) => v.toString())
          .toList(),
      imageUrl: json['image_url'] as String?,
      backgroundColor: json['background_color'] as String?,
      ownerUserId: json['owner_user_id'] as String?,
      driPercent: (json['dri_percent'] as num?)?.toDouble(),
      isUnhealthy: unhealthy,
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
    super.isUnhealthy,
    required this.source,
    required this.breakdown,
  });

  final String source;
  final List<FoodNutrient> breakdown;

  factory FoodDetail.fromJson(Map<String, dynamic> json) {
    final breakdown = (json['nutrients'] as List? ?? const [])
        .map((v) => FoodNutrient.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    final cat = json['category'] as String? ?? 'general';
    final unhealthy = json['is_unhealthy'] as bool? ??
        const {'fast-food', 'sweets', 'sugary-drinks'}.contains(cat.toLowerCase());
    return FoodDetail(
      id: json['id'] as String,
      name: FoodSummary.prettifyName(json['name'] as String),
      brand: json['brand'] as String?,
      category: cat,
      servingSizeG: (json['serving_size_g'] as num?)?.toDouble() ?? 100,
      verified: json['verified'] as bool? ?? false,
      nutrients: breakdown.map((n) => n.code).toList(),
      imageUrl: json['image_url'] as String?,
      backgroundColor: json['background_color'] as String?,
      ownerUserId: json['owner_user_id'] as String?,
      driPercent: (json['dri_percent'] as num?)?.toDouble(),
      isUnhealthy: unhealthy,
      source: json['source'] as String? ?? 'seed',
      breakdown: breakdown,
    );
  }
}
