import 'package:flutter/material.dart';

class MainTabViewModel extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void onHomeTabDoubleTap() {
    debugPrint('Home tab double tapped');
  }

  void onCollectionTabDoubleTap() {
    debugPrint('Collection tab double tapped');
  }

  void selectFloatingActionButton() {
    setIndex(1); // Scan ekranı ortada olduğu için index 1
  }

}