import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../providers/auth_provider.dart';

/// Typed wrapper around Firebase Analytics + Crashlytics user binding.
///
/// Phase 0 of the personalization roadmap: every behavior signal that the
/// learning recommendation engine will eventually consume is logged here.
/// Prefer adding a new typed method over calling `logEvent` from screens.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  bool _initialized = false;
  String? _boundUserId;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode || _forceInDebug);
  }

  // Set true via `--dart-define=ANALYTICS_DEBUG=true` to validate events
  // against the DebugView while developing.
  static const _forceInDebug = bool.fromEnvironment('ANALYTICS_DEBUG');

  /// Mirror auth state into Analytics + Crashlytics so events and crashes
  /// are attributable to a user without leaking PII (we only set the user id,
  /// never the email).
  void bindAuth(AuthProvider auth) {
    void apply() {
      final id = auth.user?.id;
      if (id == _boundUserId) return;
      _boundUserId = id;
      _analytics.setUserId(id: id);
      FirebaseCrashlytics.instance.setUserIdentifier(id ?? '');
    }

    apply();
    auth.addListener(apply);
  }

  // ── Lifecycle / nav ──────────────────────────────────────────────

  Future<void> screenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  // ── Search & discovery ──────────────────────────────────────────

  Future<void> foodSearched({required String query, int? resultCount}) {
    return _log('food_searched', {
      'query_length': query.length,
      if (resultCount != null) 'result_count': resultCount,
    });
  }

  Future<void> foodViewed({required String foodId, String? source}) {
    return _log('food_viewed', {
      'food_id': foodId,
      if (source != null) 'source': source,
    });
  }

  // ── Logging ─────────────────────────────────────────────────────

  Future<void> foodLogged({
    required String foodId,
    required String mealType,
    String? source,
  }) {
    return _log('food_logged', {
      'food_id': foodId,
      'meal_type': mealType,
      if (source != null) 'source': source,
    });
  }

  Future<void> mealPhotoAnalyzed({required int itemCount, double? confidence}) {
    return _log('meal_photo_analyzed', {
      'item_count': itemCount,
      if (confidence != null) 'confidence': confidence,
    });
  }

  // ── Recommendations ─────────────────────────────────────────────

  Future<void> recommendationShown({
    required String foodId,
    required String surface,
    required String nutrientCode,
  }) {
    return _log('recommendation_shown', {
      'food_id': foodId,
      'surface': surface,
      'nutrient_code': nutrientCode,
    });
  }

  Future<void> recommendationAccepted({
    required String foodId,
    required String surface,
  }) {
    return _log('recommendation_accepted', {
      'food_id': foodId,
      'surface': surface,
    });
  }

  Future<void> recommendationRejected({
    required String foodId,
    required String surface,
    String? reason,
  }) {
    return _log('recommendation_rejected', {
      'food_id': foodId,
      'surface': surface,
      if (reason != null) 'reason': reason,
    });
  }

  // ── Streak ──────────────────────────────────────────────────────

  Future<void> streakKept({required int days}) {
    return _log('streak_kept', {'days': days});
  }

  Future<void> streakLost({required int days}) {
    return _log('streak_lost', {'days': days});
  }

  // ── Internal ────────────────────────────────────────────────────

  Future<void> _log(String name, Map<String, Object?> params) {
    final clean = <String, Object>{};
    params.forEach((key, value) {
      if (value != null) clean[key] = value;
    });
    return _analytics.logEvent(name: name, parameters: clean);
  }
}
