import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Thin wrapper around POST /v1/interactions and the recommendation
/// feedback endpoint. Phase 0 of the personalization roadmap puts the
/// recording side here so screens don't need to know URL shapes.
///
/// Fire-and-forget: failures are intentionally swallowed because losing
/// one analytics event must never break a user-visible flow.
class InteractionsService {
  InteractionsService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<void> recordSearched({
    required String foodId,
    String? source,
    String? query,
  }) =>
      _record(
        foodId: foodId,
        action: 'searched',
        source: source ?? 'search',
        metadata: {if (query != null) 'query': query},
      );

  Future<void> recordViewed({required String foodId, String? source}) =>
      _record(foodId: foodId, action: 'viewed', source: source);

  Future<void> recordLogged({
    required String foodId,
    required String mealType,
    String? source,
  }) =>
      _record(
        foodId: foodId,
        action: 'logged',
        source: source,
        metadata: {'meal_type': mealType},
      );

  Future<void> recordFavorited({required String foodId}) =>
      _record(foodId: foodId, action: 'favorited');

  Future<void> recordUnfavorited({required String foodId}) =>
      _record(foodId: foodId, action: 'unfavorited');

  Future<void> sendRecommendationFeedback({
    required String eventId,
    required String outcome, // accepted | rejected | dismissed
    String? reason,
  }) async {
    try {
      await _api.post(
        ApiEndpoints.recommendationFeedback(eventId),
        data: {'outcome': outcome, if (reason != null) 'reason': reason},
      );
    } catch (_) {}
  }

  Future<void> _record({
    required String foodId,
    required String action,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _api.post(
        ApiEndpoints.interactions,
        data: {
          'food_id': foodId,
          'action': action,
          if (source != null) 'source': source,
          if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        },
      );
    } catch (_) {}
  }
}
