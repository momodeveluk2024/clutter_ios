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

  // Several screens (app shell, home, tracker, favorites) kick off
  // refreshDashboard around the same time on launch — that used to fan out
  // into 3-4 concurrent calls to the slow /recommendations/daily-plan
  // endpoint. Collapse concurrent refreshes for the same day into one.
  final Map<String, Future<void>> _refreshInFlight = {};
  final Map<String, Future<DailyMealPlan?>> _mealPlanInFlight = {};

  Future<void> refreshDashboard({DateTime? date}) {
    final target = _dateOnly(date ?? selectedDate);
    final key = _dateString(target);
    final existing = _refreshInFlight[key];
    if (existing != null) return existing;
    final future = _refreshDashboard(target).whenComplete(() {
      _refreshInFlight.remove(key);
    });
    _refreshInFlight[key] = future;
    return future;
  }

  Future<void> _refreshDashboard(DateTime target) async {
    selectedDate = target;
    final day = _dateString(selectedDate);
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Fire all independent API calls in parallel instead of sequentially.
      // This cuts dashboard load from ~5 round-trips to ~1 round-trip.
      final results = await Future.wait([
        _api.get(ApiEndpoints.todayIntake, query: {'date': day}),
        _api.get(ApiEndpoints.logs, query: {'from': day, 'to': day}),
        _api.get(ApiEndpoints.recommendations, query: {'date': day}),
      ]);

      todayTotals = DayNutrientTotals.fromJson(
        Map<String, dynamic>.from(results[0].data as Map),
      );
      logs = (results[1].data['logs'] as List? ?? const [])
          .map((v) => MealLog.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      recommendations =
          (results[2].data['recommendations'] as List? ?? const [])
              .map(
                (v) => Recommendation.fromJson(
                  Map<String, dynamic>.from(v as Map),
                ),
              )
              .toList();

      // These two are lower priority — fire in parallel, swallow errors.
      await Future.wait([
        loadDailyMealPlan(date: selectedDate, notify: false)
            .then((v) { dailyMealPlan = v; return v; })
            .catchError((_) { dailyMealPlan = null; return null; }),
        loadStreak(notify: false).catchError((_) => 0),
      ]);
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
  }) {
    final day = _dateString(date ?? selectedDate);
    final existing = _mealPlanInFlight[day];
    if (existing != null) return existing;
    final future = _loadDailyMealPlan(day, notify).whenComplete(() {
      _mealPlanInFlight.remove(day);
    });
    _mealPlanInFlight[day] = future;
    return future;
  }

  Future<DailyMealPlan?> _loadDailyMealPlan(String day, bool notify) async {
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

  static const Map<String, String> drinkFoodIds = {
    'Water': '018f0000-0000-7000-8004-000000000001',
    'Tea': '018f0000-0000-7000-8004-000000000002',
    'Coffee': '018f0000-0000-7000-8004-000000000003',
    'Juice': '018f0000-0000-7000-8004-000000000004',
    'Milk': '018f0000-0000-7000-8004-000000000005',
    'Coca-Cola': '018f0000-0000-7000-8004-000000000006',
    'Pepsi': '018f0000-0000-7000-8004-000000000007',
    'Fanta': '018f0000-0000-7000-8004-000000000008',
    'Sprite': '018f0000-0000-7000-8004-000000000009',
    'Energy drink': '018f0000-0000-7000-8004-000000000010',
    'Smoothie': '018f0000-0000-7000-8004-000000000011',
    'Lemonade': '018f0000-0000-7000-8004-000000000012',
  };

  Future<void> createLog({
    required String foodId,
    required double servingG,
    required String mealType,
    DateTime? date,
    String? pairedDrink,
    int pairedDrinkQuantity = 1,
    String? notes,
  }) async {
    final items = [
      {'food_id': foodId, 'serving_g': servingG},
    ];

    if (pairedDrink != null && drinkFoodIds.containsKey(pairedDrink)) {
      items.add({
        'food_id': drinkFoodIds[pairedDrink]!,
        'serving_g': 330.0 * pairedDrinkQuantity, // standard can/glass serving size in ml/g
      });
    }

    await _api.post(
      ApiEndpoints.logs,
      data: {
        'logged_on': _dateString(date ?? DateTime.now()),
        'meal_type': mealType,
        if (pairedDrink != null && pairedDrink.isNotEmpty)
          'paired_drink': pairedDrink,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'items': items,
      },
    );
    await Future.wait([
      refreshDashboard(date: date),
      loadWeek(endDate: date),
    ]);
  }

  Future<void> deleteLog(String id, {DateTime? date}) async {
    final day = date ?? selectedDate;
    await _api.delete(ApiEndpoints.log(id));
    await Future.wait([
      refreshDashboard(date: day),
      loadWeek(endDate: day),
    ]);
  }

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
