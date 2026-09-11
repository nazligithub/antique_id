import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appactor_flutter/appactor_flutter.dart';
import 'package:provider/provider.dart';
import '../../helpers/appactor_helper.dart';
import '../../helpers/intro_offer_helper.dart';
import '../../providers/app_provider.dart';

class AntiquePremiumViewModel extends ChangeNotifier {
  // The trial-led weekly plan is the primary offer when the paywall opens.
  bool _isWeeklySelected = true;
  bool _isYearlySelected = false;
  bool _isLoading = false;
  bool _configLoaded = false; // Track if remote config has been loaded

  bool get isWeeklySelected => _isWeeklySelected;
  bool get isYearlySelected => _isYearlySelected;
  bool get isLoading => _isLoading;
  bool get configLoaded => _configLoaded;

  IntroOffer? _introOffer;

  /// What the App Store is actually offering on the weekly plan. Null until it
  /// has been read, and null forever on a build or platform that cannot ask.
  IntroOffer? get introOffer => _introOffer;

  AppActorPackage? get weeklyPackage => AppactorHelper.shared.weeklyPackage;
  AppActorPackage? get yearlyPackage => AppactorHelper.shared.yearlyPackage;

  String get weeklyPrice => weeklyPackage?.localizedPriceString ?? '\$4.99';
  String get yearlyPrice => yearlyPackage?.localizedPriceString ?? '\$39.99';

  String get yearlyWeeklyPrice {
    final yearlyPriceValue = yearlyPackage?.price ?? 39.99;
    final weeklyPrice = yearlyPriceValue / 52;
    return '\$${weeklyPrice.toStringAsFixed(2)}/week';
  }

  /// The three strings below name the introductory terms, and all three come
  /// from StoreKit rather than from this file. The offer is edited in App Store
  /// Connect and can change with no release at all, so copy written here would
  /// only ever be a snapshot of what was true the day it was typed -- and a
  /// price spelled '\$0.99' was already wrong everywhere outside the US.
  String get weeklySubtitle {
    final offer = _introOffer;
    if (offer == null) return 'Cancel anytime';
    final days = offer.totalDays;
    if (offer.isFree) return '$days days free, then cancel anytime';
    return '${offer.displayPrice} for $days days, then cancel anytime';
  }

  /// Null hides the badge, which is what should happen when there is no offer
  /// to shout about.
  String? get weeklyBadgeLabel {
    final offer = _introOffer;
    if (offer == null) return null;
    final days = offer.totalDays;
    if (offer.isFree) return '$days DAYS FREE';
    return '$days DAYS · ${offer.displayPrice}';
  }

  String get primaryCtaLabel {
    if (!_isWeeklySelected) return 'Continue';
    final offer = _introOffer;
    if (offer == null) return 'Continue';
    if (offer.isFree) return 'Start ${offer.durationLabel} Free Trial';
    return 'Try ${offer.totalDays} Days for ${offer.displayPrice}';
  }

  int get savingsPercentage {
    final weeklyPriceValue = weeklyPackage?.price ?? 4.99;
    final yearlyPriceValue = yearlyPackage?.price ?? 39.99;
    final weeklyYearlyTotal = weeklyPriceValue * 52;
    if (weeklyYearlyTotal > 0) {
      final savings =
          ((weeklyYearlyTotal - yearlyPriceValue) / weeklyYearlyTotal * 100);
      return savings.round();
    }
    return 70;
  }

  void initialize() async {
    // Set config as loaded immediately to show UI
    _configLoaded = true;
    notifyListeners();

    // Offerings should already be loaded from splash, but check if we need to load them
    if (!AppactorHelper.shared.hasOfferings) {
      await AppactorHelper.shared.loadOfferings();
      notifyListeners();
    }

    await _loadIntroOffer();
  }

  Future<void> _loadIntroOffer() async {
    final productId = weeklyPackage?.productId;
    if (productId == null || productId.isEmpty) return;
    final offer = await IntroOfferHelper.forProduct(productId);
    if (offer == null) return;
    _introOffer = offer;
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

  Future<bool> purchase(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      AppActorPackage? packageToPurchase;

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

      AppActorCustomerInfo? customerInfo = await AppactorHelper.shared
          .purchasePackage(packageToPurchase, placement: 'premium_screen');

      _isLoading = false;
      notifyListeners();

      if (customerInfo != null && AppactorHelper.shared.isActive) {
        debugPrint('Purchase completed successfully');

        // Update AppProvider immediately
        if (context.mounted) {
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          await appProvider.refreshPremiumStatus();
        }

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

  Future<bool> restore(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      AppActorCustomerInfo? customerInfo = await AppactorHelper.shared
          .restorePurchases();

      _isLoading = false;
      notifyListeners();

      if (customerInfo != null && AppactorHelper.shared.isActive) {
        debugPrint('Restore completed successfully');

        // Update AppProvider immediately
        if (context.mounted) {
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          await appProvider.refreshPremiumStatus();
        }

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
    const url = 'https://mobinaz.com/terms-antique-identifier';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void openPrivacy() async {
    const url = 'https://mobinaz.com/privacy-antique-identifier';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> saveOnboardingCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }
}
