import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/providers/food_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../core/tour/app_tour.dart';
import '../core/tour/tour_prefs.dart';
import '../core/tour/trail_welcome.dart';
import '../widgets/mascot.dart';
import '../theme.dart';
import 'home.dart';
import 'explore.dart';
import 'tracker.dart';
import 'favorites.dart';
import 'profile.dart';

/// Allows child widgets to switch the active tab without routing.
/// Usage: AppShellScope.of(context)?.switchTab(4);
class AppShellScope extends InheritedWidget {
  final void Function(int index) switchTab;

  const AppShellScope({
    super.key,
    required this.switchTab,
    required super.child,
  });

  static AppShellScope? of(BuildContext context) =>
      context.findAncestorWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope old) => false;
}

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
      _showTrailWelcome();
      return;
    }
    final completed = await TourPrefs.hasCompletedTour();
    if (!completed && mounted) {
      // Wait until home has laid out, then offer the Trail.
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) _showTrailWelcome();
    }
  }

  void _showTrailWelcome() {
    if (!mounted) return;
    TrailWelcomeOverlay.show(
      context,
      onStart: () {
        // small delay lets the welcome card fade out cleanly
        Future.delayed(const Duration(milliseconds: 220), () {
          if (mounted) _runTour();
        });
      },
      onSkip: () {
        TourPrefs.markTourCompleted();
      },
    );
  }

  void _runTour() {
    final steps = <AppTourStep>[
      // Intro card — no spotlight, centered
      const AppTourStep(
        key: null,
        title: "Quick walk-through",
        description:
            "Sprout will point things out as you go. Tap anywhere to keep moving, "
            "or use the buttons below.",
        icon: Icons.tour_rounded,
        mood: MascotMood.waving,
      ),
      AppTourStep(
        key: HomeScreen.scoreKey,
        title: 'Your daily coverage',
        description:
            'This ring is your health score for today — how well your meals '
            'cover the nutrients your body needs. The score climbs as you log.',
        icon: Icons.donut_large_rounded,
        mood: MascotMood.sparkle,
      ),
      AppTourStep(
        key: HomeScreen.macroKey,
        title: 'Calories & macros, tuned to you',
        description:
            'Your kcal target is computed from your BMR + activity (your true TDEE). '
            'Protein, carbs, fat and fiber update live as you log.',
        icon: Icons.dashboard_rounded,
        mood: MascotMood.cheering,
      ),
      AppTourStep(
        key: HomeScreen.fabKey,
        title: 'The + button does everything',
        description:
            'Search foods, scan a barcode, snap your plate, or chat with the AI '
            'assistant — all from this one button.',
        icon: Icons.add_rounded,
        mood: MascotMood.happy,
      ),
      // ── Feature spotlight: AI meal scan ─────────────────────
      const AppTourStep(
        key: null,
        title: 'AI meal photo scan',
        description:
            'Snap your plate and Sprout identifies the foods, estimates portions, '
            'and fills in kcal + micros in seconds — no typing.',
        icon: Icons.center_focus_strong_rounded,
        mood: MascotMood.sparkle,
      ),
      // ── Feature spotlight: Barcode scan ─────────────────────
      const AppTourStep(
        key: null,
        title: 'Lightning barcode scan',
        description:
            'Point at any package — we pull nutrition from Open Food Facts + USDA. '
            'Logs the full vitamin & mineral profile, not just calories.',
        icon: Icons.qr_code_scanner_rounded,
        mood: MascotMood.curious,
      ),
      // ── Feature spotlight: AI chat ──────────────────────────
      const AppTourStep(
        key: null,
        title: 'Ask Sprout anything',
        description:
            '“How much iron is in spinach?”  “Build a 30g-protein lunch.” '
            'Real answers grounded in real data — and one tap to log them.',
        icon: Icons.auto_awesome_rounded,
        mood: MascotMood.happy,
      ),
      AppTourStep(
        key: AppShell.exploreTabKey,
        title: 'Explore foods & vitamins',
        description:
            'Browse foods by category and tap any vitamin to learn what it does '
            'and which foods are richest in it.',
        icon: Icons.explore_rounded,
        mood: MascotMood.curious,
      ),
      AppTourStep(
        key: AppShell.trackTabKey,
        title: 'Trends, history & coverage',
        description:
            'Daily, weekly, and monthly views. Watch your vitamin coverage climb '
            'over time and spot the micros you miss most.',
        icon: Icons.insights_rounded,
        mood: MascotMood.thinking,
      ),
      AppTourStep(
        key: AppShell.savedTabKey,
        title: 'Saved & custom meals',
        description:
            'Your favorites and the meals you build yourself — one tap to re-log '
            'breakfasts and dinners you eat all the time.',
        icon: Icons.favorite_rounded,
        mood: MascotMood.happy,
      ),
      AppTourStep(
        key: AppShell.profileTabKey,
        title: 'You & your goals',
        description:
            'Update your goals, diet, reminders and units any time. Sprout will '
            'follow along and re-tune your targets.',
        icon: Icons.person_rounded,
        mood: MascotMood.waving,
      ),
      // Outro card — no spotlight
      const AppTourStep(
        key: null,
        title: "You're all set!",
        description:
            "Log your first meal whenever you're ready — Sprout will be cheering you on.",
        icon: Icons.celebration_rounded,
        mood: MascotMood.cheering,
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

    return AppShellScope(
      switchTab: (i) {
        if (i >= 0 && i < _tabs.length && i != _index) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
          _refreshTab(context, i);
        }
      },
      child: Scaffold(
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
