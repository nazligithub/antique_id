import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../helpers/storage_helper.dart';
import '../../helpers/appactor_helper.dart';
import '../../providers/app_provider.dart';

class SplashViewModel extends ChangeNotifier {
  final StorageHelper _storageHelper = StorageHelper();

  Future<void> initialize(BuildContext context) async {
    await _storageHelper.init();

    // Load Appactor offerings and check subscription status
    try {
      await AppactorHelper.shared.loadOfferings();
      await AppactorHelper.shared.checkSubscription();
      debugPrint('Appactor initialized in splash');
    } catch (e) {
      debugPrint('Error initializing Appactor in splash: $e');
    }

    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      checkNavigation(context);
    }
  }

  void checkNavigation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Load user preferences and sync with Appactor
    await appProvider.loadUserPreferences();

    // Extra sync to ensure premium status is up-to-date
    await appProvider.syncPurchases();

    debugPrint('Navigation check - Onboarding: $onboardingCompleted, Premium: ${appProvider.isPremiumUser}');

    if (context.mounted) {
      if (!onboardingCompleted) {
        // First time user, go to onboarding
        Navigator.pushReplacementNamed(context, '/onboard');
      } else if (!appProvider.isPremiumUser) {
        // User has completed onboarding but is not premium, show paywall
        Navigator.pushReplacementNamed(context, '/paywall');
      } else {
        // Premium user, skip paywall and go directly to main app
        Navigator.pushReplacementNamed(context, '/maintab');
      }
    }
  }
}
