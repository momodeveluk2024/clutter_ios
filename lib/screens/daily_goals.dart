/// Daily kcal + macronutrient goal editor.
///
/// The screen lets the user override the server-computed Mifflin-St Jeor
/// targets with their own daily numbers for calories, protein, carbs, fat and
/// fiber. Submitting PATCHes `/me/goals` which merges into a `goal_overrides`
/// JSONB column on the backend, then re-persists the metabolic_targets so the
/// home screen reflects the new numbers immediately.
///
/// Reached by tapping the kcal/goal card on the home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/notifications/goal_reminder_scheduler.dart';
import '../core/providers/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';

class DailyGoalsScreen extends StatefulWidget {
  const DailyGoalsScreen({super.key});

  @override
  State<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends State<DailyGoalsScreen> {
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final targets = context.read<AuthProvider>().user?.metabolicTargets;
    _kcal.text = _initial(targets?.goalKcal);
    _protein.text = _initial(targets?.proteinG);
    _carbs.text = _initial(targets?.carbsG);
    _fat.text = _initial(targets?.fatG);
    _fiber.text = _initial(targets?.fiberG);
  }

  @override
  void dispose() {
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    super.dispose();
  }

  String _initial(double? value) {
    if (value == null || value <= 0) return '';
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final targets = context.watch<AuthProvider>().user?.metabolicTargets;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NVCircleIconButton(
                    icon: Icons.chevron_left,
                    background: c.surface,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Daily goals',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Set the daily numbers you want to hit. Anything you leave '
                'blank falls back to the value calculated from your profile.',
                style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.4),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _GoalField(
                      label: 'Calories',
                      unit: 'kcal',
                      controller: _kcal,
                      computed: targets?.tdeeKcal,
                    ),
                    _GoalField(
                      label: 'Protein',
                      unit: 'g',
                      controller: _protein,
                    ),
                    _GoalField(
                      label: 'Carbohydrates',
                      unit: 'g',
                      controller: _carbs,
                    ),
                    _GoalField(
                      label: 'Fat',
                      unit: 'g',
                      controller: _fat,
                    ),
                    _GoalField(
                      label: 'Fiber',
                      unit: 'g',
                      controller: _fiber,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              NVPrimaryButton(
                label: _saving ? 'Saving...' : 'Save goals',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.setGoals(
        goalKcal: _parse(_kcal.text),
        proteinG: _parse(_protein.text),
        carbsG: _parse(_carbs.text),
        fatG: _parse(_fat.text),
        fiberG: _parse(_fiber.text),
      );
      // Re-arm the daily 20:00 progress reminder against the new targets.
      await GoalReminderScheduler.scheduleFor(auth.user?.metabolicTargets);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save goals. $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? _parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed);
    if (value == null || value < 0) return null;
    return value;
  }
}

class _GoalField extends StatelessWidget {
  const _GoalField({
    required this.label,
    required this.unit,
    required this.controller,
    this.computed,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final double? computed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final hint = computed != null && computed! > 0
        ? 'Suggested ${computed!.round()}'
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              Text(
                unit,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

