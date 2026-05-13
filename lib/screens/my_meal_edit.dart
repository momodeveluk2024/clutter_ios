import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api/api_endpoints.dart';
import '../core/models/food.dart';
import '../core/models/nutrient_reference.dart';
import '../core/providers/food_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/nv_loader.dart';

/// Create or edit a user's custom meal. Pass `mealId == null` to create.
class MyMealEditScreen extends StatefulWidget {
  const MyMealEditScreen({super.key, this.mealId});

  final String? mealId;

  @override
  State<MyMealEditScreen> createState() => _MyMealEditScreenState();
}

// Predefined background palette — keeps the UI tight and consistent with
// the design system instead of a free-form picker.
const _palette = <(String label, String hex)>[
  ('Cream', '#F4ECDC'),
  ('Sage', '#DDE7DA'),
  ('Sky', '#D9E5EE'),
  ('Lavender', '#E0DCEA'),
  ('Peach', '#F2D8C9'),
  ('Coral', '#EFC9C0'),
  ('Mint', '#CDE7DA'),
  ('Default', ''),
];

class _MyMealEditScreenState extends State<MyMealEditScreen> {
  final _name = TextEditingController();
  final _imageUrl = TextEditingController();
  final _serving = TextEditingController(text: '100');
  String _selectedColor = '';
  String? _selectedCategory;
  Uint8List? _pickedImageBytes;
  String? _pickedImageFilename;
  String? _pickedImageContentType;

  // Per-nutrient enable + amount
  final Map<String, bool> _enabled = {};
  final Map<String, TextEditingController> _amount = {};

  bool _loading = false;
  bool _initialized = false;
  String? _existingImageUrl;

  String? get _mealId => widget.mealId;
  bool get _isEdit => _mealId != null && _mealId != 'new';

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
      if (_isEdit) {
        await _loadExisting();
      } else {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _imageUrl.dispose();
    _serving.dispose();
    for (final c in _amount.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final food = await context.read<FoodProvider>().getFood(_mealId!);
      _name.text = food.name;
      _serving.text = food.servingSizeG.toString();
      _existingImageUrl = food.imageUrl;
      _imageUrl.text = food.imageUrl ?? '';
      _selectedColor = food.backgroundColor ?? '';
      _selectedCategory = food.category;
      for (final n in food.breakdown) {
        if (_amount.containsKey(n.code)) {
          _enabled[n.code] = true;
          _amount[n.code]!.text = n.amountPer100G.toString();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load meal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 86,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageFilename = picked.name;
      _pickedImageContentType = picked.mimeType ?? 'image/jpeg';
      _imageUrl.clear();
    });
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

  Future<void> _save() async {
    if (_loading) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your meal a name first.')),
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
    final serving = double.tryParse(_serving.text.trim()) ?? 100;
    final nutrients = _collectNutrients();
    final color = _selectedColor.isEmpty ? null : _selectedColor;
    final urlField = _imageUrl.text.trim();
    final imageUrl = urlField.isEmpty ? null : urlField;

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final provider = context.read<FoodProvider>();
      FoodDetail saved;
      if (_isEdit) {
        saved = await provider.updateUserMeal(
          id: _mealId!,
          name: name,
          category: category,
          servingSizeG: serving,
          imageUrl: imageUrl ?? '',
          backgroundColor: color ?? '',
          nutrients: nutrients,
        );
      } else {
        saved = await provider.createUserMeal(
          name: name,
          category: category,
          servingSizeG: serving,
          imageUrl: imageUrl,
          backgroundColor: color,
          nutrients: nutrients,
        );
      }
      if (_pickedImageBytes != null) {
        await provider.uploadUserMealImage(
          id: saved.id,
          bytes: _pickedImageBytes!,
          filename: _pickedImageFilename ?? 'meal.jpg',
          contentType: _pickedImageContentType ?? 'image/jpeg',
        );
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Meal updated' : 'Meal created')),
      );
      router.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (!_isEdit) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this meal?'),
        content: const Text('This cannot be undone. Past logs that used it stay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await context.read<FoodProvider>().deleteUserMeal(_mealId!);
      messenger.showSnackBar(const SnackBar(content: Text('Meal deleted')));
      router.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
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
        title: Text(_isEdit ? 'Edit meal' : 'New meal'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _loading ? null : _delete,
            ),
        ],
      ),
      body: !_initialized
          ? const Center(child: NVLoader(label: 'Loading meal…'))
          : NVLoadingOverlay(
              isLoading: _loading,
              label: 'Saving meal…',
              child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _photoSection(),
                  const SizedBox(height: 16),
                  _colorPaletteSection(),
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
                    label: _isEdit ? 'Save changes' : 'Create meal',
                    onPressed: _loading ? null : _save,
                    accent: true,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            ),
    );
  }

  Widget _photoSection() {
    final c = NVColors.of(context);
    final bgHex = _selectedColor;
    final bg = _parseHex(bgHex) ?? c.surface;
    final hasPicked = _pickedImageBytes != null;
    final urlText = _imageUrl.text.trim();
    final remoteUrl =
        urlText.isNotEmpty ? urlText : (hasPicked ? null : _existingImageUrl);
    return NVCard(
      padding: const EdgeInsets.all(16),
      background: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: c.surfaceMuted,
                  image: hasPicked
                      ? DecorationImage(
                          image: MemoryImage(_pickedImageBytes!),
                          fit: BoxFit.cover,
                        )
                      : (remoteUrl != null && remoteUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  ApiEndpoints.mediaUrl(remoteUrl),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null),
                ),
                child:
                    !hasPicked && (remoteUrl == null || remoteUrl.isEmpty)
                    ? Icon(
                        Icons.restaurant_rounded,
                        size: 26,
                        color: c.textMuted,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick from your device or paste a URL.',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Pick'),
                onPressed: _loading ? null : _pickImage,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              hintText: 'https://… (or leave blank if you picked a file)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _colorPaletteSection() {
    final c = NVColors.of(context);
    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Background color',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _palette.map((entry) {
              final isSelected = _selectedColor == entry.$2;
              final swatch = entry.$2.isEmpty
                  ? c.surface
                  : _parseHex(entry.$2)!;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = entry.$2),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? NV.accent : c.border,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: entry.$2.isEmpty
                      ? Icon(Icons.block, size: 16, color: c.textMuted)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _basicsSection() {
    final categories = context.watch<FoodProvider>().categories;
    // ensure the selected category is actually in the list, or null if list is empty
    if (_selectedCategory != null &&
        categories.isNotEmpty &&
        !categories.any((c) => c.slug == _selectedCategory)) {
      // _selectedCategory is not in the list, but it might be valid backend-side,
      // or we just preserve it. However, dropdown requires the value to exist or be null.
      // We will append a dummy category to the list just for display if needed, or null it out.
    }

    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Meal name',
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

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.replaceFirst('#', '').trim();
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final value = int.tryParse(
    cleaned.length == 6 ? 'FF$cleaned' : cleaned,
    radix: 16,
  );
  return value == null ? null : Color(value);
}
