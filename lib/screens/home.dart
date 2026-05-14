import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'app_shell.dart';

import '../core/models/food_log.dart';
import '../core/models/nutrient_reference.dart';
import '../core/models/nutrition.dart';
import '../core/models/user.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/nv_loader.dart';
import '../widgets/meal_card.dart';
import 'meal_log_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// GlobalKeys for the app tour to target.
  static final scoreKey = GlobalKey(debugLabel: 'tour_score');
  static final macroKey = GlobalKey(debugLabel: 'tour_macros');
  static final fabKey = GlobalKey(debugLabel: 'tour_fab');

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
    final hasOverLimit = (totals?.overLimitNutrients.isNotEmpty ?? false);
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
        key: HomeScreen.fabKey,
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
              _TopBar(user: user, now: now),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  NVSpace.x5,
                  NVSpace.x4,
                  NVSpace.x5,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    KeyedSubtree(
                      key: HomeScreen.scoreKey,
                      child: _HeroToday(
                        pct: pct,
                        streak: nutrition.streak,
                        mealCount: nutrition.logs.length,
                        trackedCount: totals?.nutrients.length ?? 0,
                        metCount: totals?.metCount ?? 0,
                        scoredCount: totals?.trackedCount ?? 0,
                        isLoading: nutrition.isLoading && totals == null,
                        insightMessage: totals?.insightMessage,
                        hasOverLimit: hasOverLimit,
                      ),
                    ),
                    const SizedBox(height: NVSpace.x6),
                    if (user?.metabolicTargets != null)
                      _MetabolicTargetsCard(
                        targets: user!.metabolicTargets!,
                        todayKcal: _totalKcalFromTotals(totals),
                      ),
                    if (user?.metabolicTargets != null)
                      const SizedBox(height: NVSpace.x4),
                    KeyedSubtree(
                      key: HomeScreen.macroKey,
                      child: _MacroBentoRow(
                        totals: totals,
                        targets: user?.metabolicTargets,
                      ),
                    ),
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
                          onPressed: () => _showAllRecommendations(
                            context,
                            nutrition.recommendations,
                          ),
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - NVSpace.x3) / 2;
                          return Wrap(
                            spacing: NVSpace.x3,
                            runSpacing: NVSpace.x3,
                            children: nutrition.logs
                                .take(4)
                                .map((log) => MealImageCard(log: log, width: cardWidth))
                                .toList(),
                          );
                        },
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

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: c.bg.withOpacity(0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: NVSpace.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NVEyebrow(dateLine, color: c.textMuted),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                text: name.isEmpty ? greeting : '$greeting, ',
                children: [
                  if (name.isNotEmpty)
                    TextSpan(
                      text: '$name.',
                      style: const TextStyle(color: NV.accent),
                    ),
                ],
              ),
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
      actions: [
        NVCircleIconButton(
          icon: Icons.qr_code_scanner_rounded,
          onTap: () => context.push('/app/barcode-scan'),
        ),
        const SizedBox(width: 8),
        NVCircleIconButton(
          icon: Icons.auto_awesome_rounded,
          background: NV.accent,
          foreground: Colors.white,
          onTap: () async {
            HapticFeedback.selectionClick();
            final source = await showModalBottomSheet<ImageSource>(
              context: context,
              showDragHandle: true,
              builder: (context) => const _AiPhotoSourceSheet(),
            );
            if (source == null) return;
            try {
              final picked = await ImagePicker().pickImage(
                source: source,
                imageQuality: 88,
                maxWidth: 2200,
              );
              if (picked == null || !context.mounted) return;
              
              final now = DateTime.now();
              final mealType = now.hour < 11 ? 'breakfast' : now.hour < 15 ? 'lunch' : now.hour < 21 ? 'dinner' : 'snack';
              final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

              context.push(
                '/app/ai/meal-photo',
                extra: <String, String>{
                  'imagePath': picked.path,
                  'mealType': mealType,
                  'loggedOn': dateStr,
                },
              );
            } on PlatformException catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.message ?? 'Could not open photo picker.'),
                ),
              );
            }
          },
        ),
        const SizedBox(width: NVSpace.x3),
        UserAvatar(
          displayName: (user?.displayName as String?) ?? 'User',
          avatarUrl: user?.avatarUrl as String?,
          size: 44,
          onTap: () {
            final scope = AppShellScope.of(context);
            if (scope != null) {
              scope.switchTab(4); // Profile tab
            } else {
              context.go('/app?tab=you'); // Fallback
            }
          },
        ),
        const SizedBox(width: NVSpace.x5),
      ],
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

