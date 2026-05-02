class FcmNotificationRouter {
  const FcmNotificationRouter._();

  static String routeForData(Map<String, dynamic> data) {
    final explicitRoute = data['route']?.toString().trim();
    if (explicitRoute != null && explicitRoute.isNotEmpty) {
      return explicitRoute;
    }

    final type = data['type']?.toString();
    switch (type) {
      case 'recommendation':
        final foodId = data['food_id']?.toString().trim();
        if (foodId != null && foodId.isNotEmpty) {
          return '/app/food/$foodId';
        }
        return '/app';
      case 'weekly_summary':
        return '/app?tab=track';
      case 'ai_insight':
        return '/app/ai/chat';
      default:
        return '/app';
    }
  }
}
