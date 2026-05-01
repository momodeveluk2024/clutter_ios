import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/reminder.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  List<Reminder> reminders = [];
  bool isLoading = false;
  String? error;

  Future<List<Reminder>> loadReminders() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(ApiEndpoints.reminders);
      reminders = (response.data['reminders'] as List? ?? const [])
          .map((v) => Reminder.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      return reminders;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReminder({
    required String title,
    String? body,
    required DateTime remindAt,
    required String timezone,
    bool enabled = true,
  }) async {
    final response = await _api.post(
      ApiEndpoints.reminders,
      data: _withoutNulls({
        'title': title,
        'body': body == null || body.trim().isEmpty ? null : body.trim(),
        'remind_at': remindAt.toUtc().toIso8601String(),
        'timezone': timezone,
        'enabled': enabled,
      }),
    );
    reminders = [
      Reminder.fromJson(Map<String, dynamic>.from(response.data as Map)),
      ...reminders,
    ];
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    await _api.delete(ApiEndpoints.reminder(id));
    reminders = reminders.where((r) => r.id != id).toList();
    notifyListeners();
  }

  Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
    return Map<String, dynamic>.fromEntries(
      values.entries.where((entry) => entry.value != null),
    );
  }
}
