import 'package:flutter/material.dart';
import '../helpers/storage_helper.dart';

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
    _isPremiumUser = _storageHelper.isPremiumUser();
    _currentLanguage = _storageHelper.getLanguage();
    _currentTheme = _storageHelper.getAppTheme();
    notifyListeners();
  }

  Future<void> setPremiumUser(bool value) async {
    _isPremiumUser = value;
    await _storageHelper.setPremiumUser(value);
    notifyListeners();
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