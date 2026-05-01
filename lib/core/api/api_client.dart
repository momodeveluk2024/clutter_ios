import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient({required SecureTokenStorage tokenStorage})
    : _tokenStorage = tokenStorage,
      dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          final isRefreshCall =
              error.requestOptions.path == ApiEndpoints.refresh;
          if (response?.statusCode == 401 &&
              !alreadyRetried &&
              !isRefreshCall) {
            final refreshed = await _refreshTokens();
            if (refreshed) {
              final retryOptions = error.requestOptions;
              retryOptions.extra['retried'] = true;
              final token = await _tokenStorage.getAccessToken();
              retryOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final retryResponse = await dio.fetch<dynamic>(retryOptions);
                handler.resolve(retryResponse);
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final SecureTokenStorage _tokenStorage;
  Future<bool>? _refreshInFlight;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _guard(() => dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return _guard(() => dio.post<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> postMultipart(String path, FormData data) {
    return _guard(
      () => dio.post<dynamic>(
        path,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  Future<Response<dynamic>> put(String path, {Object? data}) {
    return _guard(() => dio.put<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {Object? data}) {
    return _guard(() => dio.patch<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> delete(String path) {
    return _guard(() => dio.delete<dynamic>(path));
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<bool> _refreshTokens() {
    _refreshInFlight ??= _doRefresh().whenComplete(
      () => _refreshInFlight = null,
    );
    return _refreshInFlight!;
  }

  Future<bool> _doRefresh() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return false;
    }
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refresh': refresh},
        options: Options(extra: {'skipAuthRefresh': true}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      await _tokenStorage.saveTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    }
  }

  ApiException _mapDioException(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return ApiException(data['error'] as String, statusCode: status);
    }
    if (status == 404) {
      return const ApiException(
        'Request not found. Restart or update the backend and try again.',
        statusCode: 404,
      );
    }
    if (status == 401) {
      return const ApiException('Please sign in again.', statusCode: 401);
    }
    if (status != null && status >= 500) {
      return const ApiException(
        'The backend had a problem. Please try again.',
        statusCode: 500,
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        'Could not reach backend at ${ApiEndpoints.baseUrl}. '
        'On a USB phone, run: adb reverse tcp:8080 tcp:8080 — '
        'or pass --dart-define=NUTRIVITA_API_URL=http://<your-PC-LAN-IP>:8080/v1.',
      );
    }
    return ApiException(error.message ?? 'Request failed', statusCode: status);
  }
}
