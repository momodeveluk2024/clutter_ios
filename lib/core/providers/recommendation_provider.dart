import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../services/interactions_service.dart';

class RecommendationCard {
  RecommendationCard({
    required this.code,
    required this.name,
    required this.message,
    required this.foodId,
    required this.foodName,
    this.foodImageUrl,
    this.percent,
    this.eventId,
  });

  final String code;
  final String name;
  final String message;
  final double? percent;
  final String foodId;
  final String foodName;
  final String? foodImageUrl;
  final String? eventId;

  factory RecommendationCard.fromJson(Map<String, dynamic> json) {
    return RecommendationCard(
      code: json['code'] as String,
      name: json['name'] as String,
      message: json['message'] as String,
      percent: (json['percent'] as num?)?.toDouble(),
      foodId: json['food_id'] as String,
      foodName: json['food_name'] as String,
      foodImageUrl: json['food_image_url'] as String?,
      eventId: json['event_id'] as String?,
    );
  }
}

/// Provider for the home-screen recommendations list. Owns:
///   - fetching from GET /v1/recommendations,
///   - feedback dispatch to /v1/recommendations/{eventID}/feedback,
///   - local optimistic removal so a thumbs-down hides the card immediately.
class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({
    required ApiClient api,
    required InteractionsService interactions,
  })  : _api = api,
        _interactions = interactions;

  final ApiClient _api;
  final InteractionsService _interactions;

  List<RecommendationCard> recommendations = const [];
  bool isLoading = false;
  String? error;

  Future<void> load({String? date}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(
        ApiEndpoints.recommendations,
        query: {if (date != null) 'date': date},
      );
      final list = (response.data['recommendations'] as List? ?? const [])
          .map((v) => RecommendationCard.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      recommendations = list;
      for (final r in list) {
        AnalyticsService.instance.recommendationShown(
          foodId: r.foodId,
          surface: 'home_recommendations',
          nutrientCode: r.code,
        );
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> accept(RecommendationCard card) async {
    AnalyticsService.instance.recommendationAccepted(
      foodId: card.foodId,
      surface: 'home_recommendations',
    );
    if (card.eventId != null) {
      await _interactions.sendRecommendationFeedback(
        eventId: card.eventId!,
        outcome: 'accepted',
      );
    }
  }

  Future<void> reject(RecommendationCard card, {String? reason}) async {
    AnalyticsService.instance.recommendationRejected(
      foodId: card.foodId,
      surface: 'home_recommendations',
      reason: reason,
    );
    recommendations =
        recommendations.where((r) => r.foodId != card.foodId).toList();
    notifyListeners();
    if (card.eventId != null) {
      await _interactions.sendRecommendationFeedback(
        eventId: card.eventId!,
        outcome: 'rejected',
        reason: reason,
      );
    }
  }
}
