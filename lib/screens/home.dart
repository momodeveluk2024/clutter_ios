import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/food_log.dart';
import '../core/models/nutrient_reference.dart';
import '../core/models/nutrition.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/nv_loader.dart';
import 'meal_log_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<NutritionProvider>().refreshDashboard();

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final auth = context.watch<AuthProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final user = auth.user;
    final now = DateTime.now();
    final totals = nutrition.todayTotals;
    final pct = totals?.averagePercent ?? 0;
    final isFirstLoad = nutrition.isLoading && totals == null;

    if (isFirstLoad) {
      return Scaffold(
        backgroundColor: c.bg,
        body: const Center(child: NVLoader(label: 'Loading your day…')),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/app/search'),
        backgroundColor: NV.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Log meal',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: NV.accent,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _TopBar(user: user, now: now),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  NVSpace.x5,
                  NVSpace.x4,
                  NVSpace.x5,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    _HeroToday(
                      pct: pct,
                      streak: nutrition.streak,
                      mealCount: nutrition.logs.length,
                      trackedCount: totals?.nutrients.length ?? 0,
                      metCount: totals?.metCount ?? 0,
                      scoredCount: totals?.trackedCount ?? 0,
                      isLoading: nutrition.isLoading && totals == null,
                    ),
                    const SizedBox(height: NVSpace.x6),
                    _MacroBentoRow(totals: totals),
                    const SizedBox(height: NVSpace.x8),
                    if (nutrition.dailyMealPlan?.hasItems ?? false) ...[
                      NVSectionHeader(
                        eyebrow: 'Today',
                        title: 'Recommended meals',
                        trailing: TextButton(
                          onPressed: () => _showDailyMealPlan(
                            context,
                            nutrition.dailyMealPlan!,
                          ),
                          child: const Text('View plan'),
                        ),
                      ),
                      const SizedBox(height: NVSpace.x3),
                      _DailyMealPlanCard(plan: nutrition.dailyMealPlan!),
                      const SizedBox(height: NVSpace.x8),
                    ],
                    if (nutrition.recommendations.isNotEmpty) ...[
                      NVSectionHeader(
                        eyebrow: 'For you',
                        title: 'Recommended foods',
                        trailing: TextButton(
                          onPressed: () => context.push('/app/explore'),
                          child: const Text('See all'),
                        ),
                      ),
                      const SizedBox(height: NVSpace.x3),
                      ...nutrition.recommendations
                          .take(2)
                          .map(
                            (rec) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: NVSpace.x3,
                              ),
                              child: _RecommendationTile(rec: rec),
                            ),
                          ),
                    ] else ...[
                      _StarterCard(),
                    ],
                    const SizedBox(height: NVSpace.x8),
                    NVSectionHeader(
                      eyebrow: 'Today',
                      title: nutrition.logs.isEmpty
                          ? 'No meals yet'
                          : '${nutrition.logs.length} ${nutrition.logs.length == 1 ? 'meal' : 'meals'} logged',
                      trailing: nutrition.logs.isEmpty
                          ? null
                          : TextButton(
                              onPressed: () => context.push('/app/tracker'),
                              child: const Text('History'),
                            ),
                    ),
                    const SizedBox(height: NVSpace.x3),
                    if (nutrition.logs.isEmpty)
                      _EmptyMealsCard()
                    else
                      ...nutrition.logs
                          .take(3)
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: NVSpace.x2,
                              ),
                              child: _MealRow(log: log),
                            ),
                          ),
                    const SizedBox(height: NVSpace.x8),
                    const NVSectionHeader(
                      eyebrow: 'Coverage',
                      title: 'Nutrients to focus on',
                    ),
                    const SizedBox(height: NVSpace.x3),
                    _NutrientGapsRow(totals: totals),
                    const SizedBox(height: 100),
                  ],
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
//  TOP BAR
// ═══════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.user, required this.now});
  final dynamic user;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final h = now.hour;
    final greeting = h < 5
        ? 'Late night'
        : h < 12
        ? 'Good morning'
        : h < 17
        ? 'Good afternoon'
        : h < 21
        ? 'Good evening'
        : 'Good night';
    final name = (user?.displayName as String?)?.split(' ').firstOrNull ?? '';
    final dateLine = '${_weekdayLong(now)}, ${_monthLong(now)} ${now.day}'
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NVSpace.x5,
        NVSpace.x3,
        NVSpace.x5,
        NVSpace.x2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NVEyebrow(dateLine, color: c.textMuted),
                const SizedBox(height: 6),
                Text(
                  name.isEmpty ? greeting : '$greeting, $name.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NVSpace.x3),
          UserAvatar(
            displayName: (user?.displayName as String?) ?? 'User',
            avatarUrl: user?.avatarUrl as String?,
            size: 44,
            onTap: () => context.push('/app/profile'),
          ),
        ],
      ),
    );
  }

  String _weekdayLong(DateTime d) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][d.weekday - 1];

  String _monthLong(DateTime d) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][d.month - 1];
}

