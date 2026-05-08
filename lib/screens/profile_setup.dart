import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _answers = _ProfileAnswers();
  int _index = 0;
  bool _saving = false;

  late final List<_Step> _steps = _buildSteps();

  List<_Step> _buildSteps() {
    return [
      _Step(
        id: 'sex',
        eyebrow: 'About you',
        question: 'How do you ',
        questionAccent: 'identify?',
        helper:
            'This helps us tune iron, calcium and vitamin targets to your body.',
        builder: (context) => _ChoiceGrid(
          options: const [
            _ChoiceOption('female', 'Female', Icons.female),
            _ChoiceOption('male', 'Male', Icons.male),
            _ChoiceOption('other', 'Other', Icons.transgender),
          ],
          value: _answers.sex,
          onChanged: (value) => setState(() {
            _answers.sex = value;
            if (value != 'female') _answers.pregnancy = null;
          }),
        ),
        canContinue: () => _answers.sex != null,
      ),
      _Step(
        id: 'dob',
        eyebrow: 'About you',
        question: 'When were you ',
        questionAccent: 'born?',
        helper:
            'Age changes the daily reference values for most vitamins and minerals.',
        builder: (context) => _DateOfBirthPicker(
          value: _answers.dob,
          onChanged: (value) => setState(() => _answers.dob = value),
        ),
        canContinue: () => _answers.dob != null,
      ),

      _Step(
        id: 'weight',
        eyebrow: 'Body',
        question: 'And your ',
        questionAccent: 'weight?',
        helper: 'You can update this any time from your profile.',
        builder: (context) => _WeightPicker(
          value: _answers.weightKg,
          onChanged: (value) => setState(() => _answers.weightKg = value),
        ),
        canContinue: () => _answers.weightKg != null,
      ),
      _Step(
        id: 'activity',
        eyebrow: 'Movement',
        question: 'How ',
        questionAccent: 'active are you?',
        helper:
            'Energy targets shift quite a bit between sedentary and very active days.',
        builder: (context) => _ChoiceList(
          options: const [
            _ChoiceOption(
              'sedentary',
              'Sedentary',
              Icons.chair_outlined,
              subtitle: 'Mostly sitting, little exercise.',
            ),
            _ChoiceOption(
              'light',
              'Lightly active',
              Icons.directions_walk,
              subtitle: 'Short walks, light chores.',
            ),
            _ChoiceOption(
              'moderate',
              'Moderate',
              Icons.directions_bike,
              subtitle: 'Workout 3 to 5 times a week.',
            ),
            _ChoiceOption(
              'active',
              'Active',
              Icons.fitness_center,
              subtitle: 'Daily training or active job.',
            ),
            _ChoiceOption(
              'very_active',
              'Very active',
              Icons.bolt_outlined,
              subtitle: 'Athlete or hard physical labor.',
            ),
          ],
          value: _answers.activity,
          onChanged: (value) => setState(() => _answers.activity = value),
        ),
        canContinue: () => _answers.activity != null,
      ),
      _Step(
        id: 'pregnancy',
        eyebrow: 'Health',
        question: 'Anything we should ',
        questionAccent: 'know?',
        helper:
            'Folate, iron and iodine targets shift during pregnancy and postpartum.',
        builder: (context) => _ChoiceList(
          options: const [
            _ChoiceOption(
              'none',
              'None of these',
              Icons.check_circle_outline,
              subtitle: 'Standard adult targets.',
            ),
            _ChoiceOption(
              'trying',
              'Trying to conceive',
              Icons.favorite_border,
              subtitle: 'Higher folate emphasis.',
            ),
            _ChoiceOption(
              'pregnant',
              'Pregnant',
              Icons.pregnant_woman,
              subtitle: 'Adjusted iron, choline, iodine.',
            ),
            _ChoiceOption(
              'postpartum',
              'Breastfeeding',
              Icons.child_friendly_outlined,
              subtitle: 'Higher daily energy and B12.',
            ),
          ],
          value: _answers.pregnancy,
          onChanged: (value) => setState(() => _answers.pregnancy = value),
        ),
        canContinue: () => _answers.pregnancy != null,
        isVisible: () => _answers.sex == 'female',
      ),
      _Step(
        id: 'goals',
        eyebrow: 'Focus',
        question: 'What do you want to ',
        questionAccent: 'work on?',
        helper:
            'Pick a few. We will lift the relevant nutrients to the top of your home screen.',
        builder: (context) => _MultiChoiceChips(
          options: const [
            _MultiOption('Energy', '⚡'),
            _MultiOption('Immunity', '🛡️'),
            _MultiOption('Bone health', '🦴'),
            _MultiOption('Heart health', '❤️'),
            _MultiOption('Focus', '🧠'),
            _MultiOption('Fitness', '💪'),
            _MultiOption('Iron support', '🩸'),
            _MultiOption('Better digestion', '🌿'),
            _MultiOption('Skin & hair', '✨'),
            _MultiOption('Sleep', '🌙'),
          ],
          values: _answers.goals,
          onChanged: (next) => setState(() => _answers.goals = next),
        ),
        canContinue: () => _answers.goals.isNotEmpty,
      ),
      _Step(
        id: 'diet',
        eyebrow: 'Plate',
        question: 'How do you ',
        questionAccent: 'eat?',
        helper: 'We will surface foods that fit and quietly hide the rest.',
        builder: (context) => _ChoiceList(
          options: const [
            _ChoiceOption(
              'Omnivore',
              'Omnivore',
              Icons.restaurant_outlined,
              subtitle: 'Anything goes.',
            ),
            _ChoiceOption(
              'Pescatarian',
              'Pescatarian',
              Icons.set_meal_outlined,
              subtitle: 'Plants + fish & seafood.',
            ),
            _ChoiceOption(
              'Vegetarian',
              'Vegetarian',
              Icons.eco_outlined,
              subtitle: 'No meat or fish.',
            ),
            _ChoiceOption(
              'Vegan',
              'Vegan',
              Icons.spa_outlined,
              subtitle: 'Plant-based only.',
            ),
            _ChoiceOption(
              'Mediterranean',
              'Mediterranean',
              Icons.local_florist_outlined,
              subtitle: 'Olive oil, fish, plenty of plants.',
            ),
            _ChoiceOption(
              'High-protein',
              'High protein',
              Icons.egg_outlined,
              subtitle: 'Protein-forward meals.',
            ),
          ],
          value: _answers.diet,
          onChanged: (value) => setState(() => _answers.diet = value),
        ),
        canContinue: () => _answers.diet != null,
      ),
      _Step(
        id: 'allergens',
        eyebrow: 'Plate',
        question: 'Any ',
        questionAccent: 'allergens?',
        helper:
            'We will warn you on foods that include them. You can skip this.',
        builder: (context) => _MultiChoiceChips(
          options: const [
            _MultiOption('Peanuts', '🥜'),
            _MultiOption('Tree nuts', '🌰'),
            _MultiOption('Dairy', '🥛'),
            _MultiOption('Eggs', '🥚'),
            _MultiOption('Soy', '🌱'),
            _MultiOption('Wheat / gluten', '🌾'),
            _MultiOption('Shellfish', '🦐'),
            _MultiOption('Fish', '🐟'),
            _MultiOption('Sesame', '🫘'),
          ],
          values: _answers.allergens,
          onChanged: (next) => setState(() => _answers.allergens = next),
        ),
        canContinue: () => true,
        skippable: true,
      ),
    ];
  }

  List<_Step> get _visibleSteps =>
      _steps.where((step) => step.isVisible()).toList();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final visible = _visibleSteps;
    final clampedIndex = _index.clamp(0, visible.length - 1);
    final step = visible[clampedIndex];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              total: visible.length,
              current: clampedIndex,
              eyebrow: step.eyebrow,
              onBack: clampedIndex == 0 ? null : _back,
              onSkip: step.skippable ? _next : null,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(step.id),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                              height: 1.1,
                              color: c.text,
                            ),
                            children: [
                              TextSpan(text: step.question),
                              TextSpan(
                                text: step.questionAccent,
                                style: GoogleFonts.instrumentSerif(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 34,
                                  letterSpacing: -0.7,
                                  height: 1.1,
                                  color: NV.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step.helper,
                          style: TextStyle(
                            fontSize: 14,
                            color: c.textMuted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        step.builder(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _Footer(
              isLast: clampedIndex == visible.length - 1,
              canContinue: step.canContinue() && !_saving,
              isSaving: _saving,
              onContinue: _next,
            ),
          ],
        ),
      ),
    );
  }

  void _back() {
    HapticFeedback.selectionClick();
    setState(() => _index = math.max(0, _index - 1));
  }

  Future<void> _next() async {
    final visible = _visibleSteps;
    if (_index < visible.length - 1) {
      HapticFeedback.selectionClick();
      setState(() => _index++);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      final auth = context.read<AuthProvider>();
      await auth.updateProfile(
        sex: _answers.sex,
        dateOfBirth: _answers.dob == null ? null : _formatDate(_answers.dob!),
        weightKg: _answers.weightKg,
        activityLevel: _answers.activity,
        pregnancyStatus: _answers.pregnancy,
      );
      await auth.updatePreferences(
        dietaryPattern: _answers.diet,
        goals: _answers.goals.toList(),
        allergens: _answers.allergens.toList(),
      );
      await auth.completeOnboarding();
      if (!mounted) return;
      context.go('/app');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime value) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${value.year}-${pad(value.month)}-${pad(value.day)}';
  }
}

