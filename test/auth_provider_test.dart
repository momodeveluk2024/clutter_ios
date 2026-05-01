import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/api/api_endpoints.dart';
import 'package:myapplication/core/api/api_exceptions.dart';
import 'package:myapplication/core/providers/auth_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';

class _AvatarApiClient extends ApiClient {
  _AvatarApiClient() : super(tokenStorage: const SecureTokenStorage());

  String? uploadedPath;
  int uploadCount = 0;
  String? patchedPath;

  @override
  Future<Response<dynamic>> postMultipart(String path, FormData data) async {
    uploadedPath = path;
    uploadCount++;
    return Response<dynamic>(
      data: {
        'id': 'user-1',
        'email': 'ahmed@gmail.com',
        'display_name': 'ahmed',
        'avatar_url': '/uploads/avatars/user-1/face.png',
        'units': 'metric',
        'locale': 'en',
        'timezone': 'Asia/Baghdad',
        'preferences': <String, dynamic>{},
      },
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> patch(String path, {Object? data}) async {
    patchedPath = path;
    return Response<dynamic>(
      data: {
        'id': 'user-1',
        'email': 'ahmed@gmail.com',
        'display_name': 'ahmed',
        'units': 'metric',
        'locale': 'en',
        'timezone': 'Asia/Baghdad',
        'preferences': <String, dynamic>{},
        'onboarding_completed_at': '2026-04-30T00:00:00Z',
        'needs_onboarding': false,
      },
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  test(
    'uploadAvatarBytes posts multipart image and refreshes current user',
    () async {
      final api = _AvatarApiClient();
      final provider = AuthProvider(
        api: api,
        storage: const SecureTokenStorage(),
      );

      await provider.uploadAvatarBytes(
        bytes: [1, 2, 3],
        filename: 'face.png',
        contentType: 'image/png',
      );

      expect(api.uploadedPath, ApiEndpoints.meAvatar);
      expect(api.uploadCount, 1);
      expect(provider.user?.avatarUrl, '/uploads/avatars/user-1/face.png');
    },
  );

  test(
    'completeOnboarding patches the completion endpoint and refreshes user',
    () async {
      final api = _AvatarApiClient();
      final provider = AuthProvider(
        api: api,
        storage: const SecureTokenStorage(),
      );

      await provider.completeOnboarding();

      expect(api.patchedPath, ApiEndpoints.meOnboardingComplete);
      expect(provider.user?.needsOnboarding, isFalse);
      expect(provider.user?.onboardingCompletedAt, isNotNull);
    },
  );

  test('ApiException string is short enough for snackbars', () {
    const error = ApiException('Request not found.', statusCode: 404);

    expect(error.toString(), 'Request not found.');
  });
}