// ═══════════════════════════════════════════════════════════════
//  HERO — editorial title + ring + headline number
// ═══════════════════════════════════════════════════════════════

class _HeroToday extends StatelessWidget {
  const _HeroToday({
    required this.pct,
    required this.streak,
    required this.mealCount,
    required this.trackedCount,
    required this.metCount,
    required this.scoredCount,
    required this.isLoading,
  });

  final double pct;
  final int streak;
  final int mealCount;
  final int trackedCount;
  final int metCount;
  final int scoredCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final pctValue = pct.round();
    final ringPct = (pct / 100).clamp(0.0, 1.0);

    return NVCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(
        NVSpace.x5,
        NVSpace.x6,
        NVSpace.x5,
        NVSpace.x5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NVEyebrow('Today', color: c.textMuted),
          const SizedBox(height: NVSpace.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? '—' : '$pctValue',
                      style: nvNumber(64, color: c.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'of daily nutrients',
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RingProgress(
                pct: ringPct,
                size: 92,
                stroke: 9,
                label: '$pctValue%',
                sub: scoredCount > 0 ? '$metCount/$scoredCount met' : 'covered',
              ),
            ],
          ),
          const SizedBox(height: NVSpace.x5),
          Container(height: 1, color: c.border),
          const SizedBox(height: NVSpace.x4),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Streak',
                  value: '$streak',
                  unit: streak == 1 ? 'day' : 'days',
                ),
              ),
              Container(width: 1, height: 28, color: c.border),
              Expanded(
                child: _MiniStat(
                  label: 'Meals',
                  value: '$mealCount',
                  unit: mealCount == 1 ? 'logged' : 'logged',
                ),
              ),
              Container(width: 1, height: 28, color: c.border),
              Expanded(
                child: _MiniStat(
                  label: 'Tracked',
                  value: '$trackedCount',
                  unit: 'nutrients',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.unit,
  });
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      children: [
        NVEyebrow(label, color: c.textMuted),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: nvNumber(20, color: c.text)),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 11,
                color: c.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MACRO BENTO — single accent (one of the macros highlighted)
// ═══════════════════════════════════════════════════════════════

class _MacroBentoRow extends StatelessWidget {
  const _MacroBentoRow({required this.totals});
  final DayNutrientTotals? totals;

  @override
  Widget build(BuildContext context) {
    final macros = const ['Protein', 'Carbs', 'Fat'];
    final macroPercents = <String, double>{};
    for (final m in macros) {
      final t = totals?.nutrients.firstWhere(
        (n) => n.code == m,
        orElse: () =>
            const NutrientTotal(code: '', name: '', unit: '', amount: 0),
      );
      macroPercents[m] = t?.driPercent ?? 0;
    }

    return Row(
      children: [
        for (var i = 0; i < macros.length; i++) ...[
          Expanded(
            child: _MacroTile(
              code: macros[i],
              pct: macroPercents[macros[i]] ?? 0,
            ),
          ),
          if (i < macros.length - 1) const SizedBox(width: NVSpace.x3),
        ],
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.code, required this.pct});
  final String code;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final hue = vitaminColors[code]!;
    final pctLabel = '${pct.round()}%';
    final shortLabel = code; // Protein / Carbs / Fat — already friendly
    return NVCard(
      padding: const EdgeInsets.all(NVSpace.x4),
      onTap: () => context.push('/app/vitamin/$code'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hue.fill,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                shortLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: NVSpace.x3),
          Text(pctLabel, style: nvNumber(22, color: c.text)),
          const SizedBox(height: NVSpace.x2),
          BarProgress(
            pct: (pct / 100).clamp(0.0, 1.0),
            color: hue.fill,
            height: 4,
          ),
        ],
      ),
    );
  }
}