class _ProfileAnswers {
  String? sex;
  DateTime? dob;
  double? weightKg;
  String? activity;
  String? pregnancy;
  String? diet;
  Set<String> goals = {};
  Set<String> allergens = {};
}

class _Step {
  _Step({
    required this.id,
    required this.eyebrow,
    required this.question,
    required this.questionAccent,
    required this.helper,
    required this.builder,
    required this.canContinue,
    this.isVisible = _alwaysTrue,
    this.skippable = false,
  });

  final String id;
  final String eyebrow;
  final String question;
  final String questionAccent;
  final String helper;
  final WidgetBuilder builder;
  final bool Function() canContinue;
  final bool Function() isVisible;
  final bool skippable;

  static bool _alwaysTrue() => true;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.current,
    required this.eyebrow,
    required this.onBack,
    required this.onSkip,
  });

  final int total;
  final int current;
  final String eyebrow;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: onBack == null
                    ? const SizedBox.shrink()
                    : NVCircleIconButton(
                        icon: Icons.chevron_left,
                        background: c.surface,
                        onTap: onBack,
                      ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: NV.accent,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: onSkip == null
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: onSkip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(total, (i) {
              final done = i <= current;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    decoration: BoxDecoration(
                      color: done ? NV.accent : c.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Step ${current + 1} of $total',
              style: TextStyle(
                fontSize: 11,
                color: c.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isLast,
    required this.canContinue,
    required this.isSaving,
    required this.onContinue,
  });

  final bool isLast;
  final bool canContinue;
  final bool isSaving;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        18 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.04),
            blurRadius: 22,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: NVPrimaryButton(
        label: isSaving ? 'Saving...' : (isLast ? 'Finish setup' : 'Continue'),
        trailingIcon: isLast ? Icons.check : Icons.arrow_forward,
        accent: true,
        onPressed: canContinue ? onContinue : null,
      ),
    );
  }
}

