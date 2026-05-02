import '../storage/notification_prefs.dart';
import 'notification_channels.dart';
import 'notification_service.dart';

class NotificationScheduler {
  NotificationScheduler._();
  static final instance = NotificationScheduler._();

  final _svc = NotificationService.instance;

  Future<void> rescheduleAll() async {
    await _scheduleMealReminders();
    await _scheduleStreakAlert();
    await _scheduleHydration();
    await _cancelBackendManagedNotifications();
  }

  Future<void> _cancelBackendManagedNotifications() async {
    await _svc.cancel(NotificationService.nutrientTipId);
    await _svc.cancel(NotificationService.weeklyReportId);
    await _svc.cancel(NotificationService.aiInsightId);
  }

  Future<void> _scheduleMealReminders() async {
    final enabled = await NotificationPrefs.getMealReminders();
    if (!enabled) {
      await _svc.cancel(NotificationService.breakfastId);
      await _svc.cancel(NotificationService.lunchId);
      await _svc.cancel(NotificationService.dinnerId);
      return;
    }

    final breakfast = await NotificationPrefs.getBreakfastTime();
    final lunch = await NotificationPrefs.getLunchTime();
    final dinner = await NotificationPrefs.getDinnerTime();

    await _svc.scheduleDaily(
      id: NotificationService.breakfastId,
      channelId: NVChannels.mealReminders,
      title: 'Time for breakfast',
      body: 'Start your day right - log your morning meal.',
      hour: breakfast.hour,
      minute: breakfast.minute,
      payload: '/app/search',
    );
    await _svc.scheduleDaily(
      id: NotificationService.lunchId,
      channelId: NVChannels.mealReminders,
      title: 'Lunch time',
      body: 'Log your midday meal so your nutrient picture stays current.',
      hour: lunch.hour,
      minute: lunch.minute,
      payload: '/app/search',
    );
    await _svc.scheduleDaily(
      id: NotificationService.dinnerId,
      channelId: NVChannels.mealReminders,
      title: 'Dinner reminder',
      body: "Log your evening meal to complete today's nutrient picture.",
      hour: dinner.hour,
      minute: dinner.minute,
      payload: '/app/search',
    );
  }

  Future<void> _scheduleStreakAlert() async {
    final enabled = await NotificationPrefs.getStreakAlerts();
    if (!enabled) {
      await _svc.cancel(NotificationService.streakId);
      return;
    }

    await _svc.scheduleDaily(
      id: NotificationService.streakId,
      channelId: NVChannels.streakUpdates,
      title: "Don't break your streak",
      body: "Have you logged all your meals today? Keep your streak alive.",
      hour: 19,
      minute: 0,
      payload: '/app',
    );
  }

  Future<void> _scheduleHydration() async {
    final enabled = await NotificationPrefs.getHydration();
    await _svc.cancelRange(
      NotificationService.hydrationBaseId,
      NotificationService.hydrationBaseId + 20,
    );
    if (!enabled) return;

    const messages = [
      'Start your morning with a glass of water.',
      'Time for a hydration break.',
      'Stay hydrated - grab some water.',
      'Midday water check.',
      'Afternoon hydration reminder.',
      'Evening water break.',
      'Last hydration reminder - finish strong today.',
    ];

    for (var i = 0; i < messages.length; i++) {
      await _svc.scheduleDaily(
        id: NotificationService.hydrationBaseId + i,
        channelId: NVChannels.hydration,
        title: 'Hydration reminder',
        body: messages[i],
        hour: 8 + (i * 2),
        minute: 0,
        payload: '/app',
      );
    }
  }
}
