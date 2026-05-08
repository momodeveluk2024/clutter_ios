import 'package:home_widget/home_widget.dart';

/// Phase 4 home-screen widget bridge. The Dart side just writes shared
/// values; the native widget extension reads them.
///
/// **Native config required:**
///   - iOS: add a Widget Extension target in Xcode, share an App Group
///     between Runner and the extension, then call `HomeWidget.setAppGroupId`.
///   - Android: add a Glance/RemoteViews receiver, register it in the
///     manifest. See https://pub.dev/packages/home_widget.
///
/// Keep payloads tiny — these surfaces wake at the OS's discretion and
/// large reads burn battery.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const _kCaloriesIntake = 'today_calories_intake';
  static const _kCaloriesTarget = 'today_calories_target';
  static const _kProteinIntake = 'today_protein_intake';
  static const _kProteinTarget = 'today_protein_target';
  static const _kStreakDays = 'streak_days';
  static const _androidWidgetName = 'NutrimateWidgetProvider';
  static const _iosWidgetName = 'NutrimateWidget';

  Future<void> publishDailySnapshot({
    required int caloriesIntake,
    required int caloriesTarget,
    required int proteinIntakeG,
    required int proteinTargetG,
    required int streakDays,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<int>(_kCaloriesIntake, caloriesIntake),
      HomeWidget.saveWidgetData<int>(_kCaloriesTarget, caloriesTarget),
      HomeWidget.saveWidgetData<int>(_kProteinIntake, proteinIntakeG),
      HomeWidget.saveWidgetData<int>(_kProteinTarget, proteinTargetG),
      HomeWidget.saveWidgetData<int>(_kStreakDays, streakDays),
    ]);
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iosWidgetName,
    );
  }
}
