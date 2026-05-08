import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/providers/food_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../core/tour/app_tour.dart';
import '../core/tour/tour_prefs.dart';
import '../theme.dart';
import 'home.dart';
import 'explore.dart';
import 'tracker.dart';
import 'favorites.dart';
import 'profile.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0, this.startTour = false});
  final int initialTab;

  /// When true, force-start the tour regardless of prefs.
  final bool startTour;

  /// GlobalKeys for the bottom nav tab icons (used by the tour).
  static final exploreTabKey = GlobalKey(debugLabel: 'tour_explore_tab');
  static final trackTabKey = GlobalKey(debugLabel: 'tour_track_tab');
  static final savedTabKey = GlobalKey(debugLabel: 'tour_saved_tab');
  static final profileTabKey = GlobalKey(debugLabel: 'tour_profile_tab');

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _index = widget.initialTab;
    }
    if (widget.startTour && !oldWidget.startTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTour());
    }
  }

  Future<void> _maybeStartTour() async {
    if (widget.startTour) {
      _runTour();
      return;
    }
    final completed = await TourPrefs.hasCompletedTour();
    if (!completed && mounted) {
      // Small delay so the home screen has time to lay out its widgets
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _runTour();
    }
  }

  void _runTour() {
    final steps = [
      AppTourStep(
        key: HomeScreen.scoreKey,
        title: 'Your Health Score',
        description:
            'This ring shows how well your meals cover essential nutrients today. '
            'Log food to watch it climb!',
        icon: Icons.donut_large_rounded,
      ),
      AppTourStep(
        key: HomeScreen.macroKey,
        title: 'Macro Overview',
        description:
            'Protein, carbs, fat, and fiber at a glance — '
            'see how your daily intake stacks up.',
        icon: Icons.dashboard_rounded,
      ),
      AppTourStep(
        key: HomeScreen.fabKey,
        title: 'Log a Meal',
        description:
            'Tap here to search and log any food. '
            'Your score and macros update instantly.',
        icon: Icons.add_rounded,
      ),
      AppTourStep(
        key: AppShell.exploreTabKey,
        title: 'Explore Foods',
        description:
            'Browse foods by category, discover vitamins, '
            'and find what your body needs.',
        icon: Icons.explore_rounded,
      ),
      AppTourStep(
        key: AppShell.trackTabKey,
        title: 'Your Tracker',
        description:
            'View daily history, weekly trends, and use '
            'AI meal photo analysis to log faster.',
        icon: Icons.insights_rounded,
      ),
      AppTourStep(
        key: AppShell.savedTabKey,
        title: 'Saved Foods',
        description:
            'Your favorite foods and custom meals — '
            'quick access for everyday logging.',
        icon: Icons.favorite_rounded,
      ),
      AppTourStep(
        key: AppShell.profileTabKey,
        title: 'Your Profile',
        description:
            'Manage your goals, diet preferences, '
            'reminders, and app settings here.',
        icon: Icons.person_rounded,
      ),
    ];

    AppTourController.start(context, steps);
    TourPrefs.markTourCompleted();
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

    // Map tab indices to their GlobalKeys (only for tabs 1–4)
    final tabKeys = <int, GlobalKey>{
      1: AppShell.exploreTabKey,
      2: AppShell.trackTabKey,
      3: AppShell.savedTabKey,
      4: AppShell.profileTabKey,
    };

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
                    key: tabKeys[i],
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
