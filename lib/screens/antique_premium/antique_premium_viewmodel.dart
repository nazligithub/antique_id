import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../helpers/revenuecat_helper.dart';

class AntiquePremiumViewModel extends ChangeNotifier {
  bool _isWeeklySelected = false;
  bool _isYearlySelected = true;
  bool _isLoading = false;

  bool get isWeeklySelected => _isWeeklySelected;
  bool get isYearlySelected => _isYearlySelected;
  bool get isLoading => _isLoading;

  Package? get weeklyPackage => RevenueCatHelper.shared.weeklyPackage;
  Package? get yearlyPackage => RevenueCatHelper.shared.yearlyPackage;

  String get weeklyPrice => weeklyPackage?.storeProduct.priceString ?? '\$4.99';
  String get yearlyPrice => yearlyPackage?.storeProduct.priceString ?? '\$39.99';

  String get yearlyWeeklyPrice {
    final yearlyPriceValue = yearlyPackage?.storeProduct.price ?? 39.99;
    final weeklyPrice = yearlyPriceValue / 52;
    return '\$${weeklyPrice.toStringAsFixed(2)}/week';
  }

  int get savingsPercentage {
    final weeklyPriceValue = weeklyPackage?.storeProduct.price ?? 4.99;
    final yearlyPriceValue = yearlyPackage?.storeProduct.price ?? 39.99;
    final weeklyYearlyTotal = weeklyPriceValue * 52;
    if (weeklyYearlyTotal > 0) {
      final savings = ((weeklyYearlyTotal - yearlyPriceValue) / weeklyYearlyTotal * 100);
      return savings.round();
    }
    return 70;
  }

  void initialize() {
    notifyListeners();
  }

  void selectWeekly() {
    _isWeeklySelected = true;
    _isYearlySelected = false;
    notifyListeners();
  }

  void selectYearly() {
    _isWeeklySelected = false;
    _isYearlySelected = true;
    notifyListeners();
  }

  Future<bool> purchase() async {
    _isLoading = true;
    notifyListeners();

    try {
      Package? packageToPurchase;

      if (_isWeeklySelected) {
        packageToPurchase = weeklyPackage;
      } else if (_isYearlySelected) {
        packageToPurchase = yearlyPackage;
      }

      if (packageToPurchase == null) {
        debugPrint('No package selected for purchase');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      CustomerInfo? customerInfo = await RevenueCatHelper.shared.purchaseProduct(packageToPurchase);

      _isLoading = false;
      notifyListeners();

      if (customerInfo != null && RevenueCatHelper.shared.isActive) {
        debugPrint('Purchase completed successfully');
        return true;
      } else {
        debugPrint('Purchase failed or user is not premium');
        return false;
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restore() async {
    _isLoading = true;
    notifyListeners();

    try {
      CustomerInfo? customerInfo = await RevenueCatHelper.shared.restorePurchases();

      _isLoading = false;
      notifyListeners();

      if (customerInfo != null && RevenueCatHelper.shared.isActive) {
        debugPrint('Restore completed successfully');
        return true;
      } else {
        debugPrint('Restore completed - no active subscriptions found');
        return false;
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void openTerms() async {
    const url = 'https://www.apple.com/legal/internet-services/terms/site.html';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void openPrivacy() async {
    const url = 'https://www.apple.com/privacy/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> saveOnboardingCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }
}