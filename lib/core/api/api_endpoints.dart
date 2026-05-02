import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // To override at run time, pass:
  //   --dart-define=NUTRIVITA_API_URL=http://<your-LAN-IP>:8080/v1
  // Physical Android device on USB? Either pass the LAN URL above, or run
  //   adb reverse tcp:8080 tcp:8080
  // and the device's localhost will hit the host machine.
  // The emulator helper 10.0.2.2 is only reachable from the Android emulator,
  // so we opt into it via ANDROID_EMULATOR=true rather than default to it.
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('NUTRIVITA_API_URL');
    if (configuredUrl.isNotEmpty) {
      return _withoutTrailingSlash(configuredUrl);
    }

    const isEmulator = bool.fromEnvironment(
      'ANDROID_EMULATOR',
      defaultValue: false, // Default to false so it uses production by default
    );
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        isEmulator) {
      return 'http://10.0.2.2:8080/v1';
    }

    // Default to the secure production VPS backend
    return 'https://api.nutrimateapp.com/v1';
  }

  static const signup = '/auth/signup';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';
  static const me = '/me';
  static const meProfile = '/me/profile';
  static const meAvatar = '/me/avatar';
  static const mePreferences = '/me/preferences';
  static const meOnboardingComplete = '/me/onboarding/complete';
  static const streak = '/me/streak';
  static const foods = '/foods';
  static const logs = '/logs';
  static const todayIntake = '/logs/today/intake';
  static const weekIntake = '/logs/week';
  static const favorites = '/favorites';
  static const reminders = '/reminders';
  static const recommendations = '/recommendations';
  static const notificationDevices = '/notifications/devices';
  static const notificationPreferences = '/notifications/preferences';
  static const aiMealPhotoAnalyze = '/ai/meal-photo/analyze';
  static const aiChat = '/ai/chat';

  static String food(String id) => '/foods/$id';
  static String log(String id) => '/logs/$id';
  static String favorite(String id) => '/favorites/$id';
  static String reminder(String id) => '/reminders/$id';
  static String notificationDevice(String id) => '/notifications/devices/$id';
  static String aiEstimate(String id) => '/ai/estimates/$id';
  static String acceptAiEstimate(String id) => '/ai/estimates/$id/accept';

  static String mediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || Uri.tryParse(trimmed)?.hasScheme == true) {
      return trimmed;
    }
    final base = Uri.parse(baseUrl);
    final origin = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
    );
    return origin.resolve(trimmed).toString();
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
