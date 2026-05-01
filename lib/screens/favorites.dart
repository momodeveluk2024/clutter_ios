import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/food.dart';
import '../core/models/food_log.dart';
import '../core/providers/food_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import 'meal_log_detail.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().loadFavorites();
      context.read<NutritionProvider>().refreshDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final provider = context.watch<FoodProvider>();
    final nutrition = context.watch<NutritionProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: c.text,
                  ),
                ),
                Icon(Icons.tune, size: 20, color: c.text),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(2, (i) {
                  final labels = ['Foods', 'Meals'];
                  final active = i == _tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? c.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? c.text : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await context.read<FoodProvider>().loadFavorites();
                if (context.mounted) {
                  await context.read<NutritionProvider>().refreshDashboard();
                }
              },
              child: _tab == 0
                  ? _FoodsList(foods: provider.favorites)
                  : _MealsList(logs: nutrition.logs),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealsList extends StatelessWidget {
  const _MealsList({required this.logs});

  final List<MealLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: const [
          _EmptyState(
            title: 'No meals logged today',
            subtitle: 'Open a food and log it to see recent meals here.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _SavedMeal(log: logs[index]),
    );
  }
}

class _SavedMeal extends StatelessWidget {
  const _SavedMeal({required this.log});

  final MealLog log;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final items = log.items
        .map((item) => '${item.foodName} (${item.servingG.round()}g)')
        .join(', ');
    final firstItem = log.items.isEmpty ? null : log.items.first;
    return NVCard(
      onTap: () => showMealLogDetails(
        context,
        log,
        date: DateTime.tryParse(log.loggedOn),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          FoodPhoto(
            label: firstItem?.foodName ?? log.mealType,
            imageUrl: firstItem?.imageUrl,
            width: 48,
            height: 48,
            radius: 15,
            tone: 'cool',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.mealType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  items.isEmpty ? 'No items attached' : items,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodsList extends StatelessWidget {
  const _FoodsList({required this.foods});

  final List<FoodSummary> foods;

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: const [
          _EmptyState(
            title: 'No saved foods yet',
            subtitle: 'Tap the heart on a food to save it here.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: foods.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final food = foods[i];
        return _FavoriteFood(food: food);
      },
    );
  }
}

class _FavoriteFood extends StatelessWidget {
  const _FavoriteFood({required this.food});

  final FoodSummary food;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return NVCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/app/food/${food.id}'),
      child: Row(
        children: [
          FoodPhoto(
            label: food.name,
            imageUrl: food.imageUrl,
            category: food.category,
            height: 52,
            width: 52,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  food.category,
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: food.nutrients
                      .take(4)
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: VitaminChip(code: v, size: 18),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, size: 18, color: NV.accent),
            onPressed: () =>
                context.read<FoodProvider>().removeFavorite(food.id),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return NVCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(Icons.favorite_outline, color: c.textMuted),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
