import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/core/api/api_client.dart';
import 'package:myapplication/core/providers/auth_provider.dart';
import 'package:myapplication/core/storage/secure_storage.dart';
import 'package:myapplication/screens/profile_setup.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {
  _NoopApiClient() : super(tokenStorage: const SecureTokenStorage());

  @override
  Future<Response<dynamic>> patch(String path, {Object? data}) async {
    return Response<dynamic>(
      data: <String, dynamic>{},
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  testWidgets('profile setup choices fit on a narrow Android viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _NoopApiClient();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            AuthProvider(api: api, storage: const SecureTokenStorage()),
        child: const MaterialApp(home: ProfileSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prefer not to say'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
