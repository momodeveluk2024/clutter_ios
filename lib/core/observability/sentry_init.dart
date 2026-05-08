import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Initialize Sentry. Crashlytics already covers native fatal crashes; Sentry
/// adds Dart breadcrumbs, performance traces, and structured exception
/// reports the support team can search by user_id. Phase 3 launch readiness.
///
/// Set the DSN with `--dart-define=SENTRY_DSN=https://...@sentry.io/...`.
/// In debug we point at no DSN, so events are dropped — matches Crashlytics
/// behavior in main.dart.
class SentryInit {
  static const _dsn = String.fromEnvironment('SENTRY_DSN');

  static Future<void> run(Future<void> Function() runApp) async {
    if (_dsn.isEmpty || kDebugMode) {
      await runApp();
      return;
    }
    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.tracesSampleRate = 0.1;
        options.attachScreenshot = false;
        options.sendDefaultPii = false;
      },
      appRunner: runApp,
    );
  }

  static Future<void> setUser(String? userId) async {
    await Sentry.configureScope((scope) {
      scope.setUser(userId == null ? null : SentryUser(id: userId));
    });
  }
}
