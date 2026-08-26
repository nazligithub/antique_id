import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appactor_flutter/appactor_flutter.dart';
import 'package:provider/provider.dart';
import '../../helpers/appactor_helper.dart';
import '../../services/supabase_service.dart';
import '../../providers/app_provider.dart';
import 'dart:async';

class AntiquePremiumViewModel extends ChangeNotifier {
  bool _isWeeklySelected = false;
  bool _isYearlySelected = true;
  bool _isLoading = false;
  bool _showYearlyAsMonthly = true; // Remote config value
  bool _configLoaded = false; // Track if remote config has been loaded
  StreamSubscription? _configSubscription;

  bool get isWeeklySelected => _isWeeklySelected;
  bool get isYearlySelected => _isYearlySelected;
  bool get isLoading => _isLoading;
  bool get showYearlyAsMonthly => _showYearlyAsMonthly;
  bool get configLoaded => _configLoaded;

  AppActorPackage? get weeklyPackage => AppactorHelper.shared.weeklyPackage;
  AppActorPackage? get yearlyPackage => AppactorHelper.shared.yearlyPackage;

  String get weeklyPrice => weeklyPackage?.localizedPriceString ?? '\$4.99';
  String get yearlyPrice => yearlyPackage?.localizedPriceString ?? '\$39.99';

  String get yearlyWeeklyPrice {
    final yearlyPriceValue = yearlyPackage?.price ?? 39.99;
    final weeklyPrice = yearlyPriceValue / 52;
    return '\$${weeklyPrice.toStringAsFixed(2)}/week';
  }

  int get savingsPercentage {
    final weeklyPriceValue = weeklyPackage?.price ?? 4.99;
    final yearlyPriceValue = yearlyPackage?.price ?? 39.99;
    final weeklyYearlyTotal = weeklyPriceValue * 52;
    if (weeklyYearlyTotal > 0) {
      final savings = ((weeklyYearlyTotal - yearlyPriceValue) / weeklyYearlyTotal * 100);
      return savings.round();
    }
    return 70;
  }

  void initialize() async {
    // Set config as loaded immediately to show UI
    _configLoaded = true;
    notifyListeners();

    // Load remote config in background
    _loadRemoteConfig();
    _listenToConfigChanges();

    // Offerings should already be loaded from splash, but check if we need to load them
    if (!AppactorHelper.shared.hasOfferings) {
      await AppactorHelper.shared.loadOfferings();
      notifyListeners();
    }
  }

  Future<void> _loadRemoteConfig() async {
    try {
      final config = await SupabaseService.getAntiqueIdentifierConfig();
      if (config != null) {
        final newStatus = config['status'] ?? true;
        if (_showYearlyAsMonthly != newStatus) {
          _showYearlyAsMonthly = newStatus;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading remote config: $e');
      // Keep default values on error
    }
  }

  void _listenToConfigChanges() {
    _configSubscription = SupabaseService.listenToAntiqueIdentifierConfig().listen(
      (config) {
        if (config != null) {
          final newStatus = config['status'] ?? true;
          if (_showYearlyAsMonthly != newStatus) {
            _showYearlyAsMonthly = newStatus;
            debugPrint('Remote config updated: showYearlyAsMonthly = $_showYearlyAsMonthly');
            notifyListeners();
          }
        }
      },
      onError: (error) {
        debugPrint('Config stream error: $error');
        // Keep using current config on error
      },
    );
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

      AppActorCustomerInfo? customerInfo = await AppactorHelper.shared.purchasePackage(
        packageToPurchase,
        placement: 'premium_screen',
      );

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
      AppActorCustomerInfo? customerInfo = await AppactorHelper.shared.restorePurchases();

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

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }
}
