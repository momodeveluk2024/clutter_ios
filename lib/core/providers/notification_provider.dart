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
  bool lowCalorieAlerts = true;

  TimeOfDay breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  bool isLoading = true;
  bool remotePushAvailable = false;
  String? remoteError;
  bool _lastAuthenticated = false;

  /// Load all saved prefs and request permission if first time.
  Future<void> initialize() async {
    // FCM initialization is now deferred to syncRemotePushDevice() to
    // completely prevent Android thread contention during app boot.

    mealReminders = await NotificationPrefs.getMealReminders();
    nutrientTips = await NotificationPrefs.getNutrientTips();
    streakAlerts = await NotificationPrefs.getStreakAlerts();
    hydration = await NotificationPrefs.getHydration();
    weeklySummary = await NotificationPrefs.getWeeklySummary();
    aiInsights = await NotificationPrefs.getAiInsights();
    lowCalorieAlerts = await NotificationPrefs.getLowCalorie();

    breakfastTime = await NotificationPrefs.getBreakfastTime();
    lunchTime = await NotificationPrefs.getLunchTime();
    dinnerTime = await NotificationPrefs.getDinnerTime();

    isLoading = false;
    notifyListeners();

    // Request permission on first launch. Detach from await so we don't
    // block initialization (and subsequent auth changes) if the user ignores the dialog.
    final alreadyRequested = await NotificationPrefs.wasPermissionRequested();
    if (!alreadyRequested) {
      NotificationService.instance.requestPermission().then((_) {
        NotificationPrefs.markPermissionRequested();
      });
    }

    // Schedule based on current prefs
    await NotificationScheduler.instance.rescheduleAll();
  }

  Future<void> handleAuthChanged({required bool isAuthenticated}) async {
    if (_lastAuthenticated == isAuthenticated) return;
    _lastAuthenticated = isAuthenticated;
    if (isAuthenticated) {
      // Detach and delay FCM token sync to prevent severe thread contention/ANRs
      // on certain Android devices during the heavy login routing and tutorial rendering phase.
      // Increased to 15 seconds to ensure all Impeller shader compilation and
      // route transitions have completely finished.
      Future.delayed(const Duration(seconds: 15), () {
        syncRemotePushDevice();
      });
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
      if (_api != null && !FcmNotificationService.instance.available) {
        await FcmNotificationService.instance.initialize(api: _api!);
        remotePushAvailable = FcmNotificationService.instance.available;
      }
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

  Future<void> setLowCalorieAlerts(bool v) async {
    lowCalorieAlerts = v;
    notifyListeners();
    await NotificationPrefs.setLowCalorie(v);
    await _updateServerPreferences(lowCalorie: v);
  }

  /// Asks the backend to send a heads-up test push to every device the
  /// current user has registered. Throws on network/HTTP error so the
  /// caller can surface a snackbar.
  Future<TestPushResult> sendTestPush() async {
    if (_api == null) {
      throw StateError('Sign in to send a test notification.');
    }
    final response = await _api.post(ApiEndpoints.notificationTest);
    final data = response.data as Map?;
    if (data == null) return const TestPushResult.empty();
    return TestPushResult(
      senderType: data['sender_type'] as String? ?? 'unknown',
      deviceCount: (data['device_count'] as num?)?.toInt() ?? 0,
      successCount: (data['success_count'] as num?)?.toInt() ?? 0,
      failureCount: (data['failure_count'] as num?)?.toInt() ?? 0,
      firstError: _firstError(data['results']),
    );
  }

  String? _firstError(Object? results) {
    if (results is! List) return null;
    for (final entry in results) {
      if (entry is Map && entry['ok'] == false) {
        final err = entry['error'];
        if (err is String && err.isNotEmpty) return err;
      }
    }
    return null;
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
      lowCalorieAlerts = prefs.lowCaloriePushEnabled;
      await NotificationPrefs.setNutrientTips(nutrientTips);
      await NotificationPrefs.setWeeklySummary(weeklySummary);
      await NotificationPrefs.setAiInsights(aiInsights);
      await NotificationPrefs.setLowCalorie(lowCalorieAlerts);
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
    bool? lowCalorie,
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
    if (lowCalorie != null) {
      data['low_calorie_push_enabled'] = lowCalorie;
    }
    try {
      await _api.patch(ApiEndpoints.notificationPreferences, data: data);
      remoteError = null;
    } catch (error) {
      remoteError = error.toString();
    }
  }
}

/// Diagnostic payload returned by /v1/notifications/test. Lets the UI tell
/// the user *why* a push didn't arrive (e.g. server is using the dev logger
/// instead of FCM, or every token was rejected as not-registered).
class TestPushResult {
  const TestPushResult({
    required this.senderType,
    required this.deviceCount,
    required this.successCount,
    required this.failureCount,
    this.firstError,
  });

  const TestPushResult.empty()
    : senderType = 'unknown',
      deviceCount = 0,
      successCount = 0,
      failureCount = 0,
      firstError = null;

  final String senderType; // "fcm" | "dev_logger" | "unknown"
  final int deviceCount;
  final int successCount;
  final int failureCount;
  final String? firstError;

  /// Human-readable one-liner for the snackbar.
  String describe() {
    if (senderType == 'dev_logger') {
      return 'Server has no Firebase credentials wired. Push was logged only — never sent.';
    }
    if (deviceCount == 0) {
      return 'No push devices registered. Sign out and back in to register.';
    }
    if (successCount == 0) {
      return 'FCM rejected every token ($failureCount failures). First error: ${firstError ?? "unknown"}';
    }
    if (failureCount > 0) {
      return 'Sent to $successCount of $deviceCount devices. $failureCount failed: ${firstError ?? "unknown"}';
    }
    return 'Sent to $successCount device${successCount == 1 ? "" : "s"} via FCM.';
  }
}
