import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/nutrient_reference.dart';
import '../core/providers/food_provider.dart';
import '../theme.dart';
import '../widgets.dart';

class BarcodeContributeScreen extends StatefulWidget {
  const BarcodeContributeScreen({super.key, required this.barcode});

  final String barcode;

  @override
  State<BarcodeContributeScreen> createState() => _BarcodeContributeScreenState();
}

class _BarcodeContributeScreenState extends State<BarcodeContributeScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _serving = TextEditingController(text: '100');
  String? _selectedCategory;

  // Per-nutrient enable + amount
  final Map<String, bool> _enabled = {};
  final Map<String, TextEditingController> _amount = {};

  bool _loading = false;
  bool _initialized = false;

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
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
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
    super.dispose();
  }

  List<({String code, double amountPer100G})> _collectNutrients() {
    final out = <({String code, double amountPer100G})>[];
    for (final entry in _enabled.entries) {
      if (!entry.value) continue;
      final raw = _amount[entry.key]?.text.trim() ?? '';
      final value = double.tryParse(raw) ?? 0;
      if (value <= 0) continue;
      out.add((code: entry.key, amountPer100G: value));
    }
    return out;
  }

  Future<void> _submit() async {
    if (_loading) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a name for this product.')),
      );
      return;
    }
    final category = _selectedCategory;
    if (category == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }
    final servingText = _serving.text.trim();
    final serving = double.tryParse(servingText);
    if (serving == null || serving <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a valid serving size (> 0).')),
      );
      return;
    }

    final nutrients = _collectNutrients();
    
    // Sanity check: macros shouldn't exceed 100g per 100g
    double totalMacrosGrams = 0;
    for (final n in nutrients) {
      if (n.code == 'Protein' || n.code == 'Carbs' || n.code == 'Fat') {
        totalMacrosGrams += n.amountPer100G;
      }
    }
    
    if (totalMacrosGrams > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total macros (Protein + Carbs + Fat) cannot exceed 100g per 100g.')),
      );
      return;
    }

    final brand = _brand.text.trim();

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final provider = context.read<FoodProvider>();
      final saved = await provider.createUserMeal(
        name: name,
        brand: brand.isEmpty ? null : brand,
        category: category,
        servingSizeG: serving,
        barcode: widget.barcode,
        nutrients: nutrients,
      );
      
      messenger.showSnackBar(
        const SnackBar(content: Text('Thank you! Product added successfully.')),
      );
      
      // Go to the new food's detail page
      router.go('/app/food/${saved.id}');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final macros = ['Calories', 'Protein', 'Carbs', 'Fat'];
    final others = nutrientCatalog
        .map((n) => n.code)
        .where((code) => !macros.contains(code))
        .toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Add Missing Product'),
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  NVCard(
                    padding: const EdgeInsets.all(16),
                    background: c.surfaceMuted,
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner, color: c.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unknown Barcode',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.textMuted,
                                ),
                              ),
                              Text(
                                widget.barcode,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: c.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _basicsSection(),
                  const SizedBox(height: 22),
                  _SectionHeader(label: 'MACROS'),
                  for (final code in macros) _nutrientRow(code),
                  const SizedBox(height: 22),
                  _SectionHeader(label: 'VITAMINS & MINERALS'),
                  for (final code in others) _nutrientRow(code),
                  const SizedBox(height: 24),
                  NVPrimaryButton(
                    label: 'Submit Product',
                    onPressed: _loading ? null : _submit,
                    accent: true,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _basicsSection() {
    final categories = context.watch<FoodProvider>().categories;

    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Product name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(
              labelText: 'Brand (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedCategory != null && categories.any((c) => c.slug == _selectedCategory)
                ? _selectedCategory
                : null,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: categories.map((c) {
              return DropdownMenuItem(
                value: c.slug,
                child: Text(c.name),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _serving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Serving size (grams)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutrientRow(String code) {
    final ref = nutrientReferencesByCode[code];
    if (ref == null) return const SizedBox.shrink();
    final c = NVColors.of(context);
    final enabled = _enabled[code] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NVCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: enabled,
              onChanged: (v) => setState(() => _enabled[code] = v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  Text(
                    'per 100 g, in ${ref.unit}',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _amount[code],
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: '0',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: !enabled
                  ? null
                  : () => _bumpAmount(code, ref.unit == 'mcg' ? 5 : 1),
              tooltip: 'Increase',
            ),
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: !enabled ? null : () => _bumpAmount(code, -1),
              tooltip: 'Decrease',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: c.textMuted,
        ),
      ),
    );
  }
}
