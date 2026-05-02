/// Core notification service — singleton that owns the
/// [FlutterLocalNotificationsPlugin] instance, registers Android
/// channels, and exposes scheduling / cancellation helpers.
///
/// Navigation on tap is handled through a payload string that
/// the app's root widget inspects on launch and when tapped.
library;

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_channels.dart';

/// Global stream that emits the notification payload when a user
/// taps a notification.  The app's root widget listens to this.
final StreamController<String?> notificationTapStream =
    StreamController<String?>.broadcast();

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Notification IDs (fixed, stable) ──────────────────────────
  // Meal reminders use IDs 100–199 (one per meal slot)
  static const breakfastId = 100;
  static const lunchId = 101;
  static const dinnerId = 102;
  // Nutrient tip
  static const nutrientTipId = 200;
  // Streak
  static const streakId = 300;
  // Hydration uses IDs 400–499
  static const hydrationBaseId = 400;
  // Weekly report
  static const weeklyReportId = 500;
  // AI insights
  static const aiInsightId = 600;
  // Engagement
  static const engagementId = 700;

  /// Call once from main() before runApp.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // ── Timezone setup ─────────────────────────────────────────
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    // ── Android init ───────────────────────────────────────────
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // ── iOS / macOS init ───────────────────────────────────────
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // ── Register channels ──────────────────────────────────────
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      for (final channel in NVChannels.all) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  // ── Permission ────────────────────────────────────────────────
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // iOS requests permission at init time
  }

  // ── Schedule ──────────────────────────────────────────────────

  /// Schedule a daily repeating notification at [hour]:[minute].
  Future<void> scheduleDaily({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName(channelId),
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Schedule a notification with a big picture (food image).
  Future<void> scheduleDailyWithImage({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName(channelId),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Schedule a weekly notification (for weekly reports).
  Future<void> scheduleWeekly({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required int dayOfWeek, // 1=Mon ... 7=Sun
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayTime(dayOfWeek, hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName(channelId),
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  /// Show an immediate notification (for testing / ad-hoc).
  Future<void> showNow({
    required int id,
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName(channelId),
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: payload,
    );
  }

  /// Cancel a specific notification.
  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Cancel all notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Cancel a range of IDs (e.g. all hydration notifications).
  Future<void> cancelRange(int from, int to) async {
    for (var i = from; i <= to; i++) {
      await _plugin.cancel(i);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfDayTime(int dayOfWeek, int hour, int minute) {
    var dt = _nextInstanceOfTime(hour, minute);
    while (dt.weekday != dayOfWeek) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  String _channelName(String id) {
    for (final ch in NVChannels.all) {
      if (ch.id == id) return ch.name;
    }
    return 'Nutrimate';
  }

  static void _onTap(NotificationResponse response) {
    notificationTapStream.add(response.payload);
  }
}
