import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/models/food_log.dart';
import '../core/models/nutrition.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import 'meal_log_detail.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  DateTime _selectedDate = _dateOnly(DateTime.now());
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final nutrition = context.read<NutritionProvider>();
    await nutrition.refreshDashboard(date: _selectedDate);
    await nutrition.loadWeek(endDate: _selectedDate);
  }

  Future<void> _selectDate(DateTime date) async {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = _dateOnly(date));
    await _refresh();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Choose tracking day',
    );
    if (picked != null) await _selectDate(picked);
  }

  Future<void> _startAiMealPhoto() async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _AiPhotoSourceSheet(),
    );
    if (source == null) return;
    await _openAiMealPhoto(source);
  }

  Future<void> _openAiMealPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2200,
      );
      if (picked == null || !mounted) return;
      context.push(
        '/app/ai/meal-photo',
        extra: <String, String>{
          'imagePath': picked.path,
          'mealType': _defaultMealType(DateTime.now()),
          'loggedOn': _dateString(_selectedDate),
        },
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not open photo picker.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final nutrition = context.watch<NutritionProvider>();
    final todayPct = ((nutrition.todayTotals?.averagePercent ?? 0) / 100).clamp(
      0.0,
      1.0,
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
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
                      NVEyebrow('Tracker', color: c.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        _dateTitle(_selectedDate),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: c.text,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                NVCircleIconButton(
                  icon: Icons.auto_awesome_rounded,
                  background: NV.accent,
                  foreground: Colors.white,
                  onTap: _startAiMealPhoto,
                ),
                const SizedBox(width: NVSpace.x2),
                NVCircleIconButton(
                  icon: Icons.calendar_today_rounded,
                  onTap: _pickDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: NVSpace.x4),
          _WeekStrip(selectedDate: _selectedDate, onSelected: _selectDate),
          const SizedBox(height: NVSpace.x5),
          Expanded(
            child: RefreshIndicator(
              color: NV.accent,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NVSpace.x5,
                  0,
                  NVSpace.x5,
                  120,
                ),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  _DaySummary(
                    pct: todayPct,
                    nutrients: nutrition.todayTotals?.nutrients.length ?? 0,
                    streak: nutrition.streak,
                    mealCount: nutrition.logs.length,
                  ),
                  const SizedBox(height: NVSpace.x6),
                  if (nutrition.todayTotals != null) ...[
                    const NVSectionHeader(
                      eyebrow: 'Macros',
                      title: 'Daily targets',
                    ),
                    const SizedBox(height: NVSpace.x4),
                    _MacroBars(totals: nutrition.todayTotals!),
                    const SizedBox(height: NVSpace.x6),
                  ],
                  NVSectionHeader(
                    eyebrow: 'Logged',
                    title: nutrition.logs.isEmpty
                        ? 'No meals'
                        : '${nutrition.logs.length} ${nutrition.logs.length == 1 ? 'meal' : 'meals'}',
                  ),
                  const SizedBox(height: NVSpace.x4),
                  if (nutrition.logs.isEmpty)
                    NVCard(
                      padding: const EdgeInsets.all(NVSpace.x5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.no_meals_outlined,
                                color: c.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: NVSpace.x3),
                              Expanded(
                                child: Text(
                                  'Nothing logged for this day.',
                                  style: TextStyle(
                                    color: c.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: NVSpace.x4),
                          FilledButton.icon(
                            onPressed: _startAiMealPhoto,
                            icon: const Icon(Icons.add_a_photo_rounded),
                            label: const Text('Analyze meal photo'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...nutrition.logs.map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: NVSpace.x2),
                        child: _MealLogCard(log: log, date: _selectedDate),
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

class _AiPhotoSourceSheet extends StatelessWidget {
  const _AiPhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NVSpace.x5,
          NVSpace.x2,
          NVSpace.x5,
          NVSpace.x5,
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
//  DAY SUMMARY — ring + KPIs
// ═══════════════════════════════════════════════════════════════

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.pct,
    required this.nutrients,
    required this.streak,
    required this.mealCount,
  });

  final double pct;
  final int nutrients;
  final int streak;
  final int mealCount;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      elevated: true,
      padding: const EdgeInsets.all(NVSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RingProgress(
                pct: pct,
                size: 96,
                stroke: 9,
                label: '${(pct * 100).round()}%',
                sub: 'covered',
              ),
              const SizedBox(width: NVSpace.x5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NVEyebrow('On track', color: c.textMuted),
                    const SizedBox(height: 4),
                    Text(
                      '$nutrients nutrients',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streak == 0
                          ? 'Start a logging streak'
                          : '$streak-day streak',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NVSpace.x5),
          Container(height: 1, color: c.border),
          const SizedBox(height: NVSpace.x4),
          Row(
            children: [
              Expanded(
                child: _MiniKPI(label: 'Meals', value: '$mealCount'),
              ),
              Container(width: 1, height: 28, color: c.border),
              Expanded(
                child: _MiniKPI(label: 'Streak', value: '$streak'),
              ),
              Container(width: 1, height: 28, color: c.border),
              Expanded(
                child: _MiniKPI(
                  label: 'Coverage',
                  value: '${(pct * 100).round()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniKPI extends StatelessWidget {
  const _MiniKPI({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      children: [
        NVEyebrow(label, color: c.textMuted),
        const SizedBox(height: 6),
        Text(value, style: nvNumber(20, color: c.text)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MACRO BARS
// ═══════════════════════════════════════════════════════════════

class _MacroBars extends StatelessWidget {
  const _MacroBars({required this.totals});
  final DayNutrientTotals totals;

  @override
  Widget build(BuildContext context) {
    final macros = const ['Protein', 'Carbs', 'Fat', 'Fiber'];
    return NVCard(
      padding: const EdgeInsets.symmetric(
        horizontal: NVSpace.x5,
        vertical: NVSpace.x4,
      ),
      child: Column(
        children: [
          for (var i = 0; i < macros.length; i++) ...[
            if (i > 0) const SizedBox(height: NVSpace.x4),
            _MacroLine(code: macros[i], totals: totals),
          ],
        ],
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  const _MacroLine({required this.code, required this.totals});
  final String code;
  final DayNutrientTotals totals;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final hue = vitaminColors[code]!;
    final t = totals.nutrients.firstWhere(
      (n) => n.code == code,
      orElse: () =>
          const NutrientTotal(code: '', name: '', unit: 'g', amount: 0),
    );
    final pct = ((t.driPercent ?? 0) / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: hue.fill,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            Text(
              '${t.amount.toStringAsFixed(t.amount >= 100 ? 0 : 1)} ${t.unit}',
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              child: Text(
                t.driPercent == null ? '—' : '${t.driPercent!.round()}%',
                textAlign: TextAlign.right,
                style: nvNumber(13, color: c.text, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        BarProgress(pct: pct, color: hue.fill, height: 4),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WEEK STRIP — clean day cells with mini coverage bar
// ═══════════════════════════════════════════════════════════════

class _WeekStrip extends StatefulWidget {
  const _WeekStrip({required this.selectedDate, required this.onSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  static final DateTime _firstDate = DateTime(2020);
  static const double _itemExtent = 56;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerSelected(jump: true),
    );
  }

  @override
  void didUpdateWidget(covariant _WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centerSelected({bool jump = false}) {
    if (!_controller.hasClients) return;
    final index = _dayIndex(widget.selectedDate);
    final viewport = _controller.position.viewportDimension;
    final max = _controller.position.maxScrollExtent;
    final target = (index * _itemExtent - viewport / 2 + _itemExtent / 2).clamp(
      0.0,
      max,
    );
    if (jump) {
      _controller.jumpTo(target);
      return;
    }
    _controller.animateTo(
      target,
      duration: NVMotion.base,
      curve: NVMotion.standard,
    );
  }

  int _dayIndex(DateTime date) => _dateOnly(date).difference(_firstDate).inDays;

  @override
  Widget build(BuildContext context) {
    final days = context.watch<NutritionProvider>().weekTotals;
    final totalsByDate = {for (final day in days) day.date: day};
    final today = _dateOnly(DateTime.now());
    final count = today.difference(_firstDate).inDays + 1;

    return SizedBox(
      height: 78,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: NVSpace.x5),
        itemCount: count,
        itemExtent: _itemExtent,
        itemBuilder: (context, i) {
          final date = _firstDate.add(Duration(days: i));
          final key = _dateString(date);
          final pct = ((totalsByDate[key]?.averagePercent ?? 0) / 100).clamp(
            0.0,
            1.0,
          );
          final active = _sameDay(date, widget.selectedDate);
          final isToday = _sameDay(date, today);
          return _DayCell(
            date: date,
            pct: pct,
            active: active,
            isToday: isToday,
            onTap: () => widget.onSelected(date),
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.pct,
    required this.active,
    required this.isToday,
    required this.onTap,
  });
  final DateTime date;
  final double pct;
  final bool active;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final dow = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: NVMotion.base,
          curve: NVMotion.emphasized,
          decoration: BoxDecoration(
            color: active ? NV.surfaceInk : c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? NV.surfaceInk : c.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dow,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: active ? const Color(0xFFD8DAC8) : c.textMuted,
                ),
              ),
              Text(
                '${date.day}',
                style: nvNumber(
                  16,
                  color: active ? const Color(0xFFFAFAFA) : c.text,
                  weight: FontWeight.w700,
                ),
              ),
              Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: active
                      ? Colors.white.withValues(alpha: 0.32)
                      : c.surfaceMuted,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: active ? Colors.white : NV.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
//  MEAL LOG CARD
// ═══════════════════════════════════════════════════════════════

class _MealLogCard extends StatelessWidget {
  const _MealLogCard({required this.log, required this.date});

  final MealLog log;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      key: ValueKey('meal-log-${log.id}'),
      onTap: () => showMealLogDetails(context, log, date: date),
      padding: const EdgeInsets.all(NVSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MealImageMosaic(
            items: log.items,
            fallbackLabel: log.mealType,
            size: 52,
            radius: NVRadius.cardSm,
          ),
          const SizedBox(width: NVSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 2),
                Text(
                  log.items.isEmpty
                      ? 'Tap to review'
                      : log.items.map((i) => i.foodName).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _mealSummary(log.items.length),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
        ],
      ),
    );
  }

  String _titleCase(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
}

String _mealSummary(int count) {
  if (count == 0) return '';
  if (count == 1) return '1 item';
  return '$count items';
}

String _dateTitle(DateTime date) {
  final today = _dateOnly(DateTime.now());
  if (_sameDay(date, today)) return 'Today';
  if (_sameDay(date, today.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return '${_weekdayName(date.weekday)}, ${_monthName(date.month)} ${date.day}';
}

String _weekdayName(int weekday) {
  return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
}

String _monthName(int month) {
  return const [
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
  ][month - 1];
}

String _dateString(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _defaultMealType(DateTime now) {
  if (now.hour < 11) return 'breakfast';
  if (now.hour < 16) return 'lunch';
  if (now.hour < 21) return 'dinner';
  return 'snack';
}
