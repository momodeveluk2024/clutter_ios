import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/providers/food_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';

class _TestApiClient extends ApiClient {
  _TestApiClient(this.payload)
    : super(tokenStorage: const SecureTokenStorage());

  final Map<String, dynamic> payload;
  Map<String, dynamic>? lastQuery;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    lastQuery = query;
    return Response<dynamic>(
      data: payload,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  test(
    'fetchFoods returns foods without notifying shared search state',
    () async {
      final api = _TestApiClient({
        'foods': [
          {
            'id': '018f0000-0000-7000-8002-000000000106',
            'name': 'Salmon, Atlantic, cooked, dry heat',
            'category': 'seafood',
            'serving_size_g': 100,
            'verified': true,
            'image_url': 'https://example.com/salmon.jpg',
            'dri_percent': 68.0,
            'nutrients': ['D', 'B12'],
          },
        ],
      });
      final provider = FoodProvider(api: api);
      var notifications = 0;
      provider.addListener(() => notifications++);

      final foods = await provider.fetchFoods(nutrient: 'D', limit: 8);

      expect(foods, hasLength(1));
      expect(foods.single.name, contains('Salmon'));
      expect(api.lastQuery, containsPair('nutrient', 'D'));
      expect(api.lastQuery, containsPair('limit', 8));
      expect(provider.foods, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(notifications, 0);
    },
  );
}
