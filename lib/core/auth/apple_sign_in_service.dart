import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Sign in with Apple wrapper. Required by App Store guideline 4.8 because
/// the app already offers Google Sign-In. Phase 3 launch blocker.
///
/// Flow: request Apple credential → exchange for Firebase OAuthCredential
/// → signInWithCredential. Firebase auth state listeners in AuthProvider
/// pick up the result automatically — no separate state to manage here.
///
/// **Native config required (NOT done in Dart):**
///   1. iOS: Xcode → Signing & Capabilities → + Sign in with Apple.
///   2. Apple Developer portal: enable Sign in with Apple for the App ID.
///   3. Firebase Console → Authentication → Sign-in method → Apple.
class AppleSignInService {
  AppleSignInService();

  bool get isAvailable => Platform.isIOS || Platform.isMacOS || kIsWeb;

  Future<firebase_auth.UserCredential?> signIn() async {
    if (!isAvailable) return null;

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauth = firebase_auth.OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );
    return firebase_auth.FirebaseAuth.instance.signInWithCredential(oauth);
  }
}
