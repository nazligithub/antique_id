import 'package:flutter/material.dart';
import 'package:appactor_flutter/appactor_flutter.dart';

class AppactorHelper {
  static const String _publicKey = 'pk_E2Y9hdD2I4yoISWMVSIvhplssEfodblm';
  static const String _proEntitlementId = 'premium';

  static AppactorHelper? _instance;
  static AppactorHelper get shared => _instance ??= AppactorHelper._();

  AppactorHelper._();

  AppActorOfferings? offerings;
  bool isActive = false;
  bool _isInitialized = false;

  /// Initialize Appactor
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) {
      debugPrint('Appactor already initialized');
      return;
    }

    try {
      await AppActor.instance.configure(
        _publicKey,
        appUserId: userId,
      );

      _isInitialized = true;
      debugPrint('Appactor initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Appactor: $e');
      _isInitialized = false;
    }
  }

  /// Load offerings from Appactor
  Future<void> loadOfferings() async {
    try {
      offerings = await AppActor.instance.getOfferings();
      debugPrint('Loaded offerings: ${offerings?.current != null ? "success" : "no current offering"}');

      if (offerings?.current != null) {
        debugPrint('Available packages:');
        if (offerings!.current!.weekly != null) {
          debugPrint('  - Weekly: ${offerings!.current!.weekly!.localizedPriceString ?? "N/A"}');
        }
        if (offerings!.current!.monthly != null) {
          debugPrint('  - Monthly: ${offerings!.current!.monthly!.localizedPriceString ?? "N/A"}');
        }
        if (offerings!.current!.annual != null) {
          debugPrint('  - Annual: ${offerings!.current!.annual!.localizedPriceString ?? "N/A"}');
        }
      }
    } catch (e) {
      debugPrint('Error loading offerings: $e');
      offerings = null;
    }
  }

  /// Check subscription status
  Future<bool> checkSubscription() async {
    try {
      final customerInfo = await AppActor.instance.getCustomerInfo();

      // Check if user has active premium entitlement
      isActive = customerInfo.hasActiveEntitlement(_proEntitlementId);

      debugPrint('Subscription status - isActive: $isActive');

      // Log all active entitlements
      final activeEntitlements = customerInfo.entitlements.entries
          .where((e) => e.value.isActive)
          .toList();

      if (activeEntitlements.isNotEmpty) {
        debugPrint('Active entitlements:');
        for (var entry in activeEntitlements) {
          debugPrint('  - ${entry.key}');
        }
      } else {
        debugPrint('No active entitlements found');
      }

      return isActive;
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      isActive = false;
      return false;
    }
  }

  /// Purchase a package
  Future<AppActorCustomerInfo?> purchasePackage(AppActorPackage package, {String? placement}) async {
    try {
      debugPrint('Attempting to purchase: ${package.productId}');

      await AppActor.instance.purchasePackage(
        package,
        placement: placement ?? 'default',
      );

      // Get updated customer info after purchase
      final customerInfo = await AppActor.instance.getCustomerInfo();

      // Update subscription status
      isActive = customerInfo.hasActiveEntitlement(_proEntitlementId);

      debugPrint('Purchase completed - isActive: $isActive');

      return customerInfo;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return null;
    }
  }

  /// Restore purchases
  Future<AppActorCustomerInfo?> restorePurchases() async {
    try {
      debugPrint('Attempting to restore purchases');

      // Sync purchases with the store
      await AppActor.instance.syncPurchases();

      // Get updated customer info
      final customerInfo = await AppActor.instance.getCustomerInfo();

      // Update subscription status
      isActive = customerInfo.hasActiveEntitlement(_proEntitlementId);

      debugPrint('Restore completed - isActive: $isActive');

      return customerInfo;
    } catch (e) {
      debugPrint('Restore error: $e');
      return null;
    }
  }

  /// Sync purchases (useful for checking subscription status after app restart)
  Future<bool> syncPurchases() async {
    try {
      debugPrint('Syncing purchases with Appactor');

      await AppActor.instance.syncPurchases();
      final customerInfo = await AppActor.instance.getCustomerInfo();
      isActive = customerInfo.hasActiveEntitlement(_proEntitlementId);

      debugPrint('Sync completed - isActive: $isActive');
      return isActive;
    } catch (e) {
      debugPrint('Sync error: $e');
      return false;
    }
  }

  /// Get weekly package
  AppActorPackage? get weeklyPackage {
    return offerings?.current?.weekly;
  }

  /// Get yearly package
  AppActorPackage? get yearlyPackage {
    return offerings?.current?.annual;
  }

  /// Get monthly package
  AppActorPackage? get monthlyPackage {
    return offerings?.current?.monthly;
  }

  /// Check if offerings are loaded
  bool get hasOfferings => offerings?.current != null;

  /// Check if Appactor is initialized
  bool get isInitialized => _isInitialized;
}
