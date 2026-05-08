import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Throttled in-app review prompt. Phase 3 launch readiness.
///
/// Apple/Google rate-limit the native dialog (max ~3 prompts per year on
/// iOS; once-per-fortnight on Android), but the API never tells us the
/// outcome — so we still need our own throttle: at most one request every
/// 90 days, and only after a positive moment (3-day streak hit, week's
/// first DRI 100%, accepted recommendation, etc).
///
/// Call [maybePrompt] from the moments above; it's a no-op when too soon.
class ReviewPromptService {
  ReviewPromptService._();
  static final ReviewPromptService instance = ReviewPromptService._();

  static const _lastPromptKey = 'review_prompt.last_at';
  static const _minIntervalDays = 90;

  Future<void> maybePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastPromptKey);
    if (lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (DateTime.now().difference(last).inDays < _minIntervalDays) return;
    }
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return;
    await review.requestReview();
    await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
  }
}
