import 'package:flutter/material.dart';

import '../core/models/food_log.dart';
import '../theme.dart';
import '../widgets.dart';
import '../screens/meal_log_detail.dart';

class MealImageCard extends StatelessWidget {
  const MealImageCard({super.key, required this.log, required this.width});
  final MealLog log;
  final double width;

  @override
  Widget build(BuildContext context) {
    final firstItem = log.items.isEmpty ? null : log.items.first;
    final title = firstItem?.foodName ?? _titleCase(log.mealType);

    return NVCard(
      onTap: () => showMealLogDetails(
        context,
        log,
        date: DateTime.tryParse(log.loggedOn),
      ),
      padding: EdgeInsets.zero,
      radius: NVRadius.card,
      child: SizedBox(
        width: width,
        height: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FoodPhoto(
              label: title,
              imageUrl: firstItem?.imageUrl,
              radius: NVRadius.card,
              tone: 'cool',
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (log.items.length > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+${log.items.length - 1} more',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
}
