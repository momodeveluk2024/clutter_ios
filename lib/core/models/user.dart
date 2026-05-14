import 'dart:convert';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.units,
    required this.locale,
    required this.timezone,
    this.avatarUrl,
    this.emailVerifiedAt,
    this.sex,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.pregnancyStatus,
    this.dietaryPattern,
    this.allergens = const [],
    this.goals = const [],
    this.preferences = const {},
    this.onboardingCompletedAt,
    this.needsOnboarding = false,
    this.metabolicTargets,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String units;
  final String locale;
  final String timezone;
  final DateTime? emailVerifiedAt;
  final String? sex;
  final String? dateOfBirth;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? pregnancyStatus;
  final String? dietaryPattern;
  final List<String> allergens;
  final List<String> goals;
  final Map<String, dynamic> preferences;
  final DateTime? onboardingCompletedAt;
  final bool needsOnboarding;
  final MetabolicTargets? metabolicTargets;

  bool get isEmailVerified => emailVerifiedAt != null;
  String get appearance => preferences['appearance'] as String? ?? 'light';

  String get goalsSummary => goals.isEmpty ? 'Set goals' : goals.join(' - ');

  String get dietSummary {
    final pattern = dietaryPattern?.trim();
    if (pattern != null && pattern.isNotEmpty) return pattern;
    return 'Set preferences';
  }

  String get remindersSummary => 'Manage';

  String get unitsLabel => units == 'imperial' ? 'Imperial' : 'Metric';

  String get appearanceLabel {
    return switch (appearance) {
      'dark' => 'Dark',
      'system' => 'System',
      _ => 'Light',
    };
  }

  String get bodySummary {
    final pieces = <String>[];
    final sexLabel = switch (sex) {
      'female' => 'F',
      'male' => 'M',
      'other' => 'Other',
      _ => null,
    };
    if (sexLabel != null) pieces.add(sexLabel);
    final age = _age;
    if (age != null) pieces.add('$age');
    if (heightCm != null) pieces.add('${heightCm!.round()} cm');
    return pieces.isEmpty ? 'Add details' : pieces.join(', ');
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? 'Friend',
      avatarUrl: json['avatar_url'] as String?,
      units: json['units'] as String? ?? 'metric',
      locale: json['locale'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'UTC',
      sex: json['sex'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      heightCm: _toDouble(json['height_cm']),
      weightKg: _toDouble(json['weight_kg']),
      activityLevel: json['activity_level'] as String?,
      pregnancyStatus: json['pregnancy_status'] as String?,
      dietaryPattern: json['dietary_pattern'] as String?,
      allergens: _stringList(json['allergens']),
      goals: _stringList(json['goals']),
      preferences: _preferences(json['preferences']),
      onboardingCompletedAt: json['onboarding_completed_at'] == null
          ? null
          : DateTime.tryParse(json['onboarding_completed_at'] as String),
      needsOnboarding: json['needs_onboarding'] as bool? ?? false,
      metabolicTargets: json['metabolic_targets'] is Map
          ? MetabolicTargets.fromJson(
              Map<String, dynamic>.from(json['metabolic_targets'] as Map))
          : null,
      emailVerifiedAt: json['email_verified_at'] == null
          ? null
          : DateTime.tryParse(json['email_verified_at'] as String),
    );
  }

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  int? get _age {
    final value = dateOfBirth;
    if (value == null || value.isEmpty) return null;
    final birthDate = DateTime.tryParse(value);
    if (birthDate == null) return null;
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    final hadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age < 0 ? null : age;
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  static Map<String, dynamic> _preferences(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      final decoded = _decodePreferencesString(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return const {};
  }

  static Object? _decodePreferencesString(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      try {
        return jsonDecode(utf8.decode(base64Decode(value)));
      } catch (_) {
        return null;
      }
    }
  }
}

/// Server-computed daily energy and macronutrient targets.
/// Derived from the Mifflin-St Jeor BMR equation on the backend.
class MetabolicTargets {
  const MetabolicTargets({
    required this.bmrKcal,
    required this.tdeeKcal,
    required this.goalKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.formula = 'mifflin_st_jeor',
    this.goalAdjustment = 0,
  });

  final double bmrKcal;
  final double tdeeKcal;
  final double goalKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String formula;
  final double goalAdjustment;

  factory MetabolicTargets.fromJson(Map<String, dynamic> json) {
    return MetabolicTargets(
      bmrKcal: (json['bmr_kcal'] as num?)?.toDouble() ?? 0,
      tdeeKcal: (json['tdee_kcal'] as num?)?.toDouble() ?? 0,
      goalKcal: (json['goal_kcal'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      formula: json['formula'] as String? ?? 'mifflin_st_jeor',
      goalAdjustment: (json['goal_adjustment'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Whether the user is in a caloric deficit (losing weight).
  bool get isDeficit => goalAdjustment < 0;

  /// Whether the user is in a caloric surplus (gaining weight/muscle).
  bool get isSurplus => goalAdjustment > 0;

  /// Human-readable goal description.
  String get goalLabel {
    if (isDeficit) return 'Lose weight';
    if (isSurplus) return 'Gain weight';
    return 'Maintain weight';
  }
}
