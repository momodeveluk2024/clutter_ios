import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/models/food_log.dart';

void main() {
  test('MealLog parses item names returned by the logs API', () {
    final log = MealLog.fromJson({
      'id': '019dc4da-c100-7b35-bc50-8bbac34a366f',
      'logged_on': '2026-04-25',
      'meal_type': 'breakfast',
      'items': [
        {
          'id': '019dc4da-c114-7b3a-a060-3215bd064c36',
          'food_id': '018f0000-0000-7000-8002-000000000106',
          'food_name': 'Salmon, Atlantic, cooked, dry heat',
          'image_url': 'https://example.com/salmon.jpg',
          'serving_g': 120,
        },
      ],
    });

    expect(log.items, hasLength(1));
    expect(log.items.single.foodName, 'Salmon, Atlantic, cooked, dry heat');
    expect(log.items.single.imageUrl, 'https://example.com/salmon.jpg');
    expect(log.items.single.servingG, 120);
  });
}
