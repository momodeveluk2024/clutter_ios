import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/router.dart';

void main() {
  test(
    'new authenticated users are routed to profile setup until complete',
    () {
      expect(
        redirectForAuthState(
          path: '/app',
          initialized: true,
          isAuthenticated: true,
          needsOnboarding: true,
        ),
        '/profile-setup',
      );
    },
  );

  test('completed users are not routed back to profile setup on login', () {
    expect(
      redirectForAuthState(
        path: '/sign-in',
        initialized: true,
        isAuthenticated: true,
        needsOnboarding: false,
      ),
      '/app',
    );
    expect(
      redirectForAuthState(
        path: '/app',
        initialized: true,
        isAuthenticated: true,
        needsOnboarding: false,
      ),
      isNull,
    );
  });

  test(
    'legacy incomplete users are not gated when backend says setup is done',
    () {
      expect(
        redirectForAuthState(
          path: '/app',
          initialized: true,
          isAuthenticated: true,
          needsOnboarding: false,
        ),
        isNull,
      );
    },
  );

  test('profile setup is authenticated-only', () {
    expect(
      redirectForAuthState(
        path: '/profile-setup',
        initialized: true,
        isAuthenticated: false,
        needsOnboarding: false,
      ),
      '/sign-in',
    );
  });
}
