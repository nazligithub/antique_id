import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/storage_helper.dart';
import '../../helpers/appactor_helper.dart';
import '../../helpers/version_check_helper.dart';
import '../../providers/app_provider.dart';

class SplashViewModel extends ChangeNotifier {
  final StorageHelper _storageHelper = StorageHelper();

  Future<void> initialize(BuildContext context) async {
    await _storageHelper.init();

    // A newer store version blocks the splash behind the Update alert. A
    // failed lookup returns null and simply falls through, so being offline
    // never locks anyone out.
    final storeInfo = await VersionCheck.storeInfo();
    if (storeInfo?.updateAvailable == true && context.mounted) {
      await _showHardUpdateDialog(context, storeInfo!);
      return;
    }

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

  Future<void> _showHardUpdateDialog(
    BuildContext context,
    StoreInfo storeInfo,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFFFAF5ED),
            title: Text(
              'update_title'.tr(),
              style: const TextStyle(
                color: Color(0xFF3E2723),
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'update_message'.tr(namedArgs: {
                'store': storeInfo.storeVersion,
                'installed': storeInfo.currentVersion,
              }),
              style: const TextStyle(color: Color(0xFF6D4C41)),
            ),
            actions: [
              FilledButton(
                onPressed: () async {
                  if (await canLaunchUrl(storeInfo.appStoreUrl)) {
                    await launchUrl(
                      storeInfo.appStoreUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B6F47),
                  foregroundColor: Colors.white,
                ),
                child: Text('update_cta'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  void checkNavigation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted =
        prefs.getBool('onboarding_completed') ?? false;
    if (!context.mounted) return;
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Load user preferences and sync with Appactor
    await appProvider.loadUserPreferences();

    // Extra sync to ensure premium status is up-to-date
    await appProvider.syncPurchases();

    debugPrint(
      'Navigation check - Onboarding: $onboardingCompleted, Premium: ${appProvider.isPremiumUser}',
    );

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
