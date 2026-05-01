import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/models/reminder.dart';
import 'package:myapplication/core/models/user.dart';

void main() {
  test('AppUser parses editable profile and preference fields', () {
    final user = AppUser.fromJson({
      'id': '019dc1d3-dd22-7cea-85d3-7f8946adde90',
      'email': 'ahmed@gmail.com',
      'display_name': 'ahmed',
      'avatar_url': '/uploads/avatars/ahmed/profile.png',
      'email_verified_at': null,
      'sex': 'female',
      'date_of_birth': '1998-04-25',
      'height_cm': 165.0,
      'weight_kg': 62.5,
      'activity_level': 'moderate',
      'pregnancy_status': 'none',
      'dietary_pattern': 'Pescatarian',
      'allergens': ['peanuts'],
      'goals': ['Immunity', 'Energy'],
      'units': 'metric',
      'locale': 'en',
      'timezone': 'Asia/Baghdad',
      'preferences': {'appearance': 'dark'},
      'onboarding_completed_at': '2026-04-30T00:00:00Z',
      'needs_onboarding': false,
    });

    expect(user.sex, 'female');
    expect(user.avatarUrl, '/uploads/avatars/ahmed/profile.png');
    expect(user.dateOfBirth, '1998-04-25');
    expect(user.heightCm, 165.0);
    expect(user.weightKg, 62.5);
    expect(user.activityLevel, 'moderate');
    expect(user.pregnancyStatus, 'none');
    expect(user.dietaryPattern, 'Pescatarian');
    expect(user.allergens, ['peanuts']);
    expect(user.goals, ['Immunity', 'Energy']);
    expect(user.appearance, 'dark');
    expect(user.onboardingCompletedAt, DateTime.parse('2026-04-30T00:00:00Z'));
    expect(user.needsOnboarding, isFalse);
    expect(user.bodySummary, 'F, 28, 165 cm');
    expect(user.goalsSummary, 'Immunity - Energy');
  });

  test('AppUser marks new signups as needing onboarding', () {
    final user = AppUser.fromJson({
      'id': '019dc1d3-dd22-7cea-85d3-7f8946adde92',
      'email': 'new@gmail.com',
      'display_name': 'New User',
      'units': 'metric',
      'locale': 'en',
      'timezone': 'Asia/Baghdad',
      'preferences': <String, dynamic>{},
      'onboarding_completed_at': null,
      'needs_onboarding': true,
    });

    expect(user.onboardingCompletedAt, isNull);
    expect(user.needsOnboarding, isTrue);
  });

  test('Reminder parses API response', () {
    final reminder = Reminder.fromJson({
      'id': '019dc1d3-dd22-7cea-85d3-7f8946adde91',
      'title': 'Log dinner',
      'body': 'Remember your minerals',
      'remind_at': '2026-04-25T19:00:00Z',
      'timezone': 'Asia/Baghdad',
      'enabled': true,
    });

    expect(reminder.title, 'Log dinner');
    expect(reminder.body, 'Remember your minerals');
    expect(reminder.enabled, isTrue);
  });
}
