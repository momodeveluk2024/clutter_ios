import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/models/nutrient_reference.dart';
import '../core/providers/food_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/mascot.dart';

/// Two-step animated flow shown when the barcode scanner cannot find a
/// product. The user adds basic info + macros/micros and submits. The
/// contribution lands in the admin dashboard (`/admin/foods` with
/// `verified=false`) where a human can approve it; once approved the next
/// scan of the same barcode will return the populated food directly.
class BarcodeContributeScreen extends StatefulWidget {
  const BarcodeContributeScreen({super.key, required this.barcode});

  final String barcode;

  @override
  State<BarcodeContributeScreen> createState() =>
      _BarcodeContributeScreenState();
}

class _BarcodeContributeScreenState extends State<BarcodeContributeScreen> {
  final PageController _pc = PageController();
  int _step = 0;

  // Basics
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _serving = TextEditingController(text: '100');
  String? _selectedCategory;

  // Nutrients
  final Map<String, bool> _enabled = {};
  final Map<String, TextEditingController> _amount = {};

  bool _loading = false;
  bool _initialized = false;

  static const _macros = ['Calories', 'Protein', 'Carbs', 'Fat', 'Fiber'];

  @override
  void initState() {
    super.initState();
    for (final n in nutrientCatalog) {
      _enabled[n.code] = false;
      _amount[n.code] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FoodProvider>();
      if (provider.categories.isEmpty) {
        await provider.fetchCategories();
      }
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _serving.dispose();
    for (final c in _amount.values) {
      c.dispose();
    }
    _pc.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Validation per step
  // ─────────────────────────────────────────────────────────────

  String? _basicsError() {
    if (_name.text.trim().isEmpty) return 'Give your product a name';
    if (_selectedCategory == null) return 'Pick a category that fits';
    final s = double.tryParse(_serving.text.trim());
    if (s == null || s <= 0) return 'Serving size must be a positive number';
    return null;
  }

  String? _nutrientsError() {
    final picked = _enabled.entries.where((e) => e.value).length;
    if (picked == 0) {
      return 'Tap at least one nutrient to enter values';
    }
    double macroSum = 0;
    for (final code in const ['Protein', 'Carbs', 'Fat']) {
      if (_enabled[code] == true) {
        macroSum += double.tryParse(_amount[code]?.text ?? '') ?? 0;
      }
    }
    if (macroSum > 100) {
      return 'Protein + Carbs + Fat cannot exceed 100g per 100g';
    }
    return null;
  }

  List<({String code, double amountPer100G})> _collectNutrients() {
    final out = <({String code, double amountPer100G})>[];
    for (final entry in _enabled.entries) {
      if (!entry.value) continue;
      final v = double.tryParse(_amount[entry.key]?.text.trim() ?? '') ?? 0;
      if (v <= 0) continue;
      out.add((code: entry.key, amountPer100G: v));
    }
    return out;
  }

  void _flash(String msg) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _next() {
    if (_step == 0) {
      final err = _basicsError();
      if (err != null) return _flash(err);
      HapticFeedback.selectionClick();
      _pc.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step = 1);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    HapticFeedback.selectionClick();
    _pc.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    setState(() => _step = 0);
  }

  Future<void> _submit() async {
    if (_loading) return;
    final err = _basicsError() ?? _nutrientsError();
    if (err != null) return _flash(err);

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final provider = context.read<FoodProvider>();
      final saved = await provider.createUserMeal(
        name: _name.text.trim(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        category: _selectedCategory!,
        servingSizeG: double.parse(_serving.text.trim()),
        barcode: widget.barcode,
        nutrients: _collectNutrients(),
      );
      if (!mounted) return;
      await _showSubmittedDialog();
      if (!mounted) return;
      // Land on the editable My Meals page so the user can refine before
      // (or after) admin review. The food already lives under their owner_user_id
      // so the edit form has full access to it.
      final router = GoRouter.of(context);
      router.go('/app');
      router.push('/app/my-meal/${saved.id}');
    } catch (e) {
      if (!mounted) return;
      _flash('Submission failed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _showSubmittedDialog() async {
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SubmittedDialog(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: !_initialized
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _Header(
                    step: _step,
                    barcode: widget.barcode,
                    onBack: _back,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pc,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _BasicsStep(
                          name: _name,
                          brand: _brand,
                          serving: _serving,
                          selectedCategory: _selectedCategory,
                          onCategory: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                        _NutrientsStep(
                          macros: _macros,
                          enabled: _enabled,
                          amount: _amount,
                          onToggle: (code, on) {
                            HapticFeedback.selectionClick();
                            setState(() => _enabled[code] = on);
                          },
                          onChange: () => setState(() {}),
                          onBump: _bumpAmount,
                        ),
                      ],
                    ),
                  ),
                  _Footer(
                    step: _step,
                    loading: _loading,
                    onNext: _next,
                  ),
                ],
              ),
      ),
    );
  }

