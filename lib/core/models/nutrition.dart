class NutrientTotal {
  const NutrientTotal({
    required this.code,
    required this.name,
    required this.unit,
    required this.amount,
    this.driAmount,
    this.driPercent,
    this.role = 'meet',
  });

  final String code;
  final String name;
  final String unit;
  final double amount;
  final double? driAmount;
  final double? driPercent;
  // 'meet' = reaching DRI is good (vitamins, minerals, protein).
  // 'limit' = staying under DRI is good (sodium); going over hurts the score.
  final String role;

  bool get isLimit => role == 'limit';

  factory NutrientTotal.fromJson(Map<String, dynamic> json) {
    return NutrientTotal(
      code: json['code'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      driAmount: (json['dri_amount'] as num?)?.toDouble(),
      driPercent: (json['dri_percent'] as num?)?.toDouble(),
      role: json['role'] as String? ?? 'meet',
    );
  }
}

class DayNutrientTotals {
  const DayNutrientTotals({required this.date, required this.nutrients});

  final String date;
  final List<NutrientTotal> nutrients;

  factory DayNutrientTotals.fromJson(Map<String, dynamic> json) {
    return DayNutrientTotals(
      date: json['date'] as String? ?? '',
      nutrients: (json['nutrients'] as List? ?? const [])
          .map((v) => NutrientTotal.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
    );
  }

  // Nutrients that contributed a score (had a non-null DRI percent).
  Iterable<NutrientTotal> get _scored =>
      nutrients.where((n) => n.driPercent != null);

  // Maps a nutrient's raw percent to its 0..100 contribution to the dial.
  // Meet nutrients: reaching 100% is the goal, going over doesn't help.
  // Limit nutrients: staying under is the goal, going over LINEARLY drops
  // the score (200% sodium -> 0, 150% sodium -> 50). This is what makes
  // logging a salty meal actually move the dial down instead of being
  // silently ignored.
  static double _scoreFor(NutrientTotal n) {
    final p = n.driPercent ?? 0;
    if (n.isLimit) {
      if (p <= 100) return 100;
      final remaining = 200 - p;
      return remaining < 0 ? 0 : remaining;
    }
    return p > 100 ? 100 : p;
  }

  double get averagePercent {
    final scored = _scored.toList();
    if (scored.isEmpty) return 0;
    final sum = scored.fold<double>(0, (a, n) => a + _scoreFor(n));
    return sum / scored.length;
  }

  // For the home dial subtitle: "X of N nutrients on target" so the user can
  // see why adding more macros doesn't move the percentage when they're
  // already maxed.
  int get metCount {
    return _scored.where((n) {
      final p = n.driPercent ?? 0;
      return n.isLimit ? p <= 100 : p >= 100;
    }).length;
  }

  int get trackedCount => _scored.length;

  // ── UI insight helpers ───────────────────────────────────────

  /// Limit nutrients (e.g. sodium) that have exceeded 100 % DRI.
  List<NutrientTotal> get overLimitNutrients =>
      _scored.where((n) => n.isLimit && (n.driPercent ?? 0) > 100).toList();

  /// Meet nutrients already at or above 100 % DRI (further intake won't help).
  List<NutrientTotal> get cappedMeetNutrients =>
      _scored.where((n) => !n.isLimit && (n.driPercent ?? 0) >= 100).toList();

  /// Meet nutrients still below 100 % DRI (more food helps).
  List<NutrientTotal> get unmetNutrients =>
      _scored.where((n) => !n.isLimit && (n.driPercent ?? 0) < 100).toList();

  /// A short, human-readable insight line for the home hero card.
  /// Tone adapts to the overall score so it feels encouraging at high
  /// percentages instead of alarming.
  String get insightMessage {
    final overLimit = overLimitNutrients;
    final unmet = unmetNutrients;
    final capped = cappedMeetNutrients;
    final score = averagePercent;

    // Priority 1: something is actively dragging the score DOWN
    if (overLimit.isNotEmpty) {
      final names = overLimit.map((n) => n.name).take(2).join(' & ');
      return '$names exceeded the daily limit — this lowers your score.';
    }

    // Priority 2: everything is met — no room to grow
    if (unmet.isEmpty && capped.isNotEmpty) {
      return 'All tracked nutrients are on target! New meals may not raise your score.';
    }

    // Priority 3: still have room — tone depends on how well we're doing
    if (unmet.isNotEmpty) {
      // Find the closest nutrient to reaching target for a specific tip
      final closest = unmet.toList()
        ..sort((a, b) =>
            (b.driPercent ?? 0).compareTo(a.driPercent ?? 0));
      final topName = closest.first.name;

      if (score >= 75) {
        // Doing great — celebrate and give a specific nudge
        return 'Almost there! A little more $topName could push you even higher.';
      } else if (score >= 40) {
        // Decent progress — motivational with specific tip
        return 'Good start! Focus on $topName to keep climbing.';
      } else {
        // Early in the day or low coverage — actionable
        return 'Log a meal to start building your nutrient coverage for today.';
      }
    }

    // Fallback: just started
    return 'Log meals to see your nutrient coverage.';
  }
}

class Recommendation {
  const Recommendation({
    required this.code,
    required this.name,
    required this.message,
    this.percent,
    required this.foodId,
    required this.foodName,
    this.foodImageUrl,
  });

  final String code;
  final String name;
  final String message;
  final double? percent;
  final String foodId;
  final String foodName;
  final String? foodImageUrl;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      code: json['code'] as String,
      name: json['name'] as String,
      message: json['message'] as String,
      percent: (json['percent'] as num?)?.toDouble(),
      foodId: json['food_id'] as String,
      foodName: json['food_name'] as String,
      foodImageUrl: json['food_image_url'] as String?,
    );
  }
}

class DailyMealPlan {
  const DailyMealPlan({required this.date, required this.meals});

  final String date;
  final List<MealPlanSlot> meals;

  bool get hasItems => meals.any((slot) => slot.items.isNotEmpty);

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    return DailyMealPlan(
      date: json['date'] as String? ?? '',
      meals: (json['meals'] as List? ?? const [])
          .map((v) => MealPlanSlot.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
    );
  }
}

class MealPlanSlot {
  const MealPlanSlot({
    required this.mealType,
    required this.title,
    required this.focusNutrients,
    required this.items,
  });

  final String mealType;
  final String title;
  final List<String> focusNutrients;
  final List<MealPlanItem> items;

  factory MealPlanSlot.fromJson(Map<String, dynamic> json) {
    return MealPlanSlot(
      mealType: json['meal_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      focusNutrients: (json['focus_nutrients'] as List? ?? const [])
          .map((v) => v.toString())
          .toList(),
      items: (json['items'] as List? ?? const [])
          .map((v) => MealPlanItem.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
    );
  }
}

class MealPlanItem {
  const MealPlanItem({
    required this.foodId,
    required this.foodName,
    this.foodImageUrl,
    required this.reason,
  });

  final String foodId;
  final String foodName;
  final String? foodImageUrl;
  final String reason;

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      foodId: json['food_id'] as String,
      foodName: json['food_name'] as String,
      foodImageUrl: json['food_image_url'] as String?,
      reason: json['reason'] as String? ?? '',
    );
  }
}
