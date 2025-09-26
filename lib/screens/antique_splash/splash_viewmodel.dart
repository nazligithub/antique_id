import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/storage_helper.dart';
import '../../helpers/revenuecat_helper.dart';

class SplashViewModel extends ChangeNotifier {
  final StorageHelper _storageHelper = StorageHelper();

  Future<void> initialize(BuildContext context) async {
    await _storageHelper.init();

    // Load RevenueCat products and check subscription status
    await RevenueCatHelper.shared.loadProducts();
    await RevenueCatHelper.shared.checkSubscription();

    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      checkNavigation(context);
    }
  }

  void checkNavigation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (context.mounted) {
      if (onboardingCompleted) {
        // User has seen onboarding before, go to splash -> paywall -> maintab
        Navigator.pushReplacementNamed(context, '/paywall');
      } else {
        // First time user, go to splash -> onboard -> paywall -> maintab
        Navigator.pushReplacementNamed(context, '/onboard');
      }
    }
  }
}