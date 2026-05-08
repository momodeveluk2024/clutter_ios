import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/food.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  List<FoodSummary> foods = [];
  List<FoodSummary> favorites = [];
  List<FoodSummary> userMeals = [];
  FoodDetail? selectedFood;
  bool isLoading = false;
  String? error;

  Future<List<FoodSummary>> fetchFoods({
    String query = '',
    String category = '',
    String nutrient = '',
    int limit = 50,
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
    int limit = 50,
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

  // ── My Meals ──────────────────────────────────────────────────

  Future<List<FoodSummary>> loadUserMeals() async {
    final response = await _api.get(ApiEndpoints.myFoods);
    userMeals = (response.data['foods'] as List? ?? const [])
        .map((v) => FoodSummary.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    notifyListeners();
    return userMeals;
  }

  Future<FoodDetail> createUserMeal({
    required String name,
    String? brand,
    required double servingSizeG,
    String? imageUrl,
    String? backgroundColor,
    required List<({String code, double amountPer100G})> nutrients,
  }) async {
    final response = await _api.post(
      ApiEndpoints.foods,
      data: {
        'name': name,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        'category': 'my_meal',
        'serving_size_g': servingSizeG,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (backgroundColor != null && backgroundColor.isNotEmpty)
          'background_color': backgroundColor,
        'nutrients': nutrients
            .map((n) => {'code': n.code, 'amount_per_100g': n.amountPer100G})
            .toList(),
      },
    );
    final detail = FoodDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    await loadUserMeals();
    return detail;
  }

  Future<FoodDetail> updateUserMeal({
    required String id,
    String? name,
    String? brand,
    double? servingSizeG,
    String? imageUrl,
    String? backgroundColor,
    List<({String code, double amountPer100G})>? nutrients,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (brand != null) body['brand'] = brand;
    if (servingSizeG != null) body['serving_size_g'] = servingSizeG;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (backgroundColor != null) body['background_color'] = backgroundColor;
    if (nutrients != null) {
      body['nutrients'] = nutrients
          .map((n) => {'code': n.code, 'amount_per_100g': n.amountPer100G})
          .toList();
    }
    final response = await _api.patch(ApiEndpoints.food(id), data: body);
    final detail = FoodDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    await loadUserMeals();
    return detail;
  }

  Future<void> deleteUserMeal(String id) async {
    await _api.delete(ApiEndpoints.food(id));
    userMeals = userMeals.where((f) => f.id != id).toList();
    notifyListeners();
  }

  Future<FoodDetail> uploadUserMealImage({
    required String id,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    final response = await _api.postMultipart(
      ApiEndpoints.foodImage(id),
      form,
    );
    final detail = FoodDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    await loadUserMeals();
    return detail;
  }

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
