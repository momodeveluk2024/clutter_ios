class ServerNotificationPreferences {
  const ServerNotificationPreferences({
    required this.recommendationPushEnabled,
    required this.weeklySummaryPushEnabled,
    required this.aiInsightsPushEnabled,
    required this.lowCaloriePushEnabled,
  });

  final bool recommendationPushEnabled;
  final bool weeklySummaryPushEnabled;
  final bool aiInsightsPushEnabled;
  final bool lowCaloriePushEnabled;

  factory ServerNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return ServerNotificationPreferences(
      recommendationPushEnabled:
          json['recommendation_push_enabled'] as bool? ?? true,
      weeklySummaryPushEnabled:
          json['weekly_summary_push_enabled'] as bool? ?? true,
      aiInsightsPushEnabled: json['ai_insights_push_enabled'] as bool? ?? false,
      lowCaloriePushEnabled:
          json['low_calorie_push_enabled'] as bool? ?? true,
    );
  }
}
