/// Persists notification toggle states and meal reminder times
/// using SharedPreferences.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPrefs {
  static const _prefix = 'nv_notif_';

  // ── Keys ──────────────────────────────────────────────────────
  static const _mealReminders = '${_prefix}meal_reminders';
  static const _nutrientTips = '${_prefix}nutrient_tips';
  static const _streakAlerts = '${_prefix}streak_alerts';
  static const _hydration = '${_prefix}hydration';
  static const _weeklySummary = '${_prefix}weekly_summary';
  static const _aiInsights = '${_prefix}ai_insights';

  static const _breakfastHour = '${_prefix}breakfast_hour';
  static const _breakfastMinute = '${_prefix}breakfast_minute';
  static const _lunchHour = '${_prefix}lunch_hour';
  static const _lunchMinute = '${_prefix}lunch_minute';
  static const _dinnerHour = '${_prefix}dinner_hour';
  static const _dinnerMinute = '${_prefix}dinner_minute';

  static const _permissionRequested = '${_prefix}permission_requested';

  // ── Toggles ───────────────────────────────────────────────────
  static Future<bool> getMealReminders() => _getBool(_mealReminders, true);
  static Future<void> setMealReminders(bool v) => _setBool(_mealReminders, v);

  static Future<bool> getNutrientTips() => _getBool(_nutrientTips, true);
  static Future<void> setNutrientTips(bool v) => _setBool(_nutrientTips, v);

  static Future<bool> getStreakAlerts() => _getBool(_streakAlerts, true);
  static Future<void> setStreakAlerts(bool v) => _setBool(_streakAlerts, v);

  static Future<bool> getHydration() => _getBool(_hydration, false);
  static Future<void> setHydration(bool v) => _setBool(_hydration, v);

  static Future<bool> getWeeklySummary() => _getBool(_weeklySummary, true);
  static Future<void> setWeeklySummary(bool v) => _setBool(_weeklySummary, v);

  static Future<bool> getAiInsights() => _getBool(_aiInsights, false);
  static Future<void> setAiInsights(bool v) => _setBool(_aiInsights, v);

  // ── Meal times ────────────────────────────────────────────────
  static Future<TimeOfDay> getBreakfastTime() async => TimeOfDay(
    hour: await _getInt(_breakfastHour, 8),
    minute: await _getInt(_breakfastMinute, 0),
  );
  static Future<void> setBreakfastTime(TimeOfDay t) async {
    await _setInt(_breakfastHour, t.hour);
    await _setInt(_breakfastMinute, t.minute);
  }

  static Future<TimeOfDay> getLunchTime() async => TimeOfDay(
    hour: await _getInt(_lunchHour, 12),
    minute: await _getInt(_lunchMinute, 30),
  );
  static Future<void> setLunchTime(TimeOfDay t) async {
    await _setInt(_lunchHour, t.hour);
    await _setInt(_lunchMinute, t.minute);
  }

  static Future<TimeOfDay> getDinnerTime() async => TimeOfDay(
    hour: await _getInt(_dinnerHour, 19),
    minute: await _getInt(_dinnerMinute, 0),
  );
  static Future<void> setDinnerTime(TimeOfDay t) async {
    await _setInt(_dinnerHour, t.hour);
    await _setInt(_dinnerMinute, t.minute);
  }

  // ── Permission ────────────────────────────────────────────────
  static Future<bool> wasPermissionRequested() =>
      _getBool(_permissionRequested, false);
  static Future<void> markPermissionRequested() =>
      _setBool(_permissionRequested, true);

  // ── Internal ──────────────────────────────────────────────────
  static Future<bool> _getBool(String key, bool fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? fallback;
  }

  static Future<void> _setBool(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }

  static Future<int> _getInt(String key, int fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? fallback;
  }

  static Future<void> _setInt(String key, int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, v);
  }
}
