import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient({required SecureTokenStorage tokenStorage})
    : dio = Dio(
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
          final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            try {
              // Force refresh is not strictly needed, but getting the token might throw
              // if the user was deleted from the Firebase Console.
              final token = await currentUser.getIdToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (e) {
              debugPrint('Failed to get ID token (user might be deleted): $e');
              // Optionally sign out locally if it's a specific auth error, 
              // but letting the API request fail with 401 is usually sufficient.
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          
          if (response?.statusCode == 401 && !alreadyRetried) {
            final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              try {
                // Delay to handle clock skew between Firebase and the backend VPS.
                // Without this, freshly issued tokens get rejected as "issued in the future".
                await Future.delayed(const Duration(seconds: 1));
                // Force refresh token
                final token = await currentUser.getIdToken(true);
                if (token != null) {
                  final retryOptions = error.requestOptions;
                  retryOptions.extra['retried'] = true;
                  retryOptions.headers['Authorization'] = 'Bearer $token';
                  final retryResponse = await dio.fetch<dynamic>(retryOptions);
                  handler.resolve(retryResponse);
                  return;
                }
              } catch (_) {
                // If refresh fails, let the error pass through
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;

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
