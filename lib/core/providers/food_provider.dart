import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/category.dart';
import '../models/food.dart';

class BarcodeNotFoundException implements Exception {
  final String barcode;
  BarcodeNotFoundException(this.barcode);
  @override
  String toString() => 'BarcodeNotFoundException: $barcode';
}

class FoodProvider extends ChangeNotifier {
  FoodProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  /// LRU in-memory cache for food detail pages (max 50 entries).
  /// Keyed by food ID. Prevents redundant API calls when users
  /// revisit the same food detail.
  static const _maxCacheSize = 50;
  final _detailCache = <String, FoodDetail>{};

  List<FoodSummary> foods = [];
  List<FoodSummary> favorites = [];
  List<FoodSummary> userMeals = [];
  FoodDetail? selectedFood;
  bool isLoading = false;
  String? error;

  List<CategorySummary> categories = [];

  Future<List<CategorySummary>> fetchCategories() async {
    final response = await _api.get(ApiEndpoints.categories);
    final raw = response.data['categories'] as List? ?? const [];
    categories = raw
        .map((v) => CategorySummary.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    notifyListeners();
    return categories;
  }

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
    // ── Cache hit → return instantly, no loading state flicker ──
    final cached = _detailCache.remove(id);
    if (cached != null) {
      // Re-insert to mark as most-recently-used
      _detailCache[id] = cached;
      selectedFood = cached;
      notifyListeners();
      return cached;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(ApiEndpoints.food(id));
      selectedFood = FoodDetail.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      _putCache(id, selectedFood!);
      return selectedFood!;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<FoodDetail> getFoodByBarcode(String barcode) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(ApiEndpoints.foodByBarcode(barcode));
      final detail = FoodDetail.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      _putCache(detail.id, detail);
      selectedFood = detail;
      return detail;
    } on DioException catch (e) {
      // Backend returns 404 with {barcode, contribute: true} when all
      // external APIs missed. Throw a typed exception so the scanner
      // screen can route to the "Be the first to add!" contribution flow.
      if (e.response?.statusCode == 404) {
        final data = e.response?.data;
        if (data is Map && data['contribute'] == true) {
          final bc = data['barcode'] as String? ?? barcode;
          throw BarcodeNotFoundException(bc);
        }
      }
      error = e.toString();
      rethrow;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _putCache(String id, FoodDetail detail) {
    _detailCache.remove(id); // re-insert at end (most recent)
    _detailCache[id] = detail;
    while (_detailCache.length > _maxCacheSize) {
      _detailCache.remove(_detailCache.keys.first); // evict oldest
    }
  }

  /// Invalidate a single cache entry (after edit / delete).
  void invalidateCache(String id) => _detailCache.remove(id);

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
    required String category,
    required double servingSizeG,
    String? barcode,
    String? imageUrl,
    String? backgroundColor,
    required List<({String code, double amountPer100G})> nutrients,
  }) async {
    final response = await _api.post(
      ApiEndpoints.foods,
      data: {
        'name': name,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        'category': category,
        'serving_size_g': servingSizeG,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
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

  /// Submits a user-drafted edit for an existing food. The original
  /// food stays untouched until an admin approves the suggestion via
  /// the admin dashboard.
  Future<void> submitFoodSuggestion({
    required String foodId,
    required String name,
    String? brand,
    String? category,
    double? servingSizeG,
    String? barcode,
    String? notes,
    required List<({String code, double amountPer100G})> nutrients,
  }) async {
    await _api.post(
      ApiEndpoints.foodSuggest(foodId),
      data: {
        'name': name,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (category != null && category.isNotEmpty) 'category': category,
        if (servingSizeG != null) 'serving_size_g': servingSizeG,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'nutrients': nutrients
            .map((n) => {'code': n.code, 'amount_per_100g': n.amountPer100G})
            .toList(),
      },
    );
  }

  Future<FoodDetail> updateUserMeal({
    required String id,
    String? name,
    String? brand,
    String? category,
    double? servingSizeG,
    String? imageUrl,
    String? backgroundColor,
    List<({String code, double amountPer100G})>? nutrients,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (brand != null) body['brand'] = brand;
    if (category != null) body['category'] = category;
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
    // Keep the detail cache in sync so re-opening the edit/detail screen
    // reflects the new name, color, image, etc. instead of a stale copy.
    _putCache(id, detail);
    if (selectedFood?.id == id) selectedFood = detail;
    await loadUserMeals();
    return detail;
  }

  Future<void> deleteUserMeal(String id) async {
    await _api.delete(ApiEndpoints.food(id));
    invalidateCache(id);
    if (selectedFood?.id == id) selectedFood = null;
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
    _putCache(id, detail);
    if (selectedFood?.id == id) selectedFood = detail;
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
