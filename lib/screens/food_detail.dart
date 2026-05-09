import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/models/food.dart';
import '../core/nutrition/overage_warning.dart';
import '../core/providers/food_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/log_success_toast.dart';
import '../widgets/nv_loader.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key, this.foodId});

  final String? foodId;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late Future<FoodDetail> _future;

  @override
  void initState() {
    super.initState();
    final foodId = widget.foodId ?? '018f0000-0000-7000-8002-000000000001';
    final provider = context.read<FoodProvider>();
    _future = Future.microtask(() {
      provider.loadFavorites();
      return provider.getFood(foodId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: FutureBuilder<FoodDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: NVLoader(label: 'Loading food…'),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(NVSpace.x5),
                child: NVCard(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Could not load food: ${snapshot.error}',
                    style: TextStyle(color: c.textMuted),
                  ),
                ),
              ),
            );
          }
          return _FoodDetailBody(food: snapshot.data!);
        },
      ),
    );
  }
}

class _FoodDetailBody extends StatelessWidget {
  const _FoodDetailBody({required this.food});

  final FoodDetail food;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final provider = context.watch<FoodProvider>();
    final isFavorite = provider.isFavorite(food.id);
    final isReferenceProfile = food.source.contains('percent Daily Value');
    final canLog = food.breakdown.any(
      (n) => n.amountPer100G > 0 || (n.driPercent ?? 0) > 0,
    );
    final isFastFood = food.isUnhealthy;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              FoodPhoto(
                label: food.name,
                imageUrl: food.imageUrl,
                category: food.category,
                height: 320,
                radius: 0,
                tone: 'warm',
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.46),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 14,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NVCircleIconButton(
                      icon: Icons.chevron_left,
                      background: Colors.white.withValues(alpha: 0.92),
                      foreground: NV.text,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    NVCircleIconButton(
                      icon: isFavorite
                          ? Icons.favorite
                          : Icons.favorite_outline,
                      background: Colors.white.withValues(alpha: 0.92),
                      foreground: isFavorite ? NV.accent : NV.text,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (isFavorite) {
                          context.read<FoodProvider>().removeFavorite(food.id);
                        } else {
                          context.read<FoodProvider>().addFavorite(food.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.88,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                        letterSpacing: -0.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            NVSpace.x5,
            NVSpace.x5,
            NVSpace.x5,
            NVSpace.x5,
          ),
          sliver: SliverList.list(
            children: [
              NVEyebrow(food.category, color: c.textMuted),
              const SizedBox(height: 4),
              Text(
                food.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: c.text,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isReferenceProfile
                    ? 'Nutrient profile · % Daily Value'
                    : '${food.servingSizeG.toStringAsFixed(0)}g serving · ${food.category}',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textMuted,
                  height: 1.45,
                ),
              ),
              if (isFastFood) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This food is marked as unhealthy. Consume in moderation.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: NVSpace.x4),
              NVCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(
                      value: food.servingSizeG.toStringAsFixed(0),
                      label: 'grams',
                    ),
                    _Metric(
                      value: '${food.breakdown.length}',
                      label: 'nutrients',
                    ),
                    _Metric(
                      value: isFastFood ? 'Unhealthy' : 'Healthy',
                      label: 'classification',
                      valueColor: isFastFood
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF2F7D4A),
                    ),
                  ],
                ),
              ),
              if (isFastFood) ...[
                const SizedBox(height: NVSpace.x4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(NVRadius.cardSm),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Unhealthy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'May be high in sodium, sugar, or saturated fat.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: c.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: NVSpace.x5),
              // ── Limit-nutrient penalty info ──
              Builder(builder: (context) {
                final limitNutrients = food.breakdown
                    .where((n) => n.isLimit)
                    .toList();
                if (limitNutrients.isEmpty) {
                  return const SizedBox.shrink();
                }
                final names = limitNutrients
                    .map((n) => n.name)
                    .take(3)
                    .join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: NVSpace.x4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(NVRadius.cardSm),
                      border: Border.all(
                        color: const Color(0xFFFCD34D),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.trending_down_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score penalty possible',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$names — exceeding the daily limit lowers your health score. Look for the ⚠ icon below.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Nutrient breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: c.text,
                  ),
                ),
              ),
              NVCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  children: food.breakdown.map((nutrient) {
                    return _NutrientRow(nutrient: nutrient);
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  isReferenceProfile
                      ? '% Daily Value from imported source profile'
                      : '% of your daily recommended intake per 100g',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
              if (isReferenceProfile)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Values shown as % of your recommended daily intake.',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ),
              if (!canLog)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Logging is limited until raw USDA nutrient amounts are added for this food.',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ),
              const SizedBox(height: NVSpace.x4),
              NVPrimaryButton(
                label: canLog ? 'Log this food' : 'Reference profile only',
                leadingIcon: canLog
                    ? Icons.add_rounded
                    : Icons.info_outline_rounded,
                accent: canLog,
                onPressed: canLog
                    ? () {
                        HapticFeedback.mediumImpact();
                        _showLogSheet(context, food);
                      }
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Raw USDA amounts are needed before logging this food.',
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLogSheet(BuildContext context, FoodDetail food) async {
    final result = await showModalBottomSheet<_LogFoodResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.80,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LogFoodSheet(food: food),
    );
    if (!context.mounted || result == null) return;

    LogSuccessToast.show(
      context,
      title: 'Logged ${food.name}',
      subtitle: '${result.servingG.round()}g · ${_humanize(result.mealType)}',
      imageUrl: food.imageUrl,
    );
  }
}

class _LogFoodResult {
  const _LogFoodResult({required this.servingG, required this.mealType});

  final double servingG;
  final String mealType;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: nvNumber(18, color: valueColor ?? c.text, weight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        NVEyebrow(label, color: c.textMuted),
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.nutrient});
  final FoodNutrient nutrient;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final code = nutrient.code;
    final pct = ((nutrient.driPercent ?? 0) / 100).clamp(0.0, 1.0);
    final hue = vitaminColors[code] ?? vitaminColors['D']!;
    final isLimit = nutrient.isLimit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          VitaminChip(code: code, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              nutrient.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.text,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          if (isLimit) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nutrient.driPercent == null
                          ? '—'
                          : '${nutrient.driPercent!.round()}%',
                      style: nvNumber(
                        13,
                        color: pct >= 1
                            ? isLimit
                                ? const Color(0xFFEF4444)
                                : hue.fill
                            : c.textMuted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isLimit)
                  Text(
                    'Limit · exceeding lowers score',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 3),
                BarProgress(
                  pct: pct,
                  color: isLimit && pct >= 1
                      ? const Color(0xFFEF4444)
                      : hue.fill,
                  height: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogFoodSheet extends StatefulWidget {
  const _LogFoodSheet({required this.food});

  final FoodDetail food;

  @override
  State<_LogFoodSheet> createState() => _LogFoodSheetState();
}

class _LogFoodSheetState extends State<_LogFoodSheet> {
  String _mealType = 'breakfast';
  double _servingG = 100;
  DateTime _loggedOn = DateTime.now();
  String? _pairedDrink;
  bool _showAllDrinks = false;
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nutrition = context.read<NutritionProvider>();
    final warnings = projectedOverages(
      currentTotals: nutrition.todayTotals,
      food: widget.food,
      servingG: _servingG,
    );
    if (warnings.isNotEmpty) {
      final shouldContinue = await _confirmOverages(warnings);
      if (!mounted || !shouldContinue) return;
    }

    setState(() => _saving = true);
    try {
      await nutrition.createLog(
        foodId: widget.food.id,
        servingG: _servingG,
        mealType: _mealType,
        date: _loggedOn,
        pairedDrink: _pairedDrink,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        _LogFoodResult(servingG: _servingG, mealType: _mealType),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmOverages(List<NutrientOverage> warnings) async {
    final c = NVColors.of(context);
    final topWarnings = warnings.take(4).toList();
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'This may pass 100%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.text,
                letterSpacing: -0.2,
              ),
            ),
            content: Text(
              topWarnings
                  .map((w) => '${w.name}: ${w.projectedPercent.round()}%')
                  .join('\n'),
              style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: NV.accent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Log anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Computes the estimated score change if the user logs this serving.
  ({double current, double projected, String label}) _scoreImpact() {
    final nutrition = context.read<NutritionProvider>();
    final totals = nutrition.todayTotals;
    if (totals == null) {
      return (current: 0, projected: 0, label: 'Log to see your score');
    }

    final currentScore = totals.averagePercent;

    // Build a projected set of nutrient totals by simulating the addition.
    // Start with what the user has already logged today.
    final projected = <String, _SimNutrient>{};
    for (final n in totals.nutrients) {
      projected[n.code] = _SimNutrient(
        amount: n.amount,
        driAmount: n.driAmount ?? 0,
        isLimit: n.isLimit,
      );
    }

    // Track which nutrient codes are new (not in today's totals)
    final newCodes = <String>{};

    for (final nutrient in widget.food.breakdown) {
      final added = nutrient.amountPer100G * (_servingG / 100);
      if (added <= 0) continue;
      final existing = projected[nutrient.code];
      if (existing != null && existing.driAmount > 0) {
        // Nutrient already in today's totals — add to existing amount
        projected[nutrient.code] = _SimNutrient(
          amount: existing.amount + added,
          driAmount: existing.driAmount,
          isLimit: existing.isLimit,
        );
      } else if (existing == null &&
          nutrient.driAmount != null &&
          nutrient.driAmount! > 0) {
        // NEW nutrient not yet logged today — use the food's DRI data
        projected[nutrient.code] = _SimNutrient(
          amount: added,
          driAmount: nutrient.driAmount!,
          isLimit: nutrient.role == 'limit',
        );
        newCodes.add(nutrient.code);
      }
    }

    if (_pairedDrink != null) {
      const drinkMacros = {
        'Water': {'Calories': 0.0, 'Carbs': 0.0},
        'Tea': {'Calories': 1.0, 'Carbs': 0.3},
        'Coffee': {'Calories': 2.0, 'Carbs': 0.0},
        'Juice': {'Calories': 45.0, 'Carbs': 10.4},
        'Milk': {'Calories': 61.0, 'Carbs': 4.8},
        'Coca-Cola': {'Calories': 42.0, 'Carbs': 10.6},
        'Pepsi': {'Calories': 41.0, 'Carbs': 10.4},
        'Fanta': {'Calories': 48.0, 'Carbs': 12.0},
        'Sprite': {'Calories': 40.0, 'Carbs': 10.0},
        'Energy drink': {'Calories': 45.0, 'Carbs': 11.0},
        'Smoothie': {'Calories': 55.0, 'Carbs': 13.0},
        'Lemonade': {'Calories': 40.0, 'Carbs': 10.5},
      };

      final macros = drinkMacros[_pairedDrink];
      if (macros != null) {
        for (final entry in macros.entries) {
          final code = entry.key;
          final added = entry.value * (330.0 / 100);
          if (added <= 0) continue;

          final existing = projected[code];
          if (existing != null && existing.driAmount > 0) {
            projected[code] = _SimNutrient(
              amount: existing.amount + added,
              driAmount: existing.driAmount,
              isLimit: existing.isLimit,
            );
          } else if (existing == null) {
            projected[code] = _SimNutrient(
              amount: added,
              driAmount: code == 'Calories' ? 2000.0 : 275.0,
              isLimit: false,
            );
            newCodes.add(code);
          }
        }
      }
    }

    // Recalculate average using same logic as DayNutrientTotals._scoreFor.
    // Include both existing nutrients AND newly introduced ones.
    double projectedSum = 0;
    int count = 0;

    // Score existing nutrients (already in today's totals)
    for (final n in totals.nutrients) {
      if (n.driPercent == null) continue;
      count++;
      final sim = projected[n.code];
      if (sim != null && sim.driAmount > 0) {
        final p = (sim.amount / sim.driAmount) * 100;
        if (sim.isLimit) {
          if (p <= 100) {
            projectedSum += 100;
          } else {
            final remaining = 200 - p;
            projectedSum += remaining < 0 ? 0 : remaining;
          }
        } else {
          projectedSum += p > 100 ? 100 : p;
        }
      } else {
        // Unchanged nutrient — use original score contribution
        final p = n.driPercent ?? 0;
        if (n.isLimit) {
          if (p <= 100) {
            projectedSum += 100;
          } else {
            final remaining = 200 - p;
            projectedSum += remaining < 0 ? 0 : remaining;
          }
        } else {
          projectedSum += p > 100 ? 100 : p;
        }
      }
    }

    // Score NEW nutrients introduced by this food (not in today's totals yet)
    for (final code in newCodes) {
      final sim = projected[code]!;
      count++;
      final p = (sim.amount / sim.driAmount) * 100;
      if (sim.isLimit) {
        if (p <= 100) {
          projectedSum += 100;
        } else {
          final remaining = 200 - p;
          projectedSum += remaining < 0 ? 0 : remaining;
        }
      } else {
        projectedSum += p > 100 ? 100 : p;
      }
    }

    final projectedScore = count > 0 ? projectedSum / count : 0.0;
    final delta = projectedScore - currentScore;

    String label;
    if (delta > 0.5) {
      label = '+${delta.round()}% estimated';
    } else if (delta < -0.5) {
      label = '${delta.round()}% estimated';
    } else {
      label = 'No score change expected';
    }

    return (current: currentScore, projected: projectedScore, label: label);
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final impact = _scoreImpact();
    final delta = impact.projected - impact.current;
    final isPositive = delta > 0.5;
    final isNegative = delta < -0.5;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          NVSpace.x5,
          0,
          NVSpace.x5,
          NVSpace.x5 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NVEyebrow('Add to your log', color: c.textMuted),
            const SizedBox(height: 6),
            Text(
              widget.food.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: c.text,
                letterSpacing: -0.4,
                height: 1.15,
              ),
            ),
            const SizedBox(height: NVSpace.x5),
            NVSelectField(
              label: 'Meal',
              value: _mealType,
              values: const ['breakfast', 'lunch', 'snack', 'dinner', 'other'],
              display: _humanize,
              onChanged: (value) {
                if (value != null) setState(() => _mealType = value);
              },
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(NVRadius.field),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(NVRadius.field),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NVEyebrow('Date', color: c.textMuted),
                            const SizedBox(height: 4),
                            Text(
                              _dateLabel(_loggedOn),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.text,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: c.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: NVSpace.x5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NVEyebrow('Serving', color: c.textMuted),
                Text(
                  '${_servingG.round()} g',
                  style: nvNumber(15, color: c.text, weight: FontWeight.w700),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: NV.accent,
                inactiveTrackColor: c.border,
                thumbColor: NV.accent,
                overlayColor: NV.accent.withValues(alpha: 0.14),
                trackHeight: 3,
              ),
              child: Slider(
                value: _servingG,
                min: 10,
                max: 500,
                divisions: 49,
                label: '${_servingG.round()}g',
                onChanged: (value) => setState(() => _servingG = value),
              ),
            ),
            // ── Pair with a drink (optional) ──
            const SizedBox(height: NVSpace.x4),
            NVEyebrow('Pair with a drink', color: c.textMuted),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              const allDrinks = [
                ('💧', 'Water'),
                ('🍵', 'Tea'),
                ('☕', 'Coffee'),
                ('🧃', 'Juice'),
                ('🥛', 'Milk'),
                ('🥤', 'Coca-Cola'),
                ('🥤', 'Pepsi'),
                ('🍊', 'Fanta'),
                ('🫧', 'Sprite'),
                ('⚡', 'Energy drink'),
                ('🍹', 'Smoothie'),
                ('🍋', 'Lemonade'),
              ];
              final visible = _showAllDrinks ? allDrinks : allDrinks.take(3).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final drink in visible)
                          _DrinkChip(
                            emoji: drink.$1,
                            label: drink.$2,
                            selected: _pairedDrink == drink.$2,
                            onTap: () => setState(() {
                              _pairedDrink =
                                  _pairedDrink == drink.$2 ? null : drink.$2;
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _showAllDrinks = !_showAllDrinks),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showAllDrinks ? 'Show less' : 'Show more',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: NV.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _showAllDrinks ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: NV.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            // ── Notes (optional) ──
            const SizedBox(height: NVSpace.x4),
            NVEyebrow('Notes (optional)', color: c.textMuted),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. At home with family, after gym…',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: c.textMuted.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: c.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NVRadius.field),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NVRadius.field),
                  borderSide: const BorderSide(color: NV.accent, width: 1.4),
                ),
              ),
            ),
            // ── Score impact preview ──
            const SizedBox(height: NVSpace.x4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isNegative
                    ? const Color(0xFFFEF2F2)
                    : isPositive
                        ? NV.accentSoft
                        : c.surface,
                borderRadius: BorderRadius.circular(NVRadius.cardSm),
                border: Border.all(
                  color: isNegative
                      ? const Color(0xFFFCA5A5)
                      : isPositive
                          ? NV.accent.withValues(alpha: 0.22)
                          : c.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isNegative
                        ? Icons.trending_down_rounded
                        : isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_flat_rounded,
                    size: 18,
                    color: isNegative
                        ? const Color(0xFFEF4444)
                        : isPositive
                            ? NV.accent
                            : c.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      impact.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isNegative
                            ? const Color(0xFFDC2626)
                            : isPositive
                                ? NV.accent
                                : c.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${impact.current.round()}% → ${impact.projected.round()}%',
                    style: nvNumber(
                      12,
                      color: c.textMuted,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NVSpace.x4),
            NVPrimaryButton(
              label: _saving ? 'Logging…' : 'Save to log',
              leadingIcon: _saving ? null : Icons.check_rounded,
              loading: _saving,
              accent: true,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loggedOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _loggedOn = picked);
    }
  }
}

String _humanize(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _dateLabel(DateTime date) {
  final today = DateTime.now();
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return 'Today';
  }
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Lightweight struct for the score-impact simulation.
class _SimNutrient {
  const _SimNutrient({
    required this.amount,
    required this.driAmount,
    required this.isLimit,
  });
  final double amount;
  final double driAmount;
  final bool isLimit;
}

class _DrinkChip extends StatelessWidget {
  const _DrinkChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Material(
      color: selected ? NV.accentSoft : c.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? NV.accent.withValues(alpha: 0.4)
                  : c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? NV.accent : c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
