import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../storage/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient api, required SecureTokenStorage storage})
    : _api = api,
      _storage = storage;

  final ApiClient _api;
  final SecureTokenStorage _storage;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;
  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      _initialized = true;
      notifyListeners();
      return;
    }
    try {
      await loadMe();
    } catch (_) {
      await _storage.clear();
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await _authenticate(ApiEndpoints.signup, {
      'display_name': displayName,
      'email': email,
      'password': password,
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _authenticate(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // The local logout should still complete even if the token is stale.
    }
    await _storage.clear();
    _user = null;
    _setLoading(false);
  }

  Future<void> forgotPassword(String email) async {
    await _runAuthAction(() async {
      await _api.post(ApiEndpoints.forgotPassword, data: {'email': email});
    });
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _runAuthAction(() async {
      await _api.post(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'new_password': newPassword},
      );
    });
  }

  Future<void> verifyEmail(String token) async {
    await _runAuthAction(() async {
      await _api.post(ApiEndpoints.verifyEmail, data: {'token': token});
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        await loadMe();
      }
    });
  }

  Future<void> updateProfile({
    String? displayName,
    String? sex,
    String? dateOfBirth,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? pregnancyStatus,
  }) async {
    await _runAuthAction(() async {
      final response = await _api.patch(
        ApiEndpoints.meProfile,
        data: _withoutNulls({
          'display_name': displayName,
          'sex': sex,
          'date_of_birth': dateOfBirth,
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'activity_level': activityLevel,
          'pregnancy_status': pregnancyStatus,
        }),
      );
      _user = AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<void> uploadAvatarBytes({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    await _runAuthAction(() async {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: filename.trim().isEmpty ? 'avatar.jpg' : filename.trim(),
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _api.postMultipart(ApiEndpoints.meAvatar, form);
      _user = AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<void> updatePreferences({
    String? units,
    String? locale,
    String? timezone,
    String? dietaryPattern,
    List<String>? allergens,
    List<String>? goals,
    Map<String, dynamic>? preferences,
  }) async {
    await _runAuthAction(() async {
      final response = await _api.patch(
        ApiEndpoints.mePreferences,
        data: _withoutNulls({
          'units': units,
          'locale': locale,
          'timezone': timezone,
          'dietary_pattern': dietaryPattern,
          'allergens': allergens,
          'goals': goals,
          'preferences': preferences,
        }),
      );
      _user = AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<void> completeOnboarding() async {
    await _runAuthAction(() async {
      final response = await _api.patch(ApiEndpoints.meOnboardingComplete);
      _user = AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<void> updateAppearance(String appearance) async {
    final merged = Map<String, dynamic>.from(_user?.preferences ?? const {});
    merged['appearance'] = appearance;
    await updatePreferences(preferences: merged);
  }

  Future<void> loadMe() async {
    final response = await _api.get(ApiEndpoints.me);
    _user = AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
    _error = null;
    notifyListeners();
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    _setLoading(true);
    try {
      final response = await _api.post(path, data: body);
      final auth = AuthResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      await _storage.saveTokens(access: auth.access, refresh: auth.refresh);
      _user = auth.user;
      _error = null;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      _error = null;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
    return Map<String, dynamic>.fromEntries(
      values.entries.where((entry) => entry.value != null),
    );
  }
}
