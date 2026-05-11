import 'package:package_info_plus/package_info_plus.dart';

/// The app's version string (e.g. "1.1.2"), read from the platform bundle —
/// i.e. the `version:` field in pubspec.yaml — and cached after the first read.
///
/// Call [warmAppVersion] once during startup (before `runApp`) so the
/// synchronous [appVersion] getter returns the real value everywhere it is
/// shown (About screen, settings footer, …) instead of a stale literal.
String _version = '';

Future<void> warmAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) _version = info.version;
  } catch (_) {
    // Leave it empty; call sites degrade gracefully.
  }
}

/// The cached app version, or an empty string if [warmAppVersion] has not
/// completed yet. Since it runs at startup this is effectively always set by
/// the time any screen renders.
String get appVersion => _version;
