import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/food.dart';
import '../core/models/nutrient_reference.dart';
import '../core/models/visual_catalog.dart';
import '../core/providers/food_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/nv_loader.dart';

class VitaminDetailScreen extends StatefulWidget {
  const VitaminDetailScreen({super.key, this.code = 'D'});
  final String code;

  @override
  State<VitaminDetailScreen> createState() => _VitaminDetailScreenState();
}

class _VitaminDetailScreenState extends State<VitaminDetailScreen> {
  late final NutrientReference _nutrient;
  late Future<List<FoodSummary>> _sourcesFuture;

  @override
  void initState() {
    super.initState();
    _nutrient =
        nutrientReferencesByCode[widget.code] ?? nutrientReferencesByCode['D']!;
    final provider = context.read<FoodProvider>();
    _sourcesFuture = provider.fetchFoods(nutrient: _nutrient.code, limit: 8);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final hue = vitaminColors[_nutrient.code] ?? vitaminColors['D']!;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: dark ? hue.fill.withValues(alpha: 0.13) : hue.bg,
            elevation: 0,
            pinned: false,
            floating: true,
            leading: NVCircleIconButton(
              icon: Icons.chevron_left,
              background: c.surface.withValues(alpha: 0.8),
              foreground: c.text,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              NVCircleIconButton(
                icon: Icons.search,
                background: c.surface.withValues(alpha: 0.8),
                foreground: c.text,
                onTap: () => context.push('/app/search'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              color: dark ? hue.fill.withValues(alpha: 0.13) : hue.bg,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _VitaminHero(nutrient: _nutrient, hue: hue),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                _DailyTargetCard(nutrient: _nutrient, hue: hue),
                const SizedBox(height: 14),
                _BenefitsCard(nutrient: _nutrient, hue: hue),
                const SizedBox(height: 14),
                _TopSources(
                  nutrient: _nutrient,
                  hue: hue,
                  sourcesFuture: _sourcesFuture,
                ),
                const SizedBox(height: 14),
                _LowIntakeCard(nutrient: _nutrient),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitaminHero extends StatelessWidget {
  const _VitaminHero({required this.nutrient, required this.hue});

  final NutrientReference nutrient;
  final VitaminHue hue;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final visual = nutrientVisualFor(nutrient.code);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.border),
        image: DecorationImage(
          image: NetworkImage(visual.imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.70),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              visual.icon,
              size: 120,
              color: hue.fill.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VitaminChip(code: nutrient.code, size: 58),
              const SizedBox(height: 16),
              Text(
                nutrient.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nutrient.summary,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.42,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  NutrientPill(
                    code: nutrient.code,
                    label: nutrient.group,
                    compact: true,
                  ),
                  if (nutrient.dailyTarget > 0)
                    _HeroMetric(label: nutrient.targetLabel, color: hue.fill),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DailyTargetCard extends StatelessWidget {
  const _DailyTargetCard({required this.nutrient, required this.hue});

  final NutrientReference nutrient;
  final VitaminHue hue;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final hasDailyTarget = nutrient.dailyTarget > 0;
    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          RingProgress(
            pct: hasDailyTarget ? 0.35 : 0,
            size: 72,
            color: hue.fill,
            label: hasDailyTarget ? 'DV' : '-',
            sub: 'adult',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Daily target'),
                const SizedBox(height: 2),
                Text(
                  hasDailyTarget ? nutrient.targetLabel : 'No established DV',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adult Daily Value reference used for source ranking',
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

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.nutrient, required this.hue});

  final NutrientReference nutrient;
  final VitaminHue hue;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Why it matters'),
          const SizedBox(height: 10),
          ...nutrient.benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: hue.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check, size: 14, color: hue.fill),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSources extends StatefulWidget {
  const _TopSources({
    required this.nutrient,
    required this.hue,
    required this.sourcesFuture,
  });

  final NutrientReference nutrient;
  final VitaminHue hue;
  final Future<List<FoodSummary>> sourcesFuture;

  @override
  State<_TopSources> createState() => _TopSourcesState();
}

class _TopSourcesState extends State<_TopSources> {
  bool _expanded = false;
  List<FoodSummary>? _allSources;
  bool _loadingMore = false;

  Future<void> _loadAll() async {
    setState(() => _loadingMore = true);
    try {
      final provider = context.read<FoodProvider>();
      final all = await provider.fetchFoods(
        nutrient: widget.nutrient.code,
        limit: 300,
      );
      if (mounted) {
        setState(() {
          _allSources = all;
          _expanded = true;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Top sources',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: c.text,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<FoodSummary>>(
          future: widget.sourcesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const NVCard(
                padding: EdgeInsets.all(18),
                child: Center(
                  child: NVLoader(label: 'Finding food sources…'),
                ),
              );
            }
            if (snapshot.hasError) {
              return NVCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Could not load sources: ${snapshot.error}',
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              );
            }
            final initialFoods = snapshot.data ?? const <FoodSummary>[];
            if (initialFoods.isEmpty) {
              return NVCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No source foods found yet.',
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              );
            }

            final displayFoods = _expanded && _allSources != null
                ? _allSources!
                : initialFoods;

            return Column(
              children: [
                ...displayFoods.map(
                  (food) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SourceFoodCard(food: food, hue: widget.hue),
                  ),
                ),
                const SizedBox(height: 4),
                if (!_expanded)
                  _ShowMoreButton(
                    loading: _loadingMore,
                    onTap: _loadAll,
                    label: 'Show more sources',
                  )
                else
                  _ShowMoreButton(
                    loading: false,
                    onTap: () => setState(() => _expanded = false),
                    label: 'Show less',
                    icon: Icons.keyboard_arrow_up_rounded,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Source rankings use the extracted percent-Daily-Value profile.',
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({
    required this.loading,
    required this.onTap,
    required this.label,
    this.icon = Icons.keyboard_arrow_down_rounded,
  });

  final bool loading;
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Material(
      color: c.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                loading ? 'Loading…' : label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: NV.accent,
                ),
              ),
              if (!loading) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 18, color: NV.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceFoodCard extends StatelessWidget {
  const _SourceFoodCard({required this.food, required this.hue});

  final FoodSummary food;
  final VitaminHue hue;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final pct = (food.driPercent ?? 0) / 100;
    return NVCard(
      onTap: () => context.push('/app/food/${food.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          FoodPhoto(
            label: food.name,
            imageUrl: food.imageUrl,
            category: food.category,
            height: 54,
            width: 54,
            radius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  food.category,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
                const SizedBox(height: 8),
                BarProgress(
                  pct: pct.clamp(0.0, 1.0),
                  color: hue.fill,
                  height: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            food.driPercent == null ? '-' : '${food.driPercent!.round()}%',
            style: TextStyle(
              color: hue.fill,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LowIntakeCard extends StatelessWidget {
  const _LowIntakeCard({required this.nutrient});

  final NutrientReference nutrient;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('If intake is low'),
          const SizedBox(height: 6),
          Text(
            nutrient.lowNote,
            style: TextStyle(fontSize: 14, color: c.text, height: 1.5),
          ),
        ],
      ),
    );
  }
}
