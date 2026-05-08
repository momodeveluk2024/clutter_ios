import 'package:shared_preferences/shared_preferences.dart';

/// Persists tour completion state using SharedPreferences.
class TourPrefs {
  static const _key = 'app_tour_completed';

  static Future<bool> hasCompletedTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}