// ───────────── shared option types ─────────────

class _ChoiceOption {
  const _ChoiceOption(this.value, this.label, this.icon, {this.subtitle});

  final String value;
  final String label;
  final IconData icon;
  final String? subtitle;
}

class _MultiOption {
  const _MultiOption(this.label, this.emoji);

  final String label;
  final String emoji;
}

// ───────────── selection widgets ─────────────

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<_ChoiceOption> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = options.length >= 3 ? 3 : 2;
        final tileHeight = constraints.maxWidth < 340 ? 136.0 : 128.0;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: tileHeight,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final selected = opt.value == value;
            return _SelectableTile(
              selected: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(opt.value);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.18)
                          : NV.accentSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      opt.icon,
                      size: 28,
                      color: selected ? Colors.white : NV.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: selected
                          ? Colors.white
                          : NVColors(
                              Theme.of(context).brightness == Brightness.dark,
                            ).text,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<_ChoiceOption> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) {
        final selected = opt.value == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SelectableTile(
            selected: selected,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(opt.value);
            },
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : NV.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    opt.icon,
                    color: selected ? Colors.white : NV.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? Colors.white
                              : NVColors(
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ).text,
                        ),
                      ),
                      if (opt.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          opt.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.78)
                                : NVColors(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ).textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: selected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MultiChoiceChips extends StatelessWidget {
  const _MultiChoiceChips({
    required this.options,
    required this.values,
    required this.onChanged,
  });

  final List<_MultiOption> options;
  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final selected = values.contains(opt.label);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final next = {...values};
            if (selected) {
              next.remove(opt.label);
            } else {
              next.add(opt.label);
            }
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? NV.accent : c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? NV.accent : c.border,
                width: 1.4,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: NV.accent.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(opt.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : c.text,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? NV.accent : c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? NV.accent : c.border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: selected
                ? NV.accent.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: dark ? 0.32 : 0.05),
            blurRadius: selected ? 22 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ───────────── numeric pickers ─────────────

class _DateOfBirthPicker extends StatelessWidget {
  const _DateOfBirthPicker({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final hasValue = value != null;
    final formatted = hasValue
        ? '${_monthName(value!.month)} ${value!.day}, ${value!.year}'
        : 'Tap to choose';
    final age = hasValue ? _ageFrom(value!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectableTile(
          selected: hasValue,
          onTap: () => _open(context),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasValue
                          ? Colors.white.withValues(alpha: 0.18)
                          : NV.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.cake_outlined,
                      color: hasValue ? Colors.white : NV.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of birth',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            color: hasValue
                                ? Colors.white.withValues(alpha: 0.7)
                                : c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatted,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: hasValue ? Colors.white : c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    color: hasValue
                        ? Colors.white.withValues(alpha: 0.7)
                        : c.textMuted,
                    size: 18,
                  ),
                ],
              ),
              if (age != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$age years',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? DateTime(now.year - 25, now.month, now.day);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    DateTime tempPicked = initial;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 380,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date of birth',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onChanged(tempPicked);
                        Navigator.pop(ctx);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: NV.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: dark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initial,
                    minimumDate: DateTime(now.year - 110),
                    maximumDate: DateTime(now.year - 10, now.month, now.day),
                    onDateTimeChanged: (date) {
                      HapticFeedback.selectionClick();
                      tempPicked = date;
                    },
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.paddingOf(ctx).bottom + 12),
            ],
          ),
        );
      },
    );
  }

  static int _ageFrom(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    final hadBirthday =
        now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) age--;
    return age;
  }

  static String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m - 1];
  }
}

