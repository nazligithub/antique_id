import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/antique_model.dart';

class ScanViewModel extends ChangeNotifier {

  bool _isScanning = false;
  String? _scanError;
  AntiqueModel? _scannedAntique;
  String? _selectedImagePath;
  File? _scannedImage;

  bool get isScanning => _isScanning;
  String? get scanError => _scanError;
  bool get hasScanError => _scanError != null;
  AntiqueModel? get scannedAntique => _scannedAntique;
  String? get selectedImagePath => _selectedImagePath;
  File? get scannedImage => _scannedImage;
  bool get hasResult => _scannedAntique != null;

  Future<void> scanFromCamera() async {
    _isScanning = true;
    _scanError = null;
    _scannedAntique = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      _scannedAntique = AntiqueModel(
        id: 'scanned_1',
        name: 'Victorian Era Pocket Watch',
        description: 'A beautifully crafted gold pocket watch from the Victorian era',
        imageUrl: '',
        price: '\$15,000',
        era: '1880s',
        origin: 'England',
      );
    } catch (e) {
      _scanError = 'Failed to scan. Please try again.';
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> scanFromGallery() async {
    _isScanning = true;
    _scanError = null;
    _scannedAntique = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      _scannedAntique = AntiqueModel(
        id: 'scanned_2',
        name: 'Chinese Ming Vase',
        description: 'Rare Ming dynasty porcelain vase with intricate blue patterns',
        imageUrl: '',
        price: '\$2.3 million',
        era: '1600s',
        origin: 'China',
      );
    } catch (e) {
      _scanError = 'Failed to scan. Please try again.';
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> processScannedImage(File imageFile) async {
    _isScanning = true;
    _scanError = null;
    _scannedAntique = null;
    _scannedImage = imageFile;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      _scannedAntique = AntiqueModel(
        id: 'scanned_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Analyzed Antique Item',
        description: 'A valuable antique item analyzed from your photo',
        imageUrl: imageFile.path,
        price: '\$8,500',
        era: '1900s',
        origin: 'Europe',
      );
    } catch (e) {
      _scanError = 'Failed to analyze image. Please try again.';
      debugPrint('Image processing error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _scannedAntique = null;
    _selectedImagePath = null;
    _scannedImage = null;
    _scanError = null;
    notifyListeners();
  }

  void addToCollection() {
    if (_scannedAntique != null) {
      debugPrint('Adding ${_scannedAntique!.name} to collection');
    }
  }

}