class _AiPhotoSourceSheet extends StatelessWidget {
  const _AiPhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NVSpace.x5, NVSpace.x2, NVSpace.x5, NVSpace.x5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Meal photo',
              style: TextStyle(
                color: c.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: NVSpace.x4),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
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
    this.insightMessage,
    this.hasOverLimit = false,
  });

  final double pct;
  final int streak;
  final int mealCount;
  final int trackedCount;
  final int metCount;
  final int scoredCount;
  final bool isLoading;
  final String? insightMessage;
  final bool hasOverLimit;

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
          Row(
            children: [
              NVEyebrow('Today', color: c.textMuted),
              const Spacer(),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showScoringExplainer(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          // ── Contextual insight banner ──
          if (insightMessage != null && !isLoading) ...[
            const SizedBox(height: NVSpace.x4),
            Builder(builder: (context) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              final warnBg = dark
                  ? const Color(0xFF78350F).withValues(alpha: 0.25)
                  : const Color(0xFFFEF3C7);
              final warnBorder = dark
                  ? const Color(0xFFB45309).withValues(alpha: 0.4)
                  : const Color(0xFFFCD34D);
              final warnIcon = dark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFFB45309);
              final warnText = dark
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFF92400E);
              final tipBg = dark
                  ? NV.accent.withValues(alpha: 0.12)
                  : NV.accentSoft;
              final tipBorder = dark
                  ? NV.accent.withValues(alpha: 0.25)
                  : NV.accent.withValues(alpha: 0.18);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: hasOverLimit ? warnBg : tipBg,
                  borderRadius: BorderRadius.circular(NVRadius.cardSm),
                  border: Border.all(
                    color: hasOverLimit ? warnBorder : tipBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      hasOverLimit
                          ? Icons.warning_amber_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: hasOverLimit ? warnIcon : NV.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insightMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: hasOverLimit ? warnText : c.text,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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

void _showScoringExplainer(BuildContext context) {
  final c = NVColors.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NVSpace.x5, 0, NVSpace.x5, NVSpace.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How your score works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your daily score is the average coverage across all tracked nutrients.',
              style: TextStyle(
                fontSize: 13,
                color: c.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: NVSpace.x5),
            _ExplainerRule(
              icon: Icons.trending_up_rounded,
              iconColor: NV.accent,
              title: 'Score goes up',
              body: 'When you log foods rich in nutrients you\'re low on, '
                  'those nutrients move closer to 100% and your score rises.',
            ),
            const SizedBox(height: NVSpace.x3),
            _ExplainerRule(
              icon: Icons.pause_rounded,
              iconColor: const Color(0xFF6B7280),
              title: 'Score stays the same',
              body: 'Nutrients are capped at 100%. If most are already at target, '
                  'extra intake of the same nutrients won\'t increase your score.',
            ),
            const SizedBox(height: NVSpace.x3),
            _ExplainerRule(
              icon: Icons.trending_down_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Score goes down',
              body: 'Sodium is a "limit" nutrient — going over 100% of your daily '
                  'limit actively lowers your score. Salty or processed foods '
                  'can push it past the limit.',
            ),
            const SizedBox(height: NVSpace.x5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NV.accentSoft,
                borderRadius: BorderRadius.circular(NVRadius.cardSm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: NV.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap any nutrient tile to see which foods can help improve that specific nutrient.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: c.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExplainerRule extends StatelessWidget {
  const _ExplainerRule({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
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
  const _MacroBentoRow({required this.totals, this.targets});
  final DayNutrientTotals? totals;
  final MetabolicTargets? targets;

  @override
  Widget build(BuildContext context) {
    final macros = const ['Protein', 'Carbs', 'Fat'];
    final macroPercents = <String, double>{};
    final macroAmounts = <String, double>{};
    for (final m in macros) {
      final t = totals?.nutrients.firstWhere(
        (n) => n.code == m,
        orElse: () =>
            const NutrientTotal(code: '', name: '', unit: '', amount: 0),
      );
      macroPercents[m] = t?.driPercent ?? 0;
      macroAmounts[m] = t?.amount ?? 0;
    }

    // Target grams from metabolic targets (if available).
    final targetGrams = <String, double?>{
      'Protein': targets?.proteinG,
      'Carbs': targets?.carbsG,
      'Fat': targets?.fatG,
    };

    return Row(
      children: [
        for (var i = 0; i < macros.length; i++) ...[
          Expanded(
            child: _MacroTile(
              code: macros[i],
              pct: macroPercents[macros[i]] ?? 0,
              amount: macroAmounts[macros[i]] ?? 0,
              targetG: targetGrams[macros[i]],
            ),
          ),
          if (i < macros.length - 1) const SizedBox(width: NVSpace.x3),
        ],
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.code,
    required this.pct,
    this.amount = 0,
    this.targetG,
  });
  final String code;
  final double pct;
  final double amount;
  final double? targetG;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final hue = vitaminColors[code]!;
    final shortLabel = code;

    // If we have a metabolic target, show progress towards that.
    final hasTarget = targetG != null && targetG! > 0;
    final goalPct = hasTarget ? (amount / targetG! * 100).clamp(0, 200) : pct;
    final pctLabel = '${goalPct.round()}%';
    final amountLabel = hasTarget
        ? '${amount.round()}g / ${targetG!.round()}g'
        : '${amount.round()}g';

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
          const SizedBox(height: 2),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: NVSpace.x2),
          BarProgress(
            pct: (goalPct / 100).clamp(0.0, 1.0),
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

void _showAllRecommendations(
  BuildContext context,
  List<Recommendation> recommendations,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _AllRecommendationsSheet(recommendations: recommendations),
  );
}

class _AllRecommendationsSheet extends StatelessWidget {
  const _AllRecommendationsSheet({required this.recommendations});
  final List<Recommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NVSpace.x5, 0, NVSpace.x5, NVSpace.x4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended for you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.text,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on your nutrient gaps today',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  NVSpace.x5, 0, NVSpace.x5, NVSpace.x6,
                ),
                itemCount: recommendations.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: NVSpace.x3),
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  return _RecommendationTile(rec: rec);
                },
              ),
            ),
          ],
        ),
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

// ═══════════════════════════════════════════════════════════════
//  METABOLIC TARGETS CARD
// ═══════════════════════════════════════════════════════════════

/// Extracts today's total consumed kcal from the nutrient totals.
double _totalKcalFromTotals(DayNutrientTotals? totals) {
  if (totals == null) return 0;
  final energy = totals.nutrients.where((n) =>
      n.code == 'Energy' || n.code == 'Calories' || n.code == 'kcal');
  if (energy.isNotEmpty) return energy.first.amount;
  // Fallback: sum macros × kcal/g.
  double sum = 0;
  for (final n in totals.nutrients) {
    if (n.code == 'Protein') sum += n.amount * 4;
    if (n.code == 'Carbs') sum += n.amount * 4;
    if (n.code == 'Fat') sum += n.amount * 9;
  }
  return sum;
}

class _MetabolicTargetsCard extends StatelessWidget {
  const _MetabolicTargetsCard({
    required this.targets,
    required this.todayKcal,
  });
  final MetabolicTargets targets;
  final double todayKcal;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final goal = targets.goalKcal;
    final pct = goal > 0 ? (todayKcal / goal).clamp(0.0, 1.5) : 0.0;
    final remaining = (goal - todayKcal).round();
    final isOver = remaining < 0;

    return NVCard(
      padding: const EdgeInsets.all(NVSpace.x5),
      child: Row(
        children: [
          // Circular calorie progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: pct.clamp(0.0, 1.0).toDouble(),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation(
                      isOver ? Colors.redAccent : NV.accent,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: isOver ? Colors.redAccent : NV.accent,
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: nvNumber(14, color: c.text),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: NVSpace.x5),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${todayKcal.round()}',
                      style: nvNumber(24, color: c.text),
                    ),
                    Text(
                      ' / ${goal.round()} kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOver
                      ? '${(-remaining)} kcal over target'
                      : '$remaining kcal remaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOver ? Colors.redAccent : NV.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _GoalStat(
                      label: 'BMR',
                      value: '${targets.bmrKcal.round()}',
                      color: c.textMuted,
                    ),
                    const SizedBox(width: NVSpace.x3),
                    _GoalStat(
                      label: 'TDEE',
                      value: '${targets.tdeeKcal.round()}',
                      color: c.textMuted,
                    ),
                    const SizedBox(width: NVSpace.x3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (targets.isDeficit
                                ? Colors.orangeAccent
                                : targets.isSurplus
                                    ? Colors.greenAccent
                                    : NV.accent)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        targets.goalLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: targets.isDeficit
                              ? Colors.deepOrange
                              : targets.isSurplus
                                  ? Colors.green
                                  : NV.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
