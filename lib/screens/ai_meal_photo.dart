import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/ai.dart';
import '../core/providers/ai_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';

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

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    await context.read<AiProvider>().analyzeMealPhoto(
      imagePath: widget.imagePath,
      mealType: widget.mealType,
      loggedOn: widget.loggedOn,
      question: _questionController.text,
    );
  }

  Future<void> _save(AiMealEstimate estimate) async {
    final ai = context.read<AiProvider>();
    await ai.updateEstimateItems(estimate.items);
    await ai.acceptCurrentEstimate();
    if (!mounted) return;
    final date = DateTime.tryParse(widget.loggedOn) ?? DateTime.now();
    final nutrition = context.read<NutritionProvider>();
    await nutrition.refreshDashboard(date: date);
    await nutrition.loadWeek(endDate: date);
    if (!mounted) return;
    context.go('/app/tracker');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Meal saved to tracker.')));
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
              ...estimate.items.map(
                (item) => _ItemEditor(
                  item: item,
                  onChanged: context.read<AiProvider>().editLocalItem,
                  onRemove: () =>
                      context.read<AiProvider>().removeLocalItem(item.id),
                ),
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
                label: Text(ai.isSaving ? 'Saving' : 'Save to tracker'),
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
  late final TextEditingController _grams = TextEditingController(
    text: widget.item.quantityG.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  void _apply(String value) {
    final grams = double.tryParse(value);
    if (grams == null || grams <= 0) return;
    final factor = grams / widget.item.quantityG;
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
                  child: Text(
                    widget.item.name,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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
            const SizedBox(height: NVSpace.x3),
            TextField(
              controller: _grams,
              keyboardType: TextInputType.number,
              onSubmitted: _apply,
              onChanged: _apply,
              decoration: const InputDecoration(labelText: 'Serving grams'),
            ),
            const SizedBox(height: NVSpace.x3),
            Wrap(
              spacing: NVSpace.x2,
              runSpacing: NVSpace.x2,
              children: [
                _MetricChip(label: '${widget.item.caloriesKcal.round()} kcal'),
                _MetricChip(
                  label: '${widget.item.proteinG.toStringAsFixed(1)}g protein',
                ),
                _MetricChip(
                  label: '${widget.item.carbsG.toStringAsFixed(1)}g carbs',
                ),
                _MetricChip(
                  label: '${widget.item.fatG.toStringAsFixed(1)}g fat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
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
