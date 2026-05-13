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
      case 'weekly_recap':
        return '/app?tab=track';
      case 'ai_insight':
        return '/app/ai/chat';
      case 'low_calorie':
      case 'no_meal_today':
      case 'low_protein':
      case 'missed_meal':
        return '/app?tab=track';
      case 'low_water':
      case 'lapsed_user':
      case 'test':
        return '/app';
      default:
        return '/app';
    }
  }
}

