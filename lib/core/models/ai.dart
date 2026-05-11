class AiMealEstimate {
  const AiMealEstimate({
    required this.id,
    required this.status,
    required this.model,
    required this.confidence,
    required this.items,
    required this.questions,
    required this.warnings,
    this.imageUrl,
    this.mealType = 'other',
    this.loggedOn = '',
  });

  final String id;
  final String status;
  final String model;
  final double confidence;
  final List<AiEstimateItem> items;
  final List<String> questions;
  final List<String> warnings;
  final String? imageUrl;
  final String mealType;
  final String loggedOn;

  factory AiMealEstimate.fromJson(Map<String, dynamic> json) {
    return AiMealEstimate(
      id: (json['estimate_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'needs_review').toString(),
      model: (json['model'] ?? '').toString(),
      confidence: _asDouble(json['confidence']),
      imageUrl: json['image_url'] as String?,
      mealType: (json['meal_type'] ?? 'other').toString(),
      loggedOn: (json['logged_on'] ?? '').toString(),
      items: (json['items'] as List? ?? const [])
          .map(
            (v) => AiEstimateItem.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      questions: _stringList(json['questions']),
      warnings: _stringList(json['warnings']),
    );
  }

  AiMealEstimate copyWith({
    String? status,
    double? confidence,
    List<AiEstimateItem>? items,
    List<String>? questions,
    List<String>? warnings,
  }) {
    return AiMealEstimate(
      id: id,
      status: status ?? this.status,
      model: model,
      confidence: confidence ?? this.confidence,
      items: items ?? this.items,
      questions: questions ?? this.questions,
      warnings: warnings ?? this.warnings,
      imageUrl: imageUrl,
      mealType: mealType,
      loggedOn: loggedOn,
    );
  }
}

class AiEstimateItem {
  const AiEstimateItem({
    required this.id,
    required this.name,
    required this.quantityG,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
    required this.source,
    this.matchedFoodId,
  });

  final String id;
  final String name;
  final String? matchedFoodId;
  final double quantityG;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double confidence;
  final String source;

  factory AiEstimateItem.fromJson(Map<String, dynamic> json) {
    return AiEstimateItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown food').toString(),
      matchedFoodId: json['matched_food_id'] as String?,
      quantityG: _asDouble(json['quantity_g']),
      caloriesKcal: _asDouble(json['calories_kcal']),
      proteinG: _asDouble(json['protein_g']),
      carbsG: _asDouble(json['carbs_g']),
      fatG: _asDouble(json['fat_g']),
      confidence: _asDouble(json['confidence']),
      source: (json['source'] ?? 'ai_estimate').toString(),
    );
  }

  /// `true` for items the user just added in the editor — their `id` is a
  /// placeholder (`local-…`) that the backend cannot parse as a UUID, so we
  /// strip it on serialisation and let the backend assign a real one.
  bool get isLocalOnly => id.startsWith('local-');

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !isLocalOnly) 'id': id,
      'name': name,
      if (matchedFoodId != null) 'matched_food_id': matchedFoodId,
      'quantity_g': quantityG,
      'calories_kcal': caloriesKcal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'confidence': confidence,
      'source': source,
    };
  }

  AiEstimateItem copyWith({
    String? name,
    double? quantityG,
    double? caloriesKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? source,
  }) {
    return AiEstimateItem(
      id: id,
      name: name ?? this.name,
      matchedFoodId: matchedFoodId,
      quantityG: quantityG ?? this.quantityG,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      confidence: confidence,
      source: source ?? this.source,
    );
  }
}

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content, this.model});

  final String role;
  final String content;
  final String? model;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringList(Object? value) {
  return (value as List? ?? const []).map((v) => v.toString()).toList();
}
