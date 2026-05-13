import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/ai.dart';
import '../core/providers/ai_provider.dart';
import '../core/providers/food_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/log_success_toast.dart';

class AiMealPhotoScreen extends StatefulWidget {
  const AiMealPhotoScreen({
    super.key,
    required this.imagePath,
    required this.mealType,
    required this.loggedOn,
  });

  final String imagePath;
  final String mealType;
  final String loggedOn;

  @override
  State<AiMealPhotoScreen> createState() => _AiMealPhotoScreenState();
}

class _AiMealPhotoScreenState extends State<AiMealPhotoScreen> {
  final _questionController = TextEditingController();
  final _mealNameController = TextEditingController();

  // Track whether the user has explicitly named the meal so we don't
  // keep overwriting their typed name with the first item's name when
  // they edit items.
  bool _mealNameTouched = false;

  @override
  void initState() {
    super.initState();
    // ─────────────────────────────────────────────────────────────
    //  FIX: clear any leftover estimate / chat state from the
    //  previous meal photo before this screen renders. Without this
    //  the next image you open would re-display the prior analysis
    //  until the new request comes back.
    // ─────────────────────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AiProvider>().reset();
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _mealNameController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    // Make absolutely sure we throw away the previous estimate before
    // we send a fresh request to the server.
    final ai = context.read<AiProvider>();
    ai.reset();
    _mealNameTouched = false;
    _mealNameController.clear();
    await ai.analyzeMealPhoto(
      imagePath: widget.imagePath,
      mealType: widget.mealType,
      loggedOn: widget.loggedOn,
      question: _questionController.text,
    );
    if (!mounted) return;
    // Seed the meal-name field with the first item the AI recognised so
    // there's a sensible default for the user to edit.
    final estimate = ai.currentEstimate;
    if (estimate != null && estimate.items.isNotEmpty && !_mealNameTouched) {
      _mealNameController.text = estimate.items.first.name;
    }
  }

  void _onAddItem() {
    final ai = context.read<AiProvider>();
    final estimate = ai.currentEstimate;
    if (estimate == null) return;
    final localId =
        'local-${DateTime.now().microsecondsSinceEpoch}';
    ai.addLocalItem(
      AiEstimateItem(
        id: localId,
        name: 'New item',
        quantityG: 100,
        caloriesKcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        confidence: 0,
        source: 'user_edit',
      ),
    );
  }

