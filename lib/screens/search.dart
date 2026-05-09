import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/food.dart';
import '../core/models/nutrient_reference.dart';
import '../core/providers/food_provider.dart';
import '../theme.dart';
import '../widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategory = ''});

  final String initialCategory;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _tab = 0;
  late String _category = widget.initialCategory;
  List<FoodSummary> _foods = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoods();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadFoods();
    });
  }

  Future<void> _loadFoods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final foods = await context.read<FoodProvider>().fetchFoods(
        query: _controller.text.trim(),
        category: _category,
        limit: 500,
      );
      if (!mounted) return;
      setState(() => _foods = foods);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NVCircleIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: c.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search foods',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: c.textMuted,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close, size: 18, color: c.textMuted),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                      filled: true,
                      fillColor: c.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _tabButton('Foods', 0, c),
                      const SizedBox(width: 8),
                      _tabButton('Vitamins', 1, c),
                      const SizedBox(width: 8),
                      _tabButton('Recipes', 2, c),
                    ],
                  ),
                  if (_category.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text(_category),
                        avatar: const Icon(Icons.category, size: 16),
                        onDeleted: () {
                          setState(() => _category = '');
                          _loadFoods();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFoods,
                child: _tab == 0
                    ? _buildFoodList()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        children: _tab == 1
                            ? const [_NutrientResults()]
                            : const [
                                _MessageCard(
                                  message:
                                      'Recipes will connect to logged meal templates next.',
                                  icon: Icons.restaurant_menu,
                                ),
                              ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Uses ListView.builder for O(visible) rendering instead of O(n).
  /// With 500 foods this eliminates the big initial-frame jank.
  Widget _buildFoodList() {
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        children: [_MessageCard(message: _error!, icon: Icons.error_outline)],
      );
    }
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        children: const [_LoadingList()],
      );
    }
    if (_foods.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        children: const [
          _MessageCard(message: 'No foods found', icon: Icons.search_off),
        ],
      );
    }
    // +1 for the header row
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: _foods.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: SectionLabel('${_foods.length} results'),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _FoodResult(food: _foods[index - 1]),
        );
      },
    );
  }

  Widget _tabButton(String label, int index, NVColors c) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _tab = index);
        if (index == 0) _loadFoods();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? NV.accent : c.surface,
          borderRadius: BorderRadius.circular(100),
          border: active ? null : Border.all(color: c.border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: NV.accent.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : c.text,
          ),
        ),
      ),
    );
  }
}

class _NutrientResults extends StatelessWidget {
  const _NutrientResults();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: SectionLabel('Nutrients'),
        ),
        ...nutrientCatalog.map(
          (nutrient) => _NutrientResult(nutrient: nutrient),
        ),
      ],
    );
  }
}

class _NutrientResult extends StatelessWidget {
  const _NutrientResult({required this.nutrient});

  final NutrientReference nutrient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NutrientCard(
        nutrient: nutrient,
        compact: true,
        onTap: () => context.push('/app/vitamin/${nutrient.code}'),
      ),
    );
  }
}

class _FoodResult extends StatelessWidget {
  const _FoodResult({required this.food});

  final FoodSummary food;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NVCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/app/food/${food.id}'),
        child: Row(
          children: [
            FoodPhoto(
              label: food.name,
              imageUrl: food.imageUrl,
              category: food.category,
              height: 56,
              width: 56,
              radius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: food.isUnhealthy
                              ? Colors.red.withValues(alpha: 0.12)
                              : const Color(0xFF2F7D4A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              food.isUnhealthy
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_rounded,
                              size: 11,
                              color: food.isUnhealthy
                                  ? Colors.red.shade700
                                  : const Color(0xFF2F7D4A),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              food.isUnhealthy ? 'Unhealthy' : 'Healthy',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: food.isUnhealthy
                                    ? Colors.red.shade700
                                    : const Color(0xFF2F7D4A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.category} - ${food.servingSizeG.toStringAsFixed(0)}g serving',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: food.nutrients
                        .take(4)
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: VitaminChip(code: h, size: 20),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF2F7D4A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 22,
                color: Color(0xFF2F7D4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: PhotoPlaceholder(label: 'loading', height: 76, radius: 16),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return NVCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: c.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: c.textMuted)),
          ),
        ],
      ),
    );
  }
}
