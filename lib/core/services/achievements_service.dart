import '../api/api_client.dart';

/// Phase 5 gamification. The backend at /v1/achievements returns the full
/// catalog with per-user unlocked_at populated. The unlock side is server-
/// driven (the engagement worker watches streaks/nutrient targets) — the
/// app just renders the list and shows a celebration when unlocked_at is
/// new since last session.
class AchievementsService {
  AchievementsService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<Achievement>> list() async {
    final response = await _api.get('/achievements');
    return (response.data['achievements'] as List? ?? const [])
        .map((v) => Achievement.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }
}

class Achievement {
  Achievement({
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.points,
    this.icon,
    this.unlockedAt,
  });

  final String code;
  final String name;
  final String description;
  final String category;
  final int points;
  final String? icon;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        points: (json['points'] as num).toInt(),
        icon: json['icon'] as String?,
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.tryParse(json['unlocked_at'] as String)
            : null,
      );
}
