import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api/api_endpoints.dart';
import '../core/models/food.dart';
import '../core/nutrition/overage_warning.dart';
import '../core/providers/auth_provider.dart';
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
    // Allow logging for any food that has at least one nutrient entry OR comes from an external source
    final hasNutrientData = food.breakdown.any(
      (n) => n.amountPer100G > 0 || (n.driPercent ?? 0) > 0,
    );
    final isExternalSource = const {'openfoodfacts', 'fatsecret', 'seed'}
        .contains(food.source.toLowerCase());
    final canLog = hasNutrientData || isExternalSource || food.breakdown.isNotEmpty;
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
                    : '${food.servingSizeG.toStringAsFixed(0)}${_servingUnit(food.category)} serving${food.brand != null ? ' · ${food.brand}' : ''} · ${food.category}',
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
              _MacrosPanel(food: food),
              const SizedBox(height: NVSpace.x3),
              NVCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(
                      value: '${food.servingSizeG.toStringAsFixed(0)} ${_servingUnit(food.category)}',
                      label: 'per serving',
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Nutrient breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'per 100${_servingUnit(food.category)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                  ],
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
              if (!hasNutrientData && !isExternalSource)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Limited nutrient data available for this food.',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ),
              const SizedBox(height: NVSpace.x4),
              NVPrimaryButton(
                label: 'Log this food',
                leadingIcon: Icons.add_rounded,
                accent: true,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showLogSheet(context, food);
                },
              ),
              const SizedBox(height: 10),
              _SaveToMyMealsButton(food: food),
              const SizedBox(height: 12),
              _SuggestEditLink(food: food),
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

    // Per-serving kcal + macros so the user can see exactly what the log adds.
    double per100(String code) {
      for (final n in food.breakdown) {
        if (n.code == code) return n.amountPer100G;
      }
      return 0;
    }

    final factor = result.servingG / 100.0;
    final p = per100('Protein') * factor;
    final cg = per100('Carbs') * factor;
    final f = per100('Fat') * factor;
    final storedKcal = per100('Calories') * factor;
    final kcal = storedKcal > 0 ? storedKcal : (p * 4 + cg * 4 + f * 9);

    final parts = <String>[
      if (kcal > 0) '+${kcal.round()} kcal',
      if (p > 0) 'P ${p.round()}g',
      if (cg > 0) 'C ${cg.round()}g',
      if (f > 0) 'F ${f.round()}g',
    ];
    final servingUnit = _servingUnit(food.category);
    final macroLine = parts.isEmpty
        ? '${result.servingG.round()}$servingUnit · ${_humanize(result.mealType)}'
        : '${parts.join(' · ')}  ·  ${result.servingG.round()}$servingUnit';

    LogSuccessToast.show(
      context,
      title: 'Logged ${food.name}',
      subtitle: macroLine,
      imageUrl: food.imageUrl,
    );
  }
}

class _LogFoodResult {
  const _LogFoodResult({required this.servingG, required this.mealType});

  final double servingG;
  final String mealType;
}

// ═══════════════════════════════════════════════════════════════
//  MACROS PANEL — calories + P/C/F/Fiber at a glance
// ═══════════════════════════════════════════════════════════════

class _MacrosPanel extends StatelessWidget {
  const _MacrosPanel({required this.food});
  final FoodDetail food;