  void _bumpAmount(String code, double delta) {
    final controller = _amount[code]!;
    final current = double.tryParse(controller.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 99999).toDouble();
    controller.text = next % 1 == 0
        ? next.toInt().toString()
        : next.toStringAsFixed(1);
    setState(() {});
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER — mascot + step indicator + barcode chip
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.barcode,
    required this.onBack,
  });

  final int step;
  final String barcode;
  final VoidCallback onBack;

  static const _stepBubbles = [
    "New food! Tell me a few basics.",
    "Now the numbers — only what you know.",
  ];
  static const _stepEyebrows = ['BASICS', 'NUTRITION'];

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NV.accentSoft.withValues(alpha: 0.35),
            c.bg,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              NVCircleIconButton(
                icon: Icons.chevron_left,
                background: c.surface,
                onTap: onBack,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        size: 14, color: NV.accent),
                    const SizedBox(width: 6),
                    Text(
                      barcode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Mascot(
                  mood: step == 0 ? MascotMood.curious : MascotMood.thinking,
                  size: 70,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Container(
                    key: ValueKey('bubble_$step'),
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                    decoration: BoxDecoration(
                      color: NV.accentSoft,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      _stepBubbles[step],
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 0; i < 2; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= step ? NV.accent : c.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _stepEyebrows[step],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NV.accent,
                  letterSpacing: 1.8,
                ),
              ),
              Text(
                'Step ${step + 1} of 2',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEP 1 — BASICS
// ═══════════════════════════════════════════════════════════════

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({
    required this.name,
    required this.brand,
    required this.serving,
    required this.selectedCategory,
    required this.onCategory,
  });

  final TextEditingController name;
  final TextEditingController brand;
  final TextEditingController serving;
  final String? selectedCategory;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final categories = context.watch<FoodProvider>().categories;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SoftTextField(
            controller: name,
            label: 'Product name',
            hint: 'e.g. Greek Yogurt 2% Plain',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 12),
          _SoftTextField(
            controller: brand,
            label: 'Brand (optional)',
            hint: 'Fage, Chobani, your favorite shop…',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: c.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final selected = cat.slug == selectedCategory;
              return GestureDetector(
                onTap: () => onCategory(cat.slug),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? NV.accent : c.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected ? NV.accent : c.border,
                      width: 1.4,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: NV.accent.withValues(alpha: 0.24),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : c.text,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _SoftTextField(
            controller: serving,
            label: 'Serving size (grams)',
            hint: '100',
            icon: Icons.scale_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 18),
          _HelperNote(
            icon: Icons.lightbulb_outline_rounded,
            text:
                'Enter values per 100g on the next step. We use these to compute your kcal + macros every time you log this food.',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEP 2 — NUTRIENTS
// ═══════════════════════════════════════════════════════════════

class _NutrientsStep extends StatelessWidget {
  const _NutrientsStep({
    required this.macros,
    required this.enabled,
    required this.amount,
    required this.onToggle,
    required this.onChange,
    required this.onBump,
  });

  final List<String> macros;
  final Map<String, bool> enabled;
  final Map<String, TextEditingController> amount;
  final void Function(String code, bool on) onToggle;
  final VoidCallback onChange;
  final void Function(String code, double delta) onBump;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final others = nutrientCatalog
        .map((n) => n.code)
        .where((code) => !macros.contains(code))
        .toList();

    final macroPicked = macros.where((c) => enabled[c] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HelperNote(
            icon: Icons.info_outline_rounded,
            text:
                "Tap the nutrients shown on the label, then type how much per 100 g. Skip anything you can't read.",
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'MACROS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: c.textMuted,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: 8),
              if (macroPicked > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NV.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$macroPicked picked',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: NV.accentDeep,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...macros.map(
            (code) => _NutrientTile(
              code: code,
              enabled: enabled[code] ?? false,
              controller: amount[code],
              onToggle: (on) => onToggle(code, on),
              onChange: onChange,
              onBump: (delta) => onBump(code, delta),
              isMacro: true,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'VITAMINS & MINERALS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: c.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...others.map(
            (code) => _NutrientTile(
              code: code,
              enabled: enabled[code] ?? false,
              controller: amount[code],
              onToggle: (on) => onToggle(code, on),
              onChange: onChange,
              onBump: (delta) => onBump(code, delta),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientTile extends StatelessWidget {
  const _NutrientTile({
    required this.code,
    required this.enabled,
    required this.controller,
    required this.onToggle,
    required this.onChange,
    required this.onBump,
    this.isMacro = false,
  });

  final String code;
  final bool enabled;
  final TextEditingController? controller;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChange;
  final ValueChanged<double> onBump;
  final bool isMacro;

  @override
  Widget build(BuildContext context) {
    final ref = nutrientReferencesByCode[code];
    if (ref == null) return const SizedBox.shrink();
    final c = NVColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: enabled
              ? NV.accent.withValues(alpha: 0.06)
              : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? NV.accent.withValues(alpha: 0.32) : c.border,
            width: enabled ? 1.4 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onToggle(!enabled),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: enabled ? NV.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: enabled ? NV.accent : c.border,
                        width: 1.6,
                      ),
                    ),
                    child: enabled
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: c.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'per 100 g · ${ref.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _RoundIcon(
              icon: Icons.remove,
              enabled: enabled,
              onTap: () => onBump(-1),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 64,
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                onChanged: (_) => onChange(),
                decoration: InputDecoration(
                  hintText: '0',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: NV.accent, width: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _RoundIcon(
              icon: Icons.add,
              enabled: enabled,
              onTap: () => onBump(ref.unit == 'mcg' ? 5 : 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, size: 14, color: c.text),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FOOTER — continue / submit button
// ═══════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.loading,
    required this.onNext,
  });

  final int step;
  final bool loading;
  final VoidCallback onNext;

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
      child: NVPrimaryButton(
        label: step == 1 ? 'Submit for review' : 'Continue',
        trailingIcon:
            step == 1 ? Icons.check_circle_outline : Icons.arrow_forward,
        accent: true,
        loading: loading,
        onPressed: loading ? null : onNext,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED PIECES
// ═══════════════════════════════════════════════════════════════

class _SoftTextField extends StatelessWidget {
  const _SoftTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: c.textMuted,
              letterSpacing: 1.4,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: c.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
            ),
            prefixIcon: Icon(icon, color: NV.accent, size: 20),
            filled: true,
            fillColor: c.surface,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NV.accent, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _HelperNote extends StatelessWidget {
  const _HelperNote({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: NV.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NV.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: NV.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: c.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUBMITTED DIALOG — mascot celebrates + explains admin review
// ═══════════════════════════════════════════════════════════════

class _SubmittedDialog extends StatelessWidget {
  const _SubmittedDialog();

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(mood: MascotMood.cheering, size: 130),
            const SizedBox(height: 4),
            Text(
              'Thanks for adding it!',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: c.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We've sent your product to our reviewers. "
              "Once approved, anyone who scans this barcode will get it "
              "instantly — no typing.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: c.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: NV.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Usually reviewed in 24 h',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            NVPrimaryButton(
              label: 'Got it',
              trailingIcon: Icons.arrow_forward,
              accent: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
