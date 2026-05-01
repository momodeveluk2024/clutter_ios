import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/providers/food_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import 'home.dart';
import 'explore.dart';
import 'tracker.dart';
import 'favorites.dart';
import 'profile.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialTab;

  static const _tabs = <_TabItem>[
    _TabItem('Home', Icons.home_outlined, Icons.home),
    _TabItem('Explore', Icons.explore_outlined, Icons.explore),
    _TabItem('Track', Icons.insights_outlined, Icons.insights),
    _TabItem('Saved', Icons.favorite_outline, Icons.favorite),
    _TabItem('You', Icons.person_outline, Icons.person),
  ];

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _index = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final pages = const [
      HomeScreen(),
      ExploreScreen(),
      TrackerScreen(),
      FavoritesScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(
            top: BorderSide(
              color: dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final active = i == _index;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _index = i);
                      _refreshTab(context, i);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active ? t.iconActive : t.icon,
                            size: 24,
                            color: active ? NV.accent : c.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: active ? NV.accent : c.textMuted,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _refreshTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.read<NutritionProvider>().refreshDashboard();
        break;
      case 2:
        final nutrition = context.read<NutritionProvider>();
        nutrition.refreshDashboard();
        nutrition.loadWeek();
        break;
      case 3:
        context.read<FoodProvider>().loadFavorites();
        break;
    }
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData iconActive;
  const _TabItem(this.label, this.icon, this.iconActive);
}
