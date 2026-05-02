import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/models/food.dart';
import '../core/nutrition/overage_warning.dart';
import '../core/providers/food_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';

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
              child: CircularProgressIndicator(color: NV.accent),
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
                    ? food.source
                    : '${food.source} · ${food.servingSizeG.toStringAsFixed(0)}g serving',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textMuted,
                  height: 1.45,
                ),
              ),
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
                      value: food.verified ? 'Yes' : 'No',
                      label: 'verified',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NVSpace.x5),
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
                    'This imported VitaminFinder profile is stored as percent Daily Value for source browsing.',
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

  void _showLogSheet(BuildContext context, FoodDetail food) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _LogFoodSheet(food: food),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: nvNumber(18, color: c.text, weight: FontWeight.w700),
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
                    Text(
                      nutrient.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.text,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      nutrient.driPercent == null
                          ? '—'
                          : '${nutrient.driPercent!.round()}%',
                      style: nvNumber(
                        13,
                        color: pct >= 1 ? hue.fill : c.textMuted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                BarProgress(pct: pct, color: hue.fill, height: 4),
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
  bool _saving = false;

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
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logged ${widget.food.name}')));
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

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
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
