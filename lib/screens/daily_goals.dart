/// Daily kcal + macronutrient goal editor.
///
/// PATCHes `/me/goals` which merges into the `goal_overrides` JSONB column on
/// the backend, then re-persists the user's metabolic_targets so the home
/// screen reflects the new numbers immediately.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/models/user.dart';
import '../core/notifications/goal_reminder_scheduler.dart';
import '../core/providers/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/mascot.dart';

class DailyGoalsScreen extends StatefulWidget {
  const DailyGoalsScreen({super.key});

  @override
  State<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends State<DailyGoalsScreen> {
  late double _kcal;
  late double _protein;
  late double _carbs;
  late double _fat;
  late double _fiber;

  bool _saving = false;
  String? _error;
  String? _activePreset;

  // Allow the full physiological range so users can model extreme cuts,
  // young children, professional athletes, or a calorie target of 0 if they
  // explicitly want to clear it.
  static const _kcalMin = 0.0;
  static const _kcalMax = 10000.0;

  @override
  void initState() {
    super.initState();
    final t = context.read<AuthProvider>().user?.metabolicTargets;
    _kcal = (t?.goalKcal ?? t?.tdeeKcal ?? 2000).clamp(_kcalMin, _kcalMax).toDouble();
    _protein = (t?.proteinG ?? 100).clamp(20, 400).toDouble();
    _carbs = (t?.carbsG ?? 250).clamp(20, 700).toDouble();
    _fat = (t?.fatG ?? 70).clamp(15, 250).toDouble();
    _fiber = (t?.fiberG ?? 28).clamp(5, 80).toDouble();
  }

  // ─────────────────────────────────────────────────────────────
  // Derived values
  // ─────────────────────────────────────────────────────────────

  double get _macroKcal => _protein * 4 + _carbs * 4 + _fat * 9;
  double get _macroFit => (_macroKcal / _kcal).clamp(0.0, 2.0);

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final user = context.watch<AuthProvider>().user;
    final t = user?.metabolicTargets;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  if (t != null) _MetabolismCard(targets: t),
                  const SizedBox(height: 16),
                  _CalorieHero(
                    value: _kcal,
                    targets: t,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _kcal = v;
                        _activePreset = null;
                        // Auto-rebalance macros to the standard 30/40/30
                        // split + USDA fiber so the numbers below the slider
                        // track the new kcal target instead of going stale.
                        _autoBalanceMacros();
                      });
                    },
                  ),
                  if (t != null && t.tdeeKcal > 0) ...[
                    const SizedBox(height: 14),
                    _PresetRow(
                      tdee: t.tdeeKcal,
                      active: _activePreset,
                      onPick: (label, kcal) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _kcal = kcal.clamp(_kcalMin, _kcalMax).toDouble();
                          _activePreset = label;
                          _autoBalanceMacros();
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SectionLabel('MACROS', help: _MacroHelp(macroFit: _macroFit)),
                  const SizedBox(height: 10),
                  _MacroCard(
                    label: 'Protein',
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFF2F7D4A),
                    unit: 'g',
                    value: _protein,
                    min: 20,
                    max: 400,
                    note: _proteinNote(user),
                    kcalPerGram: 4,
                    totalKcal: _kcal,
                    onChanged: (v) => setState(() {
                      _protein = v;
                      _activePreset = null;
                    }),
                  ),
                  _MacroCard(
                    label: 'Carbs',
                    icon: Icons.bakery_dining_rounded,
                    color: const Color(0xFFB07A1A),
                    unit: 'g',
                    value: _carbs,
                    min: 20,
                    max: 700,
                    note:
                        'Your main fuel. ~45–60% of kcal is the typical range — '
                        'lower if you prefer keto-style, higher for endurance.',
                    kcalPerGram: 4,
                    totalKcal: _kcal,
                    onChanged: (v) => setState(() {
                      _carbs = v;
                      _activePreset = null;
                    }),
                  ),
                  _MacroCard(
                    label: 'Fat',
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF6B4A8A),
                    unit: 'g',
                    value: _fat,
                    min: 15,
                    max: 250,
                    note:
                        'Hormone support, vitamin absorption. Keep above '
                        '~0.6 g/kg body weight. Most coaches suggest 25–35% of kcal.',
                    kcalPerGram: 9,
                    totalKcal: _kcal,
                    onChanged: (v) => setState(() {
                      _fat = v;
                      _activePreset = null;
                    }),
                  ),
                  _MacroCard(
                    label: 'Fiber',
                    icon: Icons.eco_rounded,
                    color: const Color(0xFF3A6B88),
                    unit: 'g',
                    value: _fiber,
                    min: 5,
                    max: 80,
                    note:
                        'Gut health + satiety. USDA target is ~14 g per '
                        '1000 kcal — about ${(_kcal * 14 / 1000).round()} g at your goal.',
                    kcalPerGram: 0,
                    totalKcal: _kcal,
                    onChanged: (v) => setState(() => _fiber = v),
                  ),
                  const SizedBox(height: 14),
                  _MacroFitBar(fit: _macroFit, kcalFromMacros: _macroKcal, goalKcal: _kcal),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _Footer(
              saving: _saving,
              onSave: _save,
              onReset: t != null ? _resetToComputed : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  String _proteinNote(AppUser? user) {
    final wKg = user?.weightKg;
    if (wKg == null || wKg <= 0) {
      return 'Protein floor is ~1.6 g per kg of body weight for active adults.';
    }
    final floor = (wKg * 1.6).round();
    final ceiling = (wKg * 2.2).round();
    return 'For your body weight, $floor–$ceiling g/day is the sweet spot for '
        'muscle and recovery.';
  }

  void _autoBalanceMacros() {
    // Crude split: 30% P (1.8 g/kg-ish), 40% C, 30% F.
    final p = (_kcal * 0.30) / 4;
    final c = (_kcal * 0.40) / 4;
    final f = (_kcal * 0.30) / 9;
    final fb = (_kcal * 14 / 1000).clamp(15, 60);
    _protein = p.clamp(20, 400).toDouble();
    _carbs = c.clamp(20, 700).toDouble();
    _fat = f.clamp(15, 250).toDouble();
    _fiber = fb.toDouble();
  }

  void _resetToComputed() {
    final t = context.read<AuthProvider>().user?.metabolicTargets;
    if (t == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _kcal = (t.tdeeKcal > 0 ? t.tdeeKcal : t.goalKcal)
          .clamp(_kcalMin, _kcalMax)
          .toDouble();
      _protein = t.proteinG.clamp(20, 400).toDouble();
      _carbs = t.carbsG.clamp(20, 700).toDouble();
      _fat = t.fatG.clamp(15, 250).toDouble();
      _fiber = t.fiberG > 0
          ? t.fiberG.clamp(5, 80).toDouble()
          : (t.tdeeKcal * 14 / 1000).clamp(5, 80).toDouble();
      _activePreset = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.setGoals(
        goalKcal: _kcal,
        proteinG: _protein,
        carbsG: _carbs,
        fatG: _fat,
        fiberG: _fiber,
      );
      await GoalReminderScheduler.scheduleFor(auth.user?.metabolicTargets);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      // context.pop() is a no-op when the route was pushed via context.go()
      // (no parent in the stack). Try pop first; if that didn't change the
      // top route, fall back to the app home so the user definitely lands
      // somewhere other than this screen.
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/app');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save goals. $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(
        children: [
          NVCircleIconButton(
            icon: Icons.chevron_left,
            background: c.surface,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily goals',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: c.text,
                  ),
                ),
                Text(
                  'Calories, macros, and fiber — fully yours.',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            height: 56,
            child: Mascot(mood: MascotMood.cheering, size: 56, compact: true),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  METABOLISM CARD — BMR, TDEE, adjustment
// ═══════════════════════════════════════════════════════════════

class _MetabolismCard extends StatelessWidget {
  const _MetabolismCard({required this.targets});
  final MetabolicTargets targets;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final adj = targets.goalAdjustment;
    final adjLabel = adj == 0
        ? 'Maintain weight'
        : adj < 0
            ? '${adj.round()} kcal · cutting'
            : '+${adj.round()} kcal · building';
    final adjColor = adj == 0
        ? c.textMuted
        : adj < 0
            ? const Color(0xFFB91C1C)
            : const Color(0xFF166534);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NV.accentSoft.withValues(alpha: 0.38),
            c.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NV.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _MetaCell(
            label: 'BMR',
            value: targets.bmrKcal,
            help: 'Energy just to keep you alive at rest.',
          ),
          Container(width: 1, height: 36, color: c.border),
          _MetaCell(
            label: 'TDEE',
            value: targets.tdeeKcal,
            help: 'Total daily energy including movement.',
          ),
          Container(width: 1, height: 36, color: c.border),
          Expanded(
            child: Column(
              children: [
                Text(
                  adjLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: adjColor,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'today\'s plan',
                  style: TextStyle(
                    fontSize: 10,
                    color: c.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
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

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value, required this.help});
  final String label;
  final double value;
  final String help;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Expanded(
      child: Tooltip(
        message: help,
        child: Column(
          children: [
            Text(
              value > 0 ? value.round().toString() : '—',
              style: nvNumber(20, color: c.text, weight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: c.textMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CALORIE HERO — big number + slider + delta indicator
// ═══════════════════════════════════════════════════════════════

class _CalorieHero extends StatelessWidget {
  const _CalorieHero({
    required this.value,
    required this.targets,
    required this.onChanged,
  });

  final double value;
  final MetabolicTargets? targets;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final tdee = targets?.tdeeKcal ?? 0;
    final delta = tdee > 0 ? value - tdee : 0;
    final deltaLabel = tdee == 0
        ? 'set your goal'
        : delta.abs() < 50
            ? 'maintain'
            : delta < 0
                ? '${delta.round()} kcal vs TDEE'
                : '+${delta.round()} kcal vs TDEE';
    final deltaColor = delta == 0 || tdee == 0
        ? c.textMuted
        : delta < 0
            ? const Color(0xFFB91C1C)
            : const Color(0xFF166534);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: NV.accent.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'DAILY KCAL TARGET',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: value, end: value),
            duration: const Duration(milliseconds: 240),
            builder: (_, v, _) => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: v.round().toString(),
                    style: GoogleFonts.instrumentSerif(
                      fontSize: 68,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2,
                      height: 1,
                      color: NV.accentDeep,
                    ),
                  ),
                  TextSpan(
                    text: ' kcal',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: deltaColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              deltaLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: deltaColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: NV.accent,
              inactiveTrackColor: c.border,
              thumbColor: NV.accent,
              overlayColor: NV.accent.withValues(alpha: 0.16),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value,
              min: _DailyGoalsScreenState._kcalMin,
              max: _DailyGoalsScreenState._kcalMax,
              divisions: 80,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1000', style: TextStyle(fontSize: 10.5, color: c.textMuted, fontWeight: FontWeight.w700)),
              Text('5000', style: TextStyle(fontSize: 10.5, color: c.textMuted, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRESETS — Lose / Maintain / Slow-bulk / Bulk
// ═══════════════════════════════════════════════════════════════

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.tdee,
    required this.active,
    required this.onPick,
  });
  final double tdee;
  final String? active;
  final void Function(String label, double kcal) onPick;

  @override
  Widget build(BuildContext context) {
    final presets = <_Preset>[
      _Preset('Lose', tdee - 500, '−500'),
      _Preset('Mild cut', tdee - 250, '−250'),
      _Preset('Maintain', tdee, '0'),
      _Preset('Lean bulk', tdee + 250, '+250'),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = presets[i];
          final isActive = active == p.label;
          return _PresetChip(
            preset: p,
            active: isActive,
            onTap: () => onPick(p.label, p.kcal),
          );
        },
      ),
    );
  }
}

class _Preset {
  const _Preset(this.label, this.kcal, this.delta);
  final String label;
  final double kcal;
  final String delta;
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.active,
    required this.onTap,
  });
  final _Preset preset;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? NV.accent : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? NV.accent : c.border,
            width: 1.4,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: NV.accent.withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              preset.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : c.text,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              preset.delta,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white.withValues(alpha: 0.85) : c.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MACRO CARD — slider + live kcal contribution + helping note
// ═══════════════════════════════════════════════════════════════

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.note,
    required this.kcalPerGram,
    required this.totalKcal,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String unit;
  final double value;
  final double min;
  final double max;
  final String note;
  final double kcalPerGram;
  final double totalKcal;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final kcalContribution = value * kcalPerGram;
    final pct = totalKcal > 0 && kcalPerGram > 0
        ? (kcalContribution / totalKcal * 100).round()
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value.round().toString(),
                        style: nvNumber(22, color: c.text, weight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: unit,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.14),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.18),
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
              ),
            ),
            Row(
              children: [
                if (kcalPerGram > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${kcalContribution.round()} kcal${pct == null ? '' : '  ·  $pct%'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(Icons.info_outline, size: 13, color: c.textMuted),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note,
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MACRO FIT — does P*4 + C*4 + F*9 match the kcal goal?
// ═══════════════════════════════════════════════════════════════

class _MacroFitBar extends StatelessWidget {
  const _MacroFitBar({
    required this.fit,
    required this.kcalFromMacros,
    required this.goalKcal,
  });
  final double fit;
  final double kcalFromMacros;
  final double goalKcal;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final delta = kcalFromMacros - goalKcal;
    final ok = delta.abs() < 80;
    final tooLow = delta < -80;
    final color = ok
        ? const Color(0xFF166534)
        : tooLow
            ? const Color(0xFFB07A1A)
            : const Color(0xFFB91C1C);
    final label = ok
        ? 'Macros match your kcal goal'
        : tooLow
            ? 'Macros are ${delta.abs().round()} kcal below your goal'
            : 'Macros are ${delta.round()} kcal over your goal';
    final hint = ok
        ? 'You\'re balanced. Save and we\'ll lock these in.'
        : tooLow
            ? 'Bump carbs or fat to fill the gap, or lower kcal.'
            : 'Trim carbs or fat — or raise kcal if you\'re bulking.';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.tune_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _FitDialPainter(
                progress: math.min(1.0, fit),
                color: color,
                track: c.border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FitDialPainter extends CustomPainter {
  _FitDialPainter({
    required this.progress,
    required this.color,
    required this.track,
  });
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 5.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final t = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, t);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _FitDialPainter old) =>
      old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.help});
  final String text;
  final Widget? help;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: c.textMuted,
            letterSpacing: 1.6,
          ),
        ),
        const Spacer(),
        ?help,
      ],
    );
  }
}

class _MacroHelp extends StatelessWidget {
  const _MacroHelp({required this.macroFit});
  final double macroFit;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 12, color: NV.accent),
          const SizedBox(width: 4),
          Text(
            '4·4·9 kcal/g',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: c.text,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FOOTER — Save + Reset
// ═══════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer({
    required this.saving,
    required this.onSave,
    required this.onReset,
  });
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.3
                  : 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onReset != null) ...[
            TextButton.icon(
              onPressed: saving ? null : onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Auto-calc'),
              style: TextButton.styleFrom(
                foregroundColor: c.textMuted,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: NVPrimaryButton(
              label: saving ? 'Saving…' : 'Save goals',
              trailingIcon: Icons.check_rounded,
              accent: true,
              loading: saving,
              onPressed: saving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}