void _showDailyMealPlan(BuildContext context, DailyMealPlan plan) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => _DailyMealPlanSheet(plan: plan),
  );
}

class _DailyMealPlanCard extends StatelessWidget {
  const _DailyMealPlanCard({required this.plan});
  final DailyMealPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final slots = plan.meals.where((slot) => slot.items.isNotEmpty).toList();
    return NVCard(
      onTap: () => _showDailyMealPlan(context, plan),
      padding: const EdgeInsets.all(NVSpace.x4),
      child: Column(
        children: [
          for (var i = 0; i < math.min(slots.length, 3); i++) ...[
            _MealPlanSlotRow(slot: slots[i], compact: true),
            if (i < math.min(slots.length, 3) - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: NVSpace.x3),
                child: Container(height: 1, color: c.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _DailyMealPlanSheet extends StatelessWidget {
  const _DailyMealPlanSheet({required this.plan});
  final DailyMealPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          NVSpace.x5,
          0,
          NVSpace.x5,
          MediaQuery.of(context).viewInsets.bottom + NVSpace.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended meals today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Picked from your current nutrient gaps and preferences.',
              style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.4),
            ),
            const SizedBox(height: NVSpace.x5),
            ...plan.meals.map(
              (slot) => Padding(
                padding: const EdgeInsets.only(bottom: NVSpace.x3),
                child: _MealPlanSlotRow(slot: slot, dismissOnTap: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPlanSlotRow extends StatelessWidget {
  const _MealPlanSlotRow({
    required this.slot,
    this.compact = false,
    this.dismissOnTap = false,
  });
  final MealPlanSlot slot;
  final bool compact;
  final bool dismissOnTap;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final item = slot.items.isEmpty ? null : slot.items.first;
    return InkWell(
      onTap: item == null
          ? null
          : () {
              if (dismissOnTap) Navigator.of(context).maybePop();
              context.push('/app/food/${item.foodId}');
            },
      borderRadius: BorderRadius.circular(NVRadius.cardSm),
      child: Padding(
        padding: EdgeInsets.all(compact ? 0 : NVSpace.x3),
        child: Row(
          children: [
            FoodPhoto(
              label: item?.foodName ?? slot.title,
              imageUrl: item?.foodImageUrl,
              width: compact ? 52 : 58,
              height: compact ? 52 : 58,
              radius: NVRadius.cardSm,
              tone: 'warm',
            ),
            const SizedBox(width: NVSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NVEyebrow(slot.title, color: c.textMuted),
                  const SizedBox(height: 4),
                  Text(
                    item?.foodName ?? 'No recommendation yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w800,
                      color: c.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (item != null && !compact) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STARTER CARD
// ═══════════════════════════════════════════════════════════════

class _StarterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      padding: const EdgeInsets.all(NVSpace.x5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: NV.accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_outlined, color: NV.accent, size: 22),
          ),
          const SizedBox(width: NVSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log your first meal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Once you log a meal we\'ll show recommendations based on your nutrient gaps.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RECOMMENDATIONS
// ═══════════════════════════════════════════════════════════════

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.rec});
  final Recommendation rec;

  @override
  Widget build(BuildContext context) {
    final nutrient = nutrientReferencesByCode[rec.code];
    final c = NVColors.of(context);
    final hue = vitaminColors[rec.code] ?? vitaminColors['D']!;
    return NVCard(
      onTap: () => context.push('/app/food/${rec.foodId}'),
      padding: const EdgeInsets.all(NVSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FoodPhoto(
            label: rec.foodName,
            imageUrl: rec.foodImageUrl,
            width: 64,
            height: 64,
            radius: NVRadius.cardSm,
            tone: 'warm',
          ),
          const SizedBox(width: NVSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NVEyebrow(
                  'Low on ${nutrient?.name ?? rec.name}',
                  color: hue.fill,
                ),
                const SizedBox(height: 4),
                Text(
                  rec.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.foodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 18, color: c.textMuted),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY MEALS
// ═══════════════════════════════════════════════════════════════

class _EmptyMealsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      padding: const EdgeInsets.all(NVSpace.x5),
      child: Row(
        children: [
          Icon(Icons.restaurant_outlined, color: c.textMuted, size: 20),
          const SizedBox(width: NVSpace.x3),
          Expanded(
            child: Text(
              'No meals logged yet today.',
              style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/app/search'),
            child: const Text('Log meal'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MEAL ROW — clean tappable list row, no card chrome
// ═══════════════════════════════════════════════════════════════

class _MealRow extends StatelessWidget {
  const _MealRow({required this.log});
  final MealLog log;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final itemText = log.items
        .map((i) => i.foodName)
        .where((n) => n.trim().isNotEmpty)
        .join(' · ');
    final firstItem = log.items.isEmpty ? null : log.items.first;
    final time = _formatTime(log);
    return NVCard(
      onTap: () => showMealLogDetails(
        context,
        log,
        date: DateTime.tryParse(log.loggedOn),
      ),
      padding: const EdgeInsets.all(NVSpace.x3),
      child: Row(
        children: [
          FoodPhoto(
            label: firstItem?.foodName ?? log.mealType,
            imageUrl: firstItem?.imageUrl,
            width: 52,
            height: 52,
            radius: NVRadius.cardSm,
            tone: 'cool',
          ),
          const SizedBox(width: NVSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _titleCase(log.mealType),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (time != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: c.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  itemText.isEmpty ? 'No items' : itemText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
        ],
      ),
    );
  }

  String? _formatTime(MealLog log) {
    final d = DateTime.tryParse(log.loggedOn);
    if (d == null) return null;
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    if (h == 0 && d.minute == 0) return null;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ampm';
  }

  String _titleCase(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
}

// ═══════════════════════════════════════════════════════════════
//  NUTRIENT GAPS (horizontal scroll)
// ═══════════════════════════════════════════════════════════════

class _NutrientGapsRow extends StatelessWidget {
  const _NutrientGapsRow({required this.totals});
  final DayNutrientTotals? totals;

  @override
  Widget build(BuildContext context) {
    final gaps = _gaps(totals);
    final starters = [
      'B12',
      'D',
      'C',
    ].map((code) => nutrientReferencesByCode[code]!).toList();
    final nutrients = gaps.isEmpty ? starters : gaps;
    final byCode = {
      for (final n in totals?.nutrients ?? const <NutrientTotal>[]) n.code: n,
    };

    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: nutrients.length,
        separatorBuilder: (_, _) => const SizedBox(width: NVSpace.x3),
        itemBuilder: (context, i) {
          final n = nutrients[i];
          final hue = vitaminColors[n.code] ?? vitaminColors['D']!;
          final pct = ((byCode[n.code]?.driPercent ?? 0) / 100).clamp(0.0, 1.0);
          return _NutrientGapCard(nutrient: n, hue: hue, pct: pct);
        },
      ),
    );
  }

  List<NutrientReference> _gaps(DayNutrientTotals? totals) {
    final nutrients = [
      ...?totals?.nutrients.where((item) => item.driPercent != null),
    ];
    nutrients.sort((a, b) => (a.driPercent ?? 0).compareTo(b.driPercent ?? 0));
    return nutrients
        .take(5)
        .map((item) => nutrientReferencesByCode[item.code])
        .whereType<NutrientReference>()
        .toList();
  }
}

class _NutrientGapCard extends StatelessWidget {
  const _NutrientGapCard({
    required this.nutrient,
    required this.hue,
    required this.pct,
  });
  final NutrientReference nutrient;
  final VitaminHue hue;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return SizedBox(
      width: 156,
      child: NVCard(
        onTap: () => context.push('/app/vitamin/${nutrient.code}'),
        padding: const EdgeInsets.all(NVSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VitaminChip(code: nutrient.code, size: 36),
            const Spacer(),
            Text(
              nutrient.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.text,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              nutrient.group,
              style: TextStyle(fontSize: 11, color: c.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: NVSpace.x3),
            Row(
              children: [
                Expanded(
                  child: BarProgress(pct: pct, color: hue.fill, height: 4),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(math.max(pct, 0) * 100).round()}%',
                  style: nvNumber(
                    11,
                    color: c.textMuted,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
