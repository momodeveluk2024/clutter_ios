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
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is optional in local/dev builds until config files are added.
  }
}

class FcmNotificationService {
  FcmNotificationService._();
  static final instance = FcmNotificationService._();

  static const _deviceIdKey = 'nv_push_device_id';

  ApiClient? _api;
  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedSub;
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
    } catch (_) {
      _available = false;
      return;
    }

    FirebaseMessaging.onBackgroundMessage(
      nutrimateFirebaseMessagingBackgroundHandler,
    );

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    final messaging = _messaging;
    if (messaging == null) return;

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
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = tokenOverride ?? await messaging.getToken();
    if (token == null || token.isEmpty) return;

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
  }

  void _handleMessage(RemoteMessage message) {
    notificationTapStream.add(FcmNotificationRouter.routeForData(message.data));
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
