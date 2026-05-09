import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/models/food.dart';
import '../core/models/nutrient_reference.dart';
import '../core/models/visual_catalog.dart';
import '../core/providers/food_provider.dart';
import '../theme.dart';
import '../widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<FoodSummary> _foods = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalog();
    });
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final foods = await context.read<FoodProvider>().fetchFoods(limit: 500);
      if (!mounted) return;
      setState(() {
        _foods = foods;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final categories = <String, int>{};
    for (final food in _foods) {
      final category = canonicalCategoryKey(food.category);
      categories.update(category, (value) => value + 1, ifAbsent: () => 1);
    }
    final cats =
        categories.entries
            .map((entry) => _CategoryCount(entry.key, entry.value))
            .toList()
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            if (byCount != 0) return byCount;
            return categoryVisualFor(
              a.name,
            ).label.compareTo(categoryVisualFor(b.name).label);
          });

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loading
                            ? 'Loading catalog'
                            : '${_foods.length} foods across ${cats.length} categories',
                        style: TextStyle(fontSize: 14, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: c.text),
                  onPressed: () => context.push('/app/search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                _NutrientGroupPickers(onSelected: _openNutrientBrowser),
                const SizedBox(height: 16),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2.5),
                        const SizedBox(height: 14),
                        Text(
                          'Loading catalog…',
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                      ],
                    ),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 36,
                          color: c.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load catalog',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadCatalog,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (cats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 36,
                          color: c.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No foods in catalog yet',
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 176,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: cats.map((cat) {
                      return _CategoryTile(
                        name: cat.name,
                        count: cat.count,
                        onTap: () => context.push(
                          '/app/search?category=${Uri.encodeComponent(cat.name)}',
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNutrientBrowser(_NutrientGroup group) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NutrientBrowserSheet(group: group),
    );
    if (!mounted || selected == null) return;
    context.push('/app/vitamin/$selected');
  }
}

class _CategoryCount {
  const _CategoryCount(this.name, this.count);

  final String name;
  final int count;
}

enum _NutrientGroup {
  vitamins(
    'Vitamins',
    'vitamin',
    Icons.auto_awesome,
    'Vitamin Suite',
    'Curated essentials for everyday vitality',
    Color(0xFF2F7D4A),
    Color(0xFFEAF5EE),
    Color(0xFF173D2A),
  ),
  minerals(
    'Minerals',
    'mineral',
    Icons.diamond_outlined,
    'Mineral Reserve',
    'Trace elements that keep the body steady',
    Color(0xFF2B7E7A),
    Color(0xFFE8F4F2),
    Color(0xFF123E42),
  ),
  macros(
    'Macros',
    'macro',
    Icons.pie_chart_outline,
    'Macro Balance',
    'The main building blocks for every meal',
    Color(0xFF946B2D),
    Color(0xFFF5EFE3),
    Color(0xFF4A3518),
  );

  const _NutrientGroup(
    this.label,
    this.catalogGroup,
    this.icon,
    this.sheetTitle,
    this.sheetSubtitle,
    this.accent,
    this.soft,
    this.deep,
  );

  final String label;
  final String catalogGroup;
  final IconData icon;
  final String sheetTitle;
  final String sheetSubtitle;
  final Color accent;
  final Color soft;
  final Color deep;

  List<NutrientReference> get nutrients => nutrientCatalog
      .where((nutrient) => nutrient.group == catalogGroup)
      .toList();

  String get countLabel => catalogGroup == 'macro'
      ? '${nutrients.length} foundations'
      : '${nutrients.length} essentials';
}

class _NutrientGroupPickers extends StatelessWidget {
  const _NutrientGroupPickers({required this.onSelected});

  final ValueChanged<_NutrientGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _NutrientGroup.values.map((group) {
          final last = group == _NutrientGroup.values.last;
          return Padding(
            padding: EdgeInsets.only(right: last ? 0 : 8),
            child: _NutrientGroupPicker(
              group: group,
              onTap: () => onSelected(group),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NutrientGroupPicker extends StatelessWidget {
  const _NutrientGroupPicker({required this.group, required this.onTap});

  final _NutrientGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    
    return Material(
      color: dark ? c.surfaceMuted : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      elevation: dark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(group.icon, size: 16, color: group.accent),
              const SizedBox(width: 8),
              Text(
                group.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: c.text,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: group.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${group.nutrients.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: group.accent,
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

class _NutrientBrowserSheet extends StatelessWidget {
  const _NutrientBrowserSheet({required this.group});

  final _NutrientGroup group;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: dark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: group.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(group.icon, size: 24, color: group.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.sheetTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group.sheetSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Divider
          Divider(
            height: 1, 
            thickness: 1, 
            color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
          ),
          
          // List
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              children: [
                _NutrientSheetSection(
                  title: group.label,
                  nutrients: group.nutrients,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientSheetSection extends StatelessWidget {
  const _NutrientSheetSection({required this.title, required this.nutrients});

  final String title;
  final List<NutrientReference> nutrients;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
          child: SectionLabel(title),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final useTwoColumns = constraints.maxWidth >= 520;
            final itemWidth = useTwoColumns
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: nutrients.map((nutrient) {
                return SizedBox(
                  width: itemWidth,
                  child: _LuxuryNutrientChip(
                    nutrient: nutrient,
                    onTap: () => Navigator.of(context).pop(nutrient.code),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LuxuryNutrientChip extends StatelessWidget {
  const _LuxuryNutrientChip({required this.nutrient, required this.onTap});

  final NutrientReference nutrient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final visual = nutrientVisualFor(nutrient.code);

    return Material(
      key: ValueKey('luxury-nutrient-chip-${nutrient.code}'),
      color: dark ? visual.accent.withValues(alpha: 0.15) : visual.accent.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: visual.accent.withValues(alpha: dark ? 0.2 : 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(visual.icon, size: 18, color: visual.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nutrient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: c.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                nutrient.code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: visual.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.count,
    required this.onTap,
  });

  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final visual = categoryVisualFor(name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 98,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FoodPhoto(
                      label: name,
                      imageUrl: visual.imageUrl,
                      height: 98,
                      radius: 0,
                      tone: 'cool',
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            visual.accent.withValues(alpha: dark ? 0.30 : 0.16),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          visual.icon,
                          size: 18,
                          color: visual.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visual.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count items',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
