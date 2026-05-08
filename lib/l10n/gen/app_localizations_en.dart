// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nutrimate';

  @override
  String get yourUsuals => 'Your usuals';

  @override
  String get recentlyLogged => 'Recently logged';

  @override
  String suggestedFor(String mealType) {
    return 'Suggested for $mealType';
  }

  @override
  String get logMeal => 'Log meal';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Your account will be scheduled for deletion. Sign in within 30 days to recover.';

  @override
  String get weeklyRecapTitle => 'Your week in nutrients';

  @override
  String streakDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }
}
