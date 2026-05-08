import 'package:flutter/material.dart';

import '../../theme.dart';

class CategoryVisual {
  const CategoryVisual({
    required this.label,
    required this.imageUrl,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String imageUrl;
  final IconData icon;
  final Color accent;
}

class NutrientVisual {
  const NutrientVisual({
    required this.label,
    required this.imageUrl,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String imageUrl;
  final IconData icon;
  final Color accent;
}

const categoryVisuals = <String, CategoryVisual>{
  'fruit': CategoryVisual(
    label: 'Fruit',
    imageUrl:
        'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=900&q=80',
    icon: Icons.local_florist_outlined,
    accent: Color(0xFFD85D43),
  ),
  'vegetables': CategoryVisual(
    label: 'Vegetables',
    imageUrl:
        'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=900&q=80',
    icon: Icons.eco_outlined,
    accent: Color(0xFF47743C),
  ),
  'dairy': CategoryVisual(
    label: 'Dairy',
    imageUrl:
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80',
    icon: Icons.icecream_outlined,
    accent: Color(0xFF718CA1),
  ),
  'drinks': CategoryVisual(
    label: 'Drinks',
    imageUrl:
        'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=900&q=80',
    icon: Icons.local_cafe_outlined,
    accent: Color(0xFFB15C45),
  ),
  'grains': CategoryVisual(
    label: 'Grains',
    imageUrl:
        'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?auto=format&fit=crop&w=900&q=80',
    icon: Icons.breakfast_dining,
    accent: Color(0xFF93843C),
  ),
  'meat': CategoryVisual(
    label: 'Meat',
    imageUrl:
        'https://images.unsplash.com/photo-1558030006-450675393462?auto=format&fit=crop&w=900&q=80',
    icon: Icons.restaurant,
    accent: Color(0xFF8A4B3D),
  ),
  'nuts-seeds': CategoryVisual(
    label: 'Nuts & Seeds',
    imageUrl:
        'https://images.unsplash.com/photo-1508061253366-f7da158b6d46?auto=format&fit=crop&w=900&q=80',
    icon: Icons.scatter_plot,
    accent: Color(0xFF9C6A3D),
  ),
  'seafood': CategoryVisual(
    label: 'Seafood',
    imageUrl:
        'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=900&q=80',
    icon: Icons.set_meal_outlined,
    accent: Color(0xFF3A6B88),
  ),
  'fast-food': CategoryVisual(
    label: 'Fast Food',
    imageUrl:
        'https://images.unsplash.com/photo-1606755962773-d324e2d533a7?auto=format&fit=crop&w=900&q=80',
    icon: Icons.lunch_dining_outlined,
    accent: Color(0xFFBA6B35),
  ),
  'world-cuisine': CategoryVisual(
    label: 'World Cuisine',
    imageUrl:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=80',
    icon: Icons.public_outlined,
    accent: Color(0xFFB48643),
  ),
  'other': CategoryVisual(
    label: 'Pantry',
    imageUrl:
        'https://images.unsplash.com/photo-1606914469633-bd39206ea739?auto=format&fit=crop&w=900&q=80',
    icon: Icons.inventory_2_outlined,
    accent: Color(0xFF7A7351),
  ),
  'soy': CategoryVisual(
    label: 'Soy',
    imageUrl:
        'https://images.unsplash.com/photo-1611077544441-5a4242195f50?auto=format&fit=crop&w=900&q=80',
    icon: Icons.spa_outlined,
    accent: Color(0xFF758E54),
  ),

  'legumes': CategoryVisual(
    label: 'Legumes',
    imageUrl:
        'https://images.unsplash.com/photo-1515543904379-3d757afe72e4?auto=format&fit=crop&w=900&q=80',
    icon: Icons.grain,
    accent: Color(0xFF6B7D47),
  ),
  'poultry': CategoryVisual(
    label: 'Poultry',
    imageUrl:
        'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=900&q=80',
    icon: Icons.dinner_dining,
    accent: Color(0xFFB1744A),
  ),
  'eggs': CategoryVisual(
    label: 'Eggs',
    imageUrl:
        'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?auto=format&fit=crop&w=900&q=80',
    icon: Icons.egg_alt_outlined,
    accent: Color(0xFFC99A37),
  ),
};

const fallbackCategoryVisual = CategoryVisual(
  label: 'Foods',
  imageUrl:
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
  icon: Icons.category_outlined,
  accent: NV.accent,
);

CategoryVisual categoryVisualFor(String category) {
  final normalized = category.toLowerCase();
  // Map legacy 'nuts' key to the canonical 'nuts-seeds' entry
  final key = normalized == 'nuts' ? 'nuts-seeds' : normalized;
  return categoryVisuals[key] ??
      CategoryVisual(
        label: _titleCase(category),
        imageUrl: fallbackCategoryVisual.imageUrl,
        icon: fallbackCategoryVisual.icon,
        accent: fallbackCategoryVisual.accent,
      );
}

NutrientVisual nutrientVisualFor(String code) {
  final hue = vitaminColors[code] ?? vitaminColors['C']!;
  return NutrientVisual(
    label: code,
    imageUrl: switch (code) {
      'Protein' => 'https://images.unsplash.com/photo-1555243896-c709bfa0b564?auto=format&fit=crop&w=900&q=80',
      'Fiber' => 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=900&q=80',
      'Carbs' => 'https://images.unsplash.com/photo-1596422846543-74c6fc0e28f1?auto=format&fit=crop&w=900&q=80',
      'Fat' => 'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?auto=format&fit=crop&w=900&q=80',
      'Ca' => 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=900&q=80',
      'Fe' => 'https://images.unsplash.com/photo-1603048297172-c92544798d5e?auto=format&fit=crop&w=900&q=80',
      'A' => 'https://images.unsplash.com/photo-1447175008436-054170c2e979?auto=format&fit=crop&w=900&q=80',
      'C' => 'https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?auto=format&fit=crop&w=900&q=80',
      'D' => 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=900&q=80',
      _ => 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=900&q=80',
    },
    icon: switch (code) {
      'A' => Icons.visibility_outlined,
      'D' => Icons.wb_sunny_outlined,
      'C' => Icons.eco_outlined,
      'E' => Icons.auto_awesome,
      'K' || 'Kp' => Icons.electric_bolt,
      'Fe' => Icons.bloodtype_outlined,
      'Ca' => Icons.shield_outlined,
      'Zn' => Icons.healing_outlined,
      'Mg' => Icons.spa_outlined,
      'Na' => Icons.water_drop_outlined,
      'P' => Icons.blur_circular_outlined,
      'Se' => Icons.brightness_5_outlined,
      'Mn' => Icons.hub_outlined,
      'S' => Icons.science_outlined,
      'Protein' => Icons.fitness_center,
      'Fiber' => Icons.grass,
      'Carbs' => Icons.bolt,
      'Fat' => Icons.water_drop_outlined,
      _ when code.startsWith('B') => Icons.bolt_outlined,
      _ => Icons.auto_awesome,
    },
    accent: hue.fill,
  );
}

String _titleCase(String value) {
  if (value.isEmpty) return fallbackCategoryVisual.label;
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
