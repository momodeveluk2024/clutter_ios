import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Phase 5 RevenueCat paywall integration.
///
/// Set keys via `--dart-define=REVENUECAT_IOS_KEY=appl_...`
/// and `--dart-define=REVENUECAT_ANDROID_KEY=goog_...`.
///
/// Two SKUs to start (configure in RevenueCat dashboard):
///   - nutrimate_pro_monthly
///   - nutrimate_pro_yearly
///
/// Entitlement identifier: `pro`. Anything else is free-tier.
class PaywallService {
  PaywallService._();
  static final PaywallService instance = PaywallService._();

  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const proEntitlement = 'pro';

  bool _initialized = false;

  Future<void> initialize({String? userId}) async {
    if (_initialized) {
      if (userId != null) await Purchases.logIn(userId);
      return;
    }
    final apiKey = Platform.isIOS ? _iosKey : _androidKey;
    if (apiKey.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('PaywallService: no RevenueCat API key — Pro features disabled.');
      }
      return;
    }
    await Purchases.setLogLevel(LogLevel.warn);
    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);
    _initialized = true;
  }

  Future<bool> hasPro() async {
    if (!_initialized) return false;
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(proEntitlement);
  }

  Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;
    return Purchases.getOfferings();
  }

  Future<bool> purchase(Package pkg) async {
    final result = await Purchases.purchasePackage(pkg);
    return result.entitlements.active.containsKey(proEntitlement);
  }

  Future<bool> restore() async {
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(proEntitlement);
  }
}
