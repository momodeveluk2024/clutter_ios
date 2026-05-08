import '../api/api_client.dart';

/// Phase 4 meal templates. Backend endpoints live at /v1/meal-templates.
/// One-tap re-log: list → tap → POST /v1/logs with the template's items.
class MealTemplateService {
  MealTemplateService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<MealTemplate>> list() async {
    final response = await _api.get('/meal-templates');
    final raw = (response.data['templates'] as List? ?? const []);
    return raw
        .map((v) => MealTemplate.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<MealTemplate> create({
    required String name,
    required String mealType,
    required List<({String foodId, double servingG})> items,
  }) async {
    final response = await _api.post(
      '/meal-templates',
      data: {
        'name': name,
        'meal_type': mealType,
        'items': items.map((i) => {'food_id': i.foodId, 'serving_g': i.servingG}).toList(),
      },
    );
    return MealTemplate.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> delete(String templateId) =>
      _api.delete('/meal-templates/$templateId');
}

class MealTemplate {
  MealTemplate({
    required this.id,
    required this.name,
    required this.mealType,
    required this.items,
  });

  final String id;
  final String name;
  final String mealType;
  final List<MealTemplateItem> items;

  factory MealTemplate.fromJson(Map<String, dynamic> json) => MealTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        mealType: json['meal_type'] as String,
        items: (json['items'] as List? ?? const [])
            .map((v) => MealTemplateItem.fromJson(Map<String, dynamic>.from(v as Map)))
            .toList(),
      );
}

class MealTemplateItem {
  MealTemplateItem({required this.foodId, required this.servingG});
  final String foodId;
  final double servingG;
  factory MealTemplateItem.fromJson(Map<String, dynamic> json) => MealTemplateItem(
        foodId: json['food_id'] as String,
        servingG: (json['serving_g'] as num).toDouble(),
      );
}