class _HeightPicker extends StatefulWidget {
  const _HeightPicker({required this.value, required this.onChanged});

  final double? value;
  final ValueChanged<double> onChanged;

  @override
  State<_HeightPicker> createState() => _HeightPickerState();
}

class _HeightPickerState extends State<_HeightPicker> {
  late double _value = widget.value ?? 170;

  @override
  Widget build(BuildContext context) {
    final cm = _value.round();
    final ft = (cm / 30.48);
    final ftWhole = ft.floor();
    final inches = ((ft - ftWhole) * 12).round();
    return _SelectableTile(
      selected: true,
      onTap: () {},
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEIGHT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$cm',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 76,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -2,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'cm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    "$ftWhole'$inches\"",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.12),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _value,
              min: 120,
              max: 220,
              divisions: 100,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _value = v);
                widget.onChanged(v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '120 cm',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '220 cm',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightPicker extends StatefulWidget {
  const _WeightPicker({required this.value, required this.onChanged});

  final double? value;
  final ValueChanged<double> onChanged;

  @override
  State<_WeightPicker> createState() => _WeightPickerState();
}

class _WeightPickerState extends State<_WeightPicker> {
  late double _value = widget.value ?? 70;

  @override
  Widget build(BuildContext context) {
    final kg = _value.round();
    final lb = (_value * 2.2046).round();
    return _SelectableTile(
      selected: true,
      onTap: () {},
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEIGHT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$kg',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 76,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -2,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'kg',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$lb lb',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.12),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _value,
              min: 35,
              max: 180,
              divisions: 145,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _value = v);
                widget.onChanged(v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '35 kg',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '180 kg',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgePicker extends StatefulWidget {
  const _AgePicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  State<_AgePicker> createState() => _AgePickerState();
}

class _AgePickerState extends State<_AgePicker> {
  late int _value = widget.value ?? 30;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: true,
      onTap: () {},
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_value',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 76,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -2,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'years',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.12),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _value.toDouble(),
              min: 16,
              max: 100,
              divisions: 84,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                final val = v.round();
                setState(() => _value = val);
                widget.onChanged(val);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '16',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '100',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
