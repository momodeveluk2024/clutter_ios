import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/food.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  List<FoodSummary> foods = [];
  List<FoodSummary> favorites = [];
  FoodDetail? selectedFood;
  bool isLoading = false;
  String? error;

  Future<List<FoodSummary>> fetchFoods({
    String query = '',
    String category = '',
    String nutrient = '',
    int limit = 25,
  }) async {
    final response = await _api.get(
      ApiEndpoints.foods,
      query: _foodQuery(
        query: query,
        category: category,
        nutrient: nutrient,
        limit: limit,
      ),
    );
    
    final results = (response.data['foods'] as List? ?? const [])
        .map((v) => FoodSummary.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
        
    // Filter out duplicates by name
    final seen = <String>{};
    return results.where((f) => seen.add(f.name.toLowerCase())).toList();
  }

  Future<List<FoodSummary>> searchFoods({
    String query = '',
    String category = '',
    String nutrient = '',
    int limit = 25,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      foods = await fetchFoods(
        query: query,
        category: category,
        nutrient: nutrient,
        limit: limit,
      );
      return foods;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<FoodDetail> getFood(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(ApiEndpoints.food(id));
      selectedFood = FoodDetail.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return selectedFood!;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<FoodSummary>> loadFavorites() async {
    final response = await _api.get(ApiEndpoints.favorites);
    favorites = (response.data['foods'] as List? ?? const [])
        .map((v) => FoodSummary.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    notifyListeners();
    return favorites;
  }

  Future<void> addFavorite(String foodId) async {
    await _api.put(ApiEndpoints.favorite(foodId));
    await loadFavorites();
  }

  Future<void> removeFavorite(String foodId) async {
    await _api.delete(ApiEndpoints.favorite(foodId));
    favorites = favorites.where((f) => f.id != foodId).toList();
    notifyListeners();
  }

  bool isFavorite(String foodId) => favorites.any((f) => f.id == foodId);

  Map<String, dynamic> _foodQuery({
    required String query,
    required String category,
    required String nutrient,
    required int limit,
  }) {
    return {
      if (query.isNotEmpty) 'q': query,
      if (category.isNotEmpty) 'category': category,
      if (nutrient.isNotEmpty) 'nutrient': nutrient,
      'limit': limit,
    };
  }
}
