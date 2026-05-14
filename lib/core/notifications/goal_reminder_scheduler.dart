/// Schedules the daily 20:00 "how's your goal going?" reminder.
///
/// Why: the user can't keep their daily kcal target in their head, so a single
/// nudge near the end of the day (before final meal / snack decisions) is the
/// cheapest way to keep tracking honest. We deliberately fire once per day,
/// not throughout — extra notifications get muted fast.
///
/// When: every day at 20:00 local time (re-armed by the OS until cancelled).
///
/// How: piggybacks on the existing local-notification infrastructure
/// (`NotificationService`). No FCM round trip — the message is built on-device
/// from the current `MetabolicTargets`, so there's no privacy cost and the
/// reminder works offline.
library;

import '../models/user.dart';
import 'notification_channels.dart';
import 'notification_service.dart';

class GoalReminderScheduler {
  static const _id = NotificationService.nutrientTipId;
  static const _hour = 20;
  static const _minute = 0;

  /// Schedule (or cancel) the daily goal-progress reminder. Pass the user's
  /// current targets — when null or zero we cancel instead of scheduling so we
  /// never fire an empty "Today's progress: 0 / 0 kcal" notification.
  static Future<void> scheduleFor(MetabolicTargets? targets) async {
    final kcal = targets?.goalKcal ?? 0;
    if (kcal <= 0) {
      await NotificationService.instance.cancel(_id);
      return;
    }
    await NotificationService.instance.scheduleDaily(
      id: _id,
      channelId: NVChannels.nutrientTips,
      title: "How's today going?",
      body: 'Your target is ${kcal.round()} kcal — open Nutrimate to log '
          'anything you ate this evening.',
      hour: _hour,
      minute: _minute,
      payload: 'goal_progress',
    );
  }

  /// Cancel without rescheduling. Used when the user clears their goal or
  /// signs out.
  static Future<void> cancel() =>
      NotificationService.instance.cancel(_id);
}
