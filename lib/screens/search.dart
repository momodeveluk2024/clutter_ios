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
  static const int _pageSize = 30;

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  int _tab = 0;
  late String _category = widget.initialCategory;
  List<FoodSummary> _foods = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state.
  int _page = 1; // 1-indexed
  int _total = 0;
  bool _hasMore = false;

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
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // New query → restart at page 1.
      _loadFoods(page: 1);
    });
  }

  Future<void> _loadFoods({int? page}) async {
    final targetPage = page ?? _page;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await context.read<FoodProvider>().fetchFoodsPage(
        query: _controller.text.trim(),
        category: _category,
        limit: _pageSize,
        offset: (targetPage - 1) * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _foods = result.foods;
        _page = targetPage;
        _total = result.total;
        _hasMore = result.hasMore;
      });
      // Snap back to the top when paging.
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalPages =>
      _total <= 0 ? 1 : ((_total + _pageSize - 1) ~/ _pageSize);

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
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner, size: 20, color: NV.accent),
                            onPressed: () => context.push('/app/barcode-scan'),
                          ),
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.close, size: 18, color: c.textMuted),
                              onPressed: () {
                                _controller.clear();
                                _onChanged('');
                              },
                            ),
                        ],
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

  /// Renders 30 foods per page with Next/Previous controls below the list.
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
    // header + foods + pager
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: _foods.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          final start = (_page - 1) * _pageSize + 1;
          final end = start + _foods.length - 1;
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: SectionLabel(
              _total > 0
                  ? '$start–$end of $_total results'
                  : '${_foods.length} results',
            ),
          );
        }
        if (index == _foods.length + 1) {
          return _Pager(
            page: _page,
            totalPages: _totalPages,
            hasMore: _hasMore,
            onPrev: _page > 1
                ? () => _loadFoods(page: _page - 1)
                : null,
            onNext: _hasMore
                ? () => _loadFoods(page: _page + 1)
                : null,
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
                    '${food.category} - ${food.servingSizeG.toStringAsFixed(0)}${_servingUnitForCategory(food.category)} serving',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Builder(builder: (_) {
                    final macroCodes = const {
                      'Calories',
                      'Protein',
                      'Carbs',
                      'Fat',
                      'Fiber',
                    };
                    final missingMacros = !food.nutrients.any(macroCodes.contains);
                    if (missingMacros) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 11,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Missing nutrition data',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Row(
                      children: food.nutrients
                          .take(4)
                          .map(
                            (h) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: VitaminChip(code: h, size: 20),
                            ),
                          )
                          .toList(),
                    );
                  }),
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

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    required this.hasMore,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final bool hasMore;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
      child: Row(
        children: [
          _PagerButton(
            label: 'Previous',
            icon: Icons.chevron_left,
            iconLeading: true,
            onTap: onPrev,
            colors: c,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Page $page of $totalPages',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted,
                ),
              ),
            ),
          ),
          _PagerButton(
            label: 'Next',
            icon: Icons.chevron_right,
            iconLeading: false,
            onTap: onNext,
            colors: c,
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.label,
    required this.icon,
    required this.iconLeading,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final bool iconLeading;
  final VoidCallback? onTap;
  final NVColors colors;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = enabled ? NV.accent : colors.textMuted.withValues(alpha: 0.5);
    final bg = enabled
        ? NV.accentSoft
        : colors.surfaceMuted.withValues(alpha: 0.6);
    final iconWidget = Icon(icon, size: 18, color: fg);
    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: fg,
      ),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: iconLeading
                  ? [iconWidget, const SizedBox(width: 4), textWidget]
                  : [textWidget, const SizedBox(width: 4), iconWidget],
            ),
          ),
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


String _servingUnitForCategory(String category) {
  const liquid = {
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
  return liquid.contains(category.toLowerCase()) ? 'ml' : 'g';
}
