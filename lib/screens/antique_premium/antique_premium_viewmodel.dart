import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

  @visibleForTesting
  set introOfferForTesting(IntroOffer? offer) => _introOffer = offer;

  @visibleForTesting
  set configLoadedForTesting(bool loaded) => _configLoaded = loaded;

  AppActorPackage? get weeklyPackage => AppactorHelper.shared.weeklyPackage;
  AppActorPackage? get yearlyPackage => AppactorHelper.shared.yearlyPackage;

  String get weeklyRenewalPrice =>
      weeklyPackage?.localizedPriceString ?? '\$4.99';

  String get weeklyPrice {
    final offer = _introOffer;
    if (offer != null && !offer.isFree && offer.displayPrice.isNotEmpty) {
      return offer.displayPrice;
    }
    return weeklyRenewalPrice;
  }

  String get weeklyDisplayPrice => weeklyPrice;

  String get yearlyPrice => yearlyPackage?.localizedPriceString ?? '\$39.99';

  String get yearlyWeeklyPrice {
    final yearlyPriceValue = yearlyPackage?.price ?? 39.99;
    final weeklyPrice = yearlyPriceValue / 52;
    return '\$${weeklyPrice.toStringAsFixed(2)}/week';
  }

  /// The strings below name the introductory terms, and all of them come
  /// from StoreKit rather than from this file. The offer is edited in App Store
  /// Connect and can change with no release at all, so copy written here would
  /// only ever be a snapshot of what was true the day it was typed -- and a
  /// price spelled '\$0.99' was already wrong everywhere outside the US.

  /// '1 week', '2 weeks', '3 days' -- how long the offer runs, or '' when
  /// StoreKit gave no usable period.
  String _spanLabel(IntroOffer offer) {
    final days = offer.totalDays;
    if (days <= 0) return '';
    if (days % 7 == 0) {
      final weeks = days ~/ 7;
      return weeks == 1
          ? 'paywall_span_one_week'.tr()
          : 'paywall_span_weeks'.tr(namedArgs: {'count': '$weeks'});
    }
    return 'paywall_span_days'.tr(namedArgs: {'count': '$days'});
  }

  /// '1-Week', '3-Day' -- the part that goes in front of "Free Trial".
  String _durationLabel(IntroOffer offer) {
    final days = offer.totalDays;
    if (days <= 0) return '';
    if (days % 7 == 0) {
      return 'paywall_duration_weeks'.tr(namedArgs: {'count': '${days ~/ 7}'});
    }
    return 'paywall_duration_days'.tr(namedArgs: {'count': '$days'});
  }

  String get weeklySubtitle {
    final offer = _introOffer;
    if (offer == null) return 'paywall_cancel_anytime'.tr();
    if (offer.isFree) {
      final span = _spanLabel(offer);
      return span.isNotEmpty
          ? 'paywall_subtitle_free'.tr(namedArgs: {'span': span})
          : 'paywall_subtitle_free_generic'.tr();
    }
    if (offer.displayPrice.isEmpty) return 'paywall_cancel_anytime'.tr();
    return 'paywall_subtitle_paid'.tr(namedArgs: {'price': weeklyRenewalPrice});
  }

  /// Null hides the badge, which is what should happen when there is no offer
  /// to shout about.
  String? get weeklyBadgeLabel {
    final offer = _introOffer;
    if (offer == null) return null;
    if (offer.isFree) {
      final days = offer.totalDays;
      // The badge strings are stored already capitalised: Dart's
      // toUpperCase() has no locale, so Turkish 'i' would come out as 'I'.
      if (days >= 7 && days % 7 == 0) {
        return 'paywall_badge_weeks_free'.tr(namedArgs: {'count': '${days ~/ 7}'});
      }
      return 'paywall_badge_days_free'.tr(namedArgs: {'count': '$days'});
    }
    if (offer.displayPrice.isEmpty) return null;
    return 'paywall_badge_special_offer'.tr();
  }

  /// An invitation plus the number the reader pays today. How long the offer
  /// lasts and what follows it are already spelled out on the selected card.
  String get primaryCtaLabel {
    if (!_isWeeklySelected) return 'common_continue'.tr();
    final offer = _introOffer;
    if (offer == null) return 'common_continue'.tr();
    if (offer.isFree) {
      return 'paywall_cta_free_trial'
          .tr(namedArgs: {'duration': _durationLabel(offer)});
    }
    if (offer.displayPrice.isEmpty) return 'common_continue'.tr();
    return 'paywall_cta_paid'.tr(namedArgs: {'price': offer.displayPrice});
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
