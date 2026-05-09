import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'fcm_notification_router.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> nutrimateFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  debugPrint('[FCM-BG] background message received: ${message.messageId}');
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is optional in local/dev builds until config files are added.
  }
  // Background messages that have a notification payload are handled by the
  // system tray automatically. Data-only messages land here but there's
  // nothing we need to do — the system channel meta-data in the manifest
  // ensures they display.
}

class FcmNotificationService {
  FcmNotificationService._();
  static final instance = FcmNotificationService._();

  static const _deviceIdKey = 'nv_push_device_id';

  ApiClient? _api;
  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  bool _initialized = false;
  bool _available = false;
  String? _pendingRoute;

  bool get available => _available;

  Future<void> initialize({required ApiClient api}) async {
    _api = api;
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      _available = true;
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('[FCM] Firebase init failed: $e');
      _available = false;
      return;
    }

    // Request permission early — on MIUI/Xiaomi and Android 13+ this is
    // required before any notification (local or FCM) can be displayed.
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] permission status: ${settings.authorizationStatus}');

    // On Android, ensure foreground messages can show heads-up banners.
    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(
      nutrimateFirebaseMessagingBackgroundHandler,
    );

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Android (and iOS) hand foreground pushes to the app instead of
    // showing them automatically — without this listener the user sees
    // nothing while they're in the app, even when the test push button
    // succeeds. Re-present each foreground message via
    // flutter_local_notifications so the heads-up banner appears.
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);

    final messaging = _messaging;
    if (messaging == null) return;

    final token = await messaging.getToken();
    debugPrint('[FCM] device token: ${token?.substring(0, 20)}...');

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingRoute = FcmNotificationRouter.routeForData(initialMessage.data);
    }
    _tokenRefreshSub = messaging.onTokenRefresh.listen(
      (token) => registerCurrentDevice(tokenOverride: token),
    );
  }

  Future<void> registerCurrentDevice({String? tokenOverride}) async {
    if (!_available || _api == null) return;
    final messaging = _messaging;
    if (messaging == null) return;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] permission denied — cannot register device');
      return;
    }

    final token = tokenOverride ?? await messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[FCM] token is null/empty — cannot register device');
      return;
    }

    debugPrint('[FCM] registering device with token ${token.substring(0, 20)}...');
    final deviceID = await _deviceID();
    await _api!.post(
      ApiEndpoints.notificationDevices,
      data: {
        'device_id': deviceID,
        'fcm_token': token,
        'platform': _platformName(),
        'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
        'timezone': DateTime.now().timeZoneName,
      },
    );
  }

  Future<void> disableCurrentDevice() async {
    if (_api == null) return;
    final deviceID = await _deviceID();
    await _api!.delete(ApiEndpoints.notificationDevice(deviceID));
  }

  String? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _openedSub?.cancel();
    await _foregroundSub?.cancel();
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('[FCM] onMessageOpenedApp: ${message.data}');
    notificationTapStream.add(FcmNotificationRouter.routeForData(message.data));
  }

  // Re-present a push that arrived while the app is in the foreground.
  // On Android, FCM does NOT auto-show a heads-up banner when the app is
  // foregrounded, so we re-display via flutter_local_notifications.
  //
  // Handles both:
  //   • notification+data messages (notification.title/body populated)
  //   • data-only messages (only message.data populated — e.g. server test)
  void _handleForeground(RemoteMessage message) {
    debugPrint('[FCM] foreground message received: '
        'notification=${message.notification?.title}, '
        'data=${message.data}');

    // Try notification payload first, then fall back to data fields.
    final notification = message.notification;
    String? title = notification?.title?.trim();
    String? body = notification?.body?.trim();

    // Data-only fallback: the server test push sends title/body in the
    // notification envelope, but some OEMs strip it. Also handles
    // future data-only messages.
    if ((title == null || title.isEmpty) && message.data.containsKey('title')) {
      title = (message.data['title'] as String?)?.trim();
    }
    if ((body == null || body.isEmpty) && message.data.containsKey('body')) {
      body = (message.data['body'] as String?)?.trim();
    }

    // Last resort: if we still have nothing displayable, use a generic
    // message so the user at least sees *something* arrived.
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      debugPrint('[FCM] foreground message dropped — no displayable content');
      return;
    }

    // Pick a channel: high-priority for calorie alerts / test, default for others.
    final type = message.data['type']?.toString() ?? '';
    final channelId = (type == 'low_calorie' || type == 'test' || type == 'test_push')
        ? 'meal_reminders'
        : 'engagement';

    debugPrint('[FCM] showing foreground notification: title=$title, channel=$channelId');
    NotificationService.instance.showNow(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      channelId: channelId,
      title: (title != null && title.isNotEmpty) ? title : 'Nutrimate',
      body: body ?? '',
      payload: FcmNotificationRouter.routeForData(message.data),
    );
  }

  Future<String> _deviceID() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };
  }
}
