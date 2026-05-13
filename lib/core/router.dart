import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/app_shell.dart';
import '../screens/ai_chat.dart';
import '../screens/ai_meal_photo.dart';
import '../screens/food_detail.dart';
import '../screens/notification_settings.dart';
import '../screens/onboarding.dart';
import '../screens/password_reset.dart';
import '../screens/profile_settings.dart';
import '../screens/profile_setup.dart';
import '../screens/search.dart';
import '../screens/barcode_scan.dart';
import '../screens/barcode_contribute.dart';
import '../screens/sign_in.dart';
import '../screens/sign_up.dart';
import '../screens/splash.dart';
import '../screens/intro_video.dart';
import '../screens/my_meal_edit.dart';
import '../screens/verify_email.dart';
import '../screens/vitamin_detail.dart';
import 'providers/auth_provider.dart';

const _authPages = {
  '/',
  '/welcome',
  '/onboarding',
  '/sign-up',
  '/sign-in',
  '/forgot-password',
  '/reset-password',
};

String? redirectForAuthState({
  required String path,
  required bool initialized,
  required bool isAuthenticated,
  required bool needsOnboarding,
  required bool needsEmailVerification,
}) {
  if (!initialized) {
    return path == '/' ? null : '/';
  }
  if (!isAuthenticated &&
      (path.startsWith('/app') || path == '/profile-setup' || path == '/verify-email')) {
    return '/sign-in';
  }
  if (!isAuthenticated) {
    return null;
  }
  // Redirect unverified email/password users to verification screen
  if (needsEmailVerification && path != '/verify-email') {
    if (path.startsWith('/app') || _authPages.contains(path) || path == '/profile-setup') {
      return '/verify-email';
    }
  }
  // If on verify-email but already verified, proceed normally
  if (!needsEmailVerification && path == '/verify-email') {
    return needsOnboarding ? '/profile-setup' : '/app';
  }
  if (needsOnboarding && path != '/profile-setup') {
    if (path.startsWith('/app') || _authPages.contains(path)) {
      return '/profile-setup';
    }
  }
  if (!needsOnboarding && path == '/profile-setup') {
    return '/app';
  }
  if (_authPages.contains(path)) {
    return needsOnboarding ? '/profile-setup' : '/app';
  }
  return null;
}

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      return redirectForAuthState(
        path: path,
        initialized: auth.initialized,
        isAuthenticated: auth.isAuthenticated,
        needsOnboarding: auth.user?.needsOnboarding ?? false,
        needsEmailVerification: auth.needsEmailVerification,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const IntroVideoScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) => AppShell(
          initialTab: switch (state.uri.queryParameters['tab']) {
            'explore' => 1,
            'track' => 2,
            'saved' => 3,
            'you' => 4,
            _ => 0,
          },
          startTour: state.uri.queryParameters['tour'] == '1',
        ),
      ),
      GoRoute(
        path: '/app/search',
        builder: (context, state) => SearchScreen(
          initialCategory: state.uri.queryParameters['category'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/barcode-scan',
        builder: (context, state) => const BarcodeScanScreen(),
      ),
      GoRoute(
        path: '/app/barcode-scan/contribute',
        builder: (context, state) {
          final barcode = state.extra as String?;
          return BarcodeContributeScreen(barcode: barcode ?? '');
        },
      ),
      GoRoute(
        path: '/app/explore',
        builder: (context, state) => const AppShell(initialTab: 1),
      ),
      GoRoute(
        path: '/app/tracker',
        builder: (context, state) => const AppShell(initialTab: 2),
      ),
      GoRoute(
        path: '/app/ai/meal-photo',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, String>) {
            return const _MissingAiPhotoScreen();
          }
          final imagePath = extra['imagePath'];
          final mealType = extra['mealType'];
          final loggedOn = extra['loggedOn'];
          if (imagePath == null || mealType == null || loggedOn == null) {
            return const _MissingAiPhotoScreen();
          }
          return AiMealPhotoScreen(
            imagePath: imagePath,
            mealType: mealType,
            loggedOn: loggedOn,
          );
        },
      ),
      GoRoute(
        path: '/app/ai/chat',
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(
        path: '/app/saved',
        builder: (context, state) => const AppShell(initialTab: 3),
      ),
      GoRoute(
        path: '/app/profile',
        builder: (context, state) => const AppShell(initialTab: 4),
      ),
      GoRoute(
        path: '/app/food/:id',
        builder: (context, state) =>
            FoodDetailScreen(foodId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/app/vitamin/:code',
        builder: (context, state) =>
            VitaminDetailScreen(code: state.pathParameters['code'] ?? 'D'),
      ),
      GoRoute(
        path: '/app/my-meal/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return MyMealEditScreen(mealId: id == 'new' ? null : id);
        },
      ),
      GoRoute(
        path: '/app/profile/goals',
        builder: (context, state) => const ProfileGoalsScreen(),
      ),
      GoRoute(
        path: '/app/profile/body',
        builder: (context, state) => const ProfileBodyScreen(),
      ),
      GoRoute(
        path: '/app/profile/diet',
        builder: (context, state) => const ProfileDietScreen(),
      ),
      GoRoute(
        path: '/app/profile/reminders',
        builder: (context, state) => const ProfileRemindersScreen(),
      ),
      GoRoute(
        path: '/app/profile/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/app/profile/units',
        builder: (context, state) => const ProfileUnitsScreen(),
      ),
      GoRoute(
        path: '/app/profile/appearance',
        builder: (context, state) => const ProfileAppearanceScreen(),
      ),
      GoRoute(
        path: '/app/profile/about',
        builder: (context, state) => const ProfileAboutScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error?.message ?? 'Route not found')),
    ),
  );
}

class _MissingAiPhotoScreen extends StatelessWidget {
  const _MissingAiPhotoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI meal estimate')),
      body: const Center(child: Text('Choose a meal photo first.')),
    );
  }
}
