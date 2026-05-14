import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/user.dart';
import '../notifications/goal_reminder_scheduler.dart';
import '../storage/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient api, required SecureTokenStorage storage})
    : _api = api,
      _storage = storage;

  final ApiClient _api;
  final SecureTokenStorage _storage;
  firebase_auth.FirebaseAuth get _firebaseAuth =>
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;
  StreamSubscription<firebase_auth.User?>? _authSub;

  /// Whether the initial verification email was successfully sent during signup.
  /// If false, the VerifyEmailScreen should auto-send on mount.
  bool _verificationEmailSent = false;
  bool get verificationEmailSent => _verificationEmailSent;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;
  bool get isAuthenticated => _user != null || _firebaseCurrentUser != null;

  /// Returns true if the current Firebase user signed up with email/password
  /// and has not yet clicked the verification link in their inbox.
  /// Google sign-in users are auto-verified, so this returns false for them.
  bool get needsEmailVerification {
    final fbUser = _firebaseCurrentUser;
    if (fbUser == null) return false;
    // Google sign-in users are always verified
    for (final info in fbUser.providerData) {
      if (info.providerId == 'google.com') return false;
    }
    return !fbUser.emailVerified;
  }

  firebase_auth.User? get _firebaseCurrentUser {
    try {
      return _firebaseAuth.currentUser;
    } on firebase_auth.FirebaseException catch (error) {
      if (error.code == 'no-app') return null;
      rethrow;
    }
  }

  Future<void> initialize() async {
    // Wait for the first auth state event before returning,
    // so the router knows whether the user is logged in.
    final completer = Completer<void>();

    _authSub?.cancel();
    _authSub = _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
      } else {
        try {
          await loadMe();
        } catch (_) {
          _user = null;
        }
      }
      _initialized = true;
      notifyListeners();
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _verificationEmailSent = false;
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);

      // Set language code before sending verification (must await to avoid
      // "Ignoring header X-Firebase-Locale because its value was null")
      await _firebaseAuth.setLanguageCode('en');

      // Send verification email with explicit ActionCodeSettings so the
      // verification link contains the correct web API key (without this,
      // the Android SDK generates links with an empty apiKey= parameter).
      try {
        await cred.user?.sendEmailVerification(
          firebase_auth.ActionCodeSettings(
            url: 'https://dsds-c4ba7.firebaseapp.com',
            handleCodeInApp: false,
          ),
        );
        _verificationEmailSent = true;
        if (kDebugMode) debugPrint('✅ Verification email sent successfully to $email');
      } catch (e) {
        _verificationEmailSent = false;
        if (kDebugMode) debugPrint('❌ sendEmailVerification failed: $e');
      }

      // Don't call reload() or getIdToken() here — the user hasn't verified
      // yet, and unnecessary calls contribute to Firebase rate-limiting.
      // loadMe may fail for new users if backend sync is slow — that's OK,
      // the user will land on verify-email and we'll retry later.
      try {
        await loadMe();
      } catch (_) {}

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await loadMe();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      // google_sign_in v7: initialize once, then authenticate
      await _googleSignIn.initialize(
        serverClientId:
            '1005767331412-o3rgulp2rikba2n70psamln8j3etpb9i.apps.googleusercontent.com',
      );
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );

      await _firebaseAuth.signInWithCredential(credential);
      await loadMe();
      _error = null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _setLoading(false);
        return; // User canceled sign-in
      }
      _error = e.toString();
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
        _storage.clear(),
      ]);
    } catch (_) {}
    _user = null;
    _setLoading(false);
  }

  /// Schedules the user's account for deletion (soft-delete with a 30-day
  /// recovery window — see backend migration 00029_account_deletion.sql) and
  /// signs the user out everywhere. Rethrows the API error if the request
  /// fails so the caller can surface it; on success the local state is the
  /// same as after [logout].
  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _api.delete(ApiEndpoints.me);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
    // Mirror logout(): drop Firebase + Google sessions and clear tokens. Best
    // effort — if one of these fails we still want the user signed out.
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
        _storage.clear(),
      ]);
    } catch (_) {}
    _user = null;
    _error = null;
    _setLoading(false);
  }

  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: token,
        newPassword: newPassword,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyEmail(String token) async {
    _setLoading(true);
    try {
      await _firebaseAuth.applyActionCode(token);
      await loadMe();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
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

  /// Persist user-set daily kcal / macro goals on the backend. Any null field
  /// is left untouched so callers can patch one field at a time. The server
  /// re-runs the metabolic calculation and applies the overrides before
  /// returning, so the resulting `metabolicTargets` reflect the new goals.
  Future<void> setGoals({
    double? goalKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
  }) async {
    await _runAuthAction(() async {
      final response = await _api.patch(
        ApiEndpoints.meGoals,
        data: _withoutNulls({
          'goal_kcal': goalKcal,
          'protein_g': proteinG,
          'carbs_g': carbsG,
          'fat_g': fatG,
          'fiber_g': fiberG,
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
    if (_firebaseCurrentUser == null) return;
    try {
      final response = await _api.get(ApiEndpoints.me);
      _user = AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    // Re-arm the daily goal-progress reminder against the freshly-loaded
    // targets. Failure here must not break sign-in, so swallow errors.
    try {
      await GoalReminderScheduler.scheduleFor(_user?.metabolicTargets);
    } catch (_) {}
    notifyListeners();
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
