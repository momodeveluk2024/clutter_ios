import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/models/ai.dart';

void main() {
  test('AiMealEstimate parses backend estimate response', () {
    final estimate = AiMealEstimate.fromJson({
      'estimate_id': 'estimate-1',
      'status': 'needs_review',
      'model': 'gemini-2.5-flash',
      'confidence': 0.76,
      'items': [
        {
          'id': 'item-1',
          'name': 'grilled chicken breast',
          'matched_food_id': 'food-1',
          'quantity_g': 180,
          'calories_kcal': 297,
          'protein_g': 55.8,
          'carbs_g': 0,
          'fat_g': 6.5,
          'confidence': 0.82,
          'source': 'matched_catalog',
        },
      ],
      'questions': ['Was the rice cooked with oil or butter?'],
      'warnings': ['Estimated from a photo. Edit portions before saving.'],
    });

    expect(estimate.id, 'estimate-1');
    expect(estimate.items.single.name, 'grilled chicken breast');
    expect(estimate.items.single.quantityG, 180);
    expect(estimate.questions, isNotEmpty);
    expect(estimate.warnings, isNotEmpty);
  });
}
