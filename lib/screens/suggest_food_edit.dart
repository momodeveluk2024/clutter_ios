import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/food.dart';
import '../core/providers/food_provider.dart';
import '../theme.dart';

/// Lets a signed-in user submit a draft correction for an existing food
/// catalog entry — e.g. the barcode reader picked up the wrong digits or
/// the name is slightly off. The submission lands as a pending row in the
/// admin dashboard; the original food is unchanged until an admin
/// approves the edit.
class SuggestFoodEditScreen extends StatefulWidget {
  const SuggestFoodEditScreen({super.key, required this.food});

  final FoodDetail food;

  @override
  State<SuggestFoodEditScreen> createState() => _SuggestFoodEditScreenState();
}

class _SuggestFoodEditScreenState extends State<SuggestFoodEditScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.food.name);
  late final TextEditingController _brand =
      TextEditingController(text: widget.food.brand ?? '');
  late final TextEditingController _serving = TextEditingController(
      text: widget.food.servingSizeG.toStringAsFixed(0));
  late final TextEditingController _barcode = TextEditingController();
  late final TextEditingController _notes = TextEditingController();
  late String _category = widget.food.category;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FoodProvider>();
      if (provider.categories.isEmpty) {
        await provider.fetchCategories();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _serving.dispose();
    _barcode.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _flash(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _name.text.trim();
    if (name.isEmpty) return _flash('Name cannot be empty');
    final serving = double.tryParse(_serving.text.trim());
    if (serving == null || serving <= 0) {
      return _flash('Serving size must be a positive number');
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await context.read<FoodProvider>().submitFoodSuggestion(
            foodId: widget.food.id,
            name: name,
            brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
            category: _category,
            servingSizeG: serving,
            barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            nutrients: const [],
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => const _SubmittedDialog(),
      );
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      _flash('Submission failed: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final categories = context.watch<FoodProvider>().categories;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Suggest a fix',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.text,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NV.accentSoft,
                  borderRadius: BorderRadius.circular(NVRadius.cardLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_moon_rounded,
                        color: NV.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your edit goes to admin for review. The current product info won\'t change for other users until an admin approves it.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: c.text,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _Label('Product name'),
              const SizedBox(height: 6),
              _Field(controller: _name, hint: 'e.g. Digestive Light Biscuits'),
              const SizedBox(height: 14),
              _Label('Brand (optional)'),
              const SizedBox(height: 6),
              _Field(controller: _brand, hint: 'e.g. McVitie\'s'),
              const SizedBox(height: 14),
              _Label('Category'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(NVRadius.field),
                  border: Border.all(color: c.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: categories.any((cat) => cat.slug == _category)
                        ? _category
                        : (categories.isNotEmpty ? categories.first.slug : null),
                    items: [
                      if (categories.isEmpty)
                        DropdownMenuItem(
                          value: _category,
                          child: Text(_category, style: TextStyle(color: c.text)),
                        )
                      else
                        ...categories.map(
                          (cat) => DropdownMenuItem(
                            value: cat.slug,
                            child:
                                Text(cat.name, style: TextStyle(color: c.text)),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Serving size (${_servingUnit(_category)})'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _serving,
                          hint: '14',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Barcode (if scanner was wrong)'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _barcode,
                          hint: 'leave blank to keep',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Label('Notes for the reviewer (optional)'),
              const SizedBox(height: 6),
              _Field(
                controller: _notes,
                hint: 'e.g. nutrients look off, name is in Turkish, etc.',
                maxLines: 3,
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: NV.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NVRadius.field),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send to admin for review',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: c.textMuted,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14.5, color: c.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: c.textMuted.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
          borderSide: const BorderSide(color: NV.accent, width: 1.4),
        ),
      ),
    );
  }
}

/// Returns 'ml' for liquid categories, 'g' for everything else. Mirrors the
/// helper in food_detail.dart — kept duplicated to avoid an import cycle.
String _servingUnit(String category) {
  const liquidCategories = {
    'drinks',
    'beverages',
    'juice',
    'milk',
    'water',
    'smoothies',
    'soda',
    'tea',
    'coffee',
    'sugary-drinks',
  };
  return liquidCategories.contains(category.toLowerCase()) ? 'ml' : 'g';
}

class _SubmittedDialog extends StatelessWidget {
  const _SubmittedDialog();

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return AlertDialog(
      backgroundColor: c.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Sent for review',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: c.text,
          letterSpacing: -0.2,
        ),
      ),
      content: Text(
        'Thanks! An admin will review your edit and update the catalog if it looks right.',
        style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.45),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: NV.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
