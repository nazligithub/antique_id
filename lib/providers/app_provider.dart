import 'package:flutter/material.dart';
import '../helpers/storage_helper.dart';
import '../helpers/appactor_helper.dart';

class AppProvider extends ChangeNotifier {
  final StorageHelper _storageHelper = StorageHelper();

  int _selectedTabIndex = 0;
  bool _isPremiumUser = false;
  String _currentLanguage = 'en';
  String _currentTheme = 'light';

  int get selectedTabIndex => _selectedTabIndex;
  bool get isPremiumUser => _isPremiumUser;
  String get currentLanguage => _currentLanguage;
  String get currentTheme => _currentTheme;

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  bool _homeScrollToTopRequested = false;
  bool get homeScrollToTopRequested => _homeScrollToTopRequested;

  set homeScrollToTopRequested(bool value) {
    _homeScrollToTopRequested = value;
    if (value) {
      Future.microtask(() {
        _homeScrollToTopRequested = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  bool _collectionScrollToTopRequested = false;
  bool get collectionScrollToTopRequested => _collectionScrollToTopRequested;

  set collectionScrollToTopRequested(bool value) {
    _collectionScrollToTopRequested = value;
    if (value) {
      Future.microtask(() {
        _collectionScrollToTopRequested = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> loadUserPreferences() async {
    try {
      // First check local storage for premium status (for offline mode)
      bool localPremiumStatus = _storageHelper.isPremiumUser();

      // Try to sync with Appactor
      bool appactorSynced = false;
      if (AppactorHelper.shared.isInitialized) {
        appactorSynced = await AppactorHelper.shared.checkSubscription();
        _isPremiumUser = AppactorHelper.shared.isActive;
      }

      // If Appactor sync failed, use local storage value
      if (!appactorSynced && localPremiumStatus) {
        debugPrint('Appactor sync failed, using local premium status: $localPremiumStatus');
        _isPremiumUser = localPremiumStatus;
      }

      // Update storage to keep in sync
      await _storageHelper.setPremiumUser(_isPremiumUser);

      _currentLanguage = _storageHelper.getLanguage();
      _currentTheme = _storageHelper.getAppTheme();

      debugPrint('User preferences loaded - Premium: $_isPremiumUser, Language: $_currentLanguage');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      // On error, use local storage values
      _isPremiumUser = _storageHelper.isPremiumUser();
      _currentLanguage = _storageHelper.getLanguage();
      _currentTheme = _storageHelper.getAppTheme();
      notifyListeners();
    }
  }

  Future<void> setPremiumUser(bool value) async {
    _isPremiumUser = value;
    await _storageHelper.setPremiumUser(value);
    debugPrint('Premium status updated: $value');
    notifyListeners();
  }

  /// Check and update premium status from Appactor
  Future<void> refreshPremiumStatus() async {
    try {
      bool newStatus = await AppactorHelper.shared.checkSubscription();

      if (_isPremiumUser != newStatus) {
        _isPremiumUser = newStatus;
        await _storageHelper.setPremiumUser(_isPremiumUser);
        debugPrint('Premium status refreshed: $_isPremiumUser');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing premium status: $e');
    }
  }

  /// Sync purchases with Appactor (useful after app restart or restore)
  Future<void> syncPurchases() async {
    try {
      bool newStatus = await AppactorHelper.shared.syncPurchases();

      if (_isPremiumUser != newStatus) {
        _isPremiumUser = newStatus;
        await _storageHelper.setPremiumUser(_isPremiumUser);
        debugPrint('Purchases synced - Premium status: $_isPremiumUser');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing purchases: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _storageHelper.setLanguage(language);
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _currentTheme = theme;
    await _storageHelper.setAppTheme(theme);
    notifyListeners();
  }

  void reset() {
    _selectedTabIndex = 0;
    _isPremiumUser = false;
    _currentLanguage = 'en';
    _currentTheme = 'light';
    _homeScrollToTopRequested = false;
    _collectionScrollToTopRequested = false;
    notifyListeners();
  }
}
