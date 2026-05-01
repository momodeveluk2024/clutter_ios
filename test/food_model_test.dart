import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/models/food.dart';

void main() {
  test('FoodSummary parses image_url from API JSON', () {
    final food = FoodSummary.fromJson({
      'id': '018f0000-0000-7000-8002-000000000101',
      'name': 'Chicken breast, cooked, roasted',
      'category': 'poultry',
      'serving_size_g': 100,
      'verified': true,
      'image_url': 'https://example.com/chicken.jpg',
      'dri_percent': 62.0,
      'nutrients': ['Protein', 'B12'],
    });

    expect(food.imageUrl, 'https://example.com/chicken.jpg');
    expect(food.driPercent, 62.0);
  });

  test('FoodDetail parses image_url from API JSON', () {
    final food = FoodDetail.fromJson({
      'id': '018f0000-0000-7000-8002-000000000101',
      'name': 'Chicken breast, cooked, roasted',
      'category': 'poultry',
      'serving_size_g': 100,
      'verified': true,
      'image_url': 'https://example.com/chicken.jpg',
      'source': 'USDA FoodData Central',
      'nutrients': [
        {
          'code': 'Protein',
          'name': 'Protein',
          'unit': 'g',
          'amount_per_100g': 31.0,
        },
      ],
    });

    expect(food.imageUrl, 'https://example.com/chicken.jpg');
    expect(food.breakdown.single.code, 'Protein');
  });
}
