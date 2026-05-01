import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/models/nutrient_reference.dart';
import 'package:myapplication/core/models/visual_catalog.dart';

void main() {
  test('required food categories have unique remote image URLs', () {
    const required = [
      'fruit',
      'vegetables',
      'dairy',
      'drinks',
      'grains',
      'meat',
      'nuts-seeds',
      'seafood',
      'fast-food',
      'world-cuisine',
      'other',
      'soy',
    ];

    final visuals = required.map(categoryVisualFor).toList();
    final urls = visuals.map((visual) => visual.imageUrl).toList();
    final icons = visuals.map((visual) => visual.icon).toList();

    expect(urls.every((url) => url.startsWith('https://')), isTrue);
    expect(urls, isNot(contains(fallbackCategoryVisual.imageUrl)));
    expect(icons, isNot(contains(fallbackCategoryVisual.icon)));
    expect(urls.toSet(), hasLength(urls.length));
    expect(icons.toSet(), hasLength(icons.length));
  });

  test('every nutrient has a visual treatment', () {
    for (final nutrient in nutrientCatalog) {
      final visual = nutrientVisualFor(nutrient.code);
      expect(visual.icon, isNotNull, reason: nutrient.code);
      expect(visual.label, isNotEmpty, reason: nutrient.code);
    }
  });
}
