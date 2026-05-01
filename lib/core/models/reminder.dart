class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    this.body,
    required this.remindAt,
    required this.timezone,
    required this.enabled,
  });

  final String id;
  final String title;
  final String? body;
  final DateTime remindAt;
  final String timezone;
  final bool enabled;

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      remindAt: DateTime.parse(json['remind_at'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
