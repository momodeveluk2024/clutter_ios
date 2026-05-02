import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/api/api_endpoints.dart';
import 'package:myapplication/core/providers/nutrition_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';

class _NutritionApiClient extends ApiClient {
  _NutritionApiClient() : super(tokenStorage: const SecureTokenStorage());

  final deletedPaths = <String>[];
  final getQueries = <String, Map<String, dynamic>?>{};

  @override
  Future<Response<dynamic>> delete(String path) async {
    deletedPaths.add(path);
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getQueries[path] = query;
    Object data = <String, dynamic>{};
    if (path == ApiEndpoints.todayIntake) {
      data = {'date': query?['date'], 'nutrients': []};
    } else if (path == ApiEndpoints.logs) {
      data = {'logs': []};
    } else if (path == ApiEndpoints.recommendations) {
      data = {'recommendations': []};
    } else if (path == ApiEndpoints.dailyMealPlan) {
      data = {'date': query?['date'], 'meals': []};
    } else if (path == ApiEndpoints.streak) {
      data = {'streak': 3};
    } else if (path == ApiEndpoints.weekIntake) {
      data = {'days': []};
    }
    return Response<dynamic>(
      data: data,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  test('deleteLog removes the log and refreshes the selected date', () async {
    final api = _NutritionApiClient();
    final provider = NutritionProvider(api: api);
    final date = DateTime(2026, 4, 20);

    await provider.deleteLog('log-123', date: date);

    expect(api.deletedPaths, [ApiEndpoints.log('log-123')]);
    expect(
      api.getQueries[ApiEndpoints.todayIntake],
      containsPair('date', '2026-04-20'),
    );
    expect(
      api.getQueries[ApiEndpoints.logs],
      containsPair('from', '2026-04-20'),
    );
    expect(api.getQueries[ApiEndpoints.logs], containsPair('to', '2026-04-20'));
    expect(
      api.getQueries[ApiEndpoints.weekIntake],
      containsPair('date', '2026-04-20'),
    );
  });
}
