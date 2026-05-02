class ServerNotificationPreferences {
  const ServerNotificationPreferences({
    required this.recommendationPushEnabled,
    required this.weeklySummaryPushEnabled,
    required this.aiInsightsPushEnabled,
  });

  final bool recommendationPushEnabled;
  final bool weeklySummaryPushEnabled;
  final bool aiInsightsPushEnabled;

  factory ServerNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return ServerNotificationPreferences(
      recommendationPushEnabled:
          json['recommendation_push_enabled'] as bool? ?? true,
      weeklySummaryPushEnabled:
          json['weekly_summary_push_enabled'] as bool? ?? true,
      aiInsightsPushEnabled: json['ai_insights_push_enabled'] as bool? ?? false,
    );
  }
}
