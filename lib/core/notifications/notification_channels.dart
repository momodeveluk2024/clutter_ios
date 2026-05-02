/// Android notification channel definitions for Nutrimate.
///
/// Each channel maps to a distinct user-visible category in the
/// device's notification settings, letting the user toggle them
/// individually.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NVChannels {
  // ── Channel IDs ──────────────────────────────────────────────
  static const mealReminders = 'meal_reminders';
  static const nutrientTips = 'nutrient_tips';
  static const streakUpdates = 'streak_updates';
  static const hydration = 'hydration';
  static const weeklyReport = 'weekly_report';
  static const aiInsights = 'ai_insights';
  static const engagement = 'engagement';

  /// All channels registered at app boot.
  static const List<AndroidNotificationChannel> all = [
    AndroidNotificationChannel(
      mealReminders,
      'Meal Reminders',
      description: 'Scheduled reminders to log meals',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      nutrientTips,
      'Nutrient Tips',
      description: 'Personalised food recommendations',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      streakUpdates,
      'Streak Updates',
      description: 'Streak milestones and motivation',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      hydration,
      'Hydration',
      description: 'Periodic water reminders',
      importance: Importance.low,
    ),
    AndroidNotificationChannel(
      weeklyReport,
      'Weekly Report',
      description: 'Weekly nutrient coverage summary',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      aiInsights,
      'AI Insights',
      description: 'Tips to use AI meal analysis',
      importance: Importance.low,
    ),
    AndroidNotificationChannel(
      engagement,
      'Engagement',
      description: 'Activity and re-engagement nudges',
      importance: Importance.min,
    ),
  ];
}
