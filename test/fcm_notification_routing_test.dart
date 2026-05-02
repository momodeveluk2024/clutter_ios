import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/notifications/fcm_notification_router.dart';

void main() {
  test('recommendation payload opens the recommended food', () {
    final route = FcmNotificationRouter.routeForData({
      'type': 'recommendation',
      'food_id': '018f0000-0000-7000-8002-000000000001',
    });

    expect(route, '/app/food/018f0000-0000-7000-8002-000000000001');
  });

  test('explicit route wins for backend payloads', () {
    final route = FcmNotificationRouter.routeForData({
      'type': 'weekly_summary',
      'route': '/app?tab=track',
    });

    expect(route, '/app?tab=track');
  });

  test('unknown payload falls back to app home', () {
    final route = FcmNotificationRouter.routeForData({'type': 'unknown'});

    expect(route, '/app');
  });
}
