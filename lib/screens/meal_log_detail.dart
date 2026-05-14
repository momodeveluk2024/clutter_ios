import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/food_log.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> showMealLogDetails(
  BuildContext context,
  MealLog log, {
  DateTime? date,
  bool allowDelete = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _MealLogDetailSheet(log: log, date: date, allowDelete: allowDelete),
  );
}

class _MealLogDetailSheet extends StatelessWidget {
  const _MealLogDetailSheet({
    required this.log,
    required this.date,
    required this.allowDelete,
  });

  final MealLog log;
  final DateTime? date;
  final bool allowDelete;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.42 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MealImageMosaic(
                      items: log.items,
                      fallbackLabel: log.mealType,
                      size: 58,
                      radius: 18,
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF123226) : NV.accentSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 12,
                          color: NV.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCase(log.mealType),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                      Text(
                        log.loggedOn,
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _itemCountLabel(log.items.length),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: NV.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionLabel('Foods eaten'),
            const SizedBox(height: 8),
            ...log.items.map((item) => _ItemRow(item: item)),
            if ((log.pairedDrink ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_cafe_outlined,
                      size: 18,
                      color: NV.accent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Paired with ${log.pairedDrink}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if ((log.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: c.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        log.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.text,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (allowDelete) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<NutritionProvider>().deleteLog(
                    log.id,
                    date: date ?? DateTime.tryParse(log.loggedOn),
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete meal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MealImageMosaic extends StatelessWidget {
  const MealImageMosaic({
    super.key,
    required this.items,
    required this.fallbackLabel,
    this.size = 52,
    this.radius = 16,
  });

  final List<MealLogItem> items;
  final String fallbackLabel;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(4).toList();
    final overflow = items.length - visibleItems.length;
    final c = NVColors(Theme.of(context).brightness == Brightness.dark);

    return ClipRRect(
      key: const ValueKey('meal-image-mosaic'),
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: visibleItems.isEmpty
            ? PhotoPlaceholder(
                label: fallbackLabel,
                width: size,
                height: size,
                radius: 0,
                tone: 'cool',
              )
            : DecoratedBox(
                decoration: BoxDecoration(color: c.surfaceMuted),
                child: _MosaicLayout(
                  items: visibleItems,
                  overflow: overflow,
                  size: size,
                ),
              ),
      ),
    );
  }
}

class _MosaicLayout extends StatelessWidget {
  const _MosaicLayout({
    required this.items,
    required this.overflow,
    required this.size,
  });

  final List<MealLogItem> items;
  final int overflow;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (items.length == 1) return _tile(items[0], 0);
    if (items.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(items[0], 0)),
          const SizedBox(width: 1),
          Expanded(child: _tile(items[1], 1)),
        ],
      );
    }
    if (items.length == 3) {
      return Row(
        children: [
          Expanded(flex: 5, child: _tile(items[0], 0)),
          const SizedBox(width: 1),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(child: _tile(items[1], 1)),
                const SizedBox(height: 1),
                Expanded(child: _tile(items[2], 2)),
              ],
            ),
          ),
        ],
      );
    }
    return GridView.count(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      children: List.generate(4, (index) {
        return _tile(items[index], index, overflow: index == 3 ? overflow : 0);
      }),
    );
  }

  Widget _tile(MealLogItem item, int index, {int overflow = 0}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FoodPhoto(
          key: ValueKey('meal-image-mosaic-tile-$index'),
          label: item.foodName,
          imageUrl: item.imageUrl,
          height: size,
          radius: 0,
          tone: 'cool',
        ),
        if (overflow > 0)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
            ),
            child: Center(
              child: Text(
                '+$overflow',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final MealLogItem item;

  @override
  Widget build(BuildContext context) {
    final c = NVColors(Theme.of(context).brightness == Brightness.dark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('meal-food-${item.foodId}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push('/app/food/${item.foodId}');
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FoodPhoto(
                  label: item.foodName,
                  imageUrl: item.imageUrl,
                  width: 38,
                  height: 38,
                  radius: 12,
                  tone: 'cool',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.foodName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      if (item.hasNutrition)
                        Text(
                          '${item.displayKcal.round()} kcal · '
                          'P ${item.proteinG.round()}g · '
                          'C ${item.carbsG.round()}g · '
                          'F ${item.fatG.round()}g · '
                          'Fb ${item.fiberG.round()}g',
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textMuted,
                          ),
                        )
                      else
                        Text(
                          'Nutrition data unavailable',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orangeAccent,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${item.servingG.round()}g',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _itemCountLabel(int count) {
  if (count == 0) return 'No foods logged';
  if (count == 1) return '1 food';
  return '$count foods';
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