  Future<void> _save(AiMealEstimate estimate) async {
    if (estimate.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item before saving.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final ai = context.read<AiProvider>();
    final foods = context.read<FoodProvider>();
    final nutrition = context.read<NutritionProvider>();

    // ── 1. Persist the user's edits on the server-side estimate. ──
    try {
      await ai.updateEstimateItems(estimate.items);
    } catch (_) {
      // Non-fatal — we'll still try to save locally below.
    }

    // ── 2. Compute consolidated per-100g nutrition for the whole meal.
    final totalGrams = estimate.items.fold<double>(
      0,
      (sum, item) => sum + item.quantityG,
    );
    final totalCalories = estimate.items.fold<double>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );
    final totalProtein = estimate.items.fold<double>(
      0,
      (sum, item) => sum + item.proteinG,
    );
    final totalCarbs = estimate.items.fold<double>(
      0,
      (sum, item) => sum + item.carbsG,
    );
    final totalFat = estimate.items.fold<double>(
      0,
      (sum, item) => sum + item.fatG,
    );

    if (totalGrams <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('At least one item must have grams > 0.'),
        ),
      );
      return;
    }

    final scale = 100 / totalGrams;
    final nutrients = <({String code, double amountPer100G})>[
      if (totalCalories > 0)
        (code: 'Calories', amountPer100G: totalCalories * scale),
      if (totalProtein > 0)
        (code: 'Protein', amountPer100G: totalProtein * scale),
      if (totalCarbs > 0)
        (code: 'Carbs', amountPer100G: totalCarbs * scale),
      if (totalFat > 0)
        (code: 'Fat', amountPer100G: totalFat * scale),
    ];

    final mealName = _mealNameController.text.trim().isNotEmpty
        ? _mealNameController.text.trim()
        : (estimate.items.length == 1
              ? estimate.items.first.name
              : 'AI meal · ${estimate.items.length} items');

    try {
      // ── 3. Create a re-usable "My Meal" entry in the user's library
      //       (same call manual add uses, so it ends up in Saved → My Meals).
      final saved = await foods.createUserMeal(
        name: mealName,
        category: widget.mealType,
        servingSizeG: totalGrams,
        nutrients: nutrients,
      );

      // ── 4. Log the meal for the requested day so it counts toward
      //       the daily macros / streak / tracker, exactly like a
      //       manual log.
      final date =
          DateTime.tryParse(widget.loggedOn) ?? DateTime.now();
      await nutrition.createLog(
        foodId: saved.id,
        servingG: totalGrams,
        mealType: widget.mealType,
        date: date,
        notes: 'Saved from AI meal photo estimate.',
      );

      // ── 5. Best effort: also flip the AI estimate to "accepted" on the
      //       server so analytics / admin review track it as resolved.
      //       This call is allowed to fail without affecting the user.
      try {
        await ai.acceptCurrentEstimate();
      } catch (_) {}

      // ── 6. Make sure the dashboard, week chart and saved tabs all
      //       reflect the new entry on the way out.
      await Future.wait([
        nutrition.refreshDashboard(date: date),
        nutrition.loadWeek(endDate: date),
        foods.loadUserMeals(),
      ]);

      if (!mounted) return;
      final itemCount = estimate.items.length;
      context.go('/app/tracker');
      LogSuccessToast.show(
        context,
        title: itemCount <= 1
            ? 'Meal logged · $mealName'
            : 'Meal logged · $itemCount items',
        subtitle: 'Saved to ${_humanizeMeal(widget.mealType)} & My Meals',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save meal: $e')),
      );
    }
  }

  String _humanizeMeal(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final ai = context.watch<AiProvider>();
    final estimate = ai.currentEstimate;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('AI meal estimate'),
        actions: [
          if (estimate != null)
            IconButton(
              tooltip: 'Ask assistant',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => context.push('/app/ai/chat'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            NVSpace.x5,
            NVSpace.x3,
            NVSpace.x5,
            NVSpace.x10,
          ),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(NVRadius.card),
              child: Image.file(
                File(widget.imagePath),
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: NVSpace.x4),
            if (estimate == null) ...[
              TextField(
                controller: _questionController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Example: estimate protein and rice portion',
                ),
              ),
              const SizedBox(height: NVSpace.x4),
              FilledButton.icon(
                onPressed: ai.isAnalyzing ? null : _analyze,
                icon: ai.isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(ai.isAnalyzing ? 'Analyzing' : 'Analyze meal'),
              ),
              const SizedBox(height: NVSpace.x3),
              Text(
                'The result is an estimate. Review portions before saving.',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
            ] else ...[
              _EstimateSummary(estimate: estimate),
              const SizedBox(height: NVSpace.x4),
              // Meal name — saved to My Meals under this title.
              NVCard(
                padding: const EdgeInsets.all(NVSpace.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NVEyebrow('Meal name', color: c.textMuted),
                    const SizedBox(height: NVSpace.x2),
                    TextField(
                      controller: _mealNameController,
                      onChanged: (_) => _mealNameTouched = true,
                      decoration: const InputDecoration(
                        hintText: 'How should this meal show in My Meals?',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NVSpace.x4),
              ...estimate.items.map(
                (item) => _ItemEditor(
                  // Re-build the row when the underlying values change so
                  // the controllers re-seed (important after the user
                  // changes grams on one item and we recalc the rest).
                  key: ValueKey(
                    '${item.id}-${item.quantityG.toStringAsFixed(1)}-'
                    '${item.caloriesKcal.toStringAsFixed(1)}-'
                    '${item.proteinG.toStringAsFixed(1)}-'
                    '${item.carbsG.toStringAsFixed(1)}-'
                    '${item.fatG.toStringAsFixed(1)}',
                  ),
                  item: item,
                  onChanged: context.read<AiProvider>().editLocalItem,
                  onRemove: () =>
                      context.read<AiProvider>().removeLocalItem(item.id),
                ),
              ),
              const SizedBox(height: NVSpace.x2),
              OutlinedButton.icon(
                onPressed: _onAddItem,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add item'),
              ),
              if (estimate.questions.isNotEmpty) ...[
                const SizedBox(height: NVSpace.x4),
                _InfoBlock(title: 'Questions', values: estimate.questions),
              ],
              if (estimate.warnings.isNotEmpty) ...[
                const SizedBox(height: NVSpace.x3),
                _InfoBlock(title: 'Warnings', values: estimate.warnings),
              ],
              const SizedBox(height: NVSpace.x5),
              FilledButton.icon(
                onPressed: ai.isSaving ? null : () => _save(estimate),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  ai.isSaving ? 'Saving' : 'Save to tracker & My Meals',
                ),
              ),
              const SizedBox(height: NVSpace.x2),
              OutlinedButton.icon(
                onPressed: () => context.push('/app/ai/chat'),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Ask about this meal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateSummary extends StatelessWidget {
  const _EstimateSummary({required this.estimate});

  final AiMealEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final calories = estimate.items.fold<double>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );
    final protein = estimate.items.fold<double>(
      0,
      (sum, item) => sum + item.proteinG,
    );
    return NVCard(
      padding: const EdgeInsets.all(NVSpace.x4),
      child: Row(
        children: [
          RingProgress(
            pct: estimate.confidence,
            size: 68,
            stroke: 7,
            label: '${(estimate.confidence * 100).round()}%',
            sub: 'confidence',
          ),
          const SizedBox(width: NVSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NVEyebrow('Estimate', color: c.textMuted),
                const SizedBox(height: 6),
                Text(
                  '${estimate.items.length} items',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${calories.round()} kcal, ${protein.toStringAsFixed(1)}g protein',
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final AiEstimateItem item;
  final ValueChanged<AiEstimateItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.item.name);
  late final TextEditingController _grams = TextEditingController(
    text: _fmt(widget.item.quantityG),
  );
  late final TextEditingController _kcal = TextEditingController(
    text: _fmt(widget.item.caloriesKcal),
  );
  late final TextEditingController _protein = TextEditingController(
    text: _fmt(widget.item.proteinG),
  );
  late final TextEditingController _carbs = TextEditingController(
    text: _fmt(widget.item.carbsG),
  );
  late final TextEditingController _fat = TextEditingController(
    text: _fmt(widget.item.fatG),
  );

  String _fmt(double value) {
    if (value == 0) return '0';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _name.dispose();
    _grams.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  /// Re-scale the macros + calories when the user changes the grams. This
  /// matches the previous behaviour (so AI's per-gram density is kept) but
  /// only when the macro fields haven't been edited by the user manually.
  void _applyGrams(String value) {
    final grams = double.tryParse(value);
    if (grams == null || grams <= 0) return;
    final current = widget.item.quantityG;
    if (current <= 0) {
      widget.onChanged(widget.item.copyWith(quantityG: grams));
      return;
    }
    final factor = grams / current;
    widget.onChanged(
      widget.item.copyWith(
        quantityG: grams,
        caloriesKcal: widget.item.caloriesKcal * factor,
        proteinG: widget.item.proteinG * factor,
        carbsG: widget.item.carbsG * factor,
        fatG: widget.item.fatG * factor,
      ),
    );
  }

  void _applyName(String value) {
    widget.onChanged(widget.item.copyWith(name: value.trim().isEmpty
        ? widget.item.name
        : value.trim()));
  }

  void _applyMacro({
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    widget.onChanged(
      widget.item.copyWith(
        caloriesKcal: kcal,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        source: 'user_edit',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NVSpace.x3),
      child: NVCard(
        padding: const EdgeInsets.all(NVSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    onSubmitted: _applyName,
                    onEditingComplete: () {
                      _applyName(_name.text);
                      FocusScope.of(context).unfocus();
                    },
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Item name',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: NVSpace.x2),
            TextField(
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSubmitted: _applyGrams,
              onEditingComplete: () {
                _applyGrams(_grams.text);
                FocusScope.of(context).unfocus();
              },
              decoration: const InputDecoration(
                labelText: 'Serving grams',
                helperText: 'Changing grams rescales the macros below.',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: NVSpace.x3),
            Row(
              children: [
                Expanded(
                  child: _MacroField(
                    controller: _kcal,
                    label: 'Calories (kcal)',
                    onChanged: (v) => _applyMacro(kcal: v),
                  ),
                ),
                const SizedBox(width: NVSpace.x2),
                Expanded(
                  child: _MacroField(
                    controller: _protein,
                    label: 'Protein (g)',
                    onChanged: (v) => _applyMacro(protein: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NVSpace.x2),
            Row(
              children: [
                Expanded(
                  child: _MacroField(
                    controller: _carbs,
                    label: 'Carbs (g)',
                    onChanged: (v) => _applyMacro(carbs: v),
                  ),
                ),
                const SizedBox(width: NVSpace.x2),
                Expanded(
                  child: _MacroField(
                    controller: _fat,
                    label: 'Fat (g)',
                    onChanged: (v) => _applyMacro(fat: v),
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

class _MacroField extends StatelessWidget {
  const _MacroField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<double> onChanged;

  void _emit(String raw) {
    final value = double.tryParse(raw);
    if (value == null || value < 0) return;
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSubmitted: _emit,
      onEditingComplete: () {
        _emit(controller.text);
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      padding: const EdgeInsets.all(NVSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NVEyebrow(title),
          const SizedBox(height: NVSpace.x2),
          ...values.map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(value, style: TextStyle(color: c.textMuted)),
            ),
          ),
        ],
      ),
    );
  }
}