  double _per100(String code) {
    for (final n in food.breakdown) {
      if (n.code == code) return n.amountPer100G;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final servingG = food.servingSizeG;
    final p100 = _per100('Protein');
    final c100 = _per100('Carbs');
    final f100 = _per100('Fat');
    final fb100 = _per100('Fiber');
    final stored100 = _per100('Calories');
    final kcal100 = stored100 > 0 ? stored100 : (p100 * 4 + c100 * 4 + f100 * 9);

    double perServing(double per100g) => per100g * servingG / 100.0;
    final kcal = perServing(kcal100);
    final p = perServing(p100);
    final cg = perServing(c100);
    final f = perServing(f100);
    final fb = perServing(fb100);

    final hasAny =
        kcal > 0 || p > 0 || cg > 0 || f > 0 || fb > 0;
    if (!hasAny) return const SizedBox.shrink();

    final unit = _servingUnit(food.category);
    return NVCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Per ${servingG.toStringAsFixed(0)}$unit serving',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: c.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NV.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: NV.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${kcal.round()} kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NV.accent,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MacroCell(label: 'Protein', value: p, unit: 'g', color: Color(0xFF2F7D4A))),
              Expanded(child: _MacroCell(label: 'Carbs', value: cg, unit: 'g', color: Color(0xFFB07A1A))),
              Expanded(child: _MacroCell(label: 'Fat', value: f, unit: 'g', color: Color(0xFF6B4A8A))),
              Expanded(child: _MacroCell(label: 'Fiber', value: fb, unit: 'g', color: Color(0xFF3A6B88))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final double value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final formatted = value >= 10
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: formatted,
                style: nvNumber(18, color: c.text, weight: FontWeight.w700),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show the actual amount per 100g
                        if (nutrient.amountPer100G > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              _formatAmount(nutrient.amountPer100G, nutrient.unit),
                              style: nvNumber(
                                11,
                                color: c.textMuted,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
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
  late double _servingG = () {
    final s = widget.food.servingSizeG;
    if (s.isFinite && s > 0) return s.clamp(1.0, 1000.0);
    return 100.0;
  }();
  DateTime _loggedOn = DateTime.now();
  String? _pairedDrink;
  int _drinkQuantity = 1;
  bool _showAllDrinks = false;
  final _notesController = TextEditingController();
  bool _saving = false;

  // Image URLs keyed by chip label (e.g. "Coca-Cola"). Populated lazily from
  // the drinks catalog so chips show the admin-uploaded photo for the matching
  // drink instead of just an emoji. Empty until the fetch resolves; the chip
  // falls back to the hardcoded emoji while loading and on any unmatched name.
  Map<String, String> _drinkImages = const {};

  @override
  void initState() {
    super.initState();
    _loadDrinkImages();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDrinkImages() async {
    try {
      final drinks = await context
          .read<FoodProvider>()
          .fetchFoods(category: 'drinks', limit: 100);
      final matched = <String, String>{};
      for (final label in _drinkChipLabels) {
        final needle = label.toLowerCase();
        for (final food in drinks) {
          final url = food.imageUrl?.trim();
          if (url == null || url.isEmpty) continue;
          if (food.name.toLowerCase().contains(needle)) {
            matched[label] = ApiEndpoints.mediaUrl(url);
            break;
          }
        }
      }
      if (!mounted || matched.isEmpty) return;
      setState(() => _drinkImages = matched);
    } catch (_) {
      // Fetch failures are non-fatal — chips just keep showing emojis.
    }
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
        pairedDrinkQuantity: _drinkQuantity,
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
          final added = entry.value * (330.0 / 100) * _drinkQuantity;
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
    if (delta > 0.1) {
      label = '+${delta.toStringAsFixed(1)}% estimated';
    } else if (delta < -0.1) {
      label = '${delta.toStringAsFixed(1)}% estimated';
    } else {
      label = 'No score change expected';
    }

    return (current: currentScore, projected: projectedScore, label: label);
  }

  /// Computes the estimated kcal change if the user logs this serving.
  ({double current, double projected, double delta}) _kcalImpact() {
    final nutrition = context.read<NutritionProvider>();
    final totals = nutrition.todayTotals;

    double current = 0;
    if (totals != null) {
      for (final n in totals.nutrients) {
        if (n.code == 'Energy' || n.code == 'Calories' || n.code == 'kcal') {
          current = n.amount;
          break;
        }
      }
    }

    // Calories from this food at the chosen serving.
    double foodKcal = 0;
    for (final n in widget.food.breakdown) {
      if (n.code == 'Energy' || n.code == 'Calories' || n.code == 'kcal') {
        foodKcal = n.amountPer100G * (_servingG / 100);
        break;
      }
    }
    // Fallback to Atwater factors when the catalog row lacks a kcal entry.
    if (foodKcal == 0) {
      for (final n in widget.food.breakdown) {
        final amt = n.amountPer100G * (_servingG / 100);
        if (n.code == 'Protein') foodKcal += amt * 4;
        if (n.code == 'Carbs') foodKcal += amt * 4;
        if (n.code == 'Fat') foodKcal += amt * 9;
      }
    }

    // Add paired drink kcal (matches the macros table used in _scoreImpact).
    double drinkKcal = 0;
    if (_pairedDrink != null) {
      const drinkCalsPer100ml = {
        'Water': 0.0,
        'Tea': 1.0,
        'Coffee': 2.0,
        'Juice': 45.0,
        'Milk': 61.0,
        'Coca-Cola': 42.0,
        'Pepsi': 41.0,
        'Fanta': 48.0,
        'Sprite': 40.0,
        'Energy drink': 45.0,
        'Smoothie': 55.0,
        'Lemonade': 40.0,
      };
      final per100 = drinkCalsPer100ml[_pairedDrink] ?? 0;
      drinkKcal = per100 * (330.0 / 100) * _drinkQuantity;
    }

    final delta = foodKcal + drinkKcal;
    return (current: current, projected: current + delta, delta: delta);
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final impact = _scoreImpact();
    final kcalImpact = _kcalImpact();
    final delta = impact.projected - impact.current;
    final isPositive = delta > 0.1;
    final isNegative = delta < -0.1;

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
                  '${_servingG.round()} ${_servingUnit(widget.food.category)}',
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
                value: _servingG.clamp(1.0, 1000.0),
                min: 1,
                max: 1000,
                divisions: 999,
                label: '${_servingG.round()}${_servingUnit(widget.food.category)}',
                onChanged: (value) => setState(() => _servingG = value),
              ),
            ),
            // ── Pair with a drink (optional) ──
            const SizedBox(height: NVSpace.x4),
            NVEyebrow('Pair with a drink', color: c.textMuted),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final visible = _showAllDrinks
                  ? _kDrinkOptions
                  : _kDrinkOptions.take(3).toList();
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
                            imageUrl: _drinkImages[drink.$2],
                            selected: _pairedDrink == drink.$2,
                            onTap: () => setState(() {
                              if (_pairedDrink == drink.$2) {
                                _pairedDrink = null;
                                _drinkQuantity = 1;
                              } else {
                                _pairedDrink = drink.$2;
                                _drinkQuantity = 1;
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      if (_pairedDrink != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _drinkQuantity > 1
                                  ? () => setState(() => _drinkQuantity--)
                                  : null,
                              icon: const Icon(Icons.remove_rounded, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: NV.accent,
                              disabledColor: c.textMuted.withValues(alpha: 0.3),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_drinkQuantity',
                                style: nvNumber(15, color: c.text, weight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: _drinkQuantity < 10
                                  ? () => setState(() => _drinkQuantity++)
                                  : null,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: NV.accent,
                              disabledColor: c.textMuted.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                    ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
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
                  if (kcalImpact.delta.abs() >= 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: kcalImpact.delta > 0
                              ? const Color(0xFFEA580C)
                              : c.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${kcalImpact.delta > 0 ? '+' : ''}${kcalImpact.delta.round()} kcal estimated',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kcalImpact.delta > 0
                                  ? const Color(0xFFC2410C)
                                  : c.textMuted,
                            ),
                          ),
                        ),
                        Text(
                          '${kcalImpact.current.round()} → ${kcalImpact.projected.round()} kcal',
                          style: nvNumber(
                            12,
                            color: c.textMuted,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
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

/// Returns 'ml' for liquid categories, 'g' for everything else.
String _servingUnit(String category) {
  const liquidCategories = {
    'drinks',
    'beverages',
    'juice',
    'milk',
    'water',
    'smoothies',
    'soda',
    'tea',
    'coffee',
    'sugary-drinks',
  };
  return liquidCategories.contains(category.toLowerCase()) ? 'ml' : 'g';
}

/// Formats a nutrient amount with its unit, e.g. "42.5g", "150kcal", "0.8mg".
String _formatAmount(double amount, String unit) {
  final formatted = amount >= 10
      ? amount.toStringAsFixed(0)
      : amount >= 1
          ? amount.toStringAsFixed(1)
          : amount.toStringAsFixed(2);
  return '$formatted$unit';
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

// Hardcoded drink pairing options. Each chip is matched against the drinks
// catalog by label substring so admins can swap the leading emoji with a real
// photo just by uploading an image to a drink whose name contains the label.
const List<(String, String)> _kDrinkOptions = [
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

Iterable<String> get _drinkChipLabels => _kDrinkOptions.map((d) => d.$2);

class _DrinkChip extends StatelessWidget {
  const _DrinkChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Material(
      color: selected ? NV.accentSoft : c.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(hasImage ? 6 : 12, hasImage ? 6 : 10, 12, hasImage ? 6 : 10),
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
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 120),
                    placeholder: (_, _) => SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    errorWidget: (_, _, _) =>
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                )
              else
                Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
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

// ═══════════════════════════════════════════════════════════════
//  SAVE TO MY MEALS — clones the food into the user's library so
//  they can edit nutrients (especially useful for OFF/FatSecret
//  barcode-resolved foods which have no owner).
// ═══════════════════════════════════════════════════════════════

/// Compact secondary link letting the user flag the catalog entry as
/// wrong (e.g. barcode reader picked up the wrong digits, name is
/// off). Routes to a form that submits a draft edit for admin review.
class _SuggestEditLink extends StatelessWidget {
  const _SuggestEditLink({required this.food});
  final FoodDetail food;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Center(
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.push('/app/food/${food.id}/suggest', extra: food);
        },
        icon: Icon(Icons.flag_outlined, size: 16, color: c.textMuted),
        label: Text(
          'Something looks wrong? Suggest a fix',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
            decoration: TextDecoration.underline,
            decorationColor: c.textMuted,
            decorationThickness: 0.8,
          ),
        ),
      ),
    );
  }
}

class _SaveToMyMealsButton extends StatefulWidget {
  const _SaveToMyMealsButton({required this.food});
  final FoodDetail food;

  @override
  State<_SaveToMyMealsButton> createState() => _SaveToMyMealsButtonState();
}

class _SaveToMyMealsButtonState extends State<_SaveToMyMealsButton> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final alreadyOwned = widget.food.ownerUserId != null &&
        currentUserId != null &&
        widget.food.ownerUserId == currentUserId;

    if (alreadyOwned) {
      // Already in My Meals — surface a direct edit shortcut instead.
      return OutlinedButton.icon(
        onPressed: () => context.push('/app/my-meal/${widget.food.id}'),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text('Edit in My Meals'),
        style: OutlinedButton.styleFrom(
          foregroundColor: NV.accent,
          side: BorderSide(color: NV.accent.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _saving ? null : _clone,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bookmark_add_outlined, size: 18),
          label: Text(_saving ? 'Saving…' : 'Save to My Meals (editable)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: NV.accent,
            side: BorderSide(color: NV.accent.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Makes a personal copy you can edit. Useful for barcode scans where the numbers are off.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            color: c.textMuted,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Future<void> _clone() async {
    HapticFeedback.selectionClick();
    setState(() => _saving = true);
    try {
      final foods = context.read<FoodProvider>();
      final nutrients = <({String code, double amountPer100G})>[];
      for (final n in widget.food.breakdown) {
        if (n.amountPer100G > 0) {
          nutrients.add((code: n.code, amountPer100G: n.amountPer100G));
        }
      }
      final saved = await foods.createUserMeal(
        name: widget.food.name,
        brand: widget.food.brand,
        category: widget.food.category,
        servingSizeG: widget.food.servingSizeG,
        imageUrl: widget.food.imageUrl,
        backgroundColor: widget.food.backgroundColor,
        nutrients: nutrients,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.push('/app/my-meal/${saved.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
