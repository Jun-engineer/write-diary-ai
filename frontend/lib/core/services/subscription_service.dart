import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'api_service.dart';
import '../providers/user_provider.dart';

/// RevenueCat API key — replace with your actual key from RevenueCat dashboard
const String kRevenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';

/// Product IDs
const String kPremiumMonthlyId = 'com.writediaryai.premium.monthly';
const String kPremiumYearlyId = 'com.writediaryai.premium.yearly';

/// RevenueCat entitlement ID
const String kPremiumEntitlementId = 'premium';

/// Subscription state
enum SubscriptionStatus {
  unknown,
  notSubscribed,
  subscribed,
  pending,
  error,
}

/// Provider for subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref);
});

/// Provider for subscription status
final subscriptionStatusProvider = StateProvider<SubscriptionStatus>((ref) {
  return SubscriptionStatus.unknown;
});

/// Provider for available packages (monthly/yearly)
final availablePackagesProvider = StateProvider<List<Package>>((ref) {
  return [];
});

/// Service to manage subscriptions via RevenueCat
class SubscriptionService {
  final Ref _ref;
  bool _initialized = false;

  SubscriptionService(this._ref);

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      final configuration = PurchasesConfiguration(kRevenueCatApiKey);
      await Purchases.configure(configuration);

      // Check current subscription status
      await refreshSubscriptionStatus();

      // Load offerings
      await _loadOfferings();

      _initialized = true;
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
      _ref.read(subscriptionStatusProvider.notifier).state =
          SubscriptionStatus.error;
    }
  }

  /// Load available offerings from RevenueCat
  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current != null) {
        _ref.read(availablePackagesProvider.notifier).state =
            current.availablePackages;
      }
    } catch (e) {
      debugPrint('Error loading offerings: $e');
    }
  }

  /// Purchase a specific package
  Future<bool> purchasePackage(Package package) async {
    try {
      _ref.read(subscriptionStatusProvider.notifier).state =
          SubscriptionStatus.pending;

      final customerInfo = await Purchases.purchasePackage(package);

      final isPremium = customerInfo
          .entitlements.all[kPremiumEntitlementId]?.isActive ?? false;

      if (isPremium) {
        _ref.read(subscriptionStatusProvider.notifier).state =
            SubscriptionStatus.subscribed;

        // Sync with backend
        await _syncPlanWithBackend(true);
        return true;
      } else {
        _ref.read(subscriptionStatusProvider.notifier).state =
            SubscriptionStatus.notSubscribed;
        return false;
      }
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        _ref.read(subscriptionStatusProvider.notifier).state =
            SubscriptionStatus.notSubscribed;
      } else {
        debugPrint('Purchase error: $e');
        _ref.read(subscriptionStatusProvider.notifier).state =
            SubscriptionStatus.error;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      _ref.read(subscriptionStatusProvider.notifier).state =
          SubscriptionStatus.error;
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();

      final isPremium = customerInfo
          .entitlements.all[kPremiumEntitlementId]?.isActive ?? false;

      _ref.read(subscriptionStatusProvider.notifier).state =
          isPremium ? SubscriptionStatus.subscribed : SubscriptionStatus.notSubscribed;

      await _syncPlanWithBackend(isPremium);
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  /// Refresh subscription status from RevenueCat
  Future<void> refreshSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      final isPremium = customerInfo
          .entitlements.all[kPremiumEntitlementId]?.isActive ?? false;

      _ref.read(subscriptionStatusProvider.notifier).state =
          isPremium ? SubscriptionStatus.subscribed : SubscriptionStatus.notSubscribed;

      await _syncPlanWithBackend(isPremium);
    } catch (e) {
      debugPrint('Error refreshing status: $e');
    }
  }

  /// Sync plan status with backend
  Future<void> _syncPlanWithBackend(bool isPremium) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.syncSubscriptionStatus(isPremium: isPremium);
      _ref.invalidate(userProvider);
    } catch (e) {
      debugPrint('Backend sync error: $e');
    }
  }

  /// Identify user with RevenueCat (call after login)
  Future<void> loginUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      await refreshSubscriptionStatus();
    } catch (e) {
      debugPrint('RevenueCat login error: $e');
    }
  }

  /// Logout from RevenueCat (call on sign out)
  Future<void> logoutUser() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }
}
