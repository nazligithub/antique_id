import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatHelper {
  static const String _apiKey = 'appl_xCAYbWMbvqObcSxNQyZDftSjvXv';
  static const String _proEntitlementId = 'pro';

  static RevenueCatHelper? _instance;
  static RevenueCatHelper get shared => _instance ??= RevenueCatHelper._();

  RevenueCatHelper._();

  List<Package>? products;
  bool isActive = false;

  /// Initialize RevenueCat
  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.info);

      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);

      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
    }
  }

  /// Load products from default offering
  Future<void> loadProducts() async {
    try {
      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null) {
        products = offerings.current!.availablePackages;
        debugPrint('Loaded ${products?.length ?? 0} products');

        // Log product details
        products?.forEach((package) {
          debugPrint('Product: ${package.storeProduct.identifier} - ${package.storeProduct.priceString}');
        });
      } else {
        debugPrint('No current offering available');
        products = [];
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      products = [];
    }
  }

  /// Check subscription status
  Future<void> checkSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      // Check if user has active "pro" entitlement
      isActive = customerInfo.entitlements.all[_proEntitlementId]?.isActive ?? false;

      debugPrint('Subscription status - isActive: $isActive');

      // Log all active entitlements
      customerInfo.entitlements.active.forEach((key, entitlementInfo) {
        debugPrint('Active entitlement: $key - ${entitlementInfo.productIdentifier}');
      });

    } catch (e) {
      debugPrint('Error checking subscription: $e');
      isActive = false;
    }
  }

  /// Purchase a product
  Future<CustomerInfo?> purchaseProduct(Package package) async {
    try {
      debugPrint('Attempting to purchase: ${package.storeProduct.identifier}');

      PurchaseResult purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      CustomerInfo customerInfo = purchaseResult.customerInfo;

      // Update subscription status
      isActive = customerInfo.entitlements.all[_proEntitlementId]?.isActive ?? false;

      debugPrint('Purchase completed - isActive: $isActive');

      return customerInfo;
    } catch (e) {
      debugPrint('Purchase error: $e');

      // Handle specific error types
      if (e is PurchasesError) {
        switch (e.code) {
          case PurchasesErrorCode.purchaseCancelledError:
            debugPrint('User cancelled purchase');
            break;
          case PurchasesErrorCode.paymentPendingError:
            debugPrint('Payment is pending');
            break;
          default:
            debugPrint('Purchase failed with error: ${e.message}');
        }
      }

      return null;
    }
  }

  /// Restore purchases
  Future<CustomerInfo?> restorePurchases() async {
    try {
      debugPrint('Attempting to restore purchases');

      CustomerInfo customerInfo = await Purchases.restorePurchases();

      // Update subscription status
      isActive = customerInfo.entitlements.all[_proEntitlementId]?.isActive ?? false;

      debugPrint('Restore completed - isActive: $isActive');

      return customerInfo;
    } catch (e) {
      debugPrint('Restore error: $e');
      return null;
    }
  }

  /// Get weekly package
  Package? get weeklyPackage {
    if (products == null || products!.isEmpty) return null;
    try {
      return products!.firstWhere(
        (package) => package.packageType == PackageType.weekly,
      );
    } catch (e) {
      return products!.isNotEmpty ? products!.first : null;
    }
  }

  /// Get yearly package
  Package? get yearlyPackage {
    if (products == null || products!.isEmpty) return null;
    try {
      return products!.firstWhere(
        (package) => package.packageType == PackageType.annual,
      );
    } catch (e) {
      return products!.isNotEmpty ? products!.last : null;
    }
  }

  /// Get monthly package
  Package? get monthlyPackage {
    if (products == null || products!.isEmpty) return null;
    try {
      return products!.firstWhere(
        (package) => package.packageType == PackageType.monthly,
      );
    } catch (e) {
      return products!.isNotEmpty ? products!.first : null;
    }
  }

  /// Check if products are loaded
  bool get hasProducts => products?.isNotEmpty ?? false;
}