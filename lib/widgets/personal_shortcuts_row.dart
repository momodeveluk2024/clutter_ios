import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/models/food.dart';
import '../theme.dart';

/// Phase 1b "Your usuals" + "Recently logged" row that drops in above the
/// search results / home meal log. Reads from GET /v1/foods/personal-shortcuts.
/// Drop into the home or search screen with `PersonalShortcutsRow(api: api,
/// onTap: (food) => ...)` and let it manage its own load state.
class PersonalShortcutsRow extends StatefulWidget {
  const PersonalShortcutsRow({
    super.key,
    required this.api,
    required this.onTap,
    this.title = 'Your usuals',
    this.recentTitle = 'Recently logged',
  });

  final ApiClient api;
  final void Function(FoodSummary) onTap;
  final String title;
  final String recentTitle;

  @override
  State<PersonalShortcutsRow> createState() => _PersonalShortcutsRowState();
}

class _PersonalShortcutsRowState extends State<PersonalShortcutsRow> {
  List<FoodSummary> _usuals = const [];
  List<FoodSummary> _recent = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await widget.api.get(ApiEndpoints.personalShortcuts);
      final data = Map<String, dynamic>.from(response.data as Map);
      _usuals = (data['usuals'] as List? ?? const [])
          .map((v) => FoodSummary.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      _recent = (data['recent'] as List? ?? const [])
          .map((v) => FoodSummary.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    } catch (_) {
      _usuals = const [];
      _recent = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_usuals.isEmpty && _recent.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_usuals.isNotEmpty) ...[
          _SectionHeader(label: widget.title),
          _row(_usuals),
          const SizedBox(height: NVSpace.x4),
        ],
        if (_recent.isNotEmpty) ...[
          _SectionHeader(label: widget.recentTitle),
          _row(_recent),
        ],
      ],
    );
  }

  Widget _row(List<FoodSummary> foods) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: NVSpace.x4),
        itemCount: foods.length,
        separatorBuilder: (_, __) => const SizedBox(width: NVSpace.x2),
        itemBuilder: (context, i) => _ShortcutChip(
          food: foods[i],
          onTap: () => widget.onTap(foods[i]),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(NVSpace.x4, NVSpace.x4, NVSpace.x4, NVSpace.x2),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.food, required this.onTap});
  final FoodSummary food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(NVRadius.card),
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(NVSpace.x2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(NVRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              food.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (food.brand != null)
              Text(
                food.brand!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
