/// Manages notification preferences and exposes reactive state
/// for the notification settings UI.
library;

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/notification_preferences.dart';
import '../notifications/fcm_notification_service.dart';
import '../notifications/notification_scheduler.dart';
import '../notifications/notification_service.dart';
import '../storage/notification_prefs.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({ApiClient? api}) : _api = api;

  final ApiClient? _api;

  // ── Observable state ──────────────────────────────────────────
  bool mealReminders = true;
  bool nutrientTips = true;
  bool streakAlerts = true;
  bool hydration = false;
  bool weeklySummary = true;
  bool aiInsights = false;

  TimeOfDay breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  bool isLoading = true;
  bool remotePushAvailable = false;
  String? remoteError;
  bool _lastAuthenticated = false;

  /// Load all saved prefs and request permission if first time.
  Future<void> initialize() async {
    if (_api != null) {
      await FcmNotificationService.instance.initialize(api: _api);
      remotePushAvailable = FcmNotificationService.instance.available;
    }

    mealReminders = await NotificationPrefs.getMealReminders();
    nutrientTips = await NotificationPrefs.getNutrientTips();
    streakAlerts = await NotificationPrefs.getStreakAlerts();
    hydration = await NotificationPrefs.getHydration();
    weeklySummary = await NotificationPrefs.getWeeklySummary();
    aiInsights = await NotificationPrefs.getAiInsights();

    breakfastTime = await NotificationPrefs.getBreakfastTime();
    lunchTime = await NotificationPrefs.getLunchTime();
    dinnerTime = await NotificationPrefs.getDinnerTime();

    isLoading = false;
    notifyListeners();

    // Request permission on first launch
    final alreadyRequested = await NotificationPrefs.wasPermissionRequested();
    if (!alreadyRequested) {
      await NotificationService.instance.requestPermission();
      await NotificationPrefs.markPermissionRequested();
    }

    // Schedule based on current prefs
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> handleAuthChanged({required bool isAuthenticated}) async {
    if (_lastAuthenticated == isAuthenticated) return;
    _lastAuthenticated = isAuthenticated;
    if (isAuthenticated) {
      await syncRemotePushDevice();
      await _loadServerPreferences();
      notifyListeners();
    } else {
      try {
        await FcmNotificationService.instance.disableCurrentDevice();
      } catch (_) {
        // Best effort only; logout should not be blocked by stale push state.
      }
    }
  }

  Future<void> syncRemotePushDevice() async {
    try {
      await FcmNotificationService.instance.registerCurrentDevice();
      remoteError = null;
    } catch (error) {
      remoteError = error.toString();
    }
  }

  // ── Toggles ───────────────────────────────────────────────────

  Future<void> setMealReminders(bool v) async {
    mealReminders = v;
    notifyListeners();
    await NotificationPrefs.setMealReminders(v);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> setNutrientTips(bool v) async {
    nutrientTips = v;
    notifyListeners();
    await NotificationPrefs.setNutrientTips(v);
    await _updateServerPreferences(recommendations: v);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> setStreakAlerts(bool v) async {
    streakAlerts = v;
    notifyListeners();
    await NotificationPrefs.setStreakAlerts(v);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> setHydration(bool v) async {
    hydration = v;
    notifyListeners();
    await NotificationPrefs.setHydration(v);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> setWeeklySummary(bool v) async {
    weeklySummary = v;
    notifyListeners();
    await NotificationPrefs.setWeeklySummary(v);
    await _updateServerPreferences(weeklySummary: v);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> setAiInsights(bool v) async {
    aiInsights = v;
    notifyListeners();
    await NotificationPrefs.setAiInsights(v);
    await _updateServerPreferences(aiInsights: v);
    await NotificationScheduler.instance.rescheduleAll();
  }

  // ── Meal time changes ─────────────────────────────────────────

  Future<void> setBreakfastTime(TimeOfDay t) async {
    breakfastTime = t;
    notifyListeners();
    await NotificationPrefs.setBreakfastTime(t);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> setLunchTime(TimeOfDay t) async {
    lunchTime = t;
    notifyListeners();
    await NotificationPrefs.setLunchTime(t);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> setDinnerTime(TimeOfDay t) async {
    dinnerTime = t;
    notifyListeners();
    await NotificationPrefs.setDinnerTime(t);
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> _loadServerPreferences() async {
    if (_api == null) return;
    try {
      final response = await _api.get(ApiEndpoints.notificationPreferences);
      final prefs = ServerNotificationPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      nutrientTips = prefs.recommendationPushEnabled;
      weeklySummary = prefs.weeklySummaryPushEnabled;
      aiInsights = prefs.aiInsightsPushEnabled;
      await NotificationPrefs.setNutrientTips(nutrientTips);
      await NotificationPrefs.setWeeklySummary(weeklySummary);
      await NotificationPrefs.setAiInsights(aiInsights);
      remoteError = null;
    } catch (error) {
      // This is expected while signed out or before the backend migration runs.
      remoteError = error.toString();
    }
  }

  Future<void> _updateServerPreferences({
    bool? recommendations,
    bool? weeklySummary,
    bool? aiInsights,
  }) async {
    if (_api == null) return;
    final data = <String, dynamic>{};
    if (recommendations != null) {
      data['recommendation_push_enabled'] = recommendations;
    }
    if (weeklySummary != null) {
      data['weekly_summary_push_enabled'] = weeklySummary;
    }
    if (aiInsights != null) {
      data['ai_insights_push_enabled'] = aiInsights;
    }
    try {
      await _api.patch(ApiEndpoints.notificationPreferences, data: data);
      remoteError = null;
    } catch (error) {
      remoteError = error.toString();
    }
  }
}
