import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/food_log.dart';
import '../models/nutrition.dart';

class NutritionProvider extends ChangeNotifier {
  NutritionProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  DayNutrientTotals? todayTotals;
  List<DayNutrientTotals> weekTotals = [];
  List<MealLog> logs = [];
  List<Recommendation> recommendations = [];
  DailyMealPlan? dailyMealPlan;
  int streak = 0;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String? error;

  Future<void> refreshDashboard({DateTime? date}) async {
    selectedDate = _dateOnly(date ?? selectedDate);
    final day = _dateString(selectedDate);
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final totalsResponse = await _api.get(
        ApiEndpoints.todayIntake,
        query: {'date': day},
      );
      todayTotals = DayNutrientTotals.fromJson(
        Map<String, dynamic>.from(totalsResponse.data as Map),
      );

      final logsResponse = await _api.get(
        ApiEndpoints.logs,
        query: {'from': day, 'to': day},
      );
      logs = (logsResponse.data['logs'] as List? ?? const [])
          .map((v) => MealLog.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();

      final recommendationsResponse = await _api.get(
        ApiEndpoints.recommendations,
        query: {'date': day},
      );
      recommendations =
          (recommendationsResponse.data['recommendations'] as List? ?? const [])
              .map(
                (v) => Recommendation.fromJson(
                  Map<String, dynamic>.from(v as Map),
                ),
              )
              .toList();

      try {
        dailyMealPlan = await loadDailyMealPlan(
          date: selectedDate,
          notify: false,
        );
      } catch (_) {
        dailyMealPlan = null;
      }

      await loadStreak(notify: false);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<DailyMealPlan?> loadDailyMealPlan({
    DateTime? date,
    bool notify = true,
  }) async {
    final day = _dateString(date ?? selectedDate);
    final response = await _api.get(
      ApiEndpoints.dailyMealPlan,
      query: {'date': day},
    );
    dailyMealPlan = DailyMealPlan.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    if (notify) notifyListeners();
    return dailyMealPlan;
  }

  Future<int> loadStreak({bool notify = true}) async {
    final streakResponse = await _api.get(ApiEndpoints.streak);
    streak = streakResponse.data['streak'] as int? ?? 0;
    if (notify) notifyListeners();
    return streak;
  }

  Future<void> loadWeek({DateTime? endDate}) async {
    final day = _dateString(endDate ?? selectedDate);
    final response = await _api.get(
      ApiEndpoints.weekIntake,
      query: {'date': day},
    );
    weekTotals = (response.data['days'] as List? ?? const [])
        .map(
          (v) =>
              DayNutrientTotals.fromJson(Map<String, dynamic>.from(v as Map)),
        )
        .toList();
    notifyListeners();
  }

  Future<void> createLog({
    required String foodId,
    required double servingG,
    required String mealType,
    DateTime? date,
    String? pairedDrink,
    String? notes,
  }) async {
    await _api.post(
      ApiEndpoints.logs,
      data: {
        'logged_on': _dateString(date ?? DateTime.now()),
        'meal_type': mealType,
        if (pairedDrink != null && pairedDrink.isNotEmpty)
          'paired_drink': pairedDrink,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'items': [
          {'food_id': foodId, 'serving_g': servingG},
        ],
      },
    );
    await refreshDashboard(date: date);
    await loadWeek(endDate: date);
  }

  Future<void> deleteLog(String id, {DateTime? date}) async {
    final day = date ?? selectedDate;
    await _api.delete(ApiEndpoints.log(id));
    await refreshDashboard(date: day);
    await loadWeek(endDate: day);
  }

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